-- 20260915140000 - IQC/OQC schema repair for Toyotaki V2 test.
-- Additive/idempotent only: no DROP TABLE, DROP COLUMN, TRUNCATE or data DELETE.
-- IQC schema is derived from the field mappings in iqc.html; OQC reuses quality_defect_catalog.

-- T40 - Du lieu IQC cu do nguoi dung cung cap (08-09/2026). Idempotent theo ma phieu.
-- Database hien tai chua co bat ky bang IQC nao, nen migration nay tu tao schema truoc khi nap du lieu cu.
create table if not exists public.iqc_lots(
 id bigserial primary key,received_at timestamptz,pickup_at timestamptz,completed_at timestamptz,supplier text,
 product_code text,product_name text,lot_no text,lot_qty numeric default 0,inspection_type text default 'Kiểm tra AQL',
 aql text,sample_qty numeric default 0,location text default 'Kho',status text default 'Chưa lấy hàng',result text,
 ok_qty numeric default 0,ng_qty numeric default 0,ok_pct numeric default 0,ng_pct numeric default 0,inspector text,
 note text,inspection_minutes integer default 0,created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create table if not exists public.iqc_defects(
 id bigserial primary key,lot_id bigint not null references public.iqc_lots(id) on delete cascade,defect_type text default 'NG khác',
 defect_name text,defect_qty numeric default 0,defect_percent numeric default 0,note text,images text,
 created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create table if not exists public.iqc_appearance_defects(id serial primary key,label text not null unique,sort_order integer not null default 100,created_at timestamptz not null default now());
create table if not exists public.iqc_lot_audit(id bigserial primary key,lot_id bigint,action text not null,old_data jsonb,new_data jsonb,actor uuid default auth.uid(),changed_at timestamptz not null default now());
create index if not exists idx_iqc_lots_created_at on public.iqc_lots(created_at desc);
create index if not exists idx_iqc_lots_product on public.iqc_lots(product_code,product_name,lot_no);
create index if not exists idx_iqc_defects_lot_id on public.iqc_defects(lot_id);
alter table public.iqc_lots enable row level security;alter table public.iqc_defects enable row level security;alter table public.iqc_appearance_defects enable row level security;alter table public.iqc_lot_audit enable row level security;
drop policy if exists "public read iqc_lots" on public.iqc_lots;create policy "public read iqc_lots" on public.iqc_lots for select using(true);
drop policy if exists "authenticated insert iqc_lots" on public.iqc_lots;create policy "authenticated insert iqc_lots" on public.iqc_lots for insert to authenticated with check(auth.uid() is not null);
drop policy if exists "authenticated update iqc_lots" on public.iqc_lots;create policy "authenticated update iqc_lots" on public.iqc_lots for update to authenticated using(auth.uid() is not null) with check(auth.uid() is not null);
drop policy if exists "authenticated delete iqc_lots" on public.iqc_lots;create policy "authenticated delete iqc_lots" on public.iqc_lots for delete to authenticated using(auth.uid() is not null);
drop policy if exists "public read iqc_defects" on public.iqc_defects;create policy "public read iqc_defects" on public.iqc_defects for select using(true);
drop policy if exists "authenticated insert iqc_defects" on public.iqc_defects;create policy "authenticated insert iqc_defects" on public.iqc_defects for insert to authenticated with check(auth.uid() is not null);
drop policy if exists "authenticated update iqc_defects" on public.iqc_defects;create policy "authenticated update iqc_defects" on public.iqc_defects for update to authenticated using(auth.uid() is not null) with check(auth.uid() is not null);
drop policy if exists "authenticated delete iqc_defects" on public.iqc_defects;create policy "authenticated delete iqc_defects" on public.iqc_defects for delete to authenticated using(auth.uid() is not null);
drop policy if exists "public read iqc_appearance_defects" on public.iqc_appearance_defects;create policy "public read iqc_appearance_defects" on public.iqc_appearance_defects for select using(true);
drop policy if exists "authenticated write iqc_appearance_defects" on public.iqc_appearance_defects;create policy "authenticated write iqc_appearance_defects" on public.iqc_appearance_defects for all to authenticated using(auth.uid() is not null) with check(auth.uid() is not null);
drop policy if exists "authenticated read iqc audit" on public.iqc_lot_audit;create policy "authenticated read iqc audit" on public.iqc_lot_audit for select to authenticated using(true);
create or replace function public.iqc_touch_updated_at()returns trigger language plpgsql as $$begin new.updated_at=now();return new;end$$;
drop trigger if exists trg_iqc_lots_touch on public.iqc_lots;create trigger trg_iqc_lots_touch before update on public.iqc_lots for each row execute function public.iqc_touch_updated_at();
drop trigger if exists trg_iqc_defects_touch on public.iqc_defects;create trigger trg_iqc_defects_touch before update on public.iqc_defects for each row execute function public.iqc_touch_updated_at();
create or replace function public.iqc_capture_lot_audit()returns trigger language plpgsql security definer set search_path=public as $$begin insert into iqc_lot_audit(lot_id,action,old_data,new_data)values(case when tg_op='DELETE' then old.id else new.id end,tg_op,case when tg_op in('UPDATE','DELETE')then to_jsonb(old)end,case when tg_op in('INSERT','UPDATE')then to_jsonb(new)end);if tg_op='DELETE' then return old;end if;return new;end$$;
drop trigger if exists trg_iqc_lot_audit on public.iqc_lots;create trigger trg_iqc_lot_audit after insert or update or delete on public.iqc_lots for each row execute function public.iqc_capture_lot_audit();

-- T38 - Master loi dung chung va phieu OQC kiem tra thanh pham.
alter table public.master_employees add column if not exists ma_nv text;
create unique index if not exists uq_master_employees_ma_nv on public.master_employees(ma_nv) where ma_nv is not null;
create table if not exists public.quality_defect_catalog(id bigserial primary key,code text not null unique,label text not null,defect_group text not null check(defect_group in('NG ngoại quan','NG kích thước','NG khác')),processes text[] not null default array['IQC','OQC','IPQC'],is_active boolean not null default true,sort_order int not null default 100,updated_at timestamptz not null default now());
insert into public.quality_defect_catalog(code,label,defect_group,processes,sort_order) values
('nut','Nứt','NG ngoại quan',array['IQC','OQC','IPQC'],1),('sut','Sứt','NG ngoại quan',array['IQC','OQC','IPQC'],2),('ro_khi','Rỗ khí','NG ngoại quan',array['IQC','OQC','IPQC'],3),('bavia','Bavia','NG ngoại quan',array['OQC','IPQC'],4),('xuoc','Xước','NG ngoại quan',array['IQC','OQC','IPQC'],5),('bong_nhom','Bong nhôm','NG ngoại quan',array['OQC','IPQC'],6),('cong_venh','Cong vênh/biến dạng','NG ngoại quan',array['IQC','OQC','IPQC'],7),('vat_c','Vật C','NG ngoại quan',array['IQC','OQC','IPQC'],8),('nhan','Nhăn','NG ngoại quan',array['OQC','IPQC'],9),('di_vat','Dị vật','NG ngoại quan',array['IQC','OQC','IPQC'],10),('dap_lech','Dập lệch','NG ngoại quan',array['OQC','IPQC'],11),('ga_lech','Gá lệch','NG ngoại quan',array['OQC','IPQC'],12),('va_dap','Va đập','NG ngoại quan',array['IQC','OQC','IPQC'],13),('khong_gia_cong','Không gia công','NG ngoại quan',array['OQC','IPQC'],14),('ng_kich_thuoc','Sai kích thước','NG kích thước',array['IQC','OQC','IPQC'],30),('chat_jig','Chật JIG','NG kích thước',array['IQC','OQC','IPQC'],31),('loi_ren','Thiếu ren/thủng ren','NG kích thước',array['IQC','OQC','IPQC'],32) on conflict(code) do update set label=excluded.label,defect_group=excluded.defect_group,processes=excluded.processes;
do $$begin if to_regclass('public.iqc_appearance_defects') is not null then insert into public.quality_defect_catalog(code,label,defect_group,processes,sort_order) select 'iqc_'||substr(md5(label),1,12),label,'NG ngoại quan',array['IQC','OQC'],100+sort_order from public.iqc_appearance_defects on conflict(code) do nothing;end if;end$$;
create table if not exists public.oqc_daily_inspection(id bigserial primary key,inspection_date date not null,shift text not null,product_code text not null,product_name text not null,inspector_code text not null,inspector_name text not null,total_qty numeric not null check(total_qty>=0),ok_qty numeric not null check(ok_qty>=0),ng_qty numeric not null check(ng_qty>=0),defects jsonb not null default '[]'::jsonb,note text,created_by uuid default auth.uid(),created_at timestamptz not null default now(),updated_at timestamptz not null default now(),check(ok_qty+ng_qty=total_qty));
create table if not exists public.oqc_daily_inspection_audit(id bigserial primary key,inspection_id bigint not null references public.oqc_daily_inspection(id),actor_id uuid,actor_name text not null,old_data jsonb,new_data jsonb,changed_at timestamptz not null default now());
alter table public.quality_defect_catalog enable row level security;alter table public.oqc_daily_inspection enable row level security;alter table public.oqc_daily_inspection_audit enable row level security;
drop policy if exists "quality defect read" on public.quality_defect_catalog;create policy "quality defect read" on public.quality_defect_catalog for select using(true);
drop policy if exists "quality defect admin write" on public.quality_defect_catalog;create policy "quality defect admin write" on public.quality_defect_catalog for all to authenticated using(public.has_role('admin','qc_manager')) with check(public.has_role('admin','qc_manager'));
drop policy if exists "oqc inspection read" on public.oqc_daily_inspection;create policy "oqc inspection read" on public.oqc_daily_inspection for select to authenticated using(true);
drop policy if exists "oqc audit read" on public.oqc_daily_inspection_audit;create policy "oqc audit read" on public.oqc_daily_inspection_audit for select to authenticated using(true);
revoke insert,update,delete on public.oqc_daily_inspection,public.oqc_daily_inspection_audit from anon,authenticated;
create or replace function public.oqc_save_daily_inspection(p_id bigint,p_data jsonb,p_actor text) returns bigint language plpgsql security definer set search_path=public as $$declare v_id bigint;v_old jsonb;v_total numeric:=coalesce((p_data->>'total_qty')::numeric,0);v_ng numeric;begin
if auth.uid() is null then raise exception 'Cần đăng nhập MES';end if;select coalesce(sum(coalesce((x->>'qty')::numeric,0)),0) into v_ng from jsonb_array_elements(coalesce(p_data->'defects','[]'::jsonb))x;if v_total<=0 or v_ng>v_total then raise exception 'Tổng kiểm phải lớn hơn 0 và Tổng NG chi tiết không được vượt Tổng kiểm';end if;if trim(coalesce(p_data->>'product_code',''))='' or trim(coalesce(p_data->>'inspector_code',''))='' then raise exception 'Thiếu Model hoặc mã nhân viên';end if;if not exists(select 1 from master_products where ma_sp=p_data->>'product_code') then raise exception 'Model không có trong Master';end if;
if p_id is null then insert into oqc_daily_inspection(inspection_date,shift,product_code,product_name,inspector_code,inspector_name,total_qty,ok_qty,ng_qty,defects,note)values((p_data->>'inspection_date')::date,p_data->>'shift',p_data->>'product_code',p_data->>'product_name',p_data->>'inspector_code',coalesce(nullif(p_data->>'inspector_name',''),p_data->>'inspector_code'),v_total,v_total-v_ng,v_ng,p_data->'defects',p_data->>'note')returning id into v_id;
else select to_jsonb(x) into v_old from oqc_daily_inspection x where id=p_id for update;if v_old is null then raise exception 'Không tìm thấy record';end if;update oqc_daily_inspection set inspection_date=(p_data->>'inspection_date')::date,shift=p_data->>'shift',product_code=p_data->>'product_code',product_name=p_data->>'product_name',inspector_code=p_data->>'inspector_code',inspector_name=coalesce(nullif(p_data->>'inspector_name',''),p_data->>'inspector_code'),total_qty=v_total,ok_qty=v_total-v_ng,ng_qty=v_ng,defects=p_data->'defects',note=p_data->>'note',updated_at=now()where id=p_id;v_id:=p_id;insert into oqc_daily_inspection_audit(inspection_id,actor_id,actor_name,old_data,new_data)values(v_id,auth.uid(),p_actor,v_old,(select to_jsonb(x)from oqc_daily_inspection x where id=v_id));end if;return v_id;end$$;
grant execute on function public.oqc_save_daily_inspection(bigint,jsonb,text) to authenticated;
create or replace function public.oqc_audit_immutable()returns trigger language plpgsql as $$begin raise exception 'Lịch sử OQC không được sửa hoặc xóa';end$$;drop trigger if exists trg_oqc_audit_immutable on public.oqc_daily_inspection_audit;create trigger trg_oqc_audit_immutable before update or delete on public.oqc_daily_inspection_audit for each row execute function public.oqc_audit_immutable();

-- Force PostgREST to see the newly-created relations immediately after commit.
notify pgrst, 'reload schema';
notify pgrst, 'reload config';
