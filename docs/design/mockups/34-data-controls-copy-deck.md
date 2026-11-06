# 34 · Data controls copy deck (Back up, Restore, Delete everything)

Status: **accepted (D139) and in `app_en.arb`.** Shipped choices: press-and-hold, so the typed-number strings (`deleteAllTypePrompt`, `deleteAllTypeLabel`, `deleteAllTypeSpoken`, `deleteAllTypeButton`) and `deleteAllHoldAction` were not added; the *Undo restore* row uses `restoreRevertRow` / `restoreRevertHint`. Strings added beyond this deck: `backUpBusy` "Backing up…", `restoreRevertLoses` "The {count} entries added since will go.", `deleteAllHoldFull` "Let go to delete", `deleteAllHoldArmed` "Double-tap again to delete everything", `deleteAllHoldHint` "Double-tap twice to delete", `deleteAllWorking` "Deleting…". Not built yet: `restoreOlderNote`, `backUpNoSpace`, `deleteAllBackupOld`, `aboutPrivacy` (the About group isn't built).

**Sources:** the product brief "Your data" (its *User decisions, 2026-11-06* are binding: one *Delete everything*, JSON via the system picker, Auto Backup **off**, `file_picker`, restore keeps a pre-restore copy so it has Undo); case study [23](../../design-research/case-studies/23-backup-reset-delete.md); SPEC BR-16, FR-ON-1, FR-SE-4, FR-SE-5, E14; the `delete*`, `*Deleted`, `incomePrivacy`, `askPrivacyNote`, `moneyComingIn`, `savings` and `lookTile` strings in `lib/l10n/app_en.arb`.

**Worked example:** today Fri 6 Nov 2026. The phone has 37 entries. A backup made on 12 Oct holds 214 entries. File name `hisaab-backup-2026-11-06.json`.

**Length:** the smallest `TestWindows` size is `smallPhone` 320×568: about 280dp of page content (about 37 characters a line of 16sp Mukta), about 232dp inside a dialog (about 30 characters) and about 200dp of snackbar text beside *Undo* (about 30 characters at 14sp). Line counts are estimates for a `smallPhone` widget test to confirm. Hindi needs 30–40% more room, so nothing below relies on one line.

**Dates:** every `{date}` is a `String` from the app's short date format, "12 Oct", with the year added only when it is not this year ("12 Oct 2025"). Never a weekday-only date here: backups can be months old.

---

## 1. Word choices

### Back up, not "Save a copy"
- **Chosen: *Back up*** (verb, two words) for the row and the act; **backup** (one word) for the file.
- The phone already uses it: Android says *Back up*, and WhatsApp's *Chat backup* is where most Indian users met the idea. Hindi guides write it as the loanword "बैकअप" (case study 23, *Words*).
- Case study 23 found that a helper often makes the backup or sets up the new phone (23 of 30 users relied on one, Gupta et al. 2022). A helper will say "backup", so the word on screen should be the word they say.
- *Save a copy* is plainer, but it clashes with the money word. In hisaab, **Saved** means money put into an RD or SIP (deck 28, word rules), and Settings has a *Savings* row two rows above this group. "Save a copy" beside *Savings* could be read as a money action. It also doesn't say what gets copied.
- Because of that clash, this deck never says "saved" about the file. Results say **Backed up**.

### Restore, explained by "Bring back"
- **Chosen: *Restore*** as the row title and the onboarding link, with **"Bring back from a backup file"** as the row's second line.
- *Restore* is the word WhatsApp shows at setup and the loanword Hindi guides use ("रिस्टोर"). It pairs with *Back up*, and helpers relay it.
- The research flags it as less familiar than "backup" (low confidence). So the second line says the same thing in plain words. Readers who know *Restore* read the title; readers who don't read the line.
- *Bring back* alone as the title was rejected because, in a list of rows, it doesn't say *what* comes back. It could be read as "bring back something I deleted", which is Undo's job.

### Delete everything, not "Erase everything"
- **Chosen: *Delete everything*.** "Delete" is the owner's word, so it is findable. It is also the verb the app already uses on every delete (*Delete bill*, *Delete saving*, "₹400 deleted").
- **"Erase" is the phone's factory-reset word** (Android: *Erase all data*). Case study 23 cites users who fear "damaging their devices unknowingly". *Erase everything* in a phone's Settings can be read as "wipe my phone". The delete page also says so outright: "Your phone and other apps stay as they are."
- **Scope beats the verb** (Lunch Money, Goodbudget). "Everything" sits under the group heading *Your hisaab*, the second line says "start again", and the page lists every item that goes.
- *Reset* is not used anywhere. It is a phone-level word too, and the owner's "reset app" is covered by "start again".

### Group heading: *Your hisaab*
- **Chosen: *Your hisaab*.** In Hindi, *hisaab* means "your record of money", so the heading names exactly what is backed up and deleted: the scope is in the words.
- *Your data* was rejected because in India "data" mostly means the mobile internet pack ("data khatam"). Under *Your data*, "Delete everything" could read as something to do with the internet, and *Back up* could sound like it needs it.
- The brand stays lowercase at the start of a heading, as `fixedBillsHint` already does ("hisaab adds…").
- If a blind read finds *Your hisaab* odd, the fallback is *Your data*.

### Other word rules in this deck
- **Never:** "export" (CSV will use it later; a backup is not a CSV), "corrupt", "invalid", "erase", "reset", "wipe", "overwrite", "file format", "JSON", "schema", "version" (except "newer hisaab"), "saved" about a file.
- **"This phone"** for the device, matching `incomePrivacy` and FR-SE-5.
- **"Nothing changed"** after every restore or delete failure, because the user's first fear is losing data.
- **"Entries"** is the glossary word (SPEC §2), already on screen in "No entries in {cycle}."

---

## 2. Settings group and rows

| Key | Text | Context / description | Lines @280dp | Notes |
|---|---|---|---|---|
| `settingsYourHisaab` | Your hisaab | Settings group heading for Back up, Restore and Delete everything. It sits under Look and before About | 1 | Justified in §1. |
| `backUpRow` | Back up | Title of the Settings row that opens the system Save screen to make a backup file | 1 | Verb first. Pairs with *Restore*. |
| `backUpLast` | Last backed up {date} | Second line of the Back up row: the date the last backup on this phone was made. Example "Last backed up 12 Oct" | 1 | A fact on the user's own phone, not a nudge. Never marigold, never a badge (brief 2.3). |
| `backUpToday` | Backed up today | Second line of the Back up row when the last backup was today | 1 | Reads better than "Last backed up 6 Nov" on the same day. |
| `backUpNever` | Not backed up yet | Second line of the Back up row when no backup has been made on this phone | 1 | "Never backed up" sounds like a verdict. "Yet" says it can still happen, without telling anyone off. |
| `restoreRow` | Restore | Title of the Settings row that opens the file picker to bring back a backup file | 1 | Justified in §1. |
| `restoreRowHint` | Bring back from a backup file | Second line of the Restore row; explains Restore in plain words | 1 (29 ch) | The second line says it again in plain words. |
| `deleteAllRow` | Delete everything | Title of the Settings row that opens the Delete everything page. Deletes all hisaab data and starts the app again | 1 | Justified in §1. Not marigold; design-ia decides whether it gets its own card. |
| `deleteAllRowHint` | Clear it all and start again | Second line of the Delete everything row | 1 (28 ch) | It covers the owner's "reset app" without the word "reset". |
| `backUpNoLock` | The backup file has no password. Anyone who has it can read your entries and notes, so keep it safe. | Note under the Your hisaab rows (or on a backup page, if UX adds one): a backup is not locked | 3 | The brief requires this line (no encryption, by decision). It names what can be read ("notes" matters: BR-16 backups include personal text). "Password" is concrete; "not encrypted" is not plain. It ends with what to do. |

Options for `backUpNoLock`:
1. "The backup file has no password. Anyone who has it can read your entries and notes, so keep it safe." **Chosen.** Fact, then what it means, then what to do.
2. "Keep your backup file safe. It isn't locked." Shorter, but "isn't locked" is vague: locked how, and against whom?
3. "Your backup isn't encrypted." Rejected: it is jargon and gives no next step.

---

## 3. Back up

The row opens the system Save screen with `hisaab-backup-YYYY-MM-DD.json` filled in (BR-16). Nothing is shown before it.

| Key | Text | Context / description | Lines | Notes |
|---|---|---|---|---|
| `backUpDone` | Backed up as {fileName} | Snackbar after the backup file is written, when the picker gives back the file name. Example "Backed up as hisaab-backup-2026-11-06.json" | 2 | The name is what the user looks for when they restore (brief risk: "can they find the file again"). Pass the name exactly as returned, so a same-day "(1)" shows. |
| `backUpDoneNoName` | Backed up | Snackbar after the backup file is written, when the picker doesn't give a name | 1 | Kept short; no exclamation mark. |
| (picker cancelled) | *(nothing)* | The user backed out of the Save screen | none | Silent, as the brief says. The user chose not to save, so there is nothing to report. |
| `backUpFailed` | Couldn't back up there. Try another folder. | Snackbar when writing the backup file fails (for example a folder that can't be written to, or a Drive error) | 2 | What happened, then how to fix it. "There" points at the user's choice, not at the user. |
| `backUpNoSpace` | Not enough space there. Free some space or pick another folder. | Snackbar when the place the user picked is full | 2 | Only if `file_picker` reports a space error that can be told apart. Otherwise `backUpFailed` covers it. |
| `backUpReadFailed` | Couldn't make the backup. Nothing changed. Try again. | Snackbar when hisaab can't read its own data to write the file (rare) | 2 | "Nothing changed" heads off the fear that backing up hurt the data. |

