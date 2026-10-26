# MyNBA 2K27 Creator: handoff for turning it into a real web app

Give ChatGPT these three files together:
1. `HANDOFF.md` (this file: spec, rules, data model, plan)
2. `mynba-creator.html` (the working prototype, about 75 KB, single file, the source of truth for every number and string)
3. `supabase-schema.sql` (database tables and security rules)

---

## 0. Paste this as your first message to ChatGPT

> I'm attaching a working single-file prototype (`mynba-creator.html`), a spec (`HANDOFF.md`) and a Supabase schema (`supabase-schema.sql`). Read all three fully before writing code.
>
> Goal: turn the prototype into a real, mobile-first web app deployed on Vercel, with accounts and saving on Supabase (Postgres + Auth + Row Level Security). It must behave exactly like the prototype. Do not change any numbers, thresholds, names or XP values. If something in the spec and the HTML disagree, the HTML wins; tell me about the disagreement.
>
> Work in phases and stop after each phase for me to confirm:
> 1. Repo scaffold (Next.js App Router + TypeScript, Tailwind or plain CSS using the design tokens in section 9), Vercel and Supabase setup steps, env vars.
> 2. Port the pure game rules out of the HTML into plain TypeScript modules with unit tests (section 5 lists them). No UI yet.
> 3. Port the UI tab by tab (Build, Badges, Games, XP, Ledger, Team, Social). Keep the prototype's layout, collapsible sections and phone-first design.
> 4. Supabase: auth (email magic link, optionally Google), `careers` table, local-first saving with debounced sync and optimistic concurrency (section 7).
> 5. Import: let a user paste the prototype's backup JSON (both the old single-career format and the new `{cur, slots, th, tab}` format) and turn it into careers.
> 6. Polish: PWA install, offline, error states, empty states, accessibility, deploy checklist.
>
> Ask me before adding features that are not in the spec. Keep answers short and give me exact commands and files, not theory.

---

## 1. What the app is

A planning and tracking tool for a player in NBA 2K27 MyNBA/MyCareer-style play. The user builds a custom player (36 attributes, total 2,700 points), equips badges, logs games, earns XP, spends XP on upgrades, keeps a season ledger with awards and a career graph, gets a generated game plan, ideal team checklist, fake social posts and interviews. The user opens it every game on a phone, so fast logging and low clutter matter most.

Everything is stored client-side in the prototype. The web app must save per user, per career, across devices.

## 2. Tabs and features (all must be ported)

Tab bar (scrolls sideways on phones): **Build, Badges, Games, XP, Ledger, Team, Social**. The app opens on the last-used tab (default Games). A gear button opens a menu with Careers, Theme (Auto/Light/Dark) and Backup (export/import).

- **Careers (gear menu):** up to 8. New, open, rename, delete (two taps to confirm). A label under the title shows the open career.
- **Build:** 36 attribute sliders in 7 groups with number boxes (min 25, max 99). Soft cap 2,700 total: shows over/under, never blocks. Starts at 25 each. "Reset all to 25". Build summary (collapsed): archetype from the two strongest categories, top 5 and bottom 5 ratings, category averages. **You play like:** top 3 comps by shape similarity (section 5.9). Position and play style selectors (used by the plan and ideal team).
- **Badges:** 53 badges, three tiers each, requirements only (no height limits). 6 slots per tier plus bought extras. Filters: Show (All, Gold/Silver/Bronze reachable, Picked only) and Category. A picked badge is dropped automatically if ratings fall below its tier.
- **Games:**
  - Hot streak panel (section 5.7).
  - Game form: PTS, REB, AST, STL, BLK, TOV, FGM, FGA, 3PM, 3PA, FTM, Win. FG% and 3P% are calculated and shown live. Validation: makes cannot exceed attempts, 3PM cannot exceed FGM, 3PA cannot exceed FGA.
  - Log game, Copy last game. Each logged game completes at most one bingo goal: the highest-XP unfinished goal the line satisfies. Undo last. Last 3 games shown.
  - Running totals tiles: GP, W-L, PPG, RPG, APG, SPG, BPG, TOV, FG%, 3P%, 3PM/g, total PTS.
  - 20-game bingo card (goals in the HTML as `GOALS`). Tapping a card toggles it by hand.
  - Highlight hunter (collapsed): 17 highlight plays, each showing "Build ready" or what is missing (real badge and attribute names). Tap to mark done.
  - "Reset card and games" is tucked in a collapsed section.
