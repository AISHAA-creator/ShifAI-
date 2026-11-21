-- Triglycerides and HDL cholesterol on a lab report (both in mg/dL).
-- They feed the model that estimates insulin resistance without an insulin test.
-- Row-level security on public.lab_reports already covers new columns.
alter table public.lab_reports
  add column if not exists triglycerides_mg_dl double precision
    check (triglycerides_mg_dl > 0),
  add column if not exists hdl_mg_dl double precision
    check (hdl_mg_dl > 0);
