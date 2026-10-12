# coLAB Mac setup

**Setup pages: https://kenrichard.github.io/colab-setup/** — an index of the steps. Each part is a folder with its own `index.html`; `style.css` and `copy.js` are shared.

| Part | Page | Script |
|---|---|---|
| 1. Install git and connect to GitHub | `1-git/` | `setup-mac.sh` |
| 2. Install Claude Code and get the code | `2-code/` | — (Claude clones the repositories) |
| 3. Sign in to VERVE | `3-sign-in/` | — |
| 4. Get a token | `4-token/` | — |
| 5. Run the screens locally against the Fly API | `5-run-ui/` | — (Claude writes `.env.local`) |
| 6. Connect Claude Code to VERVE | `6-mcp/` | — |

The rest of this file covers Part 1's script.

Installs the tools Claude Code needs to work on the coLAB project: git (from
Apple's Command Line Tools), Homebrew, the GitHub CLI and Node. It then signs
you in to GitHub.

## Run it

Open Terminal (press **⌘ + Space**, type **Terminal**, press **Return**). Paste
this line and press **Return**. It's one line even if it wraps on your screen:

```
curl -fsSL https://raw.githubusercontent.com/kenrichard/colab-setup/main/setup-mac.sh | bash
```

It takes 15–45 minutes, mostly downloads. Keep the laptop plugged in and the
lid open.

It asks for your Mac password once. Nothing appears on screen while you type
it. That's normal. Type it and press **Return**.

When it finishes, take a screenshot of the Terminal window and send it to Ken.

If something goes wrong, take a screenshot and send that instead. You can
run the script again at any time; it skips whatever is already done.

## Check without changing anything

```
curl -fsSL https://raw.githubusercontent.com/kenrichard/colab-setup/main/setup-mac.sh | bash -s -- --check
```