- **XP:** XP available, attribute list with +1 and +5 buttons and an undo, extra badge slots, XP history, Milestones (14 achievements).
- **Ledger:** add a season (Team, Games, Wins, OVR, PTS, REB, AST, STL, BLK, 3PM totals). Each season card shows record-book trivia and roasts, XP earned, and chips for Finals, Champion, Injured, Traded. Career arc text and closest comp. Career graph (SVG; metric buttons OVR, PPG, RPG, APG, 3PM/g; event markers under each season). Awards tracker: the user ticks awards per season; the app never decides wins.
- **Team:** archetype and game plan (top 3 of 9 tactics), ideal team checklist (starting five, 6th man, backup big, coach) with real-player style comps, roster log (trades, signings, picks marked Helped/Hurt/Neutral), coach and system fit tracker.
- **Social:** three fake posts (fan page, reporter, teammate) with Hype or Roast tone, using recent form and ticked awards. Media day interviews (multiple choice, 100 XP each, builds a public image of Humble/Confident/Fiery). Media narrative (headline plus analyst takes).

## 3. Per-career state (this is the JSON the prototype saves)

```ts
type Career = {
  st: Record<AttrName, number>;      // base ratings 25..99
  bo: Record<AttrName, number>;      // bought upgrades (added to st)
  pk: Record<BadgeName, 1|2|3>;      // equipped badge -> tier (1 Bronze, 2 Silver, 3 Gold)
  sl: {1:number,2:number,3:number};  // extra badge slots bought per tier
  xs: number;                        // XP spent
  hx: string[];                      // XP history lines (keep last 40)
  dn: Record<number,boolean>;        // bingo goal index -> done
  dm: Record<number,number>;         // bingo XP multiplier locked at completion
  hl: Record<number,boolean>;        // highlight index -> done
  hm: Record<number,number>;         // highlight XP multiplier locked at completion
  lg: GameLog[];                     // game log (keep last 82)
  ld: Season[];                      // ledger seasons
  iv?: {d:Record<string,1>, t:[number,number,number], c:any, r:string, m:string}; // interviews
  rl?: {s:string,t:string,d:string,i:'Helped'|'Hurt'|'Neutral'}[];               // roster log
  cf?: {n:string,y:string,g:number,w:number,pts:number,reb:number,ast:number}[]; // coach stints
  tk?: Record<string,boolean>;       // ideal team ticks
  ap?: 'PG'|'SG'|'SF'|'PF'|'C'; as?: ''|'s'|'m'|'d'|'r'; so?: 'hype'|'roast'; cm?: 'ovr'|'pts'|'reb'|'ast'|'tpm';
};
type Season = {id:number,team:string,g:number,w:number,ovr:number,pts:number,reb:number,ast:number,stl:number,blk:number,tpm:number,
  aw?:Record<string,boolean>, ev?:{Finals?:boolean,Champion?:boolean,Injured?:boolean,Traded?:boolean}};
type GameLog = {id:number, l:{pts:number,reb:number,ast:number,stl:number,blk:number,tov:number,fgm:number,fga:number,tpm:number,tpa:number,ftm:number,fgp:number,win:boolean}, hit:number[]};
```

Global (not per career): theme (`auto|light|dark`), last tab. The prototype's localStorage root is `{cur:number, slots:[{n:string, s:Career|null}], th?:string, tab?:string}` under the key `mynba27c`. The older key `mynba27b` held a single Career.

Attribute renaming migration (old name to current name) is in the HTML as `REN` and `migrate()`. Keep it for imports of old backups.

