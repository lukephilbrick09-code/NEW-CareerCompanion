# MyNBA 2K27 Creator — v12

A single-file browser-based MyNBA/MyCAREER build and career tracker. It lets you create a player build, manage badges, and track games and career progress.

> **Note:** This is a community-made companion tool, not an official NBA 2K product. NBA 2K27 badge/attribute data and requirements may change; verify in-game before relying on them.

## Features

- **Build creator:** adjust player attributes and monitor the total attribute-point budget.
- **Attribute Distribution checker:** automatically checks the number of attributes in each rating bracket whenever attributes change. Exceeding a bracket maximum displays an error; being below a maximum is allowed.
- **Attribute key:** guidance for understanding the build and attribute distribution, available in the Build tab.
- **Badge loadout:** select badges and review eligibility against the requirements included in the site. Badge slot trading includes Gold-to-Silver and Silver-to-Bronze options.
- **Career tracking:** log games, season goals, XP, training, and career progress using the available tabs.
- **Local save and backup tools:** data is stored in the browser on the device you use. Export a backup regularly if you want to preserve or transfer progress.
- **Responsive layout:** designed to work across desktop and smaller screens.

## Attribute distribution maximums

| Rating bracket | Maximum attributes |
|---|---:|
| 95–99 | 1 |
| 90–94 | 6 |
| 85–89 | 5 |
| 80–84 | 7 |
| 75–79 | 4 |
| 70–74 | 5 |
| 65–69 | 3 |
| 60–64 | 1 |
| Below 60 | 4 |

These are upper limits, not minimum targets. The distribution check is separate from the overall attribute-point budget check.

## Run locally

No build step or package installation is required.

1. Download or clone this repository.
2. Open `index.html` in a modern browser.
3. Start building your player.

If your browser restricts any feature when opening the file directly, run a simple local web server from the project folder, for example:

```bash
python -m http.server 8000
```

Then visit `http://localhost:8000`.

## Data and privacy

The site is designed to save progress in your browser on your current device. Clearing browser site data or using another browser/device may make that local data unavailable. Use the built-in export/backup option before clearing data or moving devices. Do not assume your data is automatically synced to GitHub or the cloud.

## React Bits-inspired styling

The current version includes **CSS-only styling inspired by React Bits**—for example, subtle hover movement/shadows and visible keyboard-focus outlines. It does **not** import React Bits components, React, GSAP, or Framer Motion; no React Bits component library is bundled.

## Disclaimer

This is an unofficial fan-made project and is not affiliated with, endorsed by, or sponsored by 2K or the NBA. NBA 2K and related names are trademarks of their respective owners. Badge eligibility and game mechanics may differ from the live game or change with updates.
