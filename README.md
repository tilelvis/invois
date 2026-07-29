# Invois

A local-first invoicing app for Kenyan contractors, tradespeople, and informal-sector
businesses — built with Flutter. Create KRA-VAT-compliant invoices, take payment over
M-Pesa (Till or Paybill), and keep every invoice, client, and payment status on-device.

## Features

**Invoice creation** — a guided 3-step wizard:
1. **Client** — name, Kenyan phone number (validated for `07...`, `01...`, `+254...`),
   optional KRA PIN and email
2. **Payment** — M-Pesa Till or Paybill setup, with account name/number for Paybills
3. **Billing** — line items split into Labor vs. Materials, each with its own KRA VAT
   category (Exempt / Zero-Rated / Standard 16%), plus a live running total

**Dashboard** — collected vs. outstanding revenue, paid/unpaid/overdue counts, and a
6-month revenue chart.

**Invoices** — searchable, filterable (All / Unpaid / Paid / Overdue) list. Swipe right
to toggle paid, swipe left to delete (with Undo), long-press for a quick-actions sheet,
tap through to a full detail view with an issued → due → paid timeline.

**Clients** — automatically built from saved invoices; billing totals and unpaid counts
per client, tap through to their full invoice history.

**Payments** — a Lipa na M-Pesa STK Push simulation (initiate → client PIN entry →
confirmation) that marks the invoice eTIMS-validated on completion.

**Sharing** — export any invoice as a PDF, or share a formatted summary straight to
WhatsApp.

**Settings** — dark mode (persisted), current app version, and a manual "check for
updates" action.

**Update notifications without the Play Store** — every push to `main` publishes a
tagged GitHub Release with the signed APK attached (watch the repo with "Releases"
notifications to get pinged), and the app itself shows an in-app banner when a newer
build is available.

## Tech stack

- **Flutter** / Dart, [Riverpod](https://riverpod.dev/) for state management
- **Isar** for local, offline-first storage — no account, no server, no internet
  required for day-to-day use
- **pdf** / **printing** for invoice PDF generation
- **fl_chart** for the dashboard revenue chart
- **share_plus**, **url_launcher**, **shared_preferences**, **package_info_plus**,
  **dynamic_color** (Material You theming on Android 12+), **shimmer** (loading
  skeletons)

## Getting started

```bash
flutter pub get
flutter run
```

To build a release APK locally:
```bash
flutter build apk --release
```

## Release signing (required for updates to install cleanly)

By default, release builds fall back to Flutter's debug signing key, which changes on
every machine/CI runner and causes "package conflicts" when installing a new build over
an old one. See **[`android/SIGNING.md`](android/SIGNING.md)** for how to generate a
permanent keystore and wire it into both local builds and GitHub Actions via repository
secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`).

## CI/CD

`.github/workflows/build-apk.yml` runs on every push to `main` (or manually via
`workflow_dispatch`) and:
1. Builds a signed release APK, auto-versioning `versionCode` from the GitHub Actions
   run number so it always increases
2. Uploads the APK as a workflow artifact
3. Publishes a tagged GitHub Release (`vX.Y.Z-buildN`) with the APK attached

## Project structure

```
lib/
  models/       Invoice, Client, PaymentDetails, InvoiceItem, enums
  providers/    Riverpod state (draft invoice, saved invoices list, theme)
  services/     Isar storage, PDF generation, GitHub update checks
  views/        Dashboard, Invoices, New (wizard), Clients, Settings
  widgets/      Shared UI: stepper, status badges, empty states, action sheets, etc.
test/           Unit and widget tests
android/        Native Android project + signing docs
```
