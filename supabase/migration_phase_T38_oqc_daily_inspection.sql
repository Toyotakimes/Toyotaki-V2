-- T38 — OQC kiểm tra hằng ngày, danh mục lỗi động và audit bất biến.
create table if not exists public.oqc_defect_catalog(id bigserial primary key,code text not null unique,label text not null,is_active boolean not null default true,sort_order int not null default 100,updated_at timestamptz not null default now());
insert into public.oqc_defect_catalog(code,label,sort_order) values
('nut','Nứt',1),('sut','Sứt',2),('ro_khi','Rỗ khí',3),('bavia','Bavia',4),('xuoc','Xước',5),('bong_nhom','Bong nhôm',6),('cong_venh','Cong vênh/biến dạng',7),('loi_ren','Thiếu ren/thủng ren',8),('vat_c','Vật C',9),('nhan','Nhăn',10),('di_vat','Dị vật',11),('dap_lech','Dập lệch',12),('ga_lech','Gá lệch',13),('ng_kich_thuoc','NG kích thước',14),('chat_jig','Chật Jig',15),('va_dap','Va đập',16),('khong_gia_cong','Không gia công',17) on conflict(code) do nothing;
create table if not exists public.oqc_daily_inspection(
 id bigserial primary key,inspection_date date not null,shift text not null,product_code text not null,product_name text not null,inspector_id uuid not null default auth.uid(),inspector_name text not null,
 total_qty numeric not null check(total_qty>=0),ok_qty numeric not null check(ok_qty>=0),ng_qty numeric not null check(ng_qty>=0),count_mode text not null default 'OCCURRENCE' check(count_mode in('PRODUCT','OCCURRENCE')),
 defects jsonb not null default '{}'::jsonb,note text,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
 check(ok_qty+ng_qty=total_qty)
);
create table if not exists public.oqc_daily_inspection_audit(id bigserial primary key,inspection_id bigint not null references public.oqc_daily_inspection(id),actor_id uuid,actor_name text not null,old_data jsonb,new_data jsonb,changed_at timestamptz not null default now());
alter table public.oqc_defect_catalog enable row level security;alter table public.oqc_daily_inspection enable row level security;alter table public.oqc_daily_inspection_audit enable row level security;
drop policy if exists "oqc catalog read" on public.oqc_defect_catalog;create policy "oqc catalog read" on public.oqc_defect_catalog for select using(true);
drop policy if exists "oqc catalog admin insert" on public.oqc_defect_catalog;create policy "oqc catalog admin insert" on public.oqc_defect_catalog for insert to authenticated with check(public.has_role('admin','qc_manager'));
drop policy if exists "oqc catalog admin update" on public.oqc_defect_catalog;create policy "oqc catalog admin update" on public.oqc_defect_catalog for update to authenticated using(public.has_role('admin','qc_manager')) with check(public.has_role('admin','qc_manager'));
drop policy if exists "oqc inspection read" on public.oqc_daily_inspection;create policy "oqc inspection read" on public.oqc_daily_inspection for select to authenticated using(true);
drop policy if exists "oqc audit read" on public.oqc_daily_inspection_audit;create policy "oqc audit read" on public.oqc_daily_inspection_audit for select to authenticated using(true);
revoke insert,update,delete on public.oqc_daily_inspection,public.oqc_daily_inspection_audit from anon,authenticated;
create or replace function public.oqc_save_daily_inspection(p_id bigint,p_data jsonb,p_actor text) returns bigint language plpgsql security definer set search_path=public as $$
declare v_id bigint;v_old jsonb;v_total numeric:=coalesce((p_data->>'total_qty')::numeric,0);v_ng numeric:=coalesce((p_data->>'ng_qty')::numeric,0);v_def numeric;v_mode text:=coalesce(p_data->>'count_mode','OCCURRENCE');
begin
 if auth.uid() is null then raise exception 'Cần đăng nhập MES';end if;
 if not public.has_role('admin','qc_manager') and (p_data->>'inspection_date')::date <> (now() at time zone 'Asia/Bangkok')::date then raise exception 'Chỉ Admin/QL chất lượng được sửa ngày kiểm tra';end if;
 if v_ng>v_total then raise exception 'NG không được lớn hơn Tổng kiểm';end if;
 select coalesce(sum(value::numeric),0) into v_def from jsonb_each_text(coalesce(p_data->'defects','{}'::jsonb));
 if v_mode='PRODUCT' and v_def<>v_ng then raise exception 'Đếm theo sản phẩm NG: tổng lỗi chi tiết phải bằng NG';end if;
 if v_mode='OCCURRENCE' and v_def<v_ng then raise exception 'Đếm theo lần phát sinh: tổng lỗi chi tiết phải lớn hơn hoặc bằng NG';end if;
 if p_id is null then
  insert into oqc_daily_inspection(inspection_date,shift,product_code,product_name,inspector_name,total_qty,ok_qty,ng_qty,count_mode,defects,note)
  values((p_data->>'inspection_date')::date,p_data->>'shift',p_data->>'product_code',p_data->>'product_name',p_actor,v_total,v_total-v_ng,v_ng,v_mode,p_data->'defects',p_data->>'note') returning id into v_id;
 else
  select to_jsonb(x) into v_old from oqc_daily_inspection x where id=p_id for update;if v_old is null then raise exception 'Không tìm thấy record';end if;
  update oqc_daily_inspection set inspection_date=(p_data->>'inspection_date')::date,shift=p_data->>'shift',product_code=p_data->>'product_code',product_name=p_data->>'product_name',total_qty=v_total,ok_qty=v_total-v_ng,ng_qty=v_ng,count_mode=v_mode,defects=p_data->'defects',note=p_data->>'note',updated_at=now() where id=p_id;v_id:=p_id;
  insert into oqc_daily_inspection_audit(inspection_id,actor_id,actor_name,old_data,new_data) values(v_id,auth.uid(),p_actor,v_old,(select to_jsonb(x) from oqc_daily_inspection x where id=v_id));
 end if;return v_id;
end $$;
grant execute on function public.oqc_save_daily_inspection(bigint,jsonb,text) to authenticated;
create or replace function public.oqc_audit_immutable() returns trigger language plpgsql as $$begin raise exception 'Lịch sử OQC không được sửa hoặc xóa';end$$;
drop trigger if exists trg_oqc_audit_immutable on public.oqc_daily_inspection_audit;create trigger trg_oqc_audit_immutable before update or delete on public.oqc_daily_inspection_audit for each row execute function public.oqc_audit_immutable();
