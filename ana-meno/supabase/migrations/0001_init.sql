-- أنا مِنو 🤔 — schema, RLS and authoritative game RPCs.
-- All game-rule validation happens here; clients only call the RPCs below.
-- Error messages are machine codes (e.g. ROOM_NOT_FOUND) mapped to Arabic
-- text on the client.

create extension if not exists pgcrypto;

/* ------------------------------- tables ------------------------------- */

create table if not exists public.characters (
  id int primary key,
  slug text not null unique,
  name text not null,
  gender text not null check (gender in ('male','female')),
  profession text not null,
  profession_ar text not null,
  field text not null,
  skin_tone text not null,
  hair_color text not null,
  hair_length text not null,
  hair_style text not null,
  has_glasses boolean not null,
  beard_style text not null,
  headwear text not null,
  clothing text not null,
  uniform boolean not null,
  accessory text not null,
  works_in_office boolean not null,
  works_outdoors boolean not null,
  accent text not null,
  visual_traits text not null,
  image_url text not null,
  active boolean not null default true
);

create table if not exists public.questions (
  id text primary key,
  category text not null,
  text_ar text not null,
  active boolean not null default true
);

create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  status text not null default 'waiting'
    check (status in ('waiting','playing','finished','expired')),
  host_id uuid not null,
  host_name text not null,
  guest_id uuid,
  guest_name text,
  host_rematch boolean not null default false,
  guest_rematch boolean not null default false,
  current_game_id uuid,
  created_at timestamptz not null default now(),
  started_at timestamptz,
  finished_at timestamptz,
  expires_at timestamptz not null default now() + interval '60 minutes'
);

create index if not exists rooms_code_idx on public.rooms (code);

create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  status text not null default 'active' check (status in ('active','finished')),
  current_turn uuid not null,
  turn_started_at timestamptz not null default now(),
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  pending_question_id text,
  pending_asker uuid,
  host_questions int not null default 0,
  guest_questions int not null default 0,
  host_score int not null default 0,
  guest_score int not null default 0,
  winner_id uuid,
  win_reason text check (win_reason in ('correct_guess','opponent_wrong_guess','forfeit')),
  last_guess jsonb,
  -- Populated only when the game finishes; never exposed while active.
  revealed_secrets jsonb
);

create index if not exists games_room_idx on public.games (room_id);

-- Secrets live in their own table so RLS can hide the opponent's secret
-- completely: a player can only ever select their own row.
create table if not exists public.game_secrets (
  game_id uuid not null references public.games(id) on delete cascade,
  player_id uuid not null,
  character_id int not null references public.characters(id),
  primary key (game_id, player_id)
);

create table if not exists public.game_questions (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games(id) on delete cascade,
  asker_id uuid not null,
  question_id text not null references public.questions(id),
  answer boolean,
  asked_at timestamptz not null default now(),
  answered_at timestamptz
);

create index if not exists game_questions_game_idx on public.game_questions (game_id, asked_at);

/* --------------------------------- RLS --------------------------------- */

alter table public.characters enable row level security;
alter table public.questions enable row level security;
alter table public.rooms enable row level security;
alter table public.games enable row level security;
alter table public.game_secrets enable row level security;
alter table public.game_questions enable row level security;

drop policy if exists "characters are public" on public.characters;
create policy "characters are public" on public.characters
  for select to authenticated, anon using (true);

drop policy if exists "questions are public" on public.questions;
create policy "questions are public" on public.questions
  for select to authenticated, anon using (true);

drop policy if exists "room members can read their room" on public.rooms;
create policy "room members can read their room" on public.rooms
  for select to authenticated
  using (auth.uid() in (host_id, guest_id));

drop policy if exists "room members can read their games" on public.games;
create policy "room members can read their games" on public.games
  for select to authenticated
  using (exists (
    select 1 from public.rooms r
    where r.id = room_id and auth.uid() in (r.host_id, r.guest_id)
  ));

drop policy if exists "players can read only their own secret" on public.game_secrets;
create policy "players can read only their own secret" on public.game_secrets
  for select to authenticated
  using (player_id = auth.uid());

drop policy if exists "room members can read game questions" on public.game_questions;
create policy "room members can read game questions" on public.game_questions
  for select to authenticated
  using (exists (
    select 1 from public.games g
    join public.rooms r on r.id = g.room_id
    where g.id = game_id and auth.uid() in (r.host_id, r.guest_id)
  ));

-- No insert/update/delete policies: every mutation goes through the
-- SECURITY DEFINER functions below.

/* ------------------------------- helpers ------------------------------- */

