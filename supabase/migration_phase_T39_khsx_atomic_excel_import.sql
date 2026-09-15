-- T39 - Import KHSX tu Excel theo mot giao dich: kiem tra truoc, khong ghi de/ghi nua chung.
create or replace function public.khsx_import_week_plan(
  p_week date, p_department text, p_rows jsonb, p_actor text
) returns jsonb
language plpgsql security definer set search_path=public as $$
declare
  v_count int;
  v_bad text;
begin
  if auth.uid() is null then raise exception 'Cần đăng nhập MES'; end if;
  if p_week is null or p_department is null or jsonb_typeof(p_rows) <> 'array' then
    raise exception 'Dữ liệu import không hợp lệ';
  end if;
  if p_department not in ('Đúc','Bavia','Gia Công','Sơn','OQC') then
    raise exception 'Công đoạn không hợp lệ';
  end if;
  if jsonb_array_length(p_rows)=0 then raise exception 'Không có dòng hợp lệ'; end if;

  select string_agg(distinct r->>'ma_sp', ', ')
    into v_bad from jsonb_array_elements(p_rows) r
   where not exists(select 1 from master_products m where m.ma_sp=r->>'ma_sp');
  if v_bad is not null then raise exception 'Mã SP không có trong Master: %',v_bad; end if;

  if p_department='Đúc' then
    select string_agg(distinct r->>'ma_may', ', ') into v_bad
      from jsonb_array_elements(p_rows) r
     where coalesce(r->>'ma_may','')='' or not exists(select 1 from master_machines m where m.ma_may=r->>'ma_may');
    if v_bad is not null then raise exception 'Mã máy không có trong Master: %',v_bad; end if;
    if exists(select 1 from jsonb_array_elements(p_rows) r group by r->>'ma_may',r->>'ma_sp' having count(*)>1) then
      raise exception 'File có dòng trùng Mã máy + Mã SP';
    end if;
    if exists(select 1 from jsonb_array_elements(p_rows) r join duc_khsx_tuan_plan x on x.tuan_bat_dau=p_week and x.ma_may=r->>'ma_may' and x.ma_sp=r->>'ma_sp') then
      raise exception 'Kế hoạch đã tồn tại; hãy sửa trên màn hình, không import ghi đè';
    end if;
    insert into duc_khsx_tuan_plan(tuan_bat_dau,ma_may,ma_sp,ten_sp,so_khuon,kh_tuan,t2,t3,t4,t5,t6,t7,cn,ghi_chu,updated_by,updated_at)
    select p_week,r->>'ma_may',r->>'ma_sp',coalesce(m.ten_sp,''),coalesce(r->>'so_khuon',''),
      coalesce((r->>'t2')::numeric,0)+coalesce((r->>'t3')::numeric,0)+coalesce((r->>'t4')::numeric,0)+coalesce((r->>'t5')::numeric,0)+coalesce((r->>'t6')::numeric,0)+coalesce((r->>'t7')::numeric,0)+coalesce((r->>'cn')::numeric,0),
      coalesce((r->>'t2')::numeric,0),coalesce((r->>'t3')::numeric,0),coalesce((r->>'t4')::numeric,0),coalesce((r->>'t5')::numeric,0),coalesce((r->>'t6')::numeric,0),coalesce((r->>'t7')::numeric,0),coalesce((r->>'cn')::numeric,0),coalesce(r->>'ghi_chu',''),p_actor,now()
    from jsonb_array_elements(p_rows) r join master_products m on m.ma_sp=r->>'ma_sp';
  else
    if exists(select 1 from jsonb_array_elements(p_rows) r group by r->>'ma_sp' having count(*)>1) then raise exception 'File có Mã SP trùng'; end if;
    if exists(select 1 from jsonb_array_elements(p_rows) r join cd_khsx_tuan_plan x on x.tuan_bat_dau=p_week and x.cong_doan=p_department and x.ma_sp=r->>'ma_sp') then
      raise exception 'Kế hoạch đã tồn tại; hãy sửa trên màn hình, không import ghi đè';
    end if;
    insert into cd_khsx_tuan_plan(tuan_bat_dau,cong_doan,ma_sp,ten_sp,kh_tuan,t2,t3,t4,t5,t6,t7,cn,ghi_chu,updated_by,updated_at)
    select p_week,p_department,r->>'ma_sp',coalesce(m.ten_sp,''),
      coalesce((r->>'t2')::numeric,0)+coalesce((r->>'t3')::numeric,0)+coalesce((r->>'t4')::numeric,0)+coalesce((r->>'t5')::numeric,0)+coalesce((r->>'t6')::numeric,0)+coalesce((r->>'t7')::numeric,0)+coalesce((r->>'cn')::numeric,0),
      coalesce((r->>'t2')::numeric,0),coalesce((r->>'t3')::numeric,0),coalesce((r->>'t4')::numeric,0),coalesce((r->>'t5')::numeric,0),coalesce((r->>'t6')::numeric,0),coalesce((r->>'t7')::numeric,0),coalesce((r->>'cn')::numeric,0),coalesce(r->>'ghi_chu',''),p_actor,now()
    from jsonb_array_elements(p_rows) r join master_products m on m.ma_sp=r->>'ma_sp';
  end if;
  get diagnostics v_count=row_count;
  return jsonb_build_object('inserted',v_count,'department',p_department,'week',p_week);
end $$;
revoke all on function public.khsx_import_week_plan(date,text,jsonb,text) from public,anon;
grant execute on function public.khsx_import_week_plan(date,text,jsonb,text) to authenticated;
