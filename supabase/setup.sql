-- 알뜰폰 약정 계산기 Supabase 설정
-- Supabase 대시보드 → SQL Editor에 통째로 붙여넣고 Run

-- 1) 업체 목록: 누구나 읽기만 가능
create table if not exists public.carriers (
  id text primary key,
  name text not null,
  nets jsonb not null,               -- {"KT":"day","LG U+":"incl"} day=일 단위, incl=월 단위(개통월 포함)
  sort int not null default 0,
  active boolean not null default true,
  source text not null default 'moyo',
  updated_at timestamptz not null default now(),
  constraint nets_values check (jsonb_typeof(nets) = 'object')
);
alter table public.carriers enable row level security;
drop policy if exists "carriers are public" on public.carriers;
create policy "carriers are public" on public.carriers for select to anon, authenticated using (active);
grant select on public.carriers to anon, authenticated;

-- 2) 방문·사용 기록: 누구나 쓰기만 가능, 읽기는 대시보드에서만
create table if not exists public.events (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  type text not null check (type in ('view', 'add', 'ics', 'gcal')),
  visitor_id uuid not null,
  path text check (char_length(path) <= 100),
  referrer_host text check (char_length(referrer_host) <= 100),
  device text check (device in ('ios', 'android', 'desktop')),
  in_app text check (char_length(in_app) <= 20),
  carrier_id text check (char_length(carrier_id) <= 20),
  net text check (char_length(net) <= 10),
  months int check (months between 1 and 60),
  alerts int[] check (cardinality(alerts) <= 4)
);
create index if not exists events_created_at on public.events (created_at);
alter table public.events enable row level security;
drop policy if exists "anyone can log events" on public.events;
create policy "anyone can log events" on public.events for insert to anon, authenticated with check (true);
grant insert on public.events to anon, authenticated;
revoke select, update, delete on public.events from anon, authenticated;

-- 3) 통계 보기 (대시보드 SQL Editor나 Table Editor에서 확인, 외부에는 비공개)
create or replace view public.stats_daily with (security_invoker = on) as
select (created_at at time zone 'Asia/Seoul')::date as day,
       count(*) filter (where type = 'view')                    as views,
       count(distinct visitor_id) filter (where type = 'view')  as visitors,
       count(*) filter (where type = 'add')                     as alert_opens,
       count(*) filter (where type = 'ics')                     as ics_downloads,
       count(*) filter (where type = 'gcal')                    as gcal_clicks
from public.events group by 1 order by 1 desc;

create or replace view public.stats_carriers with (security_invoker = on) as
select coalesce(c.name, e.carrier_id) as carrier, e.months,
       count(*) as uses, count(distinct e.visitor_id) as people
from public.events e left join public.carriers c on c.id = e.carrier_id
where e.type in ('ics', 'gcal', 'add')
group by 1, 2 order by uses desc;

create or replace view public.stats_sources with (security_invoker = on) as
select coalesce(in_app, referrer_host, '직접 접속') as source, device,
       count(*) as views, count(distinct visitor_id) as visitors
from public.events where type = 'view'
group by 1, 2 order by views desc;

revoke all on public.stats_daily, public.stats_carriers, public.stats_sources from anon, authenticated;

