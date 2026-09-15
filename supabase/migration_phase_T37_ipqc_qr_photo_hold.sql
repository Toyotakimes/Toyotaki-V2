-- T37 — IPQC quét tem, tối đa 10 ảnh, tự mở NCP và HOLD ngay trong một giao dịch.
-- Phụ thuộc T30 và T35. Tái sử dụng duc_ncp + duc_tem_cach_ly, không tạo bảng HOLD mới.
create or replace function public.duc_submit_ipqc_check_and_hold(
  p_id_checkpoint text, p_checklist jsonb, p_ket_qua text, p_anh_urls jsonb,
  p_ghi_chu text, p_thoi_gian_kiem_giay numeric, p_nguoi_kiem text, p_tag_no text
) returns jsonb language plpgsql security definer set search_path=public as $$
declare v_result jsonb; v_cp record; v_tem record; v_ncp text; v_open jsonb;
begin
  if auth.uid() is null then raise exception 'Cần đăng nhập MES'; end if;
  if p_ket_qua <> 'NG' then raise exception 'RPC này chỉ dùng cho kết luận NG'; end if;
  if jsonb_typeof(coalesce(p_anh_urls,'[]'::jsonb))<>'array' or jsonb_array_length(coalesce(p_anh_urls,'[]'::jsonb)) not between 1 and 10 then
    raise exception 'Mỗi phiếu IPQC phải có từ 1 đến 10 ảnh';
  end if;
  select * into v_tem from duc_tem where tag_no=trim(p_tag_no) for update;
  if not found then raise exception 'Không tìm thấy tem/LOT % trong MES',p_tag_no; end if;
  select * into v_cp from duc_ipqc_checkpoint where id_checkpoint=p_id_checkpoint for update;
  if not found then raise exception 'Không tìm thấy lần kiểm IPQC %',p_id_checkpoint; end if;
  if v_tem.ma_sp is distinct from v_cp.ma_sp then raise exception 'Tem % không thuộc mã sản phẩm đang kiểm',p_tag_no; end if;

  -- RPC lõi cũ kiểm tối đa 6; truyền 6 ảnh đầu rồi lưu lại đủ tối đa 10 ngay trong cùng transaction.
  select duc_submit_ipqc_check(p_id_checkpoint,p_checklist,p_ket_qua,
    (select coalesce(jsonb_agg(value),'[]'::jsonb) from (select value from jsonb_array_elements(p_anh_urls) with ordinality e(value,n) where n<=6 order by n) x),
    p_ghi_chu,p_thoi_gian_kiem_giay,p_nguoi_kiem) into v_result;
  if not coalesce((v_result->>'ok')::boolean,false) then raise exception '%',coalesce(v_result->>'error','Không lưu được IPQC'); end if;
  update duc_ipqc_checkpoint set anh_bang_chung_url=p_anh_urls where id_checkpoint=p_id_checkpoint;

  select id_ncp_lien_quan into v_ncp from duc_ipqc_checkpoint where id_checkpoint=p_id_checkpoint;
  if nullif(v_ncp,'') is null then
    v_open:=duc_ncp_open_case(p_id_checkpoint,v_cp.ma_may,v_cp.ma_sp,coalesce(v_tem.ten_sp,''),coalesce(v_tem.so_khuon,''),
      p_ghi_chu,greatest(coalesce(v_tem.so_luong,0),1),greatest(coalesce(v_tem.so_luong,0),1),
      'HOLD IPQC — '||p_tag_no,p_nguoi_kiem,p_nguoi_kiem,p_nguoi_kiem);
    if not coalesce((v_open->>'ok')::boolean,false) then raise exception '%',v_open->>'error'; end if;
    v_ncp:=v_open->>'id_ncp';
  end if;

  if duc_tem_id_ncp_cach_ly(p_tag_no) is null then
    insert into duc_tem_cach_ly(tag_no,id_ncp,trang_thai,nguoi_cach_ly) values(p_tag_no,v_ncp,'dang_cach_ly',p_nguoi_kiem);
    perform duc_ncp_append_log(v_ncp,'IPQC xác nhận NG — tự động HOLD tem '||p_tag_no||'; ảnh: '||jsonb_array_length(p_anh_urls));
  end if;
  return v_result||jsonb_build_object('id_ncp',v_ncp,'tag_no',p_tag_no,'lot',v_tem.lot,'hold',true);
end $$;
revoke execute on function public.duc_submit_ipqc_check_and_hold(text,jsonb,text,jsonb,text,numeric,text,text) from anon;
grant execute on function public.duc_submit_ipqc_check_and_hold(text,jsonb,text,jsonb,text,numeric,text,text) to authenticated;

-- Release chỉ hợp lệ khi NCP đã đóng hoặc có phê duyệt tiếp tục chạy còn hiệu lực.
create or replace function public.duc_ncp_giai_toa_tem(p_id_ncp text,p_tag_no text,p_user text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_updated int; v_ncp record; v_special boolean:=false;
begin
  if auth.uid() is null then raise exception 'Cần đăng nhập MES'; end if;
  select * into v_ncp from duc_ncp where id_ncp=p_id_ncp;
  if not found then return jsonb_build_object('ok',false,'error','Không tìm thấy phiếu NCP'); end if;
  if to_regclass('public.duc_ipqc_continue_request') is not null then
    execute 'select exists(select 1 from duc_ipqc_continue_request where checkpoint_id=$1 and status=''Đang có hiệu lực'')'
      into v_special using v_ncp.id_checkpoint_goc;
  end if;
  if coalesce(v_ncp.trang_thai,'')<>'dong' and not v_special then
    return jsonb_build_object('ok',false,'error','LOT chỉ được Release khi hồ sơ NCP đã xử lý xong hoặc có phê duyệt đặc biệt đang hiệu lực');
  end if;
  update duc_tem_cach_ly set trang_thai='da_giai_toa',nguoi_giai_toa=p_user,thoi_diem_giai_toa=now()
  where tag_no=p_tag_no and id_ncp=p_id_ncp and trang_thai='dang_cach_ly';
  get diagnostics v_updated=row_count;
  if v_updated=0 then return jsonb_build_object('ok',false,'error','Không tìm thấy HOLD đang mở cho tem này'); end if;
  perform duc_ncp_append_log(p_id_ncp,'RELEASE LOT/tem '||p_tag_no||' — bởi '||p_user||case when v_special then ' (phê duyệt đặc biệt)' else '' end);
  return jsonb_build_object('ok',true,'tag_no',p_tag_no,'released',true);
end $$;
revoke execute on function public.duc_ncp_giai_toa_tem(text,text,text) from anon;
grant execute on function public.duc_ncp_giai_toa_tem(text,text,text) to authenticated;

