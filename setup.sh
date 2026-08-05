#!/data/data/com.termux/files/usr/bin/bash
#
# Claude Code on Android — automated installer (proot-Ubuntu / Path B)
# Companion to the DevZoneX video. Run inside Termux on an unrooted Android phone.
#
# WHAT THIS DOES (README Chapters 1-3):
#   1. Termux packages: proot-distro, nodejs
#   2. Ubuntu container via proot-distro
#   3. Claude Code inside Ubuntu, via Anthropic's official installer
#
# WHAT THIS DOES NOT DO:
#   OmniRoute setup, provider API keys, combos, and ~/.claude/settings.json.
#   Those need your own keys and a browser, so they stay manual.
#   The script prints the next steps when it finishes.
#
# Safe to re-run. Already-completed steps are detected and skipped.
#
# Version: 2.0 (2026-08-05)
# Tested: 2026-08-05, clean run on a freshly wiped Termux (aarch64, unrooted)
# 2.0: replaced 9Router with OmniRoute (290+ providers, zero-config, auto-fallback)
# 1.2: retry pkg, curl, and the Ubuntu download; pre-flight connectivity check;
#      fully non-interactive pkg/apt so nothing can hang on a prompt
# 1.1: auto-retry apt once after clearing the index (fixes 'Hash Sum mismatch')
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Tophunt-max/claude-code-android/main/setup.sh -o setup.sh
#   cat setup.sh          # read it first
#   bash setup.sh

set -uo pipefail   # deliberately NOT -e: pkg upgrade can exit non-zero on
                   # harmless prompts. Every step below is checked explicitly.

VERSION="2.0"
MIN_FREE_MB=5000
export MAX_TRIES=3    # how many times to attempt a network operation before giving up
                     # exported so the apt_retry helper inside Ubuntu can see it

say()  { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }
ok()   { printf '\033[1;32m  ✓ %s\033[0m\n' "$1"; }
warn() { printf '\n\033[1;33m!! %s\033[0m\n' "$1"; }
die()  { printf '\n\033[1;31mXX %s\033[0m\n\n' "$1" >&2; exit 1; }

# Retry a command up to MAX_TRIES times, with a short pause between attempts.
# Used for every network operation so a single dropped packet can't fail the
# whole install. "$@" is the command; the label is printed on each retry.
retry() {
  local label="$1"; shift
  local n=1
  while ! "$@"; do
    n=$((n + 1))
    if [ "$n" -gt "$MAX_TRIES" ]; then
      echo "  !! $label failed after $MAX_TRIES attempts"
      return 1
    fi
    echo "  -- $label failed, retrying (attempt $n/$MAX_TRIES)..."
    sleep 3
  done
}

# --- what runs INSIDE ubuntu ---------------------------------------------------
# Quoted heredoc: nothing expands here in Termux. $HOME resolves inside Ubuntu.
read -r -d '' UBUNTU_SETUP <<'EOS' || true
set -e
export DEBIAN_FRONTEND=noninteractive

# --force-confold keeps existing config files instead of stopping to ask.
# Without it an unattended apt upgrade can hang forever on a dpkg prompt.
APT_OPTS='-y -qq -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef'

# Run an apt command; on failure, assume a stale index or a caching proxy
# served a mismatched file ("Hash Sum mismatch"), wipe the lists, re-update
# with caching disabled, and retry up to MAX_TRIES times. This is the single
# most common transient failure on mobile connections.
apt_retry() {
  local label="$1"; shift
  local max="${MAX_TRIES:-3}"
  local n=1
  # shellcheck disable=SC2086
  while ! apt-get $APT_OPTS "$@"; do
    n=$((n + 1))
    if [ "$n" -gt "$max" ]; then
      echo "  !! $label failed after $max attempts"
      return 1
    fi
    echo "--- $label failed; clearing the package index and retrying (attempt $n/$max)"
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    apt-get update -qq -o Acquire::http::No-Cache=true
    # shellcheck disable=SC2086
    apt-get $APT_OPTS -o Acquire::http::No-Cache=true "$@"
  done
}

echo "--- apt update / upgrade"
apt-get update -qq || apt-get update -qq -o Acquire::http::No-Cache=true
apt_retry "apt upgrade" upgrade

echo "--- installing curl git wget build-essential"
apt_retry "apt install" install curl git wget build-essential

if [ -x "$HOME/.local/bin/claude" ]; then
  echo "--- claude already present, skipping installer"
