# 5.0 Character Ledger

A working Flutter web/Android app based on **Rags - 5.0 Brett Character Sheet**. The Google Sheet is unchanged. Imported data and formulas live in `assets/reference.json`; subsequent character edits live in the app's database.

## Try it

Open this folder in VS Code. In a PowerShell terminal run:

```powershell
.\start.ps1
```

On first launch, choose a DM username and a password of at least 12 characters. Open **http://localhost:8080**, sign in, and use **DM desk** to create player accounts, create characters, or assign the imported Rags character to a player. The DM can view/edit every character; players can only view/edit their own. Account roles and ownership are enforced by the server.

The script uses the Flutter installation set up on this computer. On another computer, install Flutter and put it on PATH. `start.ps1 -Rebuild` rebuilds the web app after changes. Keep its terminal running while playing.

The supplied VS Code configuration keeps Flutter, Gradle, and Android debug state under `Documents/Codex/tools`, including `android-user` for the development keystore. This avoids changing any existing Android signing keys.

**Explore the Rags reference locally** works without signing in. It saves edits in that browser/device only. Those edits are separate from shared characters; use **Rules workshop -> Copy character backup / Restore backup** to transfer editable values explicitly. Clearing browser storage clears local exploration. Signing out preserves the local exploration copy.

## What is included

- Prominent health, defenses, saves, initiative, attacks, reactions, shields, hero points, ability scores, conditions, and skills.
- Searchable class/trade/ancestry features, feats, spellbook with slot checkboxes, equipment descriptions, inventory weights, quick notes, and detailed source-field inspection/editing.
- Calculation engine for the actual sheet's SUM, PRODUCT, IF, OR, INT, FLOOR, QUOTIENT, VLOOKUP, comparisons, arithmetic, concatenation, and cell/range references. All **225 imported formulas** match their imported results. Formula cells and progression tables cannot be overwritten by player edits.
- Server-side authentication with salted PBKDF2 password hashes, expiring opaque sessions, per-character ownership, a DM role, attributed edit history, disk persistence, and revision checks. Conflicting saves are rejected instead of silently overwriting another edit.
- Shared records refresh every 15 seconds while no edit dialog is open. This is polling, not live cursor collaboration. Server edits require a connection; local exploration works separately.

## Preserve the house rules

The app deliberately preserves the spreadsheet's behavior. It is not a generic D&D rules engine. Rags initially has **236/218 HP** because damage taken is **-18**. Strong Ideals currently bypasses the ordinary Will calculation. Luck's temporary modifier is present in the sheet but is not used by its formula. The engine retains these behaviors.

Condition descriptions can include narrative restrictions, resistance, or disadvantage that the sheet doesn't encode numerically. Those descriptions remain available, but the app does not invent numerical effects or spend actions, apply resistance, restore resources, or advance turns automatically. Equipment descriptions likewise do not automatically grant bonuses: edit the same stat inputs used in the original sheet.

The source's redundant closing parentheses in several size formulas are tolerated by the importer. Unsupported formulas report errors rather than silently reusing a stale calculated result. The `IMAGE` formula is presentation-only and its tokenized external artwork is not fetched.

New characters start as **copies of Rags**, with a new name and owner; they are not blank character-builder templates. Complete class/feat/ancestry catalogs were not present in this one reference sheet. Existing choices use its validation lists and progression tables. Some classes have missing progression entries in the original Code tab; changes that cannot calculate are rejected. Supported levels are 1-20.

## Sharing and backups

The default server is private to this computer (`127.0.0.1`). The app is **not published online**. To play from different locations, deploy the Dart server and its web build to a persistent host with HTTPS, a private data volume, and backups. No hosting account or credentials have been configured. For a controlled private network you can bind with `start.ps1 -BindAddress 0.0.0.0`; firewall and trusted HTTPS access still need to be configured for that network. Do not expose the development HTTP server directly to the public internet.

The database is `server/data/campaign.db` (Sembast, an embedded document database). Stop the server before copying this file for a complete backup, including accounts, sessions, characters, and audit history. Keep it private. Character JSON backups contain editable character values only, not accounts or server history. The UI shows the latest 100 events; the database retains all saved events.

