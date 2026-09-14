-- ===========================================================================
-- XÓA LỊCH SỬ IPQC CHO 4 TÀI KHOẢN ĐƯỢC YÊU CẦU
-- Chạy trong Supabase SQL Editor bằng tài khoản admin / service_role.
--
-- Mục tiêu của file này:
--   1) Chỉ xoá lịch sử ở bảng duc_ipqc_checkpoint
--   2) Không chạm tới user_roles / user_id / dữ liệu tài khoản khác
--   3) Backup trước khi xoá, để có thể xem lại nếu cần
--
-- Dữ liệu cần xoá:
--   - Ninh QC
--   - GĐSX
--   - nguyenvanhangvinhyenvinhphuc@gmail.com
--   - binhsau83@gmail.com
-- ===========================================================================

-- 0) Tạo bảng backup nếu chưa có
create table if not exists public.duc_ipqc_checkpoint_backup_20260914
(like public.duc_ipqc_checkpoint including all);

-- 1) Backup toàn bộ checkpoint thuộc 4 người trên
insert into public.duc_ipqc_checkpoint_backup_20260914
select cp.*
from public.duc_ipqc_checkpoint cp
where lower(trim(cp.nguoi_kiem)) in (
  lower('Ninh QC'),
  lower('GĐSX'),
  lower('nguyenvanhangvinhyenvinhphuc@gmail.com'),
  lower('binhsau83@gmail.com')
)
   or lower(trim(cp.nguoi_kiem)) in (
        select lower(email)
        from public.user_roles
        where lower(email) in (
          'nguyenvanhangvinhyenvinhphuc@gmail.com',
          'binhsau83@gmail.com'
        )
      )
   or lower(trim(cp.nguoi_kiem)) in (
        select lower(full_name)
        from public.user_roles
        where lower(full_name) in ('ninh qc', 'gđsx')
      )
   or lower(trim(cp.nguoi_kiem)) in (
        select lower(username)
        from public.user_roles
        where lower(username) in ('ninh qc', 'gđsx')
      )
   or lower(trim(cp.nguoi_kiem)) in (
        select lower(username || '_' || full_name)
        from public.user_roles
        where username is not null and full_name is not null
      )
on conflict (id_checkpoint) do nothing;

-- 2) Xóa lịch sử IPQC của 4 người này
delete from public.duc_ipqc_checkpoint cp
where lower(trim(cp.nguoi_kiem)) in (
  lower('Ninh QC'),
  lower('GĐSX'),
  lower('nguyenvanhangvinhyenvinhphuc@gmail.com'),
  lower('binhsau83@gmail.com')
)
   or lower(trim(cp.nguoi_kiem)) in (
        select lower(email)
        from public.user_roles
        where lower(email) in (
          'nguyenvanhangvinhyenvinhphuc@gmail.com',
          'binhsau83@gmail.com'
        )
      )
   or lower(trim(cp.nguoi_kiem)) in (
        select lower(full_name)
        from public.user_roles
        where lower(full_name) in ('ninh qc', 'gđsx')
      )
   or lower(trim(cp.nguoi_kiem)) in (
        select lower(username)
        from public.user_roles
        where lower(username) in ('ninh qc', 'gđsx')
      )
   or lower(trim(cp.nguoi_kiem)) in (
        select lower(username || '_' || full_name)
        from public.user_roles
        where username is not null and full_name is not null
      );

-- 3) Kiểm tra kết quả
select
  'Backup checkpoints' as label,
  count(*) as row_count
from public.duc_ipqc_checkpoint_backup_20260914
union all
select
  'Remaining checkpoints after delete' as label,
  count(*) as row_count
from public.duc_ipqc_checkpoint
where lower(trim(nguoi_kiem)) in (
  lower('Ninh QC'),
  lower('GĐSX'),
  lower('nguyenvanhangvinhyenvinhphuc@gmail.com'),
  lower('binhsau83@gmail.com')
);

-- 4) Xem số bản ghi đã backup
select 'duc_ipqc_checkpoint_backup_20260914' as backup_table, count(*) as rows
from public.duc_ipqc_checkpoint_backup_20260914;

-- 5) Xem danh sách người kiểm đã bị xóa (từ backup)
select
  nguoi_kiem,
  count(*) as so_ban_ghi
from public.duc_ipqc_checkpoint_backup_20260914
group by nguoi_kiem
order by so_ban_ghi desc, nguoi_kiem;

-- GHI CHÚ:
-- Script này CHỈ xoá lịch sử IPQC ở bảng duc_ipqc_checkpoint.
-- Nó KHÔNG xoá user_roles, user_id, email, username hoặc dữ liệu tài khoản khác.