-- 4) 업체 목록 초기값 (모요 업체 정보, 2026-11-09 기준)
insert into public.carriers (id, name, nets, sort) values
  ('m32', 'KCTV알뜰폰', '{"LG U+": "incl"}'::jsonb, 0),
  ('m2', 'KG모바일', '{"LG U+": "incl"}'::jsonb, 10),
  ('m19', 'KT스카이라이프', '{"KT": "day"}'::jsonb, 20),
  ('m3', 'KT엠모바일', '{"KT": "day"}'::jsonb, 30),
  ('m5', 'LG헬로모바일', '{"LG U+": "incl"}'::jsonb, 40),
  ('m7', 'SK7모바일', '{"SKT": "incl"}'::jsonb, 50),
  ('m14', 'U+유모바일', '{"LG U+": "incl"}'::jsonb, 60),
  ('m8', '고고모바일', '{"KT": "day", "SKT": "day"}'::jsonb, 70),
  ('m9', '더원모바일', '{"KT": "day"}'::jsonb, 80),
  ('m10', '드림라인 모바일', '{"KT": "incl"}'::jsonb, 90),
  ('m56', '리브모바일', '{"KT": "day", "LG U+": "day", "SKT": "day"}'::jsonb, 100),
  ('m11', '마블링', '{"LG U+": "day"}'::jsonb, 110),
  ('m12', '마이월드', '{"LG U+": "incl"}'::jsonb, 120),
  ('m69', '모나', '{"LG U+": "day"}'::jsonb, 130),
  ('m30', '모빙', '{"KT": "day", "LG U+": "day", "SKT": "day"}'::jsonb, 140),
  ('m39', '밸류컴', '{"KT": "incl", "LG U+": "incl"}'::jsonb, 150),
  ('m87', '비즈인모바일', '{"KT": "day"}'::jsonb, 160),
  ('m15', '사람과연결', '{"LG U+": "incl"}'::jsonb, 170),
  ('m16', '서경모바일', '{"LG U+": "incl"}'::jsonb, 180),
  ('m13', '쉐이크모바일', '{"KT": "day"}'::jsonb, 190),
  ('m1', '슈가모바일', '{"LG U+": "incl"}'::jsonb, 200),
  ('m17', '스노우맨', '{"KT": "day", "LG U+": "day", "SKT": "day"}'::jsonb, 210),
  ('m18', '스마텔', '{"KT": "day", "LG U+": "day", "SKT": "day"}'::jsonb, 220),
  ('m73', '스피츠모바일', '{"KT": "day"}'::jsonb, 230),
  ('m72', '시월모바일', '{"LG U+": "incl"}'::jsonb, 240),
  ('m26', '아시아모바일', '{"KT": "incl"}'::jsonb, 250),
  ('m21', '아이즈모바일', '{"KT": "day", "LG U+": "incl", "SKT": "day"}'::jsonb, 260),
  ('m22', '앤텔레콤', '{"KT": "incl", "LG U+": "incl"}'::jsonb, 270),
  ('m24', '에르엘', '{"KT": "day", "LG U+": "incl"}'::jsonb, 280),
  ('m25', '에스원안심모바일', '{"KT": "day", "LG U+": "incl", "SKT": "day"}'::jsonb, 290),
  ('m23', '에이모바일', '{"KT": "day", "LG U+": "incl", "SKT": "day"}'::jsonb, 300),
  ('m28', '여유알뜰모바일', '{"LG U+": "incl"}'::jsonb, 310),
  ('m27', '오파스모바일', '{"KT": "day"}'::jsonb, 320),
  ('m29', '위너스텔', '{"KT": "day", "LG U+": "day"}'::jsonb, 330),
  ('m34', '이야기모바일', '{"KT": "day", "LG U+": "day", "SKT": "day"}'::jsonb, 340),
  ('m33', '이지모바일', '{"KT": "day", "LG U+": "day"}'::jsonb, 350),
  ('m31', '인스모바일', '{"LG U+": "incl"}'::jsonb, 360),
  ('m71', '찬스모바일', '{"LG U+": "incl"}'::jsonb, 370),
  ('m35', '토스모바일', '{"KT": "incl", "LG U+": "incl", "SKT": "incl"}'::jsonb, 380),
  ('m38', '티플러스', '{"KT": "day", "LG U+": "day", "SKT": "day"}'::jsonb, 390),
  ('m37', '프리티', '{"KT": "day", "LG U+": "day", "SKT": "day"}'::jsonb, 400),
  ('m20', '핀다이렉트', '{"KT": "day", "LG U+": "day", "SKT": "day"}'::jsonb, 410),
  ('m40', '한패스모바일', '{"LG U+": "incl"}'::jsonb, 420)
on conflict (id) do update set name = excluded.name, nets = excluded.nets, sort = excluded.sort, updated_at = now();