Accessibility: the snackbars are live regions (UI_DESIGN §9). TalkBack reads the file name digit by digit. That is acceptable, because the user may need the exact name. No amounts appear in this flow.

---

## 4. Restore

The picker opens all files (`*/*`, case study 23 implication 11). Validation happens before anything changes (E14).

### 4.1 While working

| Key | Text | Context / description | Lines | Notes |
|---|---|---|---|---|
| `restoreChecking` | Checking the backup… | Shown while the picked file is read and checked, if that takes more than a moment | 1 | Only if UX shows a wait state. |
| `restoreWorking` | Bringing back your hisaab… | Shown while a restore runs, after Replace | 1 | Reuses the plain "bring back" wording. |

### 4.2 The file can't be used (snackbar; nothing changes)

| Key | Text | Context / description | Lines | Notes |
|---|---|---|---|---|
| `restoreNotBackup` | That's not a hisaab backup. Pick a file whose name starts with hisaab-backup. | Snackbar when the picked file is not a hisaab backup at all | 2–3 | Never "invalid" or "wrong file". The next step names the file to look for, which matches `backUpDone`. |
| `restoreBroken` | This backup can't be opened. It may be cut short. Try another copy. | Snackbar when the file looks like a hisaab backup but parts are missing or broken | 2–3 | Use only if engineering can tell it apart from `restoreNotBackup`. "Broken" and "cut short" are plain; "corrupt" is banned in this deck. |
| `restoreNewer` | This backup is from a newer hisaab. Update hisaab from Play Store, then try again. | Snackbar when the file's version is newer than this app (E14). Nothing is changed | 3 | Case study 23 implication 11 and Actual Budget: name the fix, never "corrupt". "Play Store" is a name every Android user knows. |
| `restoreOpenFailed` | Couldn't open that file. Try again or pick another. | Snackbar when the file can't be read at all (permission or storage error) | 2 | |
| (picker cancelled) | *(nothing)* | The user backed out of the picker | none | Silent, as in Back up. |

