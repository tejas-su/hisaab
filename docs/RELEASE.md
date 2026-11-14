# Releasing hisaab• to Google Play

This guide takes hisaab• from this repo to a Play Store listing. Claude did the parts that hold no secrets. **You** do the parts marked 🔒, in your own terminal. Claude cannot read the signing files, and it should never see a password.

Package name: `com.widgetsandco.hisaab`. **It can never change once the app is on Play.**

---

## What is already done

| Item | Where |
|---|---|
| The release build signs with your upload key when `android/key.properties` exists, and falls back to debug keys when it doesn't (so `flutter run --release` still works) | [android/app/build.gradle.kts](../android/app/build.gradle.kts) |
| Without the key, every build still works, bundles included: they are debug-signed and Gradle prints a warning. **Contributors need none of this guide** (D160) | same file |
| A template for the secrets file | [android/key.properties.example](../android/key.properties.example) |
| Git ignores keys, keystores, `.env`, `.aab`/`.apk` | [.gitignore](../.gitignore), [android/.gitignore](../android/.gitignore) |
| Claude Code cannot read or edit `key.properties`, `*.jks`, `*.keystore`, `*.p12`, `*.pk8`, `*.pepk`, `.env` or anything in `~/.android-keys/`, and cannot run `keytool` | `permissions.deny` in [.claude/settings.json](../.claude/settings.json) |
| A hook blocks any shell command that names those files or passwords | [.claude/hooks/guard-secrets.sh](../.claude/hooks/guard-secrets.sh) |
| Privacy policy page (D152) | https://tejas-su.github.io/hisaab/privacy/ |
| Play feature graphic and social preview | commit `d9ab086` |
| SDK levels: min 24, target 36, compile 36 (Flutter defaults) | Flutter's Gradle plugin |
| The app has no network permission. Auto Backup and device transfer are off | [AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml) |

> **About "claudeignore":** Claude Code has no ignore file. The supported way to stop it reaching files is `permissions.deny` plus a `PreToolUse` hook, and that is what's set up here. Both are tested: reads of `android/key.properties` and `*.jks` (anywhere, `android/upload-keystore.jks` included) are denied, and shell commands that mention them are blocked. One gap remains: Gradle itself reads the key when Claude runs a build, but nothing prints the passwords. If you want zero exposure, run release builds only yourself.

---

## 🔒 Step 1: Create the upload keystore (you, once)

The keystore lives in `android/upload-keystore.jks`, beside `key.properties` (D161). Both are git-ignored, and Claude is blocked from reading them. Living in the repo folder, the key is easy to find, but it is lost if the folder is deleted or re-cloned, or if you run `git clean -x` (which deletes ignored files). **Step 3's backups are what keep it safe.**

In **your own** terminal, from the repo root, not through Claude (cmd or PowerShell, one line):