create or replace function public._assert_member(p_room public.rooms)
returns void language plpgsql as $$
begin
  if auth.uid() is null or auth.uid() not in (p_room.host_id, coalesce(p_room.guest_id, '00000000-0000-0000-0000-000000000000'::uuid)) then
    raise exception 'NOT_IN_ROOM';
  end if;
end $$;

create or replace function public._sanitize_name(p_name text)
returns text language plpgsql as $$
declare
  v text;
begin
  v := trim(regexp_replace(coalesce(p_name, ''), '[<>"''`]', '', 'g'));
  v := regexp_replace(v, '\s+', ' ', 'g');
  v := left(v, 20);
  if char_length(v) < 2 then
    raise exception 'INVALID_NAME';
  end if;
  return v;
end $$;

-- Starts a fresh game for a room with two distinct random secrets.
-- Uses gen_random_uuid() ordering (pgcrypto randomness) for the picks.
create or replace function public._start_game(p_room public.rooms)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_game_id uuid;
  v_ids int[];
begin
  select array_agg(id) into v_ids from (
    select id from public.characters where active order by gen_random_uuid() limit 2
  ) t;
  if array_length(v_ids, 1) < 2 then
    raise exception 'UNKNOWN';
  end if;

  insert into public.games (room_id, current_turn)
  values (p_room.id, p_room.host_id)
  returning id into v_game_id;

  insert into public.game_secrets (game_id, player_id, character_id) values
    (v_game_id, p_room.host_id, v_ids[1]),
    (v_game_id, p_room.guest_id, v_ids[2]);

  update public.rooms
  set status = 'playing',
      current_game_id = v_game_id,
      started_at = coalesce(started_at, now()),
      host_rematch = false,
      guest_rematch = false
  where id = p_room.id;

  return v_game_id;
end $$;

create or replace function public._winner_score(p_questions int, p_elapsed_seconds numeric)
returns int language sql immutable as $$
  select greatest(20, 100 - p_questions * 5)
       + greatest(0, 50 - floor(greatest(0, p_elapsed_seconds) / 12))::int;
$$;

/* --------------------------------- RPCs --------------------------------- */

create or replace function public.create_room(p_name text)
returns public.rooms
language plpgsql security definer set search_path = public as $$
declare
  v_name text;
  v_code text;
  v_room public.rooms;
  v_alphabet text := 'ABCDEFGHJKLMNPQRTUVWXYZ2346789';
  v_i int;
begin
  if auth.uid() is null then raise exception 'NOT_IN_ROOM'; end if;
  v_name := public._sanitize_name(p_name);

  -- Opportunistic cleanup of stale rooms.
  update public.rooms set status = 'expired'
  where status = 'waiting' and expires_at < now();

  loop
    v_code := '';
    for v_i in 1..5 loop
      v_code := v_code || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
    end loop;
    exit when not exists (
      select 1 from public.rooms where code = v_code and status in ('waiting','playing')
    );
  end loop;

  insert into public.rooms (code, host_id, host_name)
  values (v_code, auth.uid(), v_name)
  returning * into v_room;
  return v_room;
end $$;

create or replace function public.join_room(p_code text, p_name text)
returns public.rooms
language plpgsql security definer set search_path = public as $$
declare
  v_name text;
  v_code text;
  v_room public.rooms;
begin
  if auth.uid() is null then raise exception 'NOT_IN_ROOM'; end if;
  v_code := upper(regexp_replace(coalesce(p_code, ''), '\s', '', 'g'));
  if char_length(v_code) <> 5 then raise exception 'INVALID_CODE'; end if;
  v_name := public._sanitize_name(p_name);

  select * into v_room from public.rooms where code = v_code
  order by created_at desc limit 1
  for update;

  if not found then raise exception 'ROOM_NOT_FOUND'; end if;

  -- Rejoining as an existing member is always allowed.
  if auth.uid() in (v_room.host_id, coalesce(v_room.guest_id, '00000000-0000-0000-0000-000000000000'::uuid)) then
    return v_room;
  end if;

  if v_room.status = 'expired' or (v_room.status = 'waiting' and v_room.expires_at < now()) then
    update public.rooms set status = 'expired' where id = v_room.id;
    raise exception 'ROOM_EXPIRED';
  end if;
  if v_room.guest_id is not null then raise exception 'ROOM_FULL'; end if;
  if v_room.status <> 'waiting' then raise exception 'ROOM_ALREADY_STARTED'; end if;

  update public.rooms
  set guest_id = auth.uid(), guest_name = v_name
  where id = v_room.id
  returning * into v_room;

  -- Second player joined -> the server generates the game.
  perform public._start_game(v_room);

  select * into v_room from public.rooms where id = v_room.id;
  return v_room;