Options for `restoreNewer`:
1. "This backup is from a newer hisaab. Update hisaab from Play Store, then try again." **Chosen.** The cause in plain words, then the fix in order.
2. "Update hisaab to open this backup." Shorter, but on its own it sounds as if the app is broken, and it leaves out where to update.
3. "This backup can't be read by this version." Rejected: "version" is jargon, there is no next step, and the user would think the file is bad.

### 4.3 The one confirmation dialog (BR-16)

Settings path: the phone already has data.

| Key | Text | Context / description | Lines @232dp | Notes |
|---|---|---|---|---|
| `restoreConfirmTitle` | Replace with this backup? | Title of the restore dialog, the only confirmation dialog in the app (BR-16) | 1–2 | The outcome verb comes first and matches the button. Not "Are you sure?" (NN/g). |
| `restoreConfirmFrom` | `{count, plural, =0{Made on {date}, with no entries.} =1{Made on {date}, with 1 entry.} other{Made on {date}, with {count} entries.}}` | Dialog line 1: when the backup was made and how many entries it holds. `date` is a short date, `count` is entries in the file. Example "Made on 12 Oct, with 214 entries." | 2 | Facts that let the user check it's the right file. |
| `restoreConfirmReplaces` | `{count, plural, =0{It replaces everything on this phone now. You can undo right after.} =1{It replaces everything on this phone now, including 1 entry. You can undo right after.} other{It replaces everything on this phone now, including {count} entries. You can undo right after.}}` | Dialog line 2: what happens to the data on this phone. `count` is entries on the phone now. Example "…including 37 entries. You can undo right after." | 3–4 | Two counts side by side ("214" in the file, "37" here) let the user tell a fresh phone from a full one. "You can undo" is true only because the pre-restore copy is kept (binding decision). It turns a warning into a fact. |
| `restoreConfirmYes` | Replace | Dialog key that restores the backup | 1 | The brief's word. It says the outcome and pairs with the title. |
| `restoreConfirmNo` | Keep what's here | Dialog key that closes the dialog and changes nothing | 1 | It says the outcome, not "Cancel". |

