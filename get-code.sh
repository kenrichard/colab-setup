#!/usr/bin/env bash
#
# Downloads the two coLAB repositories into ~/colab-v2.
#
# Written for Kate and Crystal, who are not developers. Every message it prints
# is meant to be read by them. Part 1 (setup-mac.sh) must have run first: this
# needs git and a GitHub sign-in.
#
# Run it with:
#
#   curl -fsSL https://raw.githubusercontent.com/kenrichard/colab-setup/main/get-code.sh | bash
#
# The line has no quotes on purpose. It gets pasted into documents, and word
# processors turn straight quotes into curly ones, which the shell rejects.
#
# Safe to run again. A repository that is already there gets the latest changes
# instead of a second copy.
set -euo pipefail

bold=$'\033[1m'; green=$'\033[32m'; red=$'\033[31m'; reset=$'\033[0m'
step() { printf '\n%s==> %s%s\n' "$bold" "$1" "$reset"; }
ok()   { printf '    %s✓%s %s\n' "$green" "$reset" "$1"; }
say()  { printf '    %s\n' "$1"; }
fail() {
  printf '\n%s✗ %s%s\n' "$red" "$1" "$reset" >&2
  printf '\nTake a screenshot of this window and send it to Ken.\n' >&2
  exit 1
}

# The two repositories, side by side. The API's scripts expect the front end
# next to it, so the folder layout matters.
ORG=colab-verve
REPOS=(verve-v2-api verve-v2-colab)
DEST="$HOME/colab-v2"

main() {
# `curl | bash` starts a shell that has not read ~/.zprofile, so Homebrew's
# tools may not be on the PATH yet.
for brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [[ -x "$brew" ]] && { eval "$("$brew" shellenv)"; break; }
done

cat <<EOF

${bold}Get the coLAB code${reset}

This downloads the coLAB project into a folder called ${bold}colab-v2${reset}
in your home folder. It takes a minute or two.

EOF

step "1 of 3: Checking Part 1 is done"
command -v git >/dev/null || fail "git isn't installed. Do Part 1 first."
command -v gh  >/dev/null || fail "The GitHub tools aren't installed. Do Part 1 first."
gh auth status >/dev/null 2>&1 || fail "You aren't signed in to GitHub. Run Part 1 again; it skips what's already done."
login="$(gh api user --jq .login)"
ok "Signed in to GitHub as $login"

step "2 of 3: Checking you have access"
for repo in "${REPOS[@]}"; do
  gh repo view "$ORG/$repo" >/dev/null 2>&1 \
    || fail "Your GitHub account ($login) can't see $ORG/$repo yet. Ken needs to add you."
done
ok "You can see both repositories"

step "3 of 3: Downloading"
mkdir -p "$DEST"
for repo in "${REPOS[@]}"; do
  if [[ -d "$DEST/$repo/.git" ]]; then
    git -C "$DEST/$repo" pull --ff-only --quiet \
      || fail "$repo is already here but couldn't be updated."
    ok "$repo: already here, now up to date"
  else
    gh repo clone "$ORG/$repo" "$DEST/$repo" -- --quiet \
      || fail "Couldn't download $repo."
    ok "$repo: downloaded"
  fi
done

cat <<EOF

${green}${bold}All done.${reset}

    Folder       $DEST
    API          $(git -C "$DEST/verve-v2-api" log -1 --format='%h  %cs  %s' | cut -c1-60)
    Front end    $(git -C "$DEST/verve-v2-colab" log -1 --format='%h  %cs  %s' | cut -c1-60)

${bold}Take a screenshot of this window and send it to Ken.${reset}

EOF
}

# No keyboard (for example, run from another program): use whatever input there is.
if { exec 3</dev/tty; } 2>/dev/null; then
  main "$@" <&3
else
  main "$@"
fi