end $$;

create or replace function public.get_my_secret(p_game_id uuid)
returns int
language plpgsql security definer set search_path = public as $$
declare
  v_character int;
begin
  select character_id into v_character
  from public.game_secrets
  where game_id = p_game_id and player_id = auth.uid();
  if not found then raise exception 'NOT_IN_ROOM'; end if;
  return v_character;
end $$;

create or replace function public.ask_question(p_game_id uuid, p_question_id text)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_game public.games;
  v_room public.rooms;
begin
  select * into v_game from public.games where id = p_game_id for update;
  if not found then raise exception 'GAME_NOT_ACTIVE'; end if;
  select * into v_room from public.rooms where id = v_game.room_id;
  perform public._assert_member(v_room);

  if v_game.status <> 'active' then raise exception 'GAME_NOT_ACTIVE'; end if;
  if v_game.current_turn <> auth.uid() then raise exception 'NOT_YOUR_TURN'; end if;
  if v_game.pending_question_id is not null then raise exception 'PENDING_QUESTION'; end if;
  if not exists (select 1 from public.questions where id = p_question_id and active) then
    raise exception 'INVALID_QUESTION';
  end if;

  update public.games
  set pending_question_id = p_question_id,
      pending_asker = auth.uid(),
      host_questions = host_questions + (case when auth.uid() = v_room.host_id then 1 else 0 end),
      guest_questions = guest_questions + (case when auth.uid() = v_room.guest_id then 1 else 0 end)
  where id = p_game_id;

  insert into public.game_questions (game_id, asker_id, question_id)
  values (p_game_id, auth.uid(), p_question_id);
end $$;

create or replace function public.answer_question(p_game_id uuid, p_answer boolean)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_game public.games;
  v_room public.rooms;
begin
  select * into v_game from public.games where id = p_game_id for update;
  if not found then raise exception 'GAME_NOT_ACTIVE'; end if;
  select * into v_room from public.rooms where id = v_game.room_id;
  perform public._assert_member(v_room);

  if v_game.status <> 'active' then raise exception 'GAME_NOT_ACTIVE'; end if;
  if v_game.pending_question_id is null then raise exception 'NO_PENDING_QUESTION'; end if;
  -- Only the defender (not the asker) may answer.
  if v_game.pending_asker = auth.uid() then raise exception 'NOT_DEFENDER'; end if;

  update public.game_questions
  set answer = p_answer, answered_at = now()
  where id = (
    select id from public.game_questions
    where game_id = p_game_id and answer is null
    order by asked_at desc limit 1
  );

  -- After answering, the turn passes to the defender.
  update public.games
  set pending_question_id = null,
      pending_asker = null,
      current_turn = auth.uid(),
      turn_started_at = now()
  where id = p_game_id;
end $$;

create or replace function public.submit_guess(p_game_id uuid, p_character_id int)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_game public.games;
  v_room public.rooms;
  v_opponent uuid;
  v_secret int;
  v_correct boolean;
  v_winner uuid;
  v_questions int;
  v_score int;
begin
  select * into v_game from public.games where id = p_game_id for update;
  if not found then raise exception 'GAME_NOT_ACTIVE'; end if;
  select * into v_room from public.rooms where id = v_game.room_id;
  perform public._assert_member(v_room);

  if v_game.status <> 'active' then raise exception 'GAME_NOT_ACTIVE'; end if;
  if v_game.current_turn <> auth.uid() then raise exception 'NOT_YOUR_TURN'; end if;
  if v_game.pending_question_id is not null then raise exception 'PENDING_QUESTION'; end if;
  if not exists (select 1 from public.characters where id = p_character_id and active) then
    raise exception 'INVALID_CHARACTER';
  end if;

  v_opponent := case when auth.uid() = v_room.host_id then v_room.guest_id else v_room.host_id end;
  select character_id into v_secret from public.game_secrets
  where game_id = p_game_id and player_id = v_opponent;

  v_correct := (v_secret = p_character_id);
  v_winner := case when v_correct then auth.uid() else v_opponent end;
  v_questions := case when v_winner = v_room.host_id then v_game.host_questions else v_game.guest_questions end;
  v_score := public._winner_score(v_questions, extract(epoch from now() - v_game.started_at));

  update public.games
  set status = 'finished',
      finished_at = now(),
      winner_id = v_winner,
      win_reason = case when v_correct then 'correct_guess' else 'opponent_wrong_guess' end,
      last_guess = jsonb_build_object(
        'playerId', auth.uid()::text, 'characterId', p_character_id, 'correct', v_correct
      ),
      host_score = case when v_winner = v_room.host_id then v_score else 0 end,
      guest_score = case when v_winner = v_room.guest_id then v_score else 0 end,
      revealed_secrets = (
        select jsonb_object_agg(player_id::text, character_id)
        from public.game_secrets where game_id = p_game_id
      )
  where id = p_game_id;

  update public.rooms set status = 'finished', finished_at = now() where id = v_room.id;