```bat
keytool -genkeypair -v -keystore android\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- `keytool` comes with the JDK. If it isn't on your PATH, use Android Studio's copy: `"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"`.
- Choose a long password and use the same one for the store and the key. Separate passwords cause trouble with JKS.
- For the name and organisation prompts, anything truthful works. Play never shows them.

## 🔒 Step 2: Create `android/key.properties` (you)

```properties
storePassword=<your password>
keyPassword=<your password>
keyAlias=upload
storeFile=upload-keystore.jks
```

`storeFile` is resolved from `android/`. An absolute path with forward slashes also works. Then confirm git ignores both files. This should print two rules, not nothing:

```powershell
git check-ignore -v android/key.properties android/upload-keystore.jks
```

## 🔒 Step 3: Back up the key (you, today)

If you lose the upload key and its password, you can't ship updates until Google resets it, which takes days. Make two backups:

- [ ] Save the `.jks` file and the password in your password manager (Bitwarden, 1Password and similar accept file attachments).
- [ ] Put a second copy on offline storage (a USB stick or an encrypted zip somewhere other than this PC).
- [ ] **Never** commit it, email it, paste it into a chat (Claude included) or upload it to cloud storage unencrypted.

## Step 4: Build the bundle

In your own terminal, from the repo root. Run `flutter analyze` and `flutter test` first.

```bat
flutter build appbundle --release
```

The bundle is `build\app\outputs\bundle\release\app-release.aab`, which is what Play takes. For a phone, `flutter build apk --release` gives `build\app\outputs\flutter-apk\app-release.apk`. (There is no `flutter build aab`; the bundle command is `appbundle`.)

If Gradle prints *"no android/key.properties, so this release build is signed with the debug key"*, step 2 isn't done, and Play will reject that bundle.

To confirm the bundle is signed with your key, not the debug key, run this yourself. It should show your name, not "Android Debug":

```powershell
keytool -printcert -jarfile build\app\outputs\bundle\release\app-release.aab
```

## Step 5: Play Console (you)

1. **Developer account:** https://play.google.com/console (one-time US$25). Choose **Personal**. Identity verification can take a few days.
2. **Create app:** name *hisaab•* (or *hisaab* if the bullet is refused), default language English (India), App, Free.
3. **Play App Signing:** accept the default. Google keeps the *app signing key*, and your `.jks` is only the *upload key*. If the upload key is ever lost or leaked, Google support can reset it.
4. **Testing before production:** a new personal account must run a **closed test with at least 12 testers for 14 days in a row** before it can apply for production. Check the current rule in the Console, because Google changes it. Start this early, since it is the longest wait.
   - Internal testing first (up to 100 testers, available within minutes), then Closed testing, then Production.

### App content (Policy → App content)

| Form | Answer for hisaab |
|---|---|
| Privacy policy | `https://tejas-su.github.io/hisaab/privacy/` |
| Ads | No ads |
| App access | All functionality is available without special access (no login) |
| Content rating | Fill in the IARC questionnaire: utility/productivity, no violence, no user-generated content, no gambling. Expect "Everyone"/"3+" |
| Target audience | 18 and over (it's a money app; avoids the Families policy) |
| Data safety | **No data collected, no data shared.** All data stays on the device. Backups are files the user saves themselves, and the Ask AI export is a share the user triggers, which counts as a user-initiated transfer, not "sharing". Also answer: *data is not encrypted in transit* is N/A because nothing is sent. Users can delete their data with *Delete everything* in the app |
| Financial features | Declare it honestly: a personal budgeting/expense tracker that moves no money, holds no account credentials and gives no loans. Pick the closest option, or "My app doesn't provide any financial features" if budgeting isn't listed |
| Government app / news / health / COVID | No |

### Store listing

- [ ] App name (max 30 characters)
- [ ] Short description (max 80): e.g. *How much can I safely spend today? An offline expense tracker for India.*
- [ ] Full description (max 4,000). Ask the `design-content` agent to draft it from SPEC.
- [ ] App icon 512 × 512 PNG
- [ ] Feature graphic 1024 × 500 (exists, `d9ab086`)
- [ ] 2–8 phone screenshots. 7-inch and 10-inch tablet screenshots are optional but help, since the app is adaptive. Ready in `docs/design/store/out/`: 8 phone, 5 seven-inch and 6 ten-inch ([how they're made](design/store/README.md)).
- [ ] Category: Finance. Contact email (shown publicly): use one you're happy to publish.

---

## Before the first upload: technical TODO

- [ ] **Version:** `pubspec.yaml` says `0.1.0+2` (`+1` went to closed testing and crashed on launch, D198). Set `1.0.0+1` for launch (or keep 0.x for testing tracks). Every upload needs a higher `+build` number.
- [ ] `flutter analyze` is clean, `flutter test` passes, and `scripts/changed_lines_coverage.sh` passes.
- [ ] **Test a release build on a real phone** (`flutter run --release`). Release builds use R8 shrinking, which can break plugins that debug builds hide:
  - [ ] Bill reminders fire at the due time, and still fire after a restart (flutter_local_notifications).
  - [ ] The home-screen widget, the Quick Settings tile and the *Add a spend* app shortcut all work, and the widget updates after midnight (WorkManager).
  - [ ] Back up, Restore and Delete everything (file_picker).
  - [ ] Ask AI opens ChatGPT and the share sheet.
  - [ ] The first-launch onboarding works on a clean install.
- [ ] **Confirm no INTERNET permission** in the release bundle. The privacy policy and Data safety form depend on it:
  `"%LOCALAPPDATA%\Android\Sdk\build-tools\<version>\aapt2.exe" dump permissions build\app\outputs\apk\release\app-release.apk` (build an APK with `flutter build apk --release` for this check).
- [ ] TalkBack pass and 1.5× text (M6 exit criteria, PLAN).
- [ ] Test on Android 7 (API 24) if you can (the emulator is fine) as well as a current phone.
- [ ] Dark mode, landscape and a foldable/tablet emulator (UI_DESIGN §13).
- [ ] Remove the stray `flutter_01.log` at the repo root. It's git-ignored, so this is tidiness only.

## Every release after that

1. Bump `version:` in `pubspec.yaml` (`1.0.1+2` and so on; the `+N` must always go up).
2. Run `flutter build appbundle --release`.
3. Upload the `.aab` to Internal testing, then promote to Closed or Production.
4. Tag the commit locally: `git tag v1.0.1`. The repo is local-only, so never push.

## If something goes wrong

| Problem | What to do |
|---|---|
| Gradle warns the release build is debug-signed | Do step 2 |
| Play says "signed in debug mode" | `key.properties` wasn't found at build time. Check it's in `android/`, not the repo root |
| Upload key lost or leaked | Play Console → Setup → App signing → *Request upload key reset*. Create a new keystore (step 1) and send Google the `.pem` it asks for |
| Play says "version code already used" | Bump the `+N` in `pubspec.yaml` |
| Claude says a command was "Blocked by guard-secrets.sh" | It's working. Run that command yourself |
