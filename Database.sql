-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.profiles (
  id uuid NOT NULL,
  full_name text,
  role text DEFAULT 'user'::text,
  name text DEFAULT full_name,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.tickets (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  status text DEFAULT 'open'::text,
  user_id uuid NOT NULL,
  helpdesk_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  attachment_url text,
  assigned_to uuid,
  CONSTRAINT tickets_pkey PRIMARY KEY (id),
  CONSTRAINT tickets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT tickets_helpdesk_id_fkey FOREIGN KEY (helpdesk_id) REFERENCES public.profiles(id),
  CONSTRAINT tickets_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.profiles(id)
);
CREATE TABLE public.comments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  ticket_id uuid NOT NULL,
  user_id uuid NOT NULL,
  content text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT comments_pkey PRIMARY KEY (id),
  CONSTRAINT comments_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id),
  CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.ticket_histories (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  ticket_id uuid NOT NULL,
  status text NOT NULL,
  description text,
  changed_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  action text,
  CONSTRAINT ticket_histories_pkey PRIMARY KEY (id),
  CONSTRAINT ticket_histories_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id),
  CONSTRAINT ticket_histories_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES auth.users(id)
);