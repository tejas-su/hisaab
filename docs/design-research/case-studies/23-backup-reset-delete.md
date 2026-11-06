# 23. Backup, restore, delete and reset

## Job
In Settings, let someone with no account and no cloud:
1. **Back up** their data to a place they pick through Android's file picker (Downloads, Drive through the picker, a USB stick),
2. **restore** from that file,
3. **delete** their data, and
4. **reset** the app to onboarding,

without losing data by mistake, without words they don't know, and without anything that needs the internet from hisaab itself.

## Where hisaab stands
- **BR-16:** a backup is one JSON file, `hisaab-backup-YYYY-MM-DD.json`, saved through the system file picker. Restore replaces all data after a confirmation dialog, "the **only** confirmation dialog in the app". The file is validated before anything is deleted, and the restore runs in one transaction. CSV export holds entries only.
- **FR-SE-4:** *Reset app* asks the user to type "RESET", then wipes everything and returns to onboarding. **E14:** a corrupt file changes nothing, and an older file is migrated. **NFR-5:** backup and restore round-trip byte-equal data.
- **D4:** no confirmation dialogs; Undo instead. BR-16 is the one exception.
- **Privacy copy:** onboarding says "What you type stays on this phone. The app never uses the internet." (FR-ON-2, D116), and About says "Everything stays on this phone." (FR-SE-5).
- **The manifest** (`android/app/src/main/AndroidManifest.xml`) sets neither `android:allowBackup` nor `android:dataExtractionRules`, so Android's default applies (see *Android Auto Backup* below).
- **Not built yet:** the settings feature doc places it in M6 (`docs/features/settings/01-architecture-overview.md`).

## Method
Desk and competitive research: Android platform docs, Google Play policy help, app help centres and open-source strings (Cashew), developer and user forums, NN/g and design-system guidance, and one Indian field study (Gupta et al. 2022). This is the cheapest method that can change the decision, because the platform's limits, what other apps do and how they fail are all in public. **It can't tell us** which words hisaab's users understand, or whether a typed confirmation stops them. Those need a blind read and a usability round (see *Open questions*).

**Limits of this pass:**
- **Blocked:** Realbyte help (**403**), Signal support (**403**), and every `whatsapp.com` / `faq.whatsapp.com` page (TLS "unable to verify the first certificate"). Those apps rest on search summaries, marked as such.
- **Not found:** Aegis's `docs/backups.md` returned **404**. The m3.material.io dialog guidelines returned a title only, so **Material 3's own wording on destructive dialogs was not read**.
- **No public source found** for axio (Walnut), 1Money or Spendee's backup or reset screens. No app was installed and recorded.
- **Thin on words:** no study of how low-literacy Indian users read "backup", "restore" or "reset" was found. The word findings below are inferences.

## Research by source

