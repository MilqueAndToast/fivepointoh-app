# Hosted browser edition

[Open 5.0 Character Ledger](https://milqueandtoast.github.io/fivepointoh-app/).

The app and GitHub source are public. This is a live, editable browser edition: edits, appearance, and history persist in browser storage. They are independent of the localhost preview and of other devices. Use Copy Backup and Workshop's Restore Backup to transfer characters. Clearing browser storage removes that browser's copy.

The hosted build opens directly into the sheet and hides campaign sign-in controls. It uses the same character calculations, equipment map, editors, and themes. No campaign server, accounts, or shared database are deployed. The normal Flutter build and Android version retain campaign-server support.

## Build

Using the Flutter SDK on PATH:

```powershell
.\tool\build_browser.ps1
```

This creates a release build in `dist/` with `BROWSER_LOCAL_ONLY=true`, bundled renderer assets, no source maps, and no generated offline service worker. The output is ignored by Git. The default base path is `/` for local testing. To match GitHub Pages, pass `-BaseHref '/fivepointoh-app/'`.

## Publish updates

Push changes to `main`. The [Publish browser app workflow](../.github/workflows/pages.yml) installs Flutter 3.47.7, runs analysis and tests, builds with the GitHub Pages base path, and deploys the artifact. Failed checks prevent deployment. You can also run the workflow manually in GitHub Actions. The repository website field and README link point to the published app.

The repository was made public with the owner's approval to enable GitHub Pages on the current plan. The campaign database and credentials remain excluded from Git. No shared server or paid hosting service has been provisioned.

## Checks

```powershell
flutter test
flutter test --dart-define=BROWSER_LOCAL_ONLY=true test/browser_local_test.dart
flutter analyze
```

The hosted-mode test covers automatic entry, restored character values, editing and saving, and the phone layout without campaign login controls.