Onboarding path: the phone has nothing yet, so there is nothing to replace.

| Key | Text | Context / description | Lines | Notes |
|---|---|---|---|---|
| `restoreFirstTitle` | Bring back this backup? | Title of the restore dialog when it starts from onboarding (the phone has no data yet) | 1 | No "replace", which would be untrue. |
| (body) | reuses `restoreConfirmFrom` | | 2 | One line is enough here. |
| `restoreFirstYes` | Bring it back | Dialog key that restores the backup from onboarding | 1 | |
| `restoreFirstNo` | Not this one | Dialog key that closes the dialog; the user stays on onboarding | 1 | It suggests the next step, picking another file. |

Options for the Settings title:
1. "Replace with this backup?" **Chosen.** It names the consequence and matches the button.
2. "Use the backup from 12 Oct?" The date comes first, but "use" hides the fact that today's data goes.
3. "Restore this backup?" It repeats the row and doesn't name the consequence.

TalkBack: the dialog reads its title, then both lines in order. Counts are plain numbers. Focus starts on the title, not on *Replace*.

### 4.4 After restoring

| Key | Text | Context / description | Lines | Notes |
|---|---|---|---|---|
| `restoreDone` | Backup from {date} restored | Snackbar on Home after a restore, with Undo (Settings path). Example "Backup from 12 Oct restored" | 1–2 | Same shape as "{bill} deleted" and "{amount} deleted": the thing, then what happened. |
| (action) | reuses `undo` ("Undo") | | | |
| `restoreUndone` | Back to what you had before | Snackbar after Undo on a restore; the data from before the restore is back | 1 | Optional. Other Undos are silent, but this one swaps everything, so a word helps. |
| `restoreFailed` | Couldn't restore. Nothing changed. Try again. | Snackbar when the restore stops part way and is rolled back | 2 | |
| `restoreUndoFailed` | Couldn't go back. The backup is still in use. | Snackbar if Undo of a restore fails (rare) | 2 | A fact about the current state, so the user knows where they stand. |
| (older file, migrated) | *(nothing extra)* | E14: an older backup is brought up to date | none | **Recommendation: say nothing.** The migration is hisaab's job, and the user only needs it to work. `restoreDone` covers it. If engineering finds that a migration has to drop or default something the user would notice, use `restoreOlderNote`. |
| `restoreOlderNote` | This backup is from an older hisaab. Newer settings start at their usual choice. | Optional extra line in the dialog, only if migrating an older backup resets something the user would notice | 2–3 | Not shown by default. |