### Android Auto Backup: the OS already backs hisaab up
- **What it copies by default:** shared preferences, `getFilesDir()`, and "Files in the directory returned by `getDatabasePath(String)`" ([Android, Auto Backup](https://developer.android.com/identity/data/autobackup)). sqflite's `getDatabasesPath` returns `data/data/<package_name>/databases` on Android ([pub.dev](https://pub.dev/documentation/sqflite/latest/sqflite/getDatabasesPath.html)). **So hisaab's database and its onboarding flag are already uploaded today**, because `allowBackup` defaults to `true` and the manifest doesn't change it.
- **Where it goes:** "a private folder in the user's Google Drive account, limited to 25 MB per app". "Only the most recent backup is stored." It "can't be read by the user or other apps". On Android 9+ it is end-to-end encrypted with the phone's PIN, pattern or password ([same page](https://developer.android.com/identity/data/autobackup)).
- **When:** only if the user has backup switched on, 24 hours have passed, the phone is idle, and it is on Wi-Fi (unless mobile data is allowed). "A device might never back up (for example, if it never connects to a network)." Over 25 MB, the system "doesn't back up data to the cloud" until the data shrinks again ([same page](https://developer.android.com/identity/data/autobackup)).
- **Restore:** automatic on install, "before the app is available to be launched". The user picks a dataset only in the phone's setup wizard ([same page](https://developer.android.com/identity/data/autobackup)).
- **The user can't choose where it goes**, and can't open it.
- **Device-to-device transfer:** on some makers' phones, `allowBackup="false"` disables Drive backup but **not** device-to-device transfer. Excluding a file from that needs `dataExtractionRules` ([Android 12 backup changes](https://developer.android.com/about/versions/12/backup-restore)).
- **Don't back up URIs:** Android warns against it, because a URI restored to a new phone may point nowhere ([Android, data backup overview](https://developer.android.com/guide/topics/data/backup)). A saved backup-folder URI is exactly such a value.
- **Play's view:** data the user sends "directly to their own external drive or cloud storage account", where the app "never collects or accesses the data", needn't be declared as collected ([Play Console, Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)). The page doesn't mention Auto Backup either way.
- **Read:** Auto Backup is a real safety net for someone who loses or replaces a phone and never made a file. It is invisible, though, it stops on phones that never see Wi-Fi, and it means the sentence "Everything stays on this phone" is not literally true.

### Storage Access Framework: what the picker can and can't do
- **No permission needed:** "the user is involved in selecting the files … this mechanism doesn't require any system permissions". Files saved this way "remain on the device after your app is uninstalled" ([Android, documents and files](https://developer.android.com/training/data-storage/shared/documents-files)).
- **Save:** `ACTION_CREATE_DOCUMENT` works "similar to … 'save as' dialogs". It **cannot overwrite**: a second file with the same name becomes `name(1).json` ([same page](https://developer.android.com/training/data-storage/shared/documents-files)). A dated name (BR-16) avoids most clashes, but a second backup on the same day gets `(1)`.
- **Open:** `ACTION_OPEN_DOCUMENT` takes a MIME filter. Some document providers don't guess the type from the extension, so a backup file can appear **greyed out**. RSAF removed its MIME filter for imports for this reason ([RSAF PR #97](https://github.com/chenxiaolong/RSAF/pull/97)). A Stack Overflow report describes the same thing for a SQLite backup on Android 11 ([kiwix mirror](https://kiwix.lema.org/stackoverflow.com_en_all_2023-11/questions/64791028/what-is-the-mime-type-for-sqlite-db-backup-in-android-11)).
- **A standing folder:** `ACTION_OPEN_DOCUMENT_TREE` plus `takePersistableUriPermission` gives lasting access to a folder (Aegis's model). On Android 11+ the user **can't pick the root of internal storage or the `Download` folder** that way. Access is also lost "if the associated document is moved or deleted" ([Android](https://developer.android.com/training/data-storage/shared/documents-files)).

### Apps
- **WhatsApp:**
  - **Backup:** Settings › Chats › Chat backup. A Google Account backup can be daily, and "your chats will also be saved to your Google Account every night after the local backup is made" (official FAQ via search summary, [whatsapp.com/faq](https://whatsapp.com/faq/en/android/28000019); the page itself failed TLS).
  - **Restore:** offered when WhatsApp is reinstalled and the number verified (third-party guides via search, for example [helpdeskgeek](https://helpdeskgeek.com/how-to/how-to-restore-whatsapp-backup-from-google-drive/)). The Chat backup screen shows the last backup's date and time ([androidheadlines](https://www.androidheadlines.com/how-to-backup-and-restore-whatsapp-messages-via-google-drive.html), via search summary).
  - **Encrypted backups:** with end-to-end encryption, a lost password or 64-digit key can't be recovered by WhatsApp ([Tom's Guide](https://tomsguide.com/news/whatsapp-encrypted-backups), via search summary). WhatsApp later added a reminder that asks for the password again ([Android Central](https://www.androidcentral.com/apps-software/whatsapp-backup-password-reminder-feature), via search).
- **Signal:**
  - **Backup:** On-device backups with a 30-digit passphrase. "You will be unable to restore a backup without the passphrase." On Android 10+ the user taps *Choose folder* ([Signal support](https://support.signal.org/hc/articles/360007059752) and [on-device backups](https://support.signal.org/hc/articles/10066926526362); both 403, so from search summaries).
  - **Restore:** offered **during first-run setup** (*Transfer or restore account › Restore from backup*). The file must keep its original name and location for Signal to find it ([troubleshooting](https://support.signal.org/hc/en-us/articles/10075152150426-Troubleshooting-Android-On-device-backups), via search).
- **Aegis Authenticator:**
  - **Automatic backups:** the README offers "Automatic backups of the vault to a location of your choosing" ([README](https://raw.githubusercontent.com/beemdevelopment/Aegis/master/README.md)). Setting them up "automatically schedules an initial backup" ([issue #1374](https://www.github.com/beemdevelopment/Aegis/issues/1374)).
  - **Rotation:** the default keeps 5 versions, and a user reported "all my old (default 5) backups have been overwritten" after a burst of small changes ([#1374](https://www.github.com/beemdevelopment/Aegis/issues/1374); also [#1245](https://www.github.com/beemdevelopment/Aegis/issues/1245) via search).
  - **Reminder:** v2.1 added a reminder when the vault changed since the last backup or export ([release notes](https://newreleases.io/project/github/beemdevelopment/Aegis/release/v2.1-beta2), via search). The FAQ advises against turning it off ([FAQ](https://github.com/beemdevelopment/Aegis/blob/master/FAQ.md), via search).
- **Money Manager (Realbyte):** backup to Google Drive (daily or weekly), to the device, or by email. An automatic backup to a `/MoneyManager` folder on exit uses `auto_` file names. The formats are `.sqlite` and `.MoneyManager2`. The restore opens from the file ([help](https://help.realbyteapps.com/hc/en-us/articles/360042747934-How-to-backup-and-restore-data); 403, search summary only).
- **Bluecoins:**
  - **Backup:** daily automatic backups to device storage (`*.bcbackup`), and "A cleanup worker deletes old backup files after a configurable retained count".
  - **Restore:** picks a file and validates it "with the current app version's schema first".
  - **Reset:** a full reset "removes all data from the device", in "Two passes", with the confirmation phrase "I know my data will be lost". A lighter reset deletes only transactions and keeps categories and accounts ([Bluecoins data management](https://new.bluecoinsapp.com/settings/data/)). Cloud sync is premium ([guide](https://ram.bluecoinsapp.com/guide/online-sync/), via search).
- **Cashew** (open-source Flutter, [`en.json`](https://raw.githubusercontent.com/jameskokoska/Cashew/main/budget/assets/translations/generated/en.json)):
  - **Restore:** "Load Backup?" / "This will replace all your current data!" / *Load*. On a fresh install it asks "Backup Found" / "Would you like to restore a backup?".
  - **Erase:** "Delete All Data" leads to "Erase Everything?", then "Are You Sure You Want to Erase Everything?" / "All data and preferences will be deleted!", with *Erase*. It says "All Google Drive backups will be kept."
  - **CSV is not a backup:** "Exporting to CSV should not be used as a backup of data. Budgets and detailed app data is not exported in the CSV!"
  - **Wrong file:** "Import may fail! Please make sure you have selected a valid Cashew [.sqlite] or [.sql] backup file", and "Your database is corrupted. You may have imported the wrong file."
  - **Restart:** "An app restart is required to load data from a backup".
- **Monefy:** sync "using your own Google Drive or Dropbox account" (App Store listing via search, [apps.apple.com](https://apps.apple.com/it/app/monefy-gestione-spese/id1212024409)). No restore or reset details were found.
- **Wallet (BudgetBakers):** account-based. It separates "start over and delete all data" (keeps the account) from "Delete profile and all data" ([BudgetBakers support](https://support.budgetbakers.com/hc/en-us/articles/7183718895762), via search summary).
- **Goodbudget:**
  - **Label:** "Clear All My Data", confirmed by a button reading "Yes, please DELETE ALL MY DATA".
  - **What stays:** envelope and account names and budgeted amounts; transactions and balances go.
  - **No undo**, and the help page advises exporting first ([Goodbudget help](https://goodbudget.com/help/budgeting-with-goodbudget/clear-data/)).
- **PocketSmith:** six checkboxes, from "Delete all categories" to "Delete everything and start again", then "Reset the selected areas" and a confirm step. "Please be careful - this cannot be reversed." It advises backing up first ([PocketSmith](https://learn.pocketsmith.com/article/285-options-for-resetting-your-pocketsmith-account)).
- **Lunch Money:** a user pressed a reset labelled as deleting a budget: "I had absolutely no understanding whatsoever that all my accounts, categories, transactions" would go (Ben Bryant, 19 Feb 2026). It was fixed in release #278, and the team split out a reset of allocations only ([feedback board](https://feedback.lunchmoney.app/general-feature-request/p/improve-wording-for-delete-this-budget-button-and-confirmation-dialog)).
- **Actual Budget:** after loading an automatic backup, "select **Revert to original version**", which stays "available until another backup is made". A backup from a newer version fails with "This budget cannot be loaded with this version of the app. Make sure the app is up-to-date." ([Actual docs](https://actualbudget.org/docs/backup-restore/restore)).
- **Android itself (Pixel):** *System › Reset options › Erase all data (factory reset)*. "A factory reset erases all your data from your phone." It asks the user to make sure their data is backed up first, and "If needed, your phone asks for your PIN" before *Erase all data* ([Pixel help](https://support.google.com/pixelphone/answer/4596836?hl=en)).
- **axio (Walnut), 1Money, Spendee:** no public source on backup or reset found.

### Destructive-action guidance
- **NN/g, Nielsen 2018** ([Confirmation dialogs](https://www.nngroup.com/articles/confirmation-dialog/)), in its own words:
  - "Use a confirmation dialog before committing to actions with serious consequences", and "Do not use confirmation dialogs for routine actions."
  - Name the item and the effect rather than "Are you sure?". Labels should "summarize what will happen for each possible response".
  - "Do go to great lengths to provide undo."
  - For the most dangerous acts, "require a nonstandard action from the user to confirm", sparingly.
- **NN/g, Laubheimer 2015:** "Don't use confirmation dialogs as the sole error prevention method"; undo makes people feel "more secure" ([Avoiding conscious mistakes](https://www.nngroup.com/articles/user-mistakes/)). Slips "often are made by expert users" ([Avoiding unconscious slips](https://www.nngroup.com/articles/slips/)).
- **GitHub, deleting a repository:**
  - **Steps:** *I want to delete this repository* › *I have read and understand these effects* › type the repository's name › *Delete this repository*.
  - **Recovery:** "Some deleted repositories can be restored within 90 days" ([GitHub Docs](https://docs.github.com/en/repositories/creating-and-managing-repositories/deleting-a-repository)).
- **Primer:** a confirmation dialog only for "serious, permanent, or widespread impacts", with "action-oriented language", not "Yes"/"No" ([Primer](https://primer.style/product/components/confirmation-dialog/guidelines)).
- **Hold to confirm:**
  - **For:** Trimble recommends press-and-hold buttons "When an action cannot be undone and/or is potentially destructive" ([Trimble Modus](https://modus.trimble.com/components/web/buttons/accessibility), via search summary).
  - **Accessibility gaps:** keyboard and reduced-motion support are the usual failures, and one implementation falls back to a visible "Press and hold for {duration}s" ([tfe-svelte-templates](https://tfe-svelte-templates.vercel.app/holdtoconfirm), via search).
  - **No study** comparing hold, typing and dialogs on error rates was found.

### Indian users: shared phones, helpers, spelling
Gupta, Mehta, Punj & Medhi Thies, *Sophistication with Limitation*, COMPASS 2022: 30 phone interviews in Hindi, low-income urban and rural India ([PDF](https://www.microsoft.com/en-us/research/wp-content/uploads/2022/05/compass22-34-taps.pdf), read from the saved file).
- **Helpers:** 23 of 30 "depended on an intermediary user to get started and continue learning". Low-literate users "displayed hesitancy to use anything apart from what they have been told", and feared "damaging their devices unknowingly".
- **Shared phones:** 22 of 30 shared their phone with family. Children used parents' phones for school, and "kids displayed ownership over the smartphones".
- **Spelling:** "If I do not know the spellings, then speaking on the mic shows the correct spellings". Users code-mix and say "certain words in English" so that systems understand them.
- **Credentials:** after a helper made an account, people would "note it down somewhere for future use (e.g., in a paper diary or in phone)".
- **Read:**
  - A backup is likely to be made, or a phone moved, by a helper. The words must survive being relayed.
  - A shared phone raises the odds of a reset nobody meant.
  - Typing an English word is a literacy test, not just a pause.
  - A passphrase written in a diary is a weak lock and an easy loss.

### Words
- **The phone's own words:** Android says *Back up*, *Reset options* and *Erase all data (factory reset)* ([Pixel help](https://support.google.com/pixelphone/answer/4596836?hl=en)). WhatsApp says *Chat backup* and restores on reinstall. Hindi-language WhatsApp guides write "बैकअप" and "रिस्टोर" as loanwords ([Amar Ujala](https://www.amarujala.com/photo-gallery/utility/how-to-restore-deleted-whatsapp-chat-follow-these-steps-2023-09-05), via search summary; not opened).
- **Inference (low confidence):** "backup" is probably familiar from WhatsApp. "Restore" is less certain, and "reset" is a phone-level word tied to wiping the whole phone.
- **Scope beats the verb.** Lunch Money's failure wasn't the word "delete" but what it covered. Goodbudget and Cashew put the scope in the button ("DELETE ALL MY DATA", "All data and preferences will be deleted!").

### Format: what the file is from the user's side
| Format | Can the user open it? | Survives app updates? | Who uses it |
|---|---|---|---|
| Raw `.db` / `.sqlite` | No (needs a SQLite tool) | Only if the app migrates old schemas on load; a newer file fails on an older app (Actual's error) | Cashew, Realbyte, Bluecoins (`.bcbackup`) |
| JSON with a version (BR-16) | It opens as text, but it means nothing to a non-technical user | Yes, if it carries a schema version and the app migrates (E14). Easy to validate before touching data | Aegis (`aegis-backup-*.json`, [script](https://gist.github.com/AutonomousCat/54830965d9a06bba9fa8058cf6ed5a70), via search) |
| CSV | Yes, in Sheets or Excel | Not a full backup: rules, categories and settings are lost. Cashew warns against it | Export only, everywhere |

**Read:** no format is human-readable to hisaab's users, so choose the format for safety (versioned, validated before anything changes) and let the **file name** carry the meaning: app name, the word "backup", and the date. BR-16 already does this.

## Patterns compared

| App | Where the backup goes | Automatic? | Restore entry | Restore safety | Delete / reset | Confirmation |
|---|---|---|---|---|---|---|
| Android Auto Backup | User's Drive, hidden, 25 MB | Nightly on Wi-Fi | On install, before first launch | Last copy only | n/a | n/a |
| WhatsApp | Phone + Google Account | Daily option | **At setup**, after reinstall | Last backup date shown | n/a | n/a |
| Signal | **User-chosen folder** | Scheduled | **At setup** | 30-digit passphrase; lost means unusable | n/a | n/a |
| Aegis | **User-chosen folder** (SAF) | On every change | Import | Keeps 5 (rotation lost a user's old ones); reminder when unsaved | n/a | n/a |
| Money Manager | Drive, device, email | On exit (`auto_`) | From the file | Not found | Not found | Not found |
| Bluecoins | Device; cloud is premium | Daily, with a retained count | Pick a file | **Validated against the schema first** | Full reset, or transactions only | **Typed phrase**, two passes |
| Cashew | Device, Drive | On open, with a limit | Settings; **"Backup Found" on a fresh install** | "Import may fail" warning | Erase everything (Drive copies kept) | Two dialogs |
| Goodbudget | Export only | No | n/a | n/a | Clears entries, **keeps names** | Button names the scope |
| PocketSmith | Its own backup | n/a | n/a | n/a | **Six scoped checkboxes** | Confirm step |
| Actual Budget | Its own backups | Yes | Backup menu | **"Revert to original version"** | n/a | n/a |
| Pixel (Android) | Google Account | Yes | At setup | n/a | Erase all data | **Back up first; device PIN** |

### What works
1. **Validate before you replace** (Bluecoins; BR-16 already does).
2. **Make restore undoable** for a while (Actual's revert). Restore is the one destructive act where the old data can be kept without breaking any promise.
3. **Offer restore where the new-phone user is: the first screen** (Signal, WhatsApp, Cashew's "Backup Found").
4. **Offer a backup at the moment of risk.** Pixel, Goodbudget and PocketSmith all say "back up first" before erasing.
5. **Put the scope in the words** ("DELETE ALL MY DATA"; "All data and preferences will be deleted!").
6. **Show when the last backup was made** (WhatsApp; Aegis's reminder when changes aren't saved).
7. **Save to a place the user picks and can see**, so the file survives uninstall (SAF).

### Failures to avoid
1. **A secret the user must keep** (Signal's 30 digits, WhatsApp's 64-digit key): lose it and the backup is useless.
2. **Scope hidden behind a narrow label** (Lunch Money, until 2026).
3. **Rotation that silently drops old copies** (Aegis's 5).
4. **CSV mistaken for a backup** (Cashew warns against it).
5. **A MIME filter that greys out the user's own file** (RSAF, the Stack Overflow report).
6. **Privacy copy that the OS quietly makes untrue** (Auto Backup is on by default).
7. **A confirmation that tests spelling in English** for Hindi-first users (inferred from Gupta et al.; not tested).

## Implications for hisaab (for `design-product`; not decisions)

| # | Implication | Evidence | Confidence |
|---|---|---|---|
| 1 | **Decide on Android Auto Backup on purpose.** Keeping it gives a silent safety net, but then "Everything stays on this phone" and "What you type stays on this phone" need rewording (for example, the phone's own backup may keep an encrypted copy in the user's Google account). Turning it off keeps the sentences true, but then needs `allowBackup="false"` **and** `dataExtractionRules` (device-to-device transfer). Either way, never back up a folder URI. | Android Auto Backup, Android 12 changes, backup overview | High (platform docs) |
| 2 | **Backup is one tap to the picker, then a result that names the file and the place.** Under the row, show "Last backup: 6 Nov" from an on-device date; that's a fact on the user's own phone, not telemetry. | SAF; WhatsApp's last-backup line; Aegis's reminder | Medium |
| 3 | **Restore: pick, check, show, then replace.** Read and validate the file first (E14). Show what's in it: the copy's date and how many days and entries it holds. Then one dialog with labels that say the outcome (for example "Replace with this backup" / "Keep what's here"). | NN/g, Primer, Bluecoins, Cashew, BR-16 | High |
| 4 | **Make restore undoable.** Before replacing, keep the current data as a local snapshot, and offer Undo on the result plus a "Go back to before" row until the next restore. That honours D4 even inside BR-16's one dialog. | Actual's revert; NN/g "provide undo" | Medium |
| 5 | **Offer restore on onboarding's first screen** as a quiet text link, for the new-phone case. | Signal, WhatsApp, Cashew's "Backup Found" | Medium (and see *Conflicts*) |
| 6 | **Merge "delete data" and "reset" into one act**: erase everything and go back to the start. A hisaab with no income rule can't answer its one question, so "delete but stay" has no useful end state. The scope goes in the words. A partial reset (Bluecoins' transactions-only, Goodbudget) is a later question, not v1. | Bluecoins, Goodbudget, PocketSmith, Lunch Money | Medium |
| 7 | **Erase offers "Back up first" as its first choice**, and erasing is the second. | Pixel, Goodbudget, PocketSmith | High |
| 8 | **Erase truly erases: keep no hidden copy.** People reset to start fresh **or** to hand the phone over, and a kept copy breaks the second reason. So erase needs a strong guard, while restore can lean on undo. | Pixel's erase; Gupta (shared phones) | Medium |
| 9 | **Rethink the typed "RESET" guard.** It is in English, it tests spelling, and it has no Hindi form. Options, all to test: (a) keep typing, but the word in the user's language; (b) hold to erase, about 3 s, with visible words and TalkBack's double-tap-and-hold; (c) the phone's own lock (PIN or fingerprint), as Pixel does, which needs a new dependency. | NN/g guideline 7; GitHub; Bluecoins; Gupta (spelling); Trimble | Low (no comparative study) |
| 10 | **No passphrase or encryption in v1.** A lost secret makes a backup worthless, and these users write passwords in diaries or hand them to helpers. The file is the user's own, in a place they chose. Say so in one line. | Signal, WhatsApp, Gupta | Medium |
| 11 | **Keep JSON (BR-16)**, but open it with an `*/*` filter and validate the content, not the MIME type. Keep the dated name. Treat a file from a newer app as "Update hisaab to open this backup", never as "corrupt". | SAF note, RSAF, Actual | Medium |
| 12 | **CSV export stays labelled as a list for spreadsheets, never as a backup.** | Cashew | High |
| 13 | **Not for v1: automatic backups to a chosen folder** (Aegis, Bluecoins). They need a persisted tree URI (and Android 11+ refuses the Download root), background work, and rotation rules that have lost users' copies. Auto Backup (implication 1) already covers "I never made a file". | SAF limits; Aegis #1374 | Medium |

## Conflicts (for `design-product`; `DECISIONS.md` wins until changed)
- **D116 / FR-ON-2 and FR-SE-5:** "stays on this phone" isn't strictly true while Auto Backup is on by default (implication 1). Either the copy or the manifest must change.
- **D4 vs BR-16:** BR-16's dialog is the agreed exception. Implications 3 and 4 keep it and add an Undo. Implication 9 may add a second guarded act (erase), which needs a decision row if it isn't a dialog.
- **FR-SE-4:** typing "RESET" (implication 9) is untested with Hindi-first users and has no localised form.
- **FR-ON-1 to FR-ON-3 (three questions):** a restore link on step 1 (implication 5) adds a control to onboarding, though not a step.
- **Task scope:** the brief lists delete and reset as two acts. The evidence suggests one (implication 6). The owner should confirm.

## Principles (appended to `principles.md` as 72–78)
See `principles.md` › *Backup, restore and erase (case study 23)*.

## Open questions
1. **Words (blind read, 5 users, Hindi and English, UPI-first, low-end phones):** show the Data rows and the erase sheet cold, and ask "What will this do?". Compare "Backup" with "Save a copy", "Restore" with "Bring back", and "Reset app" with "Erase everything and start again". Note who answers by naming WhatsApp.
2. **The erase guard (usability round, 5 users):** typed word, hold to erase, or the phone's PIN. Measure success, time, SEQ and any accidental erase. Include one task where a child is handed the phone (a role-play) to see whether the guard stops a stray tap.
3. **Where do people put the file, and can they find it a month later?** Task: "Make a backup", then a week later, "Bring your data back". Observe whether they pick Downloads, Drive or WhatsApp-to-self, and whether a helper does it.
4. **How often do people change or lose phones, and who sets up the new one?** Interviews (Mom Test): "Tell me about the last time you got a new phone. What did you lose?"
5. **Auto Backup in practice:** on low-end phones that rarely see Wi-Fi, does it ever run? Check with 5 consenting participants' own Drive *Backups* screens; never with telemetry.
6. **Not read and worth a browser session:** Realbyte and Signal help (403), WhatsApp FAQ (TLS), the m3.material.io dialog guidelines, and recordings of Money Manager's, Bluecoins' and axio's backup and reset screens.
