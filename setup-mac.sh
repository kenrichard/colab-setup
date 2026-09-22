#!/usr/bin/env bash
#
# Sets up a Mac so Claude Code can work on the coLAB repositories.
#
# Written for Kate and Crystal, who are not developers. Every message it prints
# is meant to be read by them, so it says what is happening in plain words and,
# when something fails, what to send Ken.
#
# Run it with (the $(...) form keeps the keyboard connected, which the password
# prompt and the GitHub sign-in need; `curl ... | bash` would not):
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/kenrichard/colab-setup/main/setup-mac.sh)"
#
#   --check   report what is installed and change nothing
#
# Safe to run again. Each step checks first and skips anything already done,
# so the answer to most problems is "run it again".
#
# What it installs, in order:
#   1. Apple's Command Line Tools — this is what provides git
#   2. Homebrew — installs everything else
#   3. GitHub CLI (gh) and Node
#   4. Your name and email for git
#   5. GitHub sign-in
set -euo pipefail

CHECK_ONLY=false
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=true

bold=$'\033[1m'; green=$'\033[32m'; yellow=$'\033[33m'; red=$'\033[31m'; reset=$'\033[0m'
step() { printf '\n%s==> %s%s\n' "$bold" "$1" "$reset"; }
ok()   { printf '    %s✓%s %s\n' "$green" "$reset" "$1"; }
todo() { printf '    %s•%s %s\n' "$yellow" "$reset" "$1"; }
say()  { printf '    %s\n' "$1"; }
fail() {
  printf '\n%s✗ %s%s\n' "$red" "$1" "$reset" >&2
  printf '\nTake a screenshot of this window and send it to Ken.\n' >&2
  exit 1
}

# Prompts read from the terminal directly, so they work however the script
# was started.
ask() { local answer; read -r -p "    $1 " answer </dev/tty; printf '%s' "$answer"; }

[[ "$(uname -s)" == "Darwin" ]] || fail "This script is for a Mac."
[[ "$EUID" -ne 0 ]] || fail "Run this without 'sudo' in front of it."

have_clt() {
  local dir
  dir="$(xcode-select -p 2>/dev/null)" || return 1
  [[ -x "$dir/usr/bin/git" ]]
}

find_brew() {
  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x "$candidate" ]] && { printf '%s' "$candidate"; return 0; }
  done
  return 1
}

# --check: report and stop.
if [[ "$CHECK_ONLY" == true ]]; then
  step "Checking this Mac (nothing will be changed)"
  have_clt && ok "Command Line Tools / git: $(git --version)" || todo "Command Line Tools / git: not installed"
  brew="$(find_brew)" && ok "Homebrew: $("$brew" --version | head -1)" || todo "Homebrew: not installed"
  command -v gh   >/dev/null && ok "GitHub CLI: $(gh --version | head -1)" || todo "GitHub CLI: not installed"
  command -v node >/dev/null && ok "Node: $(node --version)"               || todo "Node: not installed"
  name="$(git config --global user.name 2>/dev/null || true)"
  [[ -n "$name" ]] && ok "git name: $name" || todo "git name: not set"
  if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
    ok "GitHub: signed in as $(gh api user --jq .login 2>/dev/null)"
  else
    todo "GitHub: not signed in"
  fi
  exit 0
fi

cat <<EOF

${bold}coLAB Mac setup${reset}

This installs the tools Claude Code needs to work on the coLAB project.
It takes 15–45 minutes, mostly waiting for downloads. Keep the laptop
plugged in and the lid open.

It will ask for your Mac password once. That's the password you use to
log in to this Mac. ${bold}Nothing appears on screen while you type it${reset}
— that's normal. Type it and press Return.

EOF

groups | grep -qw admin || fail "Your Mac account isn't an administrator, so it can't install software. Ask whoever manages this Mac to make you an admin, then run this again."

sudo -v </dev/tty || fail "The password wasn't accepted."
# Keep the password good until the script ends, so a long download doesn't
# lead to a second prompt nobody is watching for.
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &

# 1. Command Line Tools. This is the same method Homebrew's own installer uses:
# the marker file makes `softwareupdate` list the tools, so they install from
# here with no dialog.
step "1 of 5: Apple Command Line Tools (this provides git)"
if have_clt; then
  ok "Already installed"