Passwords are chosen/issued by the DM in this first version. Self-service password reset, email invitations, account removal, DM reassignment, and managed cloud deployment are not implemented. There is one campaign per server/database. Do not commit its database or credentials to source control.

## Development

```powershell
flutter pub get
flutter test
flutter analyze
dart run tool/check_reference.dart
flutter build web
cd server
dart pub get
dart test
dart analyze
```

The Flutter tests verify imported formula parity, condition dependencies, shield/repeat-attack rules, excess health, and a mobile interaction/persistence flow. Server tests verify authentication, player isolation, DM access, locked formulas, level bounds, audit attribution, concurrent edit rejection, reassignment, and persistence after reopening the database.

Android can use the same server. For an Android emulator, start the server locally and use the supplied VS Code launch configuration, or:

```powershell
flutter run --dart-define=API_BASE=http://10.0.2.2:8080
```

Use `--dart-define=API_BASE=https://your-campaign-host` for release builds and physical devices. Cleartext HTTP is permitted only in the Android debug manifest for emulator development. The APK does not embed a Google account, database secret, or password.

## Attack icons and Quick Notes

Overview shows one selected attack at a time. Each attack has an Attack Variety dropdown (16 red vector glyphs plus Unassigned) and a Damage Type dropdown (ink-gray Bashing, Slashing, and Piercing glyphs). Existing nonstandard damage types remain available. The attack calculation dropdown in Edit Attack still controls the original sheet formulas independently of the visual variety. Variety choices are stored in the character overrides at `Misc!BZ29:BZ34`, previously unused cells; damage types use their original `Main!BD29:BD34` cells. Both follow the same owner/DM permissions, revision checks, audit history, and backups as other edits.

Quick Notes combines the original `Main!B25:B36` notes in order into one multiline parchment editor. Save Notes writes the complete text to `Main!B25` and clears the remaining note cells to prevent duplication. Cancel restores the last saved text. Existing notes are only consolidated when the player saves; the reference asset and original Google Sheet remain unchanged.

## Cardless character sheet

All pages now use warm ivory paper, bundled Libre Baskerville serif type, dark ink, oxblood accents, thin rules, and open stat columns. Overview conditions use a checklist. The equipment map is a connected hooded figure with simple equipment outlines, separate label targets, and no hover tooltips or interior shading. Empty equipment uses a muted outline; the selected slot uses oxblood. The serif font is bundled for web and Android rather than depending on system fonts. Font source: https://github.com/google/fonts/tree/main/ofl/librebaskerville; its SIL Open Font License is included at `assets/fonts/OFL.txt`.

Descriptions in Abilities and expanded Spellbook entries, plus Pack item names, can be clicked and edited in place with explicit Save and Cancel. Quick Notes remains a continuous inline editor. A static dependency audit includes every formula branch and range; calculation-linked fields do not get the new inline editors. Pack weights retain their existing dialog and calculation behavior.

Each ability group has Add Ability; each spell level has Add Spell, removable entries with Undo, and an editable spell-slot count (0-30). Added entries and slot lists live in validated `App!entry_*` / `App!slots_*` character override records. They are independent of the sheet rules and use the same local/server persistence, owner/DM authorization, revisions, history, and character backups. Existing source entries keep their original cell identities. No original Google Sheet or reference asset is changed.

The appearance and code before this redesign are saved at `work/before-cardless-and-inline-editing.zip` in the workspace root. Tests cover inline save/cancel, add/remove/undo, slot-count changes, persisted Pack text, server schema validation and reopening, and unchanged results for all 225 formulas after text edits.

## Light and dark appearance

Dark mode is the default when no appearance preference has been saved. An explicitly saved light-mode choice is restored on future visits. Use the Dark Mode / Light Mode control at the top of the sheet or sign-in page. On phones it is a moon/sun button in the app bar. The preference is saved on this device (`five-zero-dark-mode`); it does not change character data or the DM/player's appearance on other devices. Dark mode uses deep navy paper, ivory ink, muted rose accents, and the same serif typography and thin rules. All custom art, spell category icons, dice, tomes, equipment lines, editors, dialogs, menus, and notes use context-resolved palette roles. Switching appearance preserves open editors and unsaved drafts. Both palettes have tested text/category contrast of at least 4.5:1 against the page background.

