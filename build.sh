#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
app=build/QuickClaude.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp .build/release/QuickClaude "$app/Contents/MacOS/"
cp Resources/Info.plist "$app/Contents/"
/usr/libexec/PlistBuddy -c "Add :QuickClaudeRepo string $PWD" "$app/Contents/Info.plist"
codesign --force --sign - "$app"
cp -R .build/release/SwiftMath_SwiftMath.bundle "$app/"

mkdir -p ~/Applications
pkill -x QuickClaude || true
rm -rf ~/Applications/QuickClaude.app
cp -R "$app" ~/Applications/
open ~/Applications/QuickClaude.app
