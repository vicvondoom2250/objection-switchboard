# Objection Switchboard

Static site + Supabase. Deploy anywhere that serves static files (Netlify, Vercel, Cloudflare Pages).

1. Supabase → SQL Editor → paste `schema.sql` → change `CHANGE-ME-NOW` to your team password → Run.
2. Supabase → Settings → API → copy Project URL and anon public key into `CONFIG` at the top of `index.html`.
3. Deploy the folder. `index.html` is the whole site.

Reps add objections with the team password. Rotate it with the last line of `schema.sql`.