else
  echo "--- running Anthropic's official installer"
  # Download to a file first rather than piping straight into bash: with a
  # bare pipe, a failed download feeds bash an empty script that exits 0,
  # so the failure is silent and only shows up later as "command not found".
  # --retry/--retry-all-errors re-fetches on any transient failure.
  curl -fsSL --retry 5 --retry-delay 3 --retry-all-errors \
       https://claude.ai/install.sh -o /tmp/claude-install.sh
  [ -s /tmp/claude-install.sh ] || { echo "!! installer download was empty"; exit 1; }
  bash /tmp/claude-install.sh
  rm -f /tmp/claude-install.sh
fi

# idempotent PATH line
if ! grep -q '.local/bin' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  echo "--- added ~/.local/bin to PATH in .bashrc"
fi

export PATH="$HOME/.local/bin:$PATH"

echo "--- verifying"
claude --version
EOS

# --- sanity checks -------------------------------------------------------------

printf '\n\033[1mClaude Code on Android — automated setup v%s\033[0m\n' "$VERSION"
printf 'Termux -> Ubuntu -> Claude Code. OmniRoute setup stays manual.\n'

[ -d /data/data/com.termux ] || die "This must run inside Termux.
Install Termux from F-Droid or GitHub Releases — NOT the Play Store."

arch=$(uname -m)
case "$arch" in
  aarch64|arm64) ok "architecture $arch" ;;
  *) die "Unsupported architecture: $arch
Claude Code needs aarch64. Some budget phones ship a 32-bit OS on 64-bit
hardware; there is no workaround for those." ;;
esac

avail_mb=$(df -m "$HOME" 2>/dev/null | awk 'NR==2 {print $4}')
if [ -n "${avail_mb:-}" ] && [ "$avail_mb" -lt "$MIN_FREE_MB" ]; then
  warn "Only ${avail_mb}MB free. Ubuntu is ~2GB and unpacks before cleanup;
${MIN_FREE_MB}MB recommended."
  printf '\nContinue anyway? [y/N] '
  read -r reply
  case "$reply" in [yY]*) ;; *) die "Stopped. Free up space and re-run." ;; esac
else
  ok "${avail_mb:-?}MB free"
fi

if command -v claude >/dev/null 2>&1; then
  warn "A 'claude' command already exists in TERMUX: $(command -v claude)
That is almost certainly a leftover native (Path A) install. It will not
interfere with the Ubuntu one, but having two different 'claude' commands
in two shells gets confusing. Consider removing it afterwards."
fi

# --- connectivity pre-flight --------------------------------------------------
# The single most confusing on-camera failure is downloading for minutes
# only to discover the network is down. Check first, and bail with a clear
# message if there's no connection. --max-time keeps it from hanging.
say "Checking network"
if curl -fsS --max-time 10 -o /dev/null https://claude.ai/install.sh 2>/dev/null \
  || curl -fsS --max-time 10 -o /dev/null https://github.com 2>/dev/null; then
  ok "internet reachable"
else
  die "No internet connection, or claude.ai is unreachable.
The install downloads packages and a ~2GB Ubuntu image, so it needs a
stable connection. Check Wi-Fi/mobile data and re-run. Completed steps
are skipped, so there's no cost to re-running."
fi

# --- step 1: termux packages ---------------------------------------------------

say "Step 1/3 — Termux packages"
printf 'If asked about package maintainer configs, press y.\n\n'

# -o Dpkg::Options::=--force-confold makes pkg fully non-interactive: it
# keeps existing config files instead of stopping on a conffile prompt that
# would hang an unattended run.
retry "pkg update"    pkg update -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef
retry "pkg upgrade"   pkg upgrade -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef
retry "pkg install"   pkg install proot-distro nodejs -y

command -v proot-distro >/dev/null || die "proot-distro did not install.
Try 'pkg install proot-distro -y' manually and read the output."
ok "proot-distro ready"

if command -v node >/dev/null 2>&1; then
  ok "node $(node -v) — needed for OmniRoute"
else
  warn "Node.js did not install. OmniRoute needs it.
Fix with 'pkg install nodejs -y' before the OmniRoute step."
fi

# --- step 2: ubuntu ------------------------------------------------------------

# Check the rootfs directory directly rather than parsing `proot-distro list`.
# The --installed flag is not available on every proot-distro version, and if
# the check silently fails we would try to reinstall over a working container.
# Verify /bin/bash exists INSIDE the rootfs, not just the directory: a dropped
# download can leave a half-written rootfs dir that's not a real install, and
# skipping that as "installed" would produce a broken container silently.
UBUNTU_ROOTFS="${PREFIX:-/data/data/com.termux/files/usr}/var/lib/proot-distro/installed-rootfs/ubuntu"
ubuntu_installed() { [ -x "$UBUNTU_ROOTFS/bin/bash" ]; }