else
  say "Downloading from Apple. This is the slow one — often 10–30 minutes,"
  say "and there's no progress bar for part of it. Leave it running."
  marker=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  touch "$marker"
  label="$(softwareupdate -l 2>/dev/null |
    grep -B 1 -E 'Command Line Tools' |
    awk -F'*' '/^ *\*/ {print $2}' |
    sed -e 's/^ *Label: //' -e 's/^ *//' |
    sort -V | tail -n1)"
  if [[ -n "$label" ]]; then
    say "Installing: $label"
    sudo softwareupdate -i "$label" --verbose || true
  fi
  rm -f "$marker"

  if ! have_clt; then
    # Fall back to Apple's dialog.
    say ""
    say "Apple's installer window is opening. Click ${bold}Install${reset}, then ${bold}Agree${reset}."
    xcode-select --install 2>/dev/null || true
    say "When that window says the software was installed, come back here."
    ask "Press Return once it's finished..." >/dev/null
    have_clt || fail "The Command Line Tools still aren't installed."
  fi
  sudo xcode-select --switch /Library/Developer/CommandLineTools 2>/dev/null || true
  ok "Installed"
fi
ok "$(git --version)"

# 2. Homebrew.
step "2 of 5: Homebrew (installs the other tools)"
if brew="$(find_brew)"; then
  ok "Already installed"
else
  say "Installing. A few minutes."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    || fail "Homebrew didn't install."
  brew="$(find_brew)" || fail "Homebrew installed but can't be found."
  ok "Installed"
fi
eval "$("$brew" shellenv)"
# On Apple Silicon Homebrew lives in /opt/homebrew, which new Terminal windows
# don't search until this line is added. On Intel it is in /usr/local, which
# they already do.
if [[ "$brew" == /opt/homebrew/* ]] && ! grep -qs 'brew shellenv' "$HOME/.zprofile"; then
  printf '\neval "$(%s shellenv)"\n' "$brew" >> "$HOME/.zprofile"
fi

# 3. GitHub CLI and Node.
step "3 of 5: GitHub CLI and Node"
# Checked by command rather than by `brew list`, so a copy installed some other
# way (nvm, a .pkg installer) counts and doesn't get a second one beside it.
for formula in gh node; do
  if command -v "$formula" >/dev/null 2>&1; then
    ok "$formula already installed"
  else
    say "Installing $formula..."
    brew install --quiet "$formula" || fail "$formula didn't install."
    ok "$formula installed"
  fi
done

# 4. git identity. Every saved change is labelled with a name and email.
step "4 of 5: Your name for git"
name="$(git config --global user.name 2>/dev/null || true)"
email="$(git config --global user.email 2>/dev/null || true)"
if [[ -n "$name" && -n "$email" ]]; then
  ok "Already set: $name <$email>"
else
  say "Every change you save is labelled with your name and email."
  [[ -n "$name" ]]  || { name="$(ask "Your full name:")";  git config --global user.name "$name"; }
  [[ -n "$email" ]] || { email="$(ask "Your email:")";     git config --global user.email "$email"; }
  ok "Set: $name <$email>"
fi

# 5. GitHub sign-in. `--web` skips gh's questions; `setup-git` lets git use
# the same sign-in, which is what cloning the private repositories needs.
step "5 of 5: Sign in to GitHub"
if gh auth status >/dev/null 2>&1; then
  ok "Already signed in"
else
  say "You need a GitHub account. If you don't have one, make one at"
  say "github.com first, then come back here."
  say ""
  say "Next you'll see a code like ${bold}ABCD-1234${reset}. Press Return and a browser"
  say "opens. Sign in, paste the code, and click ${bold}Authorize${reset}."
  say ""
  gh auth login --hostname github.com --git-protocol https --web </dev/tty \
    || fail "GitHub sign-in didn't finish."
fi
gh auth setup-git
login="$(gh api user --jq .login)"
ok "Signed in as $login"

cat <<EOF

${green}${bold}All done.${reset}

    git          $(git --version | sed 's/git version //')
    GitHub CLI   $(gh --version | head -1 | awk '{print $3}')
    Node         $(node --version)
    GitHub       ${bold}$login${reset}

${bold}Take a screenshot of this window and send it to Ken.${reset}
He needs your GitHub username ($login) to give you access to the project.

Then quit the Claude app (⌘Q) and open it again so it picks up the new tools.

EOF
