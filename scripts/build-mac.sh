#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
swift build -c release
app=.build/AuraFreq.app
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp Resources/AppIcon.icns "$app/Contents/Resources/"
cp "$(swift build -c release --show-bin-path)/AuraFreq" "$app/Contents/MacOS/"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>AuraFreq</string>
<key>CFBundleIdentifier</key><string>com.huynhtancuong.aurafreq.native</string>
<key>CFBundleIconFile</key><string>AppIcon.icns</string>
<key>CFBundleName</key><string>AuraFreq</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>LSMinimumSystemVersion</key><string>15.0</string>
</dict></plist>
PLIST
codesign --force --sign - "$app"
