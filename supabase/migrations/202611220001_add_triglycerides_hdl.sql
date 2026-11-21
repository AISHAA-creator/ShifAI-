alter table public.lab_reports
  add column if not exists triglycerides_mg_dl double precision
    check (triglycerides_mg_dl > 0),
  add column if not exists hdl_mg_dl double precision
    check (hdl_mg_dl > 0);