Notes for design-ux:
- **Onboarding path:** recommend no Undo on `restoreDone`, because there is nothing before to go back to. Land on Home, as from Settings.
- **Undo duration:** the snackbar closes after 4 s (D105), except with TalkBack. A whole-data swap may deserve a longer window or a *Go back to before* row until the next restore (case study 23 implication 4). If UX adds that row: `restoreRevertRow` "Undo restore" / `restoreRevertHint` "Go back to what you had before {date}".
- **Bill reminders after a restore on a new phone:** Android's notification permission isn't restored with the file. UX should decide whether the reminder ask appears again. Its copy already exists (`remindAsk*`).

---

## 5. Onboarding link (FR-ON-1)

The first onboarding screen today is step 1, the amount ("How much money comes in each month?"). There is no separate welcome step. The link goes on that screen and is never marigold.

| Key | Text | Context / description | Lines | Notes |
|---|---|---|---|---|
| `restoreLink` | Restore a backup | Quiet text link on the first onboarding screen for someone moving from another phone; opens the file picker | 1 | It matches the Settings row and WhatsApp's setup word. Verb first, 16 characters, so it doesn't compete with the question. |
| `restoreLinkSpoken` | Restore a backup from another phone | TalkBack label for the onboarding link, so it makes sense heard alone | | It adds the reason, which the eye gets from where the link sits. |

Options:
1. "Restore a backup". **Chosen.** Short, and the same words as Settings.
2. "Have a backup? Restore it". Friendlier, but twice as long, and a question competes with the step's own question.
3. "New phone? Bring back your hisaab". It speaks to the moment, but it is long, and "Bring back your hisaab" is a new phrase to learn.

Failures on this path reuse §4.2. After a failure the user stays on step 1 with the amount untouched.

---

## 6. Delete everything page

A full page, not a dialog (BR-16 keeps the only dialog). Order, top to bottom: title, lead, list, what stays, last backup, *Back up first*, the guard.

