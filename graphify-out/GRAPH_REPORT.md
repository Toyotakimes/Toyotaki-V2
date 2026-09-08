# Graph Report - D:/Project/MES/mes-toyotaki  (2026-08-14)

## Corpus Check
- 57 files · ~127,668 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 428 nodes · 463 edges · 78 communities (56 shown, 22 thin omitted)
- Extraction: 94% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 24 edges (avg confidence: 0.84)
- Token cost: 335,078 input · 0 output

## Community Hubs (Navigation)
- IPQC Checkpoint & Incident RPCs
- Đúc Dashboard ↔ Mobile ↔ Intem Print Flow
- Chất Lượng Dashboard (KPI)
- IPQC Submit & NCP RPCs
- MES Roadmap ↔ Đúc Dashboard Core
- NVL Ledger RPCs
- NVL Inventory Page
- import-duc.mjs (Data Import Script)
- Chất Lượng Schema (cl_* tables)
- QC Manager Monitoring Board
- import-chatluong.mjs (Data Import Script)
- import-chuyencongdoan.mjs (Data Import Script)
- import-sanluong.mjs (Data Import Script)
- IPQC Evidence Upload Flow
- Roadmap: Module Overview & Shared Master Data
- Roadmap: IPQC Migration Rationale
- Sản Lượng Schema (sl_* tables)
- Admin Role Gate (Tài Khoản / Danh Mục)
- Account & Role RPCs (user_roles)
- Chuyển Công Đoạn RPCs
- intem.html Search/Autofill Functions
- admin-create-user Edge Function
- import-nvl.mjs (Data Import Script)
- Tem Tag-No Generator RPCs
- NCP Root Cause Approve/Reopen
- NCP Root Cause Draft/Submit
- Chuyển Công Đoạn Schema (view/log)
- Ca Hiện Tại Bulk Update RPC
- Rationale: Why Supabase over Sheets
- Roadmap: Legacy Sheet Sources
- Chuyển Công Đoạn Schema
- Roadmap: Chuyển Công Đoạn Module Proposal
- Chuyển Công Đoạn Confirm Actions
- Chuyển Công Đoạn Submit Transfer
- rpcWrite Helper Pair (Dashboard/Mobile)
- NCP Evidence Storage (ncp-detail)
- Tem RPC Call (intem)
- Admin Create-User Handler (quan-ly-tai-khoan)
- Roadmap Doc Pair
- Roadmap: Proactive Alerts / Long-term Ops
- KHSX Tuần Plan Table
- ipqc.html startPolling()
- Roadmap: Audit Log (chưa làm)
- mobile.html loadMasterData()
- master_employees table
- master_products table (S5)
- master_products table (S6)

## God Nodes (most connected - your core abstractions)
1. `nvl.html (Quản Lý Tồn Kho NVL)` - 18 edges
2. `duc_ca_hien_tai` - 16 edges
3. `index.html (Trang Chủ MES Supabase)` - 16 edges
4. `nvl_materials` - 9 edges
5. `MesAuth (shared/supabase-client.js) — shared session/auth helper` - 8 edges
6. `mapRows()` - 7 edges
7. `main()` - 7 edges
8. `bao-cao-ca.html (Xem Lại Báo Cáo Kết Ca)` - 7 edges
9. `quan-ly-danh-muc.html (trang admin quản lý danh mục)` - 7 edges
10. `qc-manager.html (QC Giám Sát & Xử Lý SP Không Phù Hợp)` - 6 edges

## Surprising Connections (you probably didn't know these)
- `index.html (Trang Chủ MES Supabase)` --references--> `Domain riêng mes.toyotaki.vn (kế hoạch, chưa triển khai)`  [AMBIGUOUS]
  index.html → KE_HOACH_MIGRATE_DATABASE.md
- `Cảnh báo chủ động (ngoài màn hình)` --semantically_similar_to--> `Giai đoạn 5 — Vận hành & giám sát dài hạn`  [INFERRED] [semantically similar]
  KE_HOACH_TINH_NANG_MOI.md → KE_HOACH_MIGRATE_DATABASE.md
- `ipqc.html changes vs original Apps Script` --semantically_similar_to--> `mobile.html deliberate simplifications`  [INFERRED] [semantically similar]
  ipqc.html → mobile.html
- `sl_giao_hang / sl_khsx / sl_capacity / sl_forecast / sl_comments / sl_config tables` --semantically_similar_to--> `CORE_TABLES / EXTRA_TABLES map (cl_* tables)`  [INFERRED] [semantically similar]
  sanluong-supabase.html → chatluong-supabase.html