## 4. Where the data tables live in the HTML

Search the file for these variable names; port them as typed constants/JSON:
- `GR` (36 attributes in 7 groups, names taken from the Cooper Flagg page on NBA2KLab)
- `K` and `B` (20 attribute aliases and 53 badges with Bronze/Silver/Gold requirements; `A` means all listed attributes needed, `O` means any one)
- `GOALS` (20 bingo goals: tier E/M/H/X plus conditions) and `HLG` (17 highlight goals)
- `REC` (6 all-time single-season records), `AWD` and the logic in `awards()` (award reference thresholds)
- `TACT`, `POS`, `STY`, `ROLES`, `COMP`, `SYSM` (game plan, ideal team and comps)
- `CMPA`, `CMPP`, `CLASSICS` (comp pool)
- `SOC`, `HL`, `AN`, `IVQ` (social, media and interview text templates)
- `MS` (milestones)

## 5. Rules to port as pure, unit-tested functions

1. **Effective rating:** `ef(a) = st[a] + bo[a]`. Cap each at 99 when buying.
2. **Build total target:** 2,700, soft. Over/under message only.
3. **Attribute upgrade cost (per +1, based on current effective rating r):** r<70: 25 XP, 70-79: 50, 80-84: 100, 85-89: 200, 90-94: 400, 95+: 800. Undo refunds the cost of the rating it came from. "+5" repeats +1 until the XP or the 99 cap runs out.
4. **XP earned** = bingo + ledger + highlights + interviews.
   - Bingo: goal base XP by tier E 150, M 300, H 450, X 750, times the multiplier stored at completion.
   - Highlights: E 100, M 200, H 350, X 600, times the stored multiplier.
   - Interviews: 100 each (once per context key).
   - Ledger season XP: for each of the 6 records, `round(min(pct,100)*3)` where `pct = season total / record * 100`, plus 500 if the season total beats the record. Records: points 4029, rebounds 2149, assists 1164, steals 301, blocks 456, threes 402.
   - **XP available** = earned minus spent. It can go negative if the user removes a season or unticks something; show it in red and block new purchases. Never wipe purchases automatically.
5. **Extra badge slot cost:** base Gold 1500, Silver 750, Bronze 375, times `1.35 ^ (total extra slots already bought across all tiers)`, rounded to the nearest 5.
6. **Badge eligibility:** tier t is available if all (`A`) or any (`O`) listed attributes meet that tier's threshold using effective ratings. Slots: 6 per tier plus bought extras.
7. **Hot streak:** game score `gs = pts + 1.2*reb + 1.5*ast + 2*stl + 2*blk`. A game is "big" if `gs >= 32`. Streak = consecutive big games ending at the latest game. Level: 3+ = 1, 5+ = 2, 7+ = 3. Bingo multiplier [1, 1.25, 1.5, 2], highlight multiplier [1, 1.25, 1.75, 2.5]. Level 2+ shows a house-rule badge boost (one equipped sub-Gold badge "plays as" one tier higher; level 3 shows two). It is display only. The multiplier is locked into `dm`/`hm` at completion so XP already earned never shrinks when a streak ends.
8. **Game logging:** compute `fgp = round(fgm/fga*1000)/10`. Goals satisfied by the line are those not already done whose conditions all hold. Complete only the highest-XP one (first on ties). Store the multiplier. Undo removes the goal it completed.
9. **Comp ("You play like"):** vector of 36 effective ratings, z-score it, compute RMS distance to each pool player's z-scored vector, `similarity = round(100 * max(0, 1 - d/1.8))`, show the top 3. If max minus min rating is under 12, show a "spread your ratings first" message. Also show 3 shared strengths and the 2 biggest gaps against the top match.
10. **Game plan:** nine tactics (`TACT`), each scored as the average of listed ratings plus a position nudge (`POS`) plus 6 if it matches the chosen play style (`STY`). Archetype name = top tactic name + " / " + second tactic name lower-cased. Ideal team: for each other position pick the role whose tactic has the lowest fit (largest need), avoiding tactics already used.
11. **Awards:** only reference text and the user's ticks. Never auto-award.

