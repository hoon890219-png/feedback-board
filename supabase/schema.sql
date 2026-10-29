-- Supabase 대시보드 > SQL Editor 에 통째로 붙여넣고 Run 하세요.
-- 마지막 줄의 이메일을 본인 이메일로 바꾸는 것을 잊지 마세요.

create extension if not exists pgcrypto;

create table if not exists public.apps (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 40),
  tagline text not null default '' check (char_length(tagline) <= 80),
  url text not null default '' check (char_length(url) <= 300),
  created_at timestamptz not null default now()
);

create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  app_id uuid not null references public.apps(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  detail text not null default '' check (char_length(detail) <= 800),
  author_name text not null default '' check (char_length(author_name) <= 30),
  status text not null default 'new' check (status in ('new','doing','done','hold')),
  note text not null default '' check (char_length(note) <= 1000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists feedback_app_idx on public.feedback(app_id);

-- 개발자(관리자) 이메일 목록. 외부에서 읽을 수 없습니다.
create table if not exists public.admins (email text primary key);
alter table public.admins enable row level security;

create or replace function public.is_admin() returns boolean
language sql security definer set search_path = public stable as $$
  select exists (select 1 from public.admins where lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));
$$;
grant execute on function public.is_admin() to anon, authenticated;

-- 스팸 방어: 1분에 30건 넘게 접수되면 막습니다 (전체 합계 기준).
create or replace function public.feedback_rate_limit() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from public.feedback where created_at > now() - interval '1 minute') >= 30 then
    raise exception 'too many requests';
  end if;
  return new;
end $$;
drop trigger if exists feedback_rate_limit on public.feedback;
create trigger feedback_rate_limit before insert on public.feedback
  for each row execute function public.feedback_rate_limit();

alter table public.apps enable row level security;
alter table public.feedback enable row level security;

-- 읽기: 누구나
drop policy if exists apps_read on public.apps;
create policy apps_read on public.apps for select to anon, authenticated using (true);
drop policy if exists feedback_read on public.feedback;
create policy feedback_read on public.feedback for select to anon, authenticated using (true);

-- 요청 등록: 누구나 (상태는 항상 '대기', 답변은 빈 값으로만)
drop policy if exists feedback_insert on public.feedback;
create policy feedback_insert on public.feedback for insert to anon, authenticated
  with check (status = 'new' and note = '');

-- 그 외 모든 변경(앱 추가/삭제, 상태·답변 수정, 요청 삭제): 관리자만
drop policy if exists apps_admin on public.apps;
create policy apps_admin on public.apps for all to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists feedback_admin_update on public.feedback;
create policy feedback_admin_update on public.feedback for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists feedback_admin_delete on public.feedback;
create policy feedback_admin_delete on public.feedback for delete to authenticated using (public.is_admin());

-- ★ 본인 이메일로 바꾸세요 (Supabase Auth 에 만들 계정의 이메일과 같아야 합니다)
insert into public.admins (email) values ('hoon890219@gmail.com') on conflict do nothing;