if ubuntu_installed; then
  say "Step 2/3 — Ubuntu already installed, skipping"
else
  # If a partial rootfs dir exists from a dropped previous run, remove it so
  # the fresh install doesn't collide with stale, half-extracted files.
  if [ -d "$UBUNTU_ROOTFS" ] && ! ubuntu_installed; then
    warn "Found a partial Ubuntu install (no /bin/bash inside). Removing it and starting fresh."
    proot-distro remove ubuntu >/dev/null 2>&1 || rm -rf "$UBUNTU_ROOTFS"
  fi
  say "Step 2/3 — installing Ubuntu (~2GB, usually 2-5 minutes)"
  # Retry the download: it's a large pull and mobile connections drop mid-way.
  if ! retry "proot-distro install" proot-distro install ubuntu; then
    if ubuntu_installed; then
      warn "Install reported an error but the container is complete. Continuing."
    else
      die "Ubuntu install failed after $MAX_TRIES attempts and no container was created.
Usually a dropped connection mid-download. Re-run this script — the
partial download is discarded and it starts fresh.

Only if a later run keeps failing on a half-written container should you
reset it — and be aware this DELETES everything inside Ubuntu:
  proot-distro remove ubuntu && proot-distro install ubuntu"
    fi
  fi
fi
ok "Ubuntu container ready"

# --- step 3: claude code inside ubuntu -----------------------------------------

say "Step 3/3 — installing Claude Code inside Ubuntu"
printf 'This runs apt and then Anthropic'\''s official installer. Output follows.\n'

if proot-distro login ubuntu -- bash -c "$UBUNTU_SETUP"; then
  ok "Claude Code installed and responding inside Ubuntu"
else
  die "The Ubuntu step failed. The script already retried once after clearing
the package index, so this is probably not a stale mirror.

  If the error was 'Hash Sum mismatch', it is a transient mirror/proxy issue,
  not your setup. Switch network (Wi-Fi <-> mobile data) and re-run this
  script — completed steps are skipped.

  Or finish it by hand inside Ubuntu:

  proot-distro login ubuntu
  apt clean && rm -rf /var/lib/apt/lists/*
  apt-get update -o Acquire::http::No-Cache=true
  apt install -y curl git wget build-essential
  curl -fsSL https://claude.ai/install.sh | bash
  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc
  claude --version

See troubleshooting.md"
fi

# --- next steps ----------------------------------------------------------------

cat <<'EOF'

======================================================================
 Claude Code is installed. Two manual steps left — both need your own
 accounts, so they are not automated.

 Same list, with checks and explanations:
   README.md -> "After setup.sh finishes"
======================================================================

 FIRST, know which shell you are in. This trips up most people:

   Termux prompt:  ~ $              -> OmniRoute lives HERE
   Ubuntu prompt:  root@...:~#      -> Claude Code lives HERE

 ----------------------------------------------------------------------
 1. OMNIROUTE  (in Termux, this session)

      npm install -g omniroute
      omniroute

    Leave it running. Open http://localhost:20128 in your phone browser.
    Default dashboard password: 123456
    >> CHANGE IT. It is a published default. Do this before you use this
       phone on any shared or public network.

    >> ZERO-CONFIG: OmniRoute works immediately with 40+ free providers.
       No keys needed to start. Just open the dashboard and connect free
       providers (OpenCode, Kilo, etc.) via the "Providers" tab.

    >> COMBOS: Optional. Create a "claude-opus-free" combo in the dashboard
       for auto-fallback across providers. See free-api-options.md.

 ----------------------------------------------------------------------
 2. SETTINGS.JSON  (inside Ubuntu, in a NEW Termux session)

    Swipe from the left edge -> New session, then:

      proot-distro login ubuntu
      mkdir -p ~/.claude
      nano ~/.claude/settings.json

    This must be UBUNTU's home directory. A settings.json in Termux's
    home is silently ignored — no error, nothing works. Claude Code runs
    inside Ubuntu and only reads Ubuntu's home.

    Config to paste: README.md, Chapter 6.

 ----------------------------------------------------------------------
 THEN, daily use — two Termux sessions:

      session 1:  omniroute
      session 2:  proot-distro login ubuntu  ->  claude

 Stuck? -> troubleshooting.md
======================================================================

EOF
