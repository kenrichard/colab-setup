# coLAB Mac setup

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
