-- À lancer UNE fois dans Supabase : SQL Editor > New query > coller > Run.
-- Espace admin de l'app équestre : seul gouissemmathys@gmail.com peut voir la liste des utilisateurs et leurs chiffres.
create or replace function public.dp_admin_stats()
returns table(email text, prenom text, inscrit timestamptz, derniere_connexion timestamptz, derniere_activite timestamptz, chevaux text, nb_chevaux int, seances int)
language plpgsql security definer set search_path = public, auth as $$
begin
  if lower(coalesce(auth.jwt() ->> 'email', '')) <> 'gouissemmathys@gmail.com' then
    raise exception 'acces refuse';
  end if;
  return query
  select u.email::text,
         (u.raw_user_meta_data ->> 'prenom')::text,
         u.created_at,
         u.last_sign_in_at,
         d.updated_at,
         (select string_agg(h -> 'info' ->> 'nom', ', ') from jsonb_array_elements(case when jsonb_typeof(d.data -> 's' -> 'horses') = 'array' then d.data -> 's' -> 'horses' else '[]'::jsonb end) h where coalesce(h -> 'info' ->> 'nom', '') <> '')::text,
         (select count(*) from jsonb_array_elements(case when jsonb_typeof(d.data -> 's' -> 'horses') = 'array' then d.data -> 's' -> 'horses' else '[]'::jsonb end) h where coalesce(h -> 'info' ->> 'nom', '') <> '')::int,
         (select coalesce(sum(case when jsonb_typeof(h -> 'sessions') = 'array' then jsonb_array_length(h -> 'sessions') else 0 end), 0) from jsonb_array_elements(case when jsonb_typeof(d.data -> 's' -> 'horses') = 'array' then d.data -> 's' -> 'horses' else '[]'::jsonb end) h)::int
  from auth.users u
  join public.budget_docs d on d.user_id = u.id and d.key = 'dp-state'
  order by d.updated_at desc;
end $$;
revoke all on function public.dp_admin_stats() from public, anon;
grant execute on function public.dp_admin_stats() to authenticated;
