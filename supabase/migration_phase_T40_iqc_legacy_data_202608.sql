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
alter table public.iqc_lots add column if not exists legacy_id text;
create unique index if not exists uq_iqc_lots_legacy_id on public.iqc_lots(legacy_id) where legacy_id is not null;
insert into public.iqc_lots(legacy_id,received_at,pickup_at,completed_at,supplier,product_code,product_name,lot_no,lot_qty,inspection_type,aql,sample_qty,location,status,result,ok_qty,ng_qty,inspector,note,inspection_minutes) values
('IQC-20260814-090012','2026-07-30 15:53+07','2026-08-03 10:53+07','2026-08-14 00:00+07','Việt Pháp','27L024-003P01','Inner S','30052026',1814,'Kiểm tra 100%',null,1814,'IQC','Đã kiểm tra','NG',1764,50,'Dung','',6067),
('IQC-20260814-112353-142','2026-08-12 18:25+07','2026-08-14 08:25+07','2026-08-24 00:00+07','MINHGANH','FSL140K','Handle Chưa In','12082026',2790,'Kiểm tra 100%',null,2790,'Kho','Đã kiểm tra','NG',2383,407,'Thủy + Trinh + Thủy','',14462),
('IQC-20260814-161329-569','2026-08-24 08:01+07','2026-08-24 08:02+07','2026-08-24 00:00+07','HANIN','FSL140K','Handle Đã In','13082026',729,'Kiểm tra 100%',null,729,'Đã trả','Đã kiểm tra','NG',715,14,'Thủy + Thủy','',428),
('IQC-20260814-162014-008','2026-08-13 22:18+07','2026-08-14 15:00+07','2026-08-14 00:00+07','HANIN','27L024-004A01','Chốt PIN','1208202602',14400,'Kiểm tra 100%',null,14400,'IQC','Đã kiểm tra','NG',13844,556,'Dung','NG trả nhà cung cấp BRV, HANIN',0),
('IQC-20260814-162723-291','2026-08-13 13:00+07','2026-08-13 13:00+07','2026-08-14 00:00+07','Asahi','641801012','DRILL PUMP HOUSINGVN','1308202601',300,'Kiểm tra 100%',null,300,'Đã trả','Đã kiểm tra','NG',296,4,'Dung + Yến','',660),
('IQC-20260814-165049-060','2026-08-13 13:00+07','2026-08-13 13:00+07','2026-08-19 00:00+07','Asahi','641801016','PUMP HOUSING MASTER','1308202602',180,'Kiểm tra AQL',null,180,'IQC','Đã kiểm tra','OK',180,0,'Yến','',8336),
('IQC-20260817-082119-119','2026-08-17 08:19+07','2026-08-17 14:00+07','2026-08-21 00:00+07','Việt Pháp','27L025-002P01','Inner L','1508202601',1600,'Kiểm tra 100%',null,1600,'Kho','Đã kiểm tra','NG',1596,4,'Dung','',5835),
('IQC-20260817-114136-668','2026-08-05 10:42+07','2026-08-06 15:30+07','2026-08-14 00:00+07','MINHGANH','FSL140K','Handle Chưa In','508202601',2904,'Kiểm tra 100%',null,2904,'Kho','Đã kiểm tra','NG',1322,1582,'Trinh + Giang','',11480),
('IQC-20260815-145103-216','2026-08-15 16:52+07','2026-08-20 00:00+07','2026-08-26 00:00+07','Việt Pháp','27L025-001P01','Outer L','1508202601',11016,'Kiểm tra AQL','1.0',315,'Đã trả','Đã kiểm tra','OK',315,0,'Dung','',9024),
('IQC-20260818-165326-918','2026-08-17 16:56+07','2026-08-18 00:00+07','2026-08-18 00:00+07','BRV','27L024-005P01','Chốt PIN INOX','1708202601',15500,'Kiểm tra AQL','1.0',315,'Kho','Đã kiểm tra','NG',0,0,'Dung','Trả lại NCC ngày 22/08',479),
('IQC-20260821-164171-208','2026-08-21 14:45+07','2026-08-24 00:00+07','2026-08-25 00:00+07','Việt Pháp','FSL140K','Handle Đã In','2108202601',1201,'Kiểm tra 100%',null,1201,'Kho','Đã kiểm tra','NG',1159,42,'Thủy','',1840),
('IQC-20260821-164619-990','2026-08-21 09:00+07','2026-08-24 00:00+07','2026-08-25 00:00+07','Việt Pháp','27L025-002P01','Inner L','2108202601',3788,'Kiểm tra 100%',null,3788,'IQC','Đã kiểm tra','NG',3775,13,'Dung','',3217),
('IQC-20260826-113607-745','2026-08-24 18:13+07','2026-08-26 09:35+07','2026-08-27 00:00+07','Việt Pháp','27L024-003P01','Inner S','2008202602',1646,'Kiểm tra 100%',null,1646,'Đã trả','Đã kiểm tra','OK',1646,0,'Dung','',1802),
('IQC-20260826-170034-875','2026-08-26 07:58+07','2026-08-27 07:00+07','2026-08-28 00:00+07','Việt Pháp','27L024-005P01','Chốt PIN INOX','2608202601',3920,'Kiểm tra 100%',null,3920,'Đã trả','Đã kiểm tra','NG',3245,675,'Dung','',1860),
('IQC-20260903-172117-262','2026-08-24 17:20+07','2026-08-29 08:22+07','2026-09-04 00:00+07','Việt Pháp','27L025-002P01','Inner L','2008202601',3350,'Kiểm tra 100%',null,3350,'IQC','Đã kiểm tra','OK',3350,0,'Dung','',9123),
('IQC-20260903-172334-601','2026-08-28 18:23+07',null,null,'Việt Pháp','27L024-003P01','Inner S','2808202603',2332,'Kiểm tra 100%',null,2332,'Kho','Chưa lấy hàng',null,0,0,'Dung','',0),
('IQC-20260903-172432-288','2026-08-28 18:24+07',null,null,'Việt Pháp','27L025-002P01','Inner L','2808202604',776,'Kiểm tra 100%',null,776,'Kho','Chưa lấy hàng',null,0,0,'Dung','',0),
('IQC-20260905-105922-185','2026-09-04 17:00+07',null,null,'Việt Pháp','27L024-003P01','Inner S','409202601',2674,'Kiểm tra 100%',null,2674,'Kho','Chưa lấy hàng',null,0,0,'Dung','',0),
('IQC-20260905-110009-442','2026-09-04 17:00+07',null,null,'Việt Pháp','27L025-002P01','Inner L','409202602',169,'Kiểm tra 100%',null,169,'Kho','Chưa lấy hàng',null,0,0,'Dung','',0),
('IQC-20260905-154531-600','2026-09-05 17:44+07','2026-09-07 08:45+07',null,'Việt Pháp','27L026-001P01','Outer LL','509202601',5000,'Kiểm tra AQL','1.0',500,'IQC','Đang kiểm tra',null,0,0,'Dung','',0)
on conflict(legacy_id) do nothing;

