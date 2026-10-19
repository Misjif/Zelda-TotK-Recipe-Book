# Tears of the Kingdom Recipe Book

Cooking, fusing, building and a painted map of Hyrule, worked out from your own bag. Put this folder on GitHub once, and GitHub turns it into a real Android app (no browser needed) that you install from the repository's Releases page. It opens full screen from your app drawer and works offline.

## 1. Put it on GitHub (once)

1. Unzip the download first. On a Pixel, open **Files**, tap the zip, then **Extract**.
2. Sign in at **github.com** (a free account is fine).
3. Tap **+** (top right), then **New repository**. Give it a name, for example `recipe-book`, leave it **Public**, and tap **Create repository**.
4. On the new repository's page, tap **uploading an existing file** (or **Add file**, then **Upload files**).
5. Tap **choose your files** and select **all** the files from the unzipped folder at once. They all go at the top level, no folders. Then tap **Commit changes**.
   If you don't see the upload option on your phone, open Chrome's **⋮** menu and tick **Desktop site**.

## 2. Turn on the app build (once)

1. **Add your signing key.** In the repository, open **Settings**, then **Secrets and variables**, then **Actions**, and tap **New repository secret**. Name: `APP_SIGNING_KEY`. Secret: the whole text of `recipe-book-signing-key.txt` (sent to you separately; it is not in this folder). Tap **Add secret**.
   Keep that key file somewhere safe, such as your Google Drive. Every update of the app has to be signed with the same key; without it, the phone can only take a new version after uninstalling the old one.
2. **Switch the build on.** Open `build-app.yml` in the repository, tap the pencil (**Edit**), and change its name to `.github/workflows/build-app.yml` (typing each **/** makes a folder). Tap **Commit changes**.
3. Tap **Actions**. **Build the Android app** is running; it takes about 5 minutes. A green tick means the app is ready.
   A red cross: tap it to see why. If it says the key is missing, add it (step 1), then tap **Re-run all jobs**.

## 3. Install the app on the phone

1. In Chrome on the phone, open `https://github.com/YOUR-NAME/recipe-book/releases/latest/download/recipe-book.apk` (your user name and repository name), or on the repository's page tap **Releases**, then **recipe-book.apk**.
2. Open the downloaded file. The first time, Android asks to allow installs from Chrome: tap **Settings**, turn on **Allow from this source**, go back, and tap **Install**.
3. If Play Protect says it doesn't recognise the app, tap **More details**, then **Install anyway**. It's your own app, so Google hasn't seen it before.
4. **Recipe Book** now sits in your app drawer.

## 4. Bring your bag over

Each copy of the app keeps its own bag. In the copy that has your bag (for example the page in Claude): **Shop**, then the **Bag** tab, **Move or back up your bag**, **Copy bag code**. In the new app: **Shop**, then the **Bag** tab, **Move or back up your bag**, paste the code, then tap **Load this bag** twice. A copied code also works as a backup.

## Updating later

Upload the new files over the old ones (same names) and commit. GitHub builds the new app by itself; about 5 minutes later, open the same download link and install it over the old app. Your bag stays.

## Good to know

- The same files also run as a web page on GitHub Pages, if you ever want that: **Settings**, then **Pages**, **Deploy from a branch**, branch **main**, folder **/ (root)**. That version runs inside Chrome.
- In a public repository anyone who finds it can see these files. Your bag isn't in them (it stays on your phone), and neither is your signing key: it lives only in the secret. Never upload the key file. If you don't use the web version, you can make the repository private (**Settings**, **General**, **Change visibility**); the app build and the download link keep working while you're signed in to GitHub.
- Android is starting to require apps to come from developers registered with Google: in a few countries since September 2026, and everywhere in 2027 by Google's plan. For your own app there are two ways to keep installing it: a free limited-distribution account (no ID needed, up to 20 phones), or Android's one-time "advanced" setting for apps from unregistered developers (it includes a 24-hour wait).
- The app reads **Switch screenshots** right on the phone, no AI.
- Links to guides and sources open in your browser.
- The phone's Back gesture steps back inside an open popup, then closes it; with no popup open it leaves the app as usual.
- The fonts (Cinzel, Nunito and Marcellus) are under the SIL Open Font License; see `OFL.txt`. All drawings and the painted map are the app's own.
- Fan-made reference, not affiliated with Nintendo.
