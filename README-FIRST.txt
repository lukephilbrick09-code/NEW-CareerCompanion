MYNBA 2K27 CREATOR — START HERE

THE SIMPLEST FIRST GOAL: publish the current website and get a link.

FILES IN THIS FOLDER
- index.html: the website, including the Flux Lines-style animated background.
- HANDOFF.md: the fuller specification for connecting accounts and online saving later.
- supabase-schema.sql: database setup for the later Supabase stage. You do NOT need this to publish the first static website.

DO THIS IMMEDIATELY AFTER DOWNLOADING THE ZIP
1. Extract/unzip this folder somewhere easy to find, such as your Desktop.
2. Open https://github.com and sign in (create a free account if needed).
3. Click the + in the top-right, then New repository.
4. Repository name: mynba-creator. Choose Public, then Create repository.
5. On the new repository page, click Add file, then Upload files.
6. Open the unzipped folder on your computer. Drag index.html into the GitHub upload page.
   You can also upload HANDOFF.md and supabase-schema.sql now so they are kept with the project, but only index.html is required for the first published website.
7. Click Commit changes.
8. Go to https://vercel.com and sign in with GitHub.
9. Click Add New → Project. Find mynba-creator and click Import.
10. Leave the default settings alone and click Deploy.
11. When Vercel finishes, click Visit to open your website link.

IMPORTANT
- The first published version is a static website. It saves data in that browser/device only.
- Online accounts and cross-device career saving are NOT connected yet.
- Do not put a Supabase service-role/secret key in index.html or anywhere public.
- Later, the SQL file is run in Supabase → SQL Editor. The HTML must also be updated with Supabase connection/auth code; SQL alone does not connect it.