end $$;

create or replace function public.timeout_turn(p_game_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_game public.games;
  v_room public.rooms;
  v_next uuid;
begin
  select * into v_game from public.games where id = p_game_id for update;
  if not found then raise exception 'GAME_NOT_ACTIVE'; end if;
  select * into v_room from public.rooms where id = v_game.room_id;
  perform public._assert_member(v_room);

  if v_game.status <> 'active' then raise exception 'GAME_NOT_ACTIVE'; end if;
  if now() - v_game.turn_started_at < interval '90 seconds' then
    raise exception 'TURN_NOT_EXPIRED';
  end if;

  v_next := case when v_game.current_turn = v_room.host_id then v_room.guest_id else v_room.host_id end;

  if v_game.pending_question_id is not null then
    -- Defender never answered: drop the question and refund the asker.
    delete from public.game_questions
    where id = (
      select id from public.game_questions
      where game_id = p_game_id and answer is null
      order by asked_at desc limit 1
    );
    update public.games
    set host_questions = greatest(0, host_questions - (case when pending_asker = v_room.host_id then 1 else 0 end)),
        guest_questions = greatest(0, guest_questions - (case when pending_asker = v_room.guest_id then 1 else 0 end))
    where id = p_game_id;
  end if;

  update public.games
  set pending_question_id = null,
      pending_asker = null,
      current_turn = v_next,
      turn_started_at = now()
  where id = p_game_id;
end $$;

create or replace function public.request_rematch(p_room_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_room public.rooms;
  v_game public.games;
begin
  select * into v_room from public.rooms where id = p_room_id for update;
  if not found then raise exception 'ROOM_NOT_FOUND'; end if;
  perform public._assert_member(v_room);
  if v_room.guest_id is null then raise exception 'REMATCH_NOT_ALLOWED'; end if;

  select * into v_game from public.games where id = v_room.current_game_id;
  if not found or v_game.status <> 'finished' then raise exception 'REMATCH_NOT_ALLOWED'; end if;

  update public.rooms
  set host_rematch = host_rematch or (auth.uid() = host_id),
      guest_rematch = guest_rematch or (auth.uid() = guest_id)
  where id = p_room_id
  returning * into v_room;

  if v_room.host_rematch and v_room.guest_rematch then
    perform public._start_game(v_room);
  end if;
end $$;

create or replace function public.leave_room(p_room_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_room public.rooms;
  v_game public.games;
  v_winner uuid;
  v_questions int;
  v_score int;
begin
  select * into v_room from public.rooms where id = p_room_id for update;
  if not found then return; end if;
  perform public._assert_member(v_room);

  if v_room.current_game_id is not null then
    select * into v_game from public.games where id = v_room.current_game_id for update;
    if found and v_game.status = 'active' and v_room.guest_id is not null then
      -- Leaving an active game forfeits it.
      v_winner := case when auth.uid() = v_room.host_id then v_room.guest_id else v_room.host_id end;
      v_questions := case when v_winner = v_room.host_id then v_game.host_questions else v_game.guest_questions end;
      v_score := public._winner_score(v_questions, extract(epoch from now() - v_game.started_at));
      update public.games
      set status = 'finished',
          finished_at = now(),
          winner_id = v_winner,
          win_reason = 'forfeit',
          host_score = case when v_winner = v_room.host_id then v_score else 0 end,
          guest_score = case when v_winner = v_room.guest_id then v_score else 0 end,
          revealed_secrets = (
            select jsonb_object_agg(player_id::text, character_id)
            from public.game_secrets where game_id = v_game.id
          )
      where id = v_game.id;
    end if;
  end if;

  update public.rooms set status = 'finished', finished_at = now() where id = p_room_id;
end $$;

/* ------------------------------ realtime ------------------------------ */

do $$ begin
  alter publication supabase_realtime add table public.rooms;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.games;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.game_questions;
exception when duplicate_object then null; end $$;
