#!/usr/bin/env bash
# Builds the Recipe Book Android app (recipe-book.apk) from the files next to this script.
#
# GitHub runs this for you after every upload (the "Build the Android app" workflow in .github/workflows) and posts
# the finished app on the repository's Releases page. What it does:
#   1. reads your signing key from the APP_SIGNING_KEY secret (the same key every time, so the phone accepts each
#      new version as an update of the app it already has)
#   2. takes the app's own files (index.html, the fonts, the icons, the map pictures) and nothing else
#   3. puts them in Capacitor's Android shell: a small app that shows them full screen, with no browser
#   4. adds the icons and the start-up screen from android-kit.zip
#   5. builds and signs the app with Gradle, and posts it under Releases (keeping the 3 newest builds)
# It needs Node 22+, Java 21 and the Android SDK, which GitHub's ubuntu-24.04 machines have.
# ANDROID_DRY_RUN=1 stops before the Gradle build (to check the steps before it on a machine without the SDK).
set -euo pipefail

APP_ID="app.totk.recipebook"   # never change this: Android only updates an app with the same id and the same key
APP_NAME="Recipe Book"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
work="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/recipe-book-android"
out="${APK_OUT:-$here/recipe-book.apk}"

say() { echo "== $*"; }
fail() { echo "::error::$*"; exit 1; }

# 1. the signing key: the secret holds "password:keystore", the keystore written out in base64
key="${APP_SIGNING_KEY:-}"
[ -n "$key" ] || fail "The APP_SIGNING_KEY secret is missing. Add it under Settings > Secrets and variables > Actions (see the README), then run the build again."
key="$(printf '%s' "$key" | tr -d ' \r\n\t')"
case "$key" in
  ?*:?*) ;;
  *) fail "The APP_SIGNING_KEY secret doesn't look right: it should be one long line with a colon near the start. Paste the whole key file into it again." ;;
esac
export APP_KEY_PASSWORD="${key%%:*}"
echo "::add-mask::$APP_KEY_PASSWORD"
rm -rf "$work"
mkdir -p "$work/www"
printf '%s' "${key#*:}" | base64 -d > "$work/key.p12" 2>/dev/null || fail "The APP_SIGNING_KEY secret couldn't be read. Paste the whole key file into it again."
keytool -list -keystore "$work/key.p12" -storetype pkcs12 -storepass "$APP_KEY_PASSWORD" -alias recipe-book > /dev/null 2>&1 \
  || fail "The APP_SIGNING_KEY secret couldn't be opened. Paste the whole key file into it again."
export APP_KEYSTORE="$work/key.p12"
say "signing key ok"

# 2. the app's own files; nothing else in the repository goes into the app
[ -s "$here/index.html" ] || fail "index.html is missing: upload all the files from the app zip."
cp "$here/index.html" "$work/www/"
n=0
for f in "$here"/*.woff2 "$here"/map-*.webp "$here"/icon-*.png "$here"/manifest.webmanifest "$here"/OFL.txt; do
  [ -f "$f" ] || continue
  cp "$f" "$work/www/"
  n=$((n + 1))
done
ls "$work/www"/map-surface-*.webp > /dev/null 2>&1 || fail "The map pictures (map-surface-....webp) are missing: upload all the files from the app zip."
ls "$work/www"/*.woff2 > /dev/null 2>&1 || fail "The font files (.woff2) are missing: upload all the files from the app zip."
say "web files: index.html and $n more"

# 3. Capacitor's Android shell, at the exact versions this was made with (package-lock.json in the kit)
[ -s "$here/android-kit.zip" ] || fail "android-kit.zip is missing: upload all the files from the app zip."
mkdir -p "$work/kit"
unzip -q -o "$here/android-kit.zip" -d "$work/kit"
cp "$work/kit/package.json" "$work/kit/package-lock.json" "$work/"
cd "$work"
npm ci --no-audit --no-fund
cat > capacitor.config.json << EOF
{
  "appId": "$APP_ID",
  "appName": "$APP_NAME",
  "webDir": "www",
  "backgroundColor": "#07152a",
  "plugins": {
    "SystemBars": { "insetsHandling": "native", "style": "DARK" }
  }
}
EOF
npx cap add android

# 4. icons, start-up screen and colours; portrait only, like the app installed from Chrome
cp -R "$work/kit/res/." android/app/src/main/res/
node -e '
const fs = require("fs"), f = "android/app/src/main/AndroidManifest.xml";
let s = fs.readFileSync(f, "utf8");
const a = "android:name=\".MainActivity\"";
if (s.split(a).length !== 2) { console.error("MainActivity not found once in " + f); process.exit(1); }
s = s.replace(a, a + "\n            android:screenOrientation=\"portrait\"");
fs.writeFileSync(f, s);
'

# 5. a build number that only goes up (minutes since 2026), and signing with your key
code=$(( ( $(date -u +%s) - 1767225600 ) / 60 ))
name="$(date -u +%Y.%m.%d)-${GITHUB_RUN_NUMBER:-local}"
cat >> android/app/build.gradle << EOF

// ---- Recipe Book (added by android-build.sh): the build number, and signing with your key ----
android {
    defaultConfig {
        versionCode = $code
        versionName = "$name"
    }
    signingConfigs {
        recipeBook {
            storeFile = file(System.getenv("APP_KEYSTORE"))
            storeType = "pkcs12"
            storePassword = System.getenv("APP_KEY_PASSWORD")
            keyAlias = "recipe-book"
            keyPassword = System.getenv("APP_KEY_PASSWORD")
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.recipeBook
        }
    }
}
EOF
say "Android project ready: $APP_ID, version $name ($code)"
if [ -n "${ANDROID_DRY_RUN:-}" ]; then say "dry run: stopping before the Gradle build"; exit 0; fi

cd android
chmod +x gradlew
./gradlew --no-daemon --stacktrace assembleRelease
apk="app/build/outputs/apk/release/app-release.apk"
[ -s "$apk" ] || fail "The build finished without making the app file."
cp "$apk" "$out"
say "built $(du -h "$out" | cut -f1) app"
if [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME/build-tools" ]; then
  bt="$(find "$ANDROID_HOME/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -n 1)"
  "$bt/apksigner" verify --print-certs "$out" | grep -i "SHA-256" || true
fi

# 6. post it under Releases (only when GitHub runs this), and keep only the 3 newest builds there
if [ -n "${GITHUB_ACTIONS:-}" ]; then
  tag="app-build-${GITHUB_RUN_NUMBER}-${GITHUB_RUN_ATTEMPT:-1}"
  gh release create "$tag" "$out" --repo "$GITHUB_REPOSITORY" --target "$GITHUB_SHA" --latest \
    --title "Recipe Book app $name" \
    --notes "Open recipe-book.apk on your phone to install the app, or to update it. Built from commit ${GITHUB_SHA:0:7}."
  say "posted: https://github.com/$GITHUB_REPOSITORY/releases/latest/download/recipe-book.apk"
  gh release list --repo "$GITHUB_REPOSITORY" --limit 100 --json tagName,createdAt \
    --jq 'map(select(.tagName | startswith("app-build-"))) | sort_by(.createdAt) | reverse | .[3:] | .[].tagName' \
    | while read -r old; do gh release delete "$old" --repo "$GITHUB_REPOSITORY" --yes --cleanup-tag || true; done || true
fi
