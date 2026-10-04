# QuickClaude

A tiny Claude chat window for macOS. Press a shortcut anywhere and a small popup appears with the input ready; ask, read the answer, click away and it's gone.

- Global shortcut (default **⌃Space**) shows and hides the popup
- Model and effort pickers, remembered between chats
- Full markdown rendering: headings, lists, tables, code blocks, math
- Web search built in
- "Open in Claude" hands the chat to the Claude desktop app
- Menu bar icon (✦) to change the shortcut, check for updates, or quit
- Starts automatically at login

QuickClaude runs [Claude Code](https://docs.claude.com/en/docs/claude-code/overview) in the background, so it uses your Claude subscription.

## Requirements

- macOS 14 (Sonoma) or later
- A Claude account (Pro, Max, Team or Enterprise)
- Claude Code installed and signed in
- Apple's command line developer tools, to build the app

## Install

Open **Terminal** and run each step.

**1. Install the developer tools** (skip if already installed; a dialog appears, click Install and wait for it to finish):

```sh
xcode-select --install
```

**2. Install Claude Code and sign in:**

```sh
curl -fsSL https://claude.ai/install.sh | bash
claude
```

Finish signing in in the browser, then type `/exit`.

**3. Download and build QuickClaude:**

```sh
git clone https://github.com/Tost-1/QuickClaude.git ~/QuickClaude
cd ~/QuickClaude && ./build.sh
```

The first build takes about a minute. QuickClaude is installed to `~/Applications`, starts right away, and macOS shows a "Login Item Added" notice. Press **⌃Space** to try it.

Keep the `~/QuickClaude` folder: updates are pulled and built from it.

### Or let Claude Code do it

After step 2, start `claude` and paste:

> Install QuickClaude by following the README at https://github.com/Tost-1/QuickClaude: install the Xcode command line tools if missing, clone the repo to ~/QuickClaude, and run ./build.sh.

## Using it

| Action | How |
| --- | --- |
| Show / hide | ⌃Space (or click ✦ → Open QuickClaude) |
| Send | Enter (Shift+Enter for a new line) |
| Hide | Esc, click outside, or the shortcut again |
| New chat | ⌘N or the pencil button |
| Continue in the Claude app | The ↗ button (opens in the desktop app's Code view) |
| Change shortcut | ✦ → Change Shortcut… |
| Quit | ✦ → Quit QuickClaude |

The window can be resized and remembers its size. Hiding keeps the current chat; start a new one with ⌘N.

## Updating

Click ✦ → **Check for Updates…**. If there are new changes it lists them; **Install and Restart** pulls, rebuilds and relaunches the app.

To update by hand:

```sh
cd ~/QuickClaude && git pull && ./build.sh
```

## Troubleshooting

- **The shortcut does nothing.** macOS may be using ⌃Space to switch input languages. Turn that off in System Settings → Keyboard → Keyboard Shortcuts → Input Sources, or pick another shortcut from ✦ → Change Shortcut….
- **No ✦ icon in the menu bar.** A menu bar manager (Hidden Bar, Bartender, Ice) or the notch may be hiding it. Reveal it and ⌘-drag it into the visible area.
- **"Couldn't find the claude CLI".** Finish step 2 and make sure `claude` works in Terminal.
- **Replies fail with a login error.** Run `claude` in Terminal and sign in again.

## Uninstall

```sh
pkill -x QuickClaude
rm -rf ~/Applications/QuickClaude.app ~/QuickClaude ~/.quickclaude
defaults delete com.claytonroques.QuickClaude
```

Then remove QuickClaude from System Settings → General → Login Items if it's still listed.
