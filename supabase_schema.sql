-- Jinger's Palace / aichat：Supabase 表与 RLS（整文件复制到 SQL Editor 执行，勿带 Markdown 反引号）
-- 若曾执行失败但表已存在，可先删掉旧表再跑： DROP TABLE IF EXISTS public.aichat_user_data CASCADE;

create table public.aichat_user_data (
  user_id uuid primary key references auth.users (id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.aichat_user_data enable row level security;

create policy "aichat_select_own"
  on public.aichat_user_data for select
  using (auth.uid() = user_id);

create policy "aichat_insert_own"
  on public.aichat_user_data for insert
  with check (auth.uid() = user_id);

create policy "aichat_update_own"
  on public.aichat_user_data for update
  using (auth.uid() = user_id);