## 6. What is real and what is estimated (keep these labels in the UI)

Real (sourced from NBA2KLab 2K27 pages): the 36 attribute names and groups (Cooper Flagg page), the 53 badges and their tier requirements (badge requirements page), and the 26 current-player rating vectors (player ratings table, first page, plus Cooper Flagg's page).

My estimates, not game data: the 15 all-time players in `CLASSICS` (only Jordan's, Kobe's and Shaq's three-point ratings were anchored to 2K26 listings), award reference thresholds, tactic weights, ideal-team target ratings, highlight attribute thresholds, hot-streak and XP economy numbers, and all text templates.

Suggested follow-up: scrape or import the full NBA2KLab ratings table (502 current players across 21 pages) for a much bigger comp pool, and store it in a Supabase table. Check their terms of use first.

## 7. Supabase and Vercel plan

- **Stack:** Next.js (App Router) + TypeScript on Vercel, `@supabase/supabase-js` and `@supabase/ssr`. Env vars: `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`. The anon key is safe in the browser only because Row Level Security is on for every table.
- **Auth:** email magic link first, Google optional.
- **Storage model:** one row per career in `careers` with the whole `Career` JSON in `state jsonb`. See `supabase-schema.sql`. Normalised tables for games and seasons can come later if you want leaderboards or analytics.
- **Local-first saving:** keep working from localStorage, write to Supabase 1-2 seconds after the last change (debounced), and on load fetch and merge.
- **Conflicts:** optimistic concurrency. The row has an integer `version` that a trigger increments. The client updates with `.eq('id', id).eq('version', knownVersion)`. If zero rows update, fetch the newer row and ask which to keep (or default to the newer `updated_at`).
- **First login import:** if the user has localStorage data from the prototype, offer to upload it as Career 1. Support pasting the old backup JSON in both formats.
- **Sharing (optional):** a career can be flagged `is_shared` with a `share_slug` for a read-only recap page. If you do this, expose only a safe subset through a database view or a server route instead of the whole `state`.
- **Deploy:** push to GitHub, import the repo in Vercel, add the two env vars, set Supabase Auth redirect URLs to the Vercel and local URLs. Supabase free projects can pause when inactive; check current limits.

## 8. Mobile and quality requirements

- Phone first, one thumb. Safe-area padding for notches. Sticky tab bar that scrolls horizontally. Collapsible sections for secondary content.
- Light and dark themes, plus Auto.
- Never block with `window.prompt` or `confirm`. Use inline inputs and two-tap confirmations.
- Offline support and installable PWA.
- Escape all user-entered text (team names, roster notes) when rendering.
- Unit tests for every function in section 5 using the prototype's behaviour as the reference. A simple approach: feed the same inputs to the HTML (in a browser console) and to the TypeScript, compare outputs.

## 9. Design tokens (from the prototype)

Fonts: Barlow Condensed (600, 700) for headings and numbers, Barlow (400, 500, 600) for body.
Light: bg `#f6ecd6`, card `#fffaf0`, text `#1b2430`, muted `#6b6354`, line `#d9c9a4`, accent `#a3362b`, ok `#2a6f77`, warn `#b5651d`, gold `#c9971c`, silver `#8a96a3`, bronze `#a8683a`.
Dark: bg `#141b24`, card `#1d2631`, text `#f1e4c6`, muted `#a89f8a`, line `#33404f`, accent `#e0705f`, ok `#5fb3bb`, warn `#e0a05a`.
Base font about 15px, small helper text 13px, cards with 10px radius.

## 10. Known gaps and ideas for later

- The prototype was tested with a scripted stand-in browser, not on real phones. Expect small layout fixes.
- Old tendencies feature was removed on purpose. Do not rebuild it.
- Ideas: CSV export of games and seasons, share-card image, undo toast after XP purchases, "Close season" (turn logged games into a Ledger season), season simulator, trade and draft board, bigger comp pool.