- `Comment save handler → sl_comments upsert (requires login)` --semantically_similar_to--> `Comment save to cl_comments (requires login)`  [INFERRED] [semantically similar]
  sanluong-supabase.html → chatluong-supabase.html

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Khối Đúc + IPQC + In tem + QR chuyển công đoạn migrate như 1 khối liên kết** — ke_hoach_migrate_database_dashboard_duc, ke_hoach_migrate_database_ipqc, ke_hoach_migrate_database_in_tem, ke_hoach_migrate_database_qr_chuyen_cong_doan [EXTRACTED 1.00]
- **4 hệ thống cùng phụ thuộc 1 file KHSX Master duy nhất** — ke_hoach_migrate_database_khsx_master, ke_hoach_migrate_database_dashboard_duc, ke_hoach_migrate_database_in_tem, ke_hoach_migrate_database_qr_chuyen_cong_doan, ke_hoach_migrate_database_ton_kho_nvl [EXTRACTED 1.00]
- **Luồng đăng nhập MES: trang chủ, trang login, Supabase client dùng chung** — index_trangchu, shared_login, shared_supabase_client [EXTRACTED 1.00]
- **QR label printing flow across duc-dashboard, mobile, and intem** — duc_dashboard_opentemprint, mobile_opentemprintmobile, intem_applyprefill, intem_intem, rpc_duc_ghi_tem [INFERRED 0.85]
- **IPQC due/checkpoint state shared between dashboard badge, mobile badge, and ipqc queue screen** — rpc_duc_get_ipqc_due_by_id_dong, table_duc_ca_hien_tai, table_duc_ipqc_checkpoint, ipqc_getactiveiddongset, duc_dashboard_fetchshiftstate, mobile_loadshiftstate [INFERRED 0.85]
- **Shared design pattern: static Supabase page replacing a Google Apps Script Web App screen, with explicit deliberate-simplification comment block** — duc_dashboard_rationale_scope, mobile_rationale_simplification, ipqc_rationale_changes, intem_rationale_changes [INFERRED 0.85]
- **Non-conforming product (NCP) workflow spans open case, root-cause form, approval** — qc_manager_loadncplist, ncp_detail, duc_ncp_table, duc_ncp_update_root_cause_rpc, duc_ncp_approve_root_cause_rpc [EXTRACTED 1.00]
- **Admin-only master data pages share the same user_roles.role='admin' gating pattern** — quan_ly_danh_muc_main_gate, quan_ly_tai_khoan_main_gate, user_roles_table [INFERRED 0.85]
- **QR-tag driven stage transfer: scan tag, submit transfer log, receiving department confirms/rejects** — chuyencongdoan_ondecoded, chuyencongdoan_submittransfer, chuyencongdoan_confirmone, cd_chuyen_cong_doan_log_table [EXTRACTED 1.00]

## Communities (78 total, 22 thin omitted)

### Community 0 - "IPQC Checkpoint & Incident RPCs"
Cohesion: 0.06
Nodes (21): loop, duc_report_mold_issue(), duc_request_ipqc_check(), duc_set_incident_open(), duc_carry_over_shift(), duc_end_shift(), duc_update_mold_shots_from_shift(), duc_acquire_lock() (+13 more)

### Community 1 - "Đúc Dashboard ↔ Mobile ↔ Intem Print Flow"
Cohesion: 0.06
Nodes (30): chuyencongdoan.html (QR-scan precedent page), duc-dashboard.html scope & deliberate omissions, openCameraForSearch(), intem.html 2026-08-14 optimization update, getActiveIdDongSet(), loadQueue(), ipqc.html changes vs original Apps Script, renderQueue() (+22 more)

### Community 2 - "Chất Lượng Dashboard (KPI)"
Cohesion: 0.07
Nodes (35): view cd_v_vi_tri_hien_tai, chatluong-supabase.html (Dashboard KPI Chất Lượng), CORE_TABLES / EXTRA_TABLES map (cl_* tables), Direct Supabase read/write replacing CSV_URLS/Google Sheet/Apps Script, loadData(), Comment save to cl_comments (requires login), chuyencongdoan.html (Chuyển Công Đoạn & Xác Nhận Nhận Hàng), Live camera QR scan feasible on static web (vs Apps Script sandbox camera block) (+27 more)

### Community 3 - "IPQC Submit & NCP RPCs"
Cohesion: 0.07
Nodes (16): duc_submit_ipqc_check(), duc_ncp_append_log(), duc_ncp_id_counter, duc_ncp_open_case(), duc_record_mold_maintenance(), duc_bao_cao_ca, duc_diecast_log, duc_ipqc_checkpoint (+8 more)

