<div align="center">

# Claude Code on Android

**The real Claude Code, running on an unrooted phone. No PC, no root, no paid plan.**

Termux → proot-Ubuntu → Claude Code, with free model access through a local [OmniRoute](https://github.com/diegosouzapw/OmniRoute) gateway (290+ providers, zero-config).

![Android 8+](https://img.shields.io/badge/Android-8%2B-3DDC84?logo=android&logoColor=white)
![No root](https://img.shields.io/badge/root-not%20needed-success)
![Cost](https://img.shields.io/badge/cost-free-blue)
![Arch](https://img.shields.io/badge/arch-aarch64-lightgrey)
![Disk](https://img.shields.io/badge/disk-~5GB-orange)

<br>

<a href="screenshot-portrait.png"><img src="screenshot-portrait.png" alt="Claude Code running in a Termux session on an Android phone, showing the welcome panel with the claude-opus-free model and OmniRoute gateway"/></a>

<sub>A real session — Claude Code in Termux on an unrooted phone, answering through OmniRoute's zero-config auto-routing.</sub>

<br>

**▶️ Full step-by-step setup video:** [youtu.be/DUBBbO6FzOo](https://youtu.be/DUBBbO6FzOo)

The chapters in this repo match the chapters on screen. New here? [Watch the video first](https://youtu.be/DUBBbO6FzOo), then use this page as the copy-paste reference.

</div>

> [!NOTE]
> **Verified 2026-08-05** on an unrooted aarch64 Android phone with OmniRoute v3.8.50+.
> Free provider tiers change often. If a step breaks: [`free-api-options.md`](free-api-options.md), then [`troubleshooting.md`](troubleshooting.md).

---

## Contents

| | |
|---|---|
| [How the pieces fit](#how-the-pieces-fit) | The one thing to understand before you start |
| [What you need](#what-you-need) | Requirements, and the Termux build that actually works |
| [Quick start](#quick-start-scripted) | `setup.sh` — Chapters 1–3, unattended |
| [After `setup.sh` finishes](#after-setupsh-finishes) | The manual half, as a copy-paste list |
| [Full walkthrough](#full-walkthrough) | Chapters 1–6, every command explained |
| [Daily use](#daily-use) | The two-session routine |
| [Useful commands](#useful-commands) | Cheat sheet, split by which shell it runs in |
| [Why proot-Ubuntu](#why-proot-ubuntu-and-not-the-native-install) | And why the easier-looking path breaks |
| [Honest limits](#honest-limits) | What this setup is bad at |

---

## How the pieces fit

```
Termux
├── session 1:  omniroute                    → listens on 127.0.0.1:20128
└── session 2:  proot-distro login ubuntu
                └── Ubuntu ── claude         → talks to 127.0.0.1:20128
```

OmniRoute runs in **Termux**. Claude Code runs **inside Ubuntu**. proot doesn't isolate the network, so `127.0.0.1` inside Ubuntu still reaches the gateway running in Termux.

**Always know which shell you're in.** Most problems in this stack are the right command in the wrong environment:

| Prompt | You're in | What lives here |
|---|---|---|
| `~ $` | Termux | `omniroute`, `node`, `proot-distro` |
| `root@localhost:~#` | Ubuntu | `claude`, `~/.claude/settings.json` |

> [!IMPORTANT]
> Ubuntu has its **own home directory**. `~/.claude/settings.json` has to be created *inside* Ubuntu — a copy in Termux's home is silently ignored, with no error.
>
> Node.js is needed in **Termux** (for OmniRoute), not in Ubuntu.

---

## What you need

| | |
|---|---|
| **Phone** | Any Android 8+, **not rooted** |
| **CPU** | `aarch64` — check with `uname -m` |
| **RAM** | 4GB or more |
| **Storage** | ~5GB free (Ubuntu alone is ~2GB) |
| **App** | Termux from [F-Droid](https://f-droid.org/packages/com.termux/) or [GitHub Releases](https://github.com/termux/termux-app/releases) |
| **Not needed** | A PC, a paid Claude plan, root |

> [!WARNING]
> **Don't use the Play Store build of Termux.** It's an experimental branch the Termux maintainers recommend against, and it's the single most common cause of "nothing works." Uninstall it and install from F-Droid or GitHub Releases instead.

---

## Quick start (scripted)

[`setup.sh`](setup.sh) does Chapters 1–3 — Termux packages, Ubuntu, Claude Code — unattended:

```bash
curl -fsSL https://raw.githubusercontent.com/Tophunt-max/claude-code-android/main/setup.sh -o setup.sh
cat setup.sh          # read it before you run it
bash setup.sh
```

Tested on a clean run: freshly wiped Termux → working `claude` inside Ubuntu, no manual fixes needed. Safe to re-run too — completed steps are detected and skipped.

<details>
<summary><b>What the script actually does, step by step</b></summary>

<br>

No surprises — this is everything it touches, in order:

**Before installing anything, it checks:**

| Check | If it fails |
|---|---|
| Running inside Termux | Stops — this isn't a script for a PC |
| CPU is `aarch64` | Stops — Claude Code has no 32-bit build, no workaround |
| ~5GB free storage | Asks before continuing — Ubuntu unpacks before cleanup |
| A leftover Path A `claude` in Termux | Warns only — it doesn't touch or delete it |
| **Internet reachable** | Stops with a clear message — so it never downloads for minutes then fails on no connection |

**Step 1 — Termux packages.** `pkg update && pkg upgrade`, then installs `proot-distro` (runs the Ubuntu container) and `nodejs` (needed for OmniRoute). Fully non-interactive — keeps existing configs so nothing hangs.

**Step 2 — Ubuntu.** `proot-distro install ubuntu` — a ~2GB download from the official proot-distro mirrors, retried up to 3×. If a previous run left a half-finished container (no `/bin/bash` inside), removes it and starts fresh.

**Step 3 — Claude Code, inside Ubuntu.** Runs `apt update && apt upgrade` non-interactively (keeping existing configs, so it can't hang on a prompt), installs `curl git wget build-essential`, then runs Anthropic's official installer.

**What it deliberately does NOT do:**

- No OmniRoute install, no API keys, no `settings.json` — those need your accounts and a browser, so they stay manual and the script prints them as next steps
- Never asks for root, never runs `su`
- Deletes nothing — not even a leftover Path A install
- Sends nothing anywhere — the only network traffic is the package downloads above

The whole thing is ~250 lines of commented bash. `cat setup.sh` before running it — that's why the download step is separate.

</details>

It stops after Chapter 3 on purpose. Chapters 4–6 (OmniRoute, providers, combos, `settings.json`) need your own free API keys and a browser, so the script prints them as next steps instead of guessing.

> [!TIP]
> Do it manually the first time anyway. When something breaks later — and on free tiers it will — you'll know which piece to look at.

---

## After `setup.sh` finishes

The script leaves you with a working `claude` inside Ubuntu that isn't pointed at anything yet. Six steps left. They're the same as Chapters 4–6 below, collected here in order so you can work straightforwardly without scrolling.

**1. Confirm the install, in Termux — prompt `~ $`**

```bash
proot-distro login ubuntu -- /root/.local/bin/claude --version
```

Prints a version and drops you back in Termux. Call the binary by its full path here: a non-interactive login (`bash -lc 'claude ...'`) doesn't pick up the `PATH` line in `.bashrc`, so a bare `claude` would fail.

**2. Start OmniRoute, in Termux**

```bash
npm install -g omniroute
omniroute
```

**Leave this session running.** Close it and Claude Code loses its endpoint.

**3. Set up the dashboard, in your phone's browser**

Open `http://localhost:20128` — default password `123456`.

- **Change that password first.** It's a published default.
- **Zero-config mode:** OmniRoute works immediately with 40+ free providers (OpenCode, Kilo, etc.). No setup required — just start using it.
- **Add more providers** via the Providers tab if you want. See [`free-api-options.md`](free-api-options.md) for rankings.
- **Create combos** (optional) for auto-fallback. A simple priority-ordered list named `claude-opus-free` works.

**4. Open a second Termux session and enter Ubuntu**

Swipe from the **left edge** → **New session**, then:

```bash
proot-distro login ubuntu
```

Prompt becomes `root@localhost:~#`. Everything below runs here.

**5. Write the config, inside Ubuntu**

```bash
mkdir -p ~/.claude
nano ~/.claude/settings.json
```

Paste the JSON from [Chapter 6](#chapter-6--point-claude-code-at-omniroute), then `Ctrl+O`, `Enter`, `Ctrl+X`.

> [!IMPORTANT]
> This has to be **Ubuntu's** home, not Termux's. A `settings.json` in Termux's `~` is silently ignored.

**6. Check it, then run it — inside Ubuntu**

```bash
cat ~/.claude/settings.json                                          # right file, valid JSON?
curl -s http://127.0.0.1:20128/ -o /dev/null -w '%{http_code}\n'     # any HTTP code = gateway reachable
claude
```

Watch the OmniRoute session while you send your first message. A line like `▶ POST /v1/chat/completions` means the whole chain works. Nothing at all means the config isn't right.

**Every session after this** — two Termux sessions, `omniroute` in one, `proot-distro login ubuntu` → `claude` in the other. Full list of commands worth knowing: [Useful commands](#useful-commands).

---

# Full walkthrough

## Chapter 1 — Prepare Termux

> Runs in **Termux** — prompt `~ $`

```bash
pkg update && pkg upgrade -y
pkg install proot-distro nodejs -y
```

Press `y` if prompted about package maintainer configurations.

`proot-distro` runs the Ubuntu container. `nodejs` is needed for OmniRoute.

```bash
uname -m        # must print aarch64
node -v         # confirms Node is ready for OmniRoute
```

## Chapter 2 — Install Ubuntu

> Runs in **Termux**

```bash
proot-distro install ubuntu
```

2–5 minutes depending on connection speed. Then log in:

```bash
proot-distro login ubuntu
```

The prompt changes from `~ $` to something like `root@localhost:~#`. **You are now inside Ubuntu.** Everything in Chapter 3 runs here.

Leave Ubuntu with `exit`. Get back in with `proot-distro login ubuntu`.

## Chapter 3 — Install Claude Code

> Runs **inside Ubuntu** — prompt `root@localhost:~#`

```bash
apt update && apt upgrade -y
apt install -y curl git wget build-essential
```

Then Anthropic's official installer:

```bash
curl -fsSL https://claude.ai/install.sh | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
claude --version
```

That's the real installer from Anthropic — no patching, no community shim. It installs a standalone binary, which is why **you don't need Node.js inside Ubuntu.**

> [!TIP]
> **Skip the `nodesource` step some guides put here.** `curl -fsSL https://nodesource.com | bash -` is not a setup script — `nodesource.com` is just a website, so that command pipes a web page into bash and does nothing. Harmless but pointless.

## Chapter 4 — Install OmniRoute

> Back in **Termux** — prompt `~ $`

OmniRoute gives you one local endpoint that connects to 290+ providers, with intelligent fallback when one runs dry. It works immediately with no setup — just connect free providers to use them.

Leave Ubuntu (`exit`), or open a fresh Termux session — swipe from the left edge → **New session**:

```bash
npm install -g omniroute
omniroute
```

The gateway starts on `http://localhost:20128`. **Leave this session running.** Close it and the gateway dies, and Claude Code stops working.

## Chapter 5 — Configure providers (optional)

Open `http://localhost:20128` in your phone's browser. Default dashboard password: `123456`

> [!CAUTION]
> **Change that password.** It's a published default. Low risk while the gateway only listens on localhost on your own phone — a real problem the moment that port is reachable from another device.

**Zero-config mode (recommended for most users):**
- OmniRoute ships with 40+ free providers already connected.
- Just open the dashboard and verify the Providers tab shows your available models.
- You're ready to go.

**Add custom providers (optional):**
- Go to **Providers → Available Providers** and sign up with any free provider (OpenCode, Kilo Code, Requesty, etc.).
- Connect them in the dashboard.
- See [`free-api-options.md`](free-api-options.md) for rankings and ordering logic.

**Build combos (optional):**
- Combos are priority-ordered lists of providers for auto-fallback.
- A simple combo named `claude-opus-free` works; add more providers if you want redundancy.
- See [`free-api-options.md`](free-api-options.md) for why multiple combos can help.

## Chapter 6 — Point Claude Code at OmniRoute

> Runs **inside Ubuntu** — in your other session

```bash
proot-distro login ubuntu
mkdir -p ~/.claude
nano ~/.claude/settings.json
```

> [!IMPORTANT]
> **This has to be Ubuntu's home directory, not Termux's.** Claude Code runs inside Ubuntu and only reads the config there. A `settings.json` sitting in Termux's `~` is silently ignored — no error, it just doesn't work.

Paste this, then `Ctrl+O`, `Enter`, `Ctrl+X`:

```json
{
  "hasCompletedOnboarding": true,
  "env": {
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:20128/v1",
    "ANTHROPIC_AUTH_TOKEN": "sk_omniroute",
    "ANTHROPIC_DEFAULT_FABLE_MODEL": "auto",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "auto",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "auto",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "auto"
  }
}
```

Four things in there that matter:

| | |
|---|---|
| **`127.0.0.1`, not `localhost`** | `localhost` can resolve to IPv6 `::1` while OmniRoute listens on IPv4 only — connection refused for no obvious reason. Use the numeric address. |
| **`/v1` on the end** | Without it the API paths don't line up and every request fails. |
| **`hasCompletedOnboarding`** | Skips Claude Code's login flow. You're authenticating against your own local gateway, so this is what stops it asking for a Claude account. |
| **`sk_omniroute`** | The local gateway's own token, not a real Anthropic key. Nothing secret — safe in a public repo. |
| **`"auto"`** | Tells OmniRoute to pick the best available provider automatically. Works immediately with zero setup. |

> [!IMPORTANT]
> **`"auto"` is OmniRoute's smart routing mode.** It works immediately — no combo needed. OmniRoute picks the best provider in real-time based on latency, success rate, and remaining quota.
>
> If you created a custom combo in Chapter 5, use its name instead of `"auto"` (e.g., `"claude-opus-free"`). The name has to match the dashboard **exactly** — that's the most common silent failure in this setup.

Then start it:

```bash
claude
```

<details>
<summary><b>Optional: custom model aliases</b></summary>

<br>

OmniRoute's `auto` mode works for everything. But Claude Code fires a constant stream of *small* background calls at the **Haiku** tier — file reads, summaries, tool routing, context analysis. Those burns through quota quickly.

Point the Haiku tier at a different combo with more generous free limits:

```json
"ANTHROPIC_DEFAULT_HAIKU_MODEL": "auto/cheap"
```

OmniRoute's `auto/cheap` variant prioritizes cost over quality — perfect for background work. See [OmniRoute's auto-combo guide](https://github.com/diegosouzapw/OmniRoute) for all 5 variants.

</details>

---

## Daily use

Two Termux sessions, swipe from the left edge to switch:

| Session | Command | |
|---|---|---|
| 1 | `omniroute` | leave it running |
| 2 | `proot-distro login ubuntu` → `claude` | do your work here |

See [`troubleshooting.md`](troubleshooting.md) for keyboard setup, session persistence, and battery survival.

---

## Useful commands

Everything you'll actually reach for, grouped by the shell it belongs in. Running one of these in the wrong shell is the most common reason something "doesn't work."

### In Termux — prompt `~ $`

| Command | What it does |
|---|---|
| `pkg update && pkg upgrade -y` | Refresh package lists and upgrade everything installed |
| `pkg install <name> -y` | Install a Termux package |
| `uname -m` | Print CPU architecture — must say `aarch64` |
| `df -h $HOME` | Check free storage before installing Ubuntu |
| `termux-setup-storage` | Grant Termux access to phone storage, creates `~/storage` |
| `cd ~/storage/shared` | Jump to your phone's internal storage (Downloads, Documents…) |
| `termux-reload-settings` | Apply changes to `~/.termux/termux.properties`, e.g. the extra-keys row |
| `command -v claude` | Check whether a leftover Path A `claude` is still on the Termux side |
| `omniroute` | Start the gateway — leave this session running |
| `pkill -f omniroute` | Kill a stuck gateway when the port is already in use |
| `proot-distro list` | List available and installed distros |
| `proot-distro login ubuntu` | Enter Ubuntu — this is where Claude Code lives |

### In Ubuntu — prompt `root@localhost:~#`

| Command | What it does |
|---|---|
| `apt update && apt upgrade -y` | Ubuntu's own package refresh — separate from `pkg` in Termux |
| `apt install -y <name>` | Install an Ubuntu package |
| `claude --version` | Confirm Claude Code is installed and on PATH |
| `claude` | Start Claude Code |
| `mkdir -p ~/.claude` | Create the config directory — in **Ubuntu's** home, not Termux's |
| `nano ~/.claude/settings.json` | Edit the config that points Claude Code at OmniRoute |
| `cat ~/.claude/settings.json` | Read the config back to confirm you edited the right one |
| `ls -la ~/.local/bin/claude` | Check the binary actually exists when `claude` isn't found |
| `source ~/.bashrc` | Reload PATH after adding `~/.local/bin` to it |
| `curl -s http://127.0.0.1:20128/ -o /dev/null -w '%{http_code}\n'` | Test that Ubuntu can reach OmniRoute in Termux — any HTTP code means yes |
| `cd /data/data/com.termux/files/home` | Reach Termux's home from inside Ubuntu, for files you also open in an Android app |
| `cd /sdcard/Download` | Jump to your phone's internal Download folder — the short path to shared storage |
| `cd /data/data/com.termux/files/home/storage/downloads` | Same folder via Termux's storage symlink — works once `termux-setup-storage` has been run |
| `cd /data/data/com.termux/files/home/storage/external-1` | The SD card — Termux's writable app folder on it (Android 11+ blocks the rest of the card) |
| `ls /storage` | List mounted volumes; an SD card shows up as `XXXX-XXXX` — its root is `/storage/XXXX-XXXX` |
| `exit` | Back out to Termux |

### Deploying from the phone — in Ubuntu

| Command | What it does |
|---|---|
| `git config --global user.name "<name>"` | Set the name on your commits, once per install |
| `git config --global user.email "<email>"` | Same for email |
| `git clone https://github.com/<user>/<repo>.git` | Pull a repo down onto the phone |
| `git add -A` | Stage everything you and Claude Code changed |
| `git commit -m "<message>"` | Commit the staged changes |
| `git push` | Push to GitHub — use a **personal access token** as the password, not your account password |

### Inside a Claude Code session

| | |
|---|---|
| `/help` | List every available command — start here |
| `/clear` | Wipe the conversation and start fresh |
| `/compact` | Summarise a long conversation to free up context |
| `/model` | Switch which model tier gets used |
| `/status` | Show the current config, including which base URL it's talking to |
| `Esc` | Interrupt Claude mid-response |
| `/exit` | Quit back to the shell |

### nano, for anyone who hasn't used it

| | |
|---|---|
| `Ctrl+O` then `Enter` | Save |
| `Ctrl+X` | Exit |
| `Ctrl+K` | Cut the current line — useful for clearing a bad config |

> [!TIP]
> Swipe from the **left edge** of Termux for the session drawer, then **New session**. That's how you run OmniRoute and Claude Code at the same time.

### Starting over

> [!WARNING]
> `proot-distro remove ubuntu` **deletes the container and everything inside it** — Claude Code, your `settings.json`, and any project files you created in there. Only use it on an install that never worked.

```bash
proot-distro remove ubuntu     # destroys the container
proot-distro install ubuntu    # fresh one, then re-run Chapter 3
```

---

## Why proot-Ubuntu, and not the native install

There are two ways to get Claude Code onto Android. **The simpler-looking one is the one that breaks.**

| | Native Termux (Path A) | proot-Ubuntu (Path B) — this repo |
|---|---|---|
| How it works | Patches Anthropic's `linux-arm64` binary to run against Termux's `glibc-runner` | Real Ubuntu userland inside Termux, running Anthropic's own installer |
| Disk | ~230MB | ~2GB |
| Setup time | 5–10 min | 10–15 min |
| When it goes wrong | Sandbox errors, `EACCES` on file writes, hangs | Behaves like ordinary Linux |
| Pick it when | You're tight on storage | Default |

Anthropic ships Claude Code as a glibc-linked binary with no Android build, and Termux runs on Android's Bionic libc. Path A is a shim over that gap, so the filesystem and `process.platform` don't match real Linux, and certain dependencies fail silently.

The maintainer of the Path A installer recommends the same:

> "Native Termux (Path A) works and is great for those who need it, especially with hardware or storage limitations. I highly recommend running it in proot-Ubuntu (Path B) though: it is the most stable version and works perfectly."
>
> — [ferrumclaudepilgrim/claude-code-android](https://github.com/ferrumclaudepilgrim/claude-code-android)

Choose Path A only if you're tight on storage, or on Android 8/10 where the native binary trips Android's seccomp filter anyway.

---

## Honest limits

- Ubuntu costs ~2GB of storage. That's the price of the version that actually works.
- proot adds syscall-translation overhead. Noticeable on older devices, not prohibitive.
- Free provider tiers have rate limits. OmniRoute's fallback softens this, it doesn't remove it.
- Long agentic tasks drain battery fast. Stay plugged in for heavy work.
- Big repos are slow on phone hardware. This shines for small-to-medium projects.
- **Anthropic's official mobile path** (Claude Code Remote Control) needs a PC running *and* a Pro/Max plan. This setup needs neither — that's the whole point.

---

## What's in this repo

| File | |
|---|---|
| [`setup.sh`](setup.sh) | Automates Chapters 1–3. Idempotent, no OmniRoute. |
| [`free-api-options.md`](free-api-options.md) | Providers, combo ordering, and why two combos beat one |
| [`troubleshooting.md`](troubleshooting.md) | Failure modes, each tagged with the shell it happens in |

## Credits

Path comparison and the native-install alternative: [`ferrumclaudepilgrim/claude-code-android`](https://github.com/ferrumclaudepilgrim/claude-code-android) · Container: [proot-distro](https://github.com/termux-pacman/proot-distro) · AI Gateway: [OmniRoute](https://github.com/diegosouzapw/OmniRoute)

Hit an error that isn't documented? Open an issue — [`troubleshooting.md`](troubleshooting.md) is meant to grow.

Licensed [MIT](LICENSE).