## Second video palette trial

Adapted `palette_changes2.mp4` to the current open ledger layout: aqua for nonnegative numeric values, current HP and its progress bar, attack rolls/damage/range/critical details, ability modifiers, and skills; rose for negative values, action controls, and attack-variety glyphs; cooler slate-blue rules. The follow-up trial uses the video's deep navy background (#0C1827), a darker blue sidebar, and subtle blue control surfaces. Ivory text, serif type, spacing, and line weights remain. Light mode uses deeper aqua and rose inks for readable contrast on ivory paper. Colors only: the reference data and formulas are unchanged. The pre-trial source is saved at `C:/Sandbox/Codex_C/palette-review-2/before-video-2.zip`.

## Earlier palette 6 trial

The current appearance uses palette6.png: plum #362F4F backgrounds, violet #5B23FF selected surfaces, lime #E4FF30 actions, and a lighter blue #64B8FF for readable numeric ink on plum. Light mode uses lavender paper, violet controls, and deeper blue ink. Typography, rules, layout, and calculations are unchanged. The preceding palette is backed up at C:/Sandbox/Codex_C/before-palette6.dart.

## Earlier palette 5 trial

Palette5.png replaces the preceding trial: deep blue backgrounds, lemon #FFF83F numeric ink, gold #FFCD54 damage icons, and readable pink #FF85B6 action accents. Light mode uses pale cream paper with blue and deeper pink inks. The previous palette is saved at C:/Sandbox/Codex_C/before-palette5.dart.

## Equipment reference silhouette

The equipment map uses a native vector contour based on dnd_silhouette.png, preserving the hood, stance, clothing, and boots. The backpack, cape, diagonal strap, sword, and hip pouch are removed. A continuous tunic outline replaces the pouch's traced bulge.

All figure pixels belong to exactly one equipment slot. Upper arms select Shoulders, forearms Wrists, gloves Hands, fingers the appropriate Ring, waist Belt, tunic/thighs/knees Legs, and boots Feet. Broad curved forehead and eye bands replace tiny patches. Compound paths preserve holes so small parts do not steal adjacent taps. On phones, Headband, Eye, Neck, Ring I and Ring II have nearby 44px controls; all other slot labels remain below the figure. Tests check dense silhouette coverage, intended anatomy, target sizes and nonoverlap at 300px, empty-slot editing, and accessibility.

## Current palette 3 trial

palette3.png supplies evergreen #091413, forest #285A48, jade #408A71, and mint #B0E4CC. Dark mode uses the exact evergreen background with forest selections, jade rules and mint values. Light mode uses green ivory paper and deeper green inks. Derived green accents preserve tested contrast. Typography, rules, layout conventions, character data and calculations remain intact. The prior palette is saved at C:/Sandbox/Codex_C/before-palette3.dart.


## Direct editing and light palette (October 25)

Light mode uses ivory, ink, and burgundy; the green dark palette remains the default. The appearance control is an icon-only 44 px square. Pack names and weights, skill ranks, and reactions are directly editable with Save/Cancel or Enter. Shield states, shield loss, Strong Ideals, allies ahead, and hero points use inline controls. Skill totals, reaction limits, and carried weight remain calculated; the skill pencil only edits miscellaneous bonuses. The equipment contour has narrower shoulders, lighter upper arms, and softer hips, retaining the shared face, collar, wrist, and boot boundaries.

## Pack quantities and category colors (October 25)

The Pack table occupies half the available desktop content width and uses the full width on smaller screens. Columns are Qty, Item, and Weight each. Quantity is a nonnegative whole number; weight is a nonnegative number with a fixed lb suffix. Capacity and carried weight also show lb. Existing rows default to quantity 1, preserving their previous totals and item names. Carried weight includes quantity times per-item weight without replacing the imported formula. Clearing an item also clears its quantity and weight overrides.

Ability scores use seven distinct pastel category hues with readable light-mode counterparts; INT uses faded blue. Skills inherit their governing ability color for names, ranks, and totals. Attack and damage glyphs have separate category colors, and their painted curve bounds are centered in adjacent 44 px cells.