with d(legacy_id,defect_type,defect_name,qty,at) as(values
('IQC-20260814-090012','NG ngoại quan','Kéo xước, va đập',34,'2026-08-14 15:55:00+07'::timestamptz),('IQC-20260814-090012','NG ngoại quan','Nứt, sứt, rạn',4,'2026-08-14 15:55:01+07'),('IQC-20260814-090012','NG ngoại quan','Khác màu, loang',8,'2026-08-14 15:55:05+07'),('IQC-20260814-090012','NG ngoại quan','Khác — khác',4,'2026-08-14 15:55:09+07'),
('IQC-20260814-162723-291','NG ngoại quan','Kéo xước, va đập',2,'2026-08-14 16:28:50+07'),('IQC-20260814-162723-291','NG ngoại quan','Rỗ khí',1,'2026-08-14 16:28:53+07'),('IQC-20260814-162723-291','NG kích thước','Chật JIG',1,'2026-08-14 16:28:56+07'),
('IQC-20260817-114136-668','NG ngoại quan','Rỗ khí — Mặt C',864,'2026-08-17 11:45:33+07'),('IQC-20260817-114136-668','NG ngoại quan','Rỗ khí — Mặt khác',111,'2026-08-17 11:45:35+07'),('IQC-20260817-114136-668','NG ngoại quan','Mạ lỗi',324,'2026-08-17 11:45:38+07'),('IQC-20260817-114136-668','NG ngoại quan','Khác — NG phôi',283,'2026-08-17 11:45:40+07'),
('IQC-20260814-162014-008','NG ngoại quan','Thừa thiếu liệu — Thiếu nhựa',7,'2026-08-20 00:00+07'),('IQC-20260814-162014-008','NG ngoại quan','Khác — Dị vật nhựa',20,'2026-08-20 00:00:01+07'),('IQC-20260814-162014-008','NG ngoại quan','Kéo xước, va đập — Chốt PIN',529,'2026-08-20 00:00:02+07'),
('IQC-20260814-112353-142','NG kích thước','Chật JIG',27,'2026-08-24 00:00+07'),('IQC-20260814-112353-142','NG ngoại quan','Mạ lỗi',86,'2026-08-24 00:00:01+07'),('IQC-20260814-112353-142','NG ngoại quan','Rỗ khí — Mặt C',139,'2026-08-24 00:00:02+07'),('IQC-20260814-112353-142','NG ngoại quan','Rỗ khí — Mặt khác',44,'2026-08-24 00:00:03+07'),
('IQC-20260814-161329-569','NG ngoại quan','Rỗ khí — Mặt C',3,'2026-08-24 00:00:04+07'),('IQC-20260814-161329-569','NG ngoại quan','Rỗ khí — Mặt khác',6,'2026-08-24 00:00:05+07'),('IQC-20260814-161329-569','NG ngoại quan','Mạ lỗi — Mài lem mặt C, mạ không hết',5,'2026-08-24 00:00:06+07'),
('IQC-20260817-082119-119','NG ngoại quan','Nứt, sứt, rạn',4,'2026-08-24 00:00:07+07'),('IQC-20260821-164619-990','NG ngoại quan','Nứt, sứt, rạn',10,'2026-09-03 00:00+07'),('IQC-20260821-164619-990','NG ngoại quan','Khác — Bẩn',3,'2026-09-03 00:00:01+07'))
insert into public.iqc_defects(lot_id,defect_type,defect_name,defect_qty,defect_percent,created_at)
select l.id,d.defect_type,d.defect_name,d.qty,case when l.sample_qty>0 then d.qty*100/l.sample_qty else 0 end,d.at from d join public.iqc_lots l using(legacy_id)
where not exists(select 1 from public.iqc_defects x where x.lot_id=l.id and x.defect_type=d.defect_type and x.defect_name=d.defect_name and x.defect_qty=d.qty);

grant select on public.iqc_lots,public.iqc_defects,public.iqc_appearance_defects to anon,authenticated;
grant insert,update,delete on public.iqc_lots,public.iqc_defects,public.iqc_appearance_defects to authenticated;
grant select on public.iqc_lot_audit to authenticated;
grant usage,select on sequence public.iqc_lots_id_seq,public.iqc_defects_id_seq,public.iqc_appearance_defects_id_seq to authenticated;
notify pgrst,'reload schema';