| Key | Text | Context / description | Lines | Notes |
|---|---|---|---|---|
| `deleteAllTitle` | Delete everything | Title of the Delete everything page | 1 | The same words as the row. |
| `deleteAllLead` | This clears hisaab on this phone. It opens again at the first step, like new. | First sentence on the page: what happens | 2–3 | It says the end state, not just the loss. |
| `deleteAllListTitle` | This goes: | Heading over the list of what is deleted | 1 | Plain words. A colon introduces the list. |
| `deleteAllItemEntries` | Every entry you added | List item | 1 | "Entries" is the glossary word. |
| `deleteAllItemIncome` | Money coming in | List item: the income set up in onboarding | 1 | Same words as the Settings row (`moneyComingIn`). |
| `deleteAllItemBills` | Bills and their reminders | List item | 1 | Reminders go with bills. Users think of them as one thing. |
| `deleteAllItemSavings` | Savings | List item | 1 | Same as the Settings row. |
| `deleteAllItemCategories` | Categories you added or changed | List item; the 8 built-in categories come back as new | 1 | It doesn't say "categories" alone, because the built-in tiles come back and saying they go would be untrue. |
| `deleteAllItemSettings` | Look and your other settings | List item: Look, month start and other choices go back to the start | 1 | It names Look (the brief's list) and covers the rest without a long list. |
| `deleteAllNoUndo` | There's no Undo for this. | Line after the list | 1 | It points at a button people know. Inform, not alarm: no exclamation mark, no "permanently". |
| `deleteAllStays` | Backup files you made stay where you put them. | Line saying backup files are not touched | 2 | The brief's sentence, in plainer words (Cashew: "Drive backups will be kept"). |
| `deleteAllPhoneSafe` | Only hisaab is cleared. Your phone and other apps stay as they are. | Line that answers the fear of wiping the phone | 2 | From Gupta et al.'s fear of "damaging their devices". This is why "Delete" was chosen over "Erase". |
| `deleteAllLastBackup` | reuses `backUpLast` / `backUpToday` | The last-backup line, above *Back up first* | 1 | |
| `deleteAllNoBackup` | Not backed up yet. Back up first to keep a copy. | Last-backup line when there is no backup | 2 | A fact plus a next step. It is not a nag, because this is the moment of risk (Pixel, Goodbudget). |
| `deleteAllBackupOld` | Last backed up {date}. Entries after that aren't in it. | Last-backup line when entries were added after the last backup | 2 | Optional, if the data can tell. It gives a fact, not a warning. |
| `deleteAllBackUpFirst` | Back up first | Key that makes a backup, then returns to this page | 1 | Verb first. On return the line updates and `backUpDone` shows. |

### 6.1 The guard, option A: press and hold (the brief's choice)

| Key | Text | Context / description | Lines | Notes |
|---|---|---|---|---|
| `deleteAllHold` | Hold to delete everything | Label on the destructive key; it fills while pressed and deletes when full | 1 (25 ch) | The instruction and the outcome in one. Never marigold. |
| `deleteAllHoldCaption` | `{seconds, plural, =1{Keep your finger on it for 1 second} other{Keep your finger on it for {seconds} seconds}}` | Caption under the hold key, always visible (also covers reduced motion, where there is no fill) | 1–2 | The research says hold keys fail when the duration isn't shown. "Finger" is plainer than "press". |
| `deleteAllHoldShort` | Keep holding till it fills up. | Shown when the key is let go early; nothing was deleted | 1 | No blame. It doesn't say "bar", which is a glossary word for Today's bar. |
| `deleteAllHoldSpoken` | Delete everything in hisaab | TalkBack label for the hold key | | Makes sense heard alone, with the scope. |
| `deleteAllHoldSpokenHint` | delete everything | `onLongPressHint`: TalkBack says "Double-tap and hold to delete everything" | | Lowercase, because TalkBack puts its own words in front. |
| `deleteAllHoldAction` | Delete everything now | TalkBack custom action on the hold key (Actions menu) | | Deliberate enough as it is. design-interaction decides whether to offer it. |

### 6.2 The guard, option B: type to confirm (alternative)

Recommend **digits, not a word**. A 4-digit number shown on screen is the same on Hindi and English keyboards and tests nothing but care. Typing "DELETE" or "RESET" is a spelling test (case study 23, failure 7).

| Key | Text | Context / description | Lines | Notes |
|---|---|---|---|---|
| `deleteAllTypePrompt` | To delete, type {code} below. | Prompt above the field. `code` is 4 random digits, shown spaced ("4 7 2 1") | 1 | |
| `deleteAllTypeLabel` | Type the number | Field label (TalkBack also reads the prompt) | 1 | Opens the number keyboard. |
| `deleteAllTypeSpoken` | To delete, type the number {code} | TalkBack label for the prompt; `code` is read digit by digit | | |
| `deleteAllTypeButton` | Delete everything | Key, disabled until the number matches | 1 | No error while typing. The key turns on when the number is right. |
| *(fallback if a word is required)* `deleteAllTypeWord` | To delete, type delete below. | Prompt when a word is used instead of digits; the match ignores case | 1 | Not recommended. If used, accept the Hindi "हटाएँ" too, which needs a Hindi ARB first. |

### 6.3 After deleting

| Key | Text | Context / description | Notes |
|---|---|---|---|
| (screen) | *(nothing visible)* | The app opens onboarding step 1 | As the brief says, the fresh first step is the message. |
| `deleteAllDoneSpoken` | Everything deleted. hisaab is starting again. | TalkBack announcement only, sent as the app lands on onboarding | A TalkBack user gets no visual cue that the delete worked, so this fills the gap. |
| `deleteAllFailed` | Couldn't delete. Nothing changed. Try again. | Snackbar if the delete fails and is rolled back; the user stays on the page | The pattern matches `restoreFailed`. |

---

## 7. Privacy lines

**Is "Everything stays on this phone." true now?** Yes, once the build has all three:
1. `android:allowBackup="false"`.
2. `android:dataExtractionRules` excluding everything. Without it, some makers' phone-to-phone transfer still copies the database (case study 23).
3. No `INTERNET` permission in the merged release manifest. **To check:** confirm that adding `file_picker` doesn't add one.

A backup the user saves to Drive does leave the phone, but the user does it, and the Drive app uploads it, not hisaab. The Ask AI export is the same (`askPrivacyNote`: "Nothing leaves your phone until you share it."). So the About line should say so in its second sentence.

| Key | Text | Context / description | Notes |
|---|---|---|---|
| `aboutPrivacy` | Everything stays on this phone. Nothing leaves unless you share it or back it up. | About privacy line (FR-SE-5) | The first sentence is FR-SE-5's own. The second keeps it literally true now that Back up exists, and it echoes `askPrivacyNote`. |
| `incomePrivacy` | *(keep)* What you type stays on this phone. The app never uses the internet. | Onboarding caption (D116) | Still true. hisaab never uses the network; the system picker does any upload. |
| `backUpNoLock` | see §2 | | The brief's "file is not locked" line. |

---

## 8. Checks

- **Banned words:** "transaction", "debit", "credit", "budget period" and "Oops" appear in no proposed string. Also avoided: "corrupt", "invalid", "erase", "reset", "wipe", "export", "JSON", "version", and "saved" about a file.
- **Glossary (SPEC §2):** *Entry*, *Bill*, *Saving* and *Money coming in* are used as defined. **New terms** to add: *Backup* (the file), *Back up* (the act), *Restore*, *Delete everything*.
- **Voice:** no exclamation marks. Every failure says what happened, says "Nothing changed" where data was at stake, and gives a next step. There is no blame: "Couldn't back up there", never "You picked a bad folder".
- **Buttons:** every key names its outcome (*Replace*, *Keep what's here*, *Bring it back*, *Back up first*, *Hold to delete everything*). No "OK", "Yes" or "Cancel".
- **Money:** no amounts in this feature. Counts are entries, as ICU `plural`.
- **ICU:** `restoreConfirmFrom`, `restoreConfirmReplaces` and `deleteAllHoldCaption` use `plural` with `=0`/`=1` where English needs it. Dates are pre-formatted `String` placeholders. No string concatenation: the two dialog lines are separate keys, not glued.
- **Reading level:** the longest sentence is 15 words (`backUpNoLock`, second clause). The hardest words are "backup", "restore" and "password", all loanwords Hindi-first users meet in WhatsApp and UPI. Run the Flesch check on the final ARB values.
- **TalkBack:** the hold key, the onboarding link and the post-delete moment have spoken labels that make sense alone. Every icon in these rows needs a label from design-ui's icon choice (not covered here).

---

## 9. Doc edits to make when this is adopted (not made here)

- **SPEC §2 glossary:** add *Backup* ("One file with everything in hisaab, made by *Back up* and saved where the user picks (BR-16)"), *Restore* and *Delete everything* ("Clears all hisaab data on this phone and opens onboarding; replaces *Reset app*").
- **SPEC FR-SE-5:** the About line becomes `aboutPrivacy`.
- **SPEC FR-SE-4 / BR-16 / E14:** quote `restoreConfirm*`, `restoreNewer`, `deleteAllHold` as the English values, as FR-ON-2 does.
- **UI_DESIGN §8 Voice:** add "Back up (verb) / backup (noun). Never *export* for a backup, *erase* or *reset* for deleting, or *saved* for a file (it means money put in). After a failure that touched data, say *Nothing changed*."
- **DECISIONS:** the brief's row, plus "Group heading *Your hisaab*, not *Your data* ('data' reads as the mobile internet pack)".

## 10. Open questions

1. **Group heading.** Put *Your hisaab* against *Your data* in the case study 23 blind read.
2. **Guard.** Hold (6.1) or typed digits (6.2)? Digits are a cheaper fallback than a typed word if the hallway test fails the hold.
3. **Restore Undo window.** Is a 4 s snackbar enough for a whole-data swap, or add the *Undo restore* row (§4.4)?
4. **`restoreBroken` against `restoreNotBackup`.** Can validation tell "not ours" from "ours but damaged"? If not, ship only `restoreNotBackup`.