### Community 4 - "MES Roadmap ↔ Đúc Dashboard Core"
Cohesion: 0.11
Nodes (23): bao-cao-ca.html (Xem Lại Báo Cáo Kết Ca), duc-dashboard.html (Bảng Điều Khiển Đúc), duc_end_shift (RPC kết ca), table duc_khsx_tuan_plan, index.html (Trang Chủ MES Supabase), intem.html (In Tem Công Đoạn Đúc), ipqc.html (Màn Hình IPQC Kiểm Tra Tuần Kiểm), duc_bao_cao_ca (bảng đề xuất) (+15 more)

### Community 5 - "NVL Ledger RPCs"
Cohesion: 0.18
Nodes (11): nvl_add_transaction(), nvl_update_opening(), nvl_update_plan_nhap(), nvl_update_settings(), nvl_cai_dat, nvl_giao_dich, nvl_ke_hoach_ngay, nvl_materials (+3 more)

### Community 6 - "NVL Inventory Page"
Cohesion: 0.12
Nodes (17): nvl.html (Quản Lý Tồn Kho NVL), RPC nvl_add_transaction, Full Apps Script backend action → Supabase table/view/RPC mapping (getAllData etc. → nvl_* RPCs), RPC nvl_check_fifo (public, no login needed), RPC nvl_create_tem, table nvl_giao_dich, All units normalized to kg (old sheet mixed kg and tons across tabs — gotcha #3), nvl_materials is sole source of truth for material catalog (replaces hardcoded MATERIALS array + KHSX Master sheet) (+9 more)

### Community 7 - "import-duc.mjs (Data Import Script)"
Cohesion: 0.25
Nodes (16): base64url(), DB_JOBS, dedupeByKeys(), firstSheetTitle(), getAccessToken(), main(), mapRows(), pad() (+8 more)

### Community 8 - "Chất Lượng Schema (cl_* tables)"
Cohesion: 0.14
Nodes (13): cl_bat_thuong_chua_tra_loi, cl_bat_thuong_kh, cl_bat_thuong_nb, cl_bat_thuong_thang, cl_comments, cl_config, cl_ng_lan1, cl_qc_daily (+5 more)

### Community 10 - "QC Manager Monitoring Board"
Cohesion: 0.25
Nodes (8): table duc_ca_hien_tai, table duc_ipqc_checkpoint, Client-side filter/aggregate over duc_ipqc_checkpoint/duc_ncp instead of one server aggregate function (small row counts, RLS public read), getActiveIdDongSet duplicated from ipqc.html — no shared JS module by repo convention (no build step), getActiveIdDongSet(), QC Giám sát tab: Real-time IPQC monitoring board, loadBoard() — real-time monitor tab, searchHistory() — tra cứu lịch sử tab

### Community 11 - "import-chatluong.mjs (Data Import Script)"
Cohesion: 0.43
Nodes (7): CSV_URLS, csvToObjects(), fetchCSV(), main(), parseCSV(), toNum(), upsert()

### Community 12 - "import-chuyencongdoan.mjs (Data Import Script)"
Cohesion: 0.46
Nodes (7): csvToObjects(), fetchCSV(), main(), parseCSV(), toNum(), toVNTimestamp(), upsert()

### Community 13 - "import-sanluong.mjs (Data Import Script)"
Cohesion: 0.43
Nodes (7): CSV_URLS, csvToObjects(), fetchCSV(), main(), parseCSV(), toNum(), upsert()

### Community 14 - "IPQC Evidence Upload Flow"
Cohesion: 0.29
Nodes (7): submitCheck(), uploadEvidencePhotos(), migration_phase4_step12 (duc_submit_ipqc_check validation), migration_phase4_step4 (p_anh_urls design), migration_phase_D0_foundation.sql, RPC duc_submit_ipqc_check, Supabase Storage bucket ipqc-evidence

### Community 15 - "Roadmap: Module Overview & Shared Master Data"
Cohesion: 0.38
Nodes (7): Module Dashboard Đúc, KHSX Master (Google Sheet dùng chung), master_products/master_machines/master_employees (đề xuất bảng danh mục chung), Module Quản Lý Tồn Kho NVL, Bảo trì khuôn theo lịch, Liên kết tồn kho NVL ↔ kế hoạch sản xuất, Phân tích sự cố (Pareto)

### Community 16 - "Roadmap: IPQC Migration Rationale"
Cohesion: 0.29
Nodes (7): duc_ca_hien_tai (bảng đề xuất), duc_su_co_log (bảng đề xuất), duc_van_de_khuon (bảng đề xuất), Module IPQC / QC Giám sát, duc_ipqc_checkpoint (bảng đề xuất), Vì sao IPQC phải migrate cùng khối Đúc (rationale), Giám sát job nền (pg_cron)

### Community 17 - "Sản Lượng Schema (sl_* tables)"
Cohesion: 0.29
Nodes (6): sl_capacity, sl_comments, sl_config, sl_forecast, sl_giao_hang, sl_khsx

### Community 18 - "Admin Role Gate (Tài Khoản / Danh Mục)"
Cohesion: 0.47
Nodes (6): Admin-only role gate replaces direct Supabase Dashboard edits for master data, main() admin gate — check user_roles.role === 'admin', Admin-only role gate for account/role management page, loadUsers() — list user_roles, inline role change, main() admin gate — check user_roles.role === 'admin', table user_roles (user_id, email, username, full_name, role)

### Community 19 - "Account & Role RPCs (user_roles)"
Cohesion: 0.60
Nodes (4): auth.users, public.current_role_of(), public.has_role(), public.user_roles

### Community 23 - "import-nvl.mjs (Data Import Script)"
Cohesion: 0.83
Nodes (3): fetchAction(), main(), upsert()

### Community 25 - "NCP Root Cause Approve/Reopen"
Cohesion: 0.67
Nodes (3): RPC duc_ncp_approve_root_cause, RPC duc_ncp_reopen_root_cause, approve() / reopen()

### Community 26 - "NCP Root Cause Draft/Submit"
Cohesion: 0.67
Nodes (3): RPC duc_ncp_submit_root_cause_for_approval, RPC duc_ncp_update_root_cause, saveDraft() / submitForApproval()

### Community 27 - "Chuyển Công Đoạn Schema (view/log)"
Cohesion: 0.67
Nodes (3): chuyen_cong_doan_log (bảng đề xuất), duc_tem (bảng đề xuất, PK tag_no), Module Đọc QR Chuyển Công Đoạn

### Community 28 - "Ca Hiện Tại Bulk Update RPC"
Cohesion: 0.67
Nodes (3): DB Sheet (11 sheet nghiệp vụ Đúc), Diecast Sheet (log sản lượng theo phút), Module In Tem Công Đoạn Đúc

### Community 29 - "Rationale: Why Supabase over Sheets"
Cohesion: 0.67
Nodes (3): Google Sheet (legacy datastore), Supabase (Postgres backend), Vì sao chọn Supabase (rationale)

## Ambiguous Edges - Review These
- `index.html (Trang Chủ MES Supabase)` → `Domain riêng mes.toyotaki.vn (kế hoạch, chưa triển khai)`  [AMBIGUOUS]
  KE_HOACH_MIGRATE_DATABASE.md · relation: references
- `Diecast Sheet (log sản lượng theo phút)` → `DB Sheet (11 sheet nghiệp vụ Đúc)`  [AMBIGUOUS]
  KE_HOACH_MIGRATE_DATABASE.md · relation: shares_data_with

## Knowledge Gaps
- **110 isolated node(s):** `sb`, `MesAuth`, `ROLES`, `corsHeaders`, `CSV_URLS` (+105 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **22 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `index.html (Trang Chủ MES Supabase)` and `Domain riêng mes.toyotaki.vn (kế hoạch, chưa triển khai)`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `Diecast Sheet (log sản lượng theo phút)` and `DB Sheet (11 sheet nghiệp vụ Đúc)`?**
  _Edge tagged AMBIGUOUS (relation: shares_data_with) - confidence is low._
- **Why does `index.html (Trang Chủ MES Supabase)` connect `MES Roadmap ↔ Đúc Dashboard Core` to `Chất Lượng Dashboard (KPI)`, `NVL Inventory Page`?**
  _High betweenness centrality (0.033) - this node is a cross-community bridge._
- **Why does `duc_ca_hien_tai` connect `IPQC Checkpoint & Incident RPCs` to `IPQC Submit & NCP RPCs`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Why does `nvl.html (Quản Lý Tồn Kho NVL)` connect `NVL Inventory Page` to `Chất Lượng Dashboard (KPI)`, `MES Roadmap ↔ Đúc Dashboard Core`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **What connects `sb`, `MesAuth`, `ROLES` to the rest of the system?**
  _110 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `IPQC Checkpoint & Incident RPCs` be split into smaller, more focused modules?**
  _Cohesion score 0.057004830917874394 - nodes in this community are weakly interconnected._