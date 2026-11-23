# WarrantyVault

**WarrantyVault** is a production-quality, personal vehicle battery warranty tracker built in Flutter (Dart). Designed specifically for single-user personal use on Android, it allows you to log every battery installation, monitor warranty expiration, and manage vehicle replacement history.

---

## Features

- **Instant Zero-Login Access**: Opens directly to the Dashboard after the native splash screen. No login screens, sign-up forms, or sign-out buttons. Silent background authentication connects to your private Supabase backend using credentials in `.env`.
- **Offline-First & Background Sync**: Reads from local Hive cache instantly on app launch. Works 100% offline. Offline additions, updates, and deletes are queued and automatically synchronized when an internet connection is restored (conflict resolution: last write wins by `updated_at`).
- **Modern Material 3 UI**:
  - Light mode: Soft grey-blue background (`#F1F5F9`), clean white cards, dark navy text (`#0F172A`), and sky blue accent (`#0284C7`).
  - Dark mode: Near-black navy background (`#0B1220`), slate card surfaces (`#162032`), light text (`#E2E8F0`), and light blue accent (`#38BDF8`).
  - Google Fonts: **Poppins** for headings and **Inter** for body text.
- **Dynamic Dashboard**:
  - 4 Live Stat Cards (Total, Under Warranty, Expiring Soon, Expired) with instant drill-down filters on tap.
  - Interactive Donut Chart (`fl_chart`) showing real-time warranty status distribution.
  - "Expiring Soon" watchlist displaying up to 5 batteries expiring in the next 30 days with days remaining.
- **Search, Sort & Multi-Filter**:
  - Live search debounced at 250ms that searches across normalized vehicle numbers, owner names, and battery companies simultaneously.
  - Filter chips for All, Expiring Soon (≤30 days), Active, Expired, Company multi-select, and custom expiry date ranges.
  - 6 Sort options: Expiry soonest first (default), Expiry latest first, Recently added, Owner name A–Z, Company A–Z, and Vehicle number.
- **Battery Company Smart Autocomplete**:
  - Pre-seeded with top brands: *Exide, Surya, Amaron, Star, Power, AVM, ABM*.
  - Ranked by usage frequency, prefix match, contains match, and fuzzy matching (Levenshtein distance ≤ 2, so typos like `amrn` or `exid` match).
  - Quick `+ Add 'name' as new company` option to register custom brands dynamically.
- **Calendar-Accurate Warranty Expiry**:
  - Expiry date is auto-calculated: `purchase_date + warranty_months`.
  - Accurately clamps to the last day of shorter target months and accounts for leap years (e.g. 31 Aug + 6 months = 28/29 Feb).
- **Vehicle Replacement History**:
  - Multiple batteries can be tracked for the same vehicle over time.
  - Detail screen automatically lists "Previous batteries for this vehicle".
- **Easy Deletion with 5-Second Undo**:
  - Swipe left on list items to delete.
  - Prominent red Delete button on the Detail screen.
  - Red "Delete this entry" button at the bottom of the Edit screen.
  - Every deletion requires confirmation and provides a 5-second Undo action snackbar.
- **CSV Export & Import**:
  - Unobtrusive, muted Export CSV button at the bottom of Dashboard, All Batteries, and Settings screens. Exports all entries and opens the Android share sheet.
  - Import CSV in Settings parses entries, skips duplicates, and recalculates expiry dates automatically.
- **Quick Actions**: One-tap phone dialer for owner and share plain-text warranty details.

---

## Project Structure

```
Warrantyvault/
├── android/                   # Native Android configuration (minSdk 23, com.warrantyvault.app)
├── assets/
│   └── logo/                  # App logo, launcher icon, and splash screen source images
│       ├── logo.png           # Native splash & Dashboard header logo
│       ├── logo.jpeg          # Original uploaded logo
│       └── icon_square.png    # 1024x1024 launcher & adaptive icon source
├── lib/
│   ├── core/
│   │   ├── constants/         # App constants, defaults, asset paths
│   │   ├── routes/            # GoRouter configuration with ShellRoute
│   │   ├── theme/             # Material 3 light & dark themes, Google Fonts
│   │   └── utils/             # Date utils, normalization, Levenshtein fuzzy match, status classification
│   ├── data/
│   │   ├── models/            # Immutable BatteryModel and CompanyModel
│   │   ├── repositories/      # BatteryRepository and CompanyRepository
│   │   └── services/          # HiveService (local cache), SupabaseService, SyncService
│   ├── features/
│   │   ├── dashboard/         # Dashboard screen, stats provider, donut chart
│   │   ├── batteries_list/    # All Batteries list, search, filter chips, sort
│   │   ├── entry_form/        # Add & Edit form with autocomplete & live preview
│   │   ├── detail/            # Battery detail, previous batteries, call/share/delete
│   │   ├── companies/         # Manage companies (add, rename, delete)
│   │   └── settings/          # Theme switcher, Import CSV, app info
│   ├── widgets/               # StatusBadge, WarrantyProgressBar, ExportCsvButton, AppScaffold
│   └── main.dart              # App bootstrap, native splash removal, Hive & Supabase init
├── test/                      # Comprehensive unit tests
│   ├── date_utils_test.dart
│   ├── normalization_test.dart
│   ├── fuzzy_match_test.dart
│   ├── status_utils_test.dart
│   └── dashboard_counts_test.dart
├── .env.example               # Environment variables template
├── supabase_setup.sql         # Supabase database schema, RLS, and triggers
└── pubspec.yaml               # Dependencies and asset configuration
```

---

## Step-by-Step Setup Guide

### Step 1: Create Supabase Project & Run SQL Setup
1. Log in to [Supabase](https://supabase.com/) and create a new project.
2. In the Supabase dashboard, navigate to **SQL Editor** > **New query**.
3. Copy the contents of [`supabase_setup.sql`](supabase_setup.sql) into the editor and click **Run**.
   - This creates the `companies` and `batteries` tables with all required fields, constraints, foreign keys, and indexes.
   - It enables Row-Level Security (RLS) so that rows are only accessible by your authenticated user ID (`auth.uid() = user_id`).
   - It registers a PostgreSQL trigger to update `updated_at` automatically on modification.

### Step 2: Create Single User in Supabase & Disable Public Sign-ups
1. Go to **Authentication** > **Users** in your Supabase dashboard.
2. Click **Add User** > **Create User**.
3. Enter your personal email (e.g., `you@example.com`) and a strong password. Confirm creation.
4. **Disable public registration**:
   - Go to **Authentication** > **Providers** > **Email**.
   - Turn OFF (uncheck) **"Enable Signup"**.
   - Click **Save**. This ensures no other user can create accounts on your private backend.

### Step 3: Configure `.env`
1. Copy `.env.example` to `.env` in the project root:
   ```powershell
   Copy-Item .env.example .env
   ```
2. Open `.env` and fill in your Supabase project details:
   ```env
   # From Supabase Dashboard > Project Settings > API:
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOi...

   # The single user credentials created in Step 2:
   SUPABASE_USER_EMAIL=you@example.com
   SUPABASE_USER_PASSWORD=your-secure-password
   ```
   > **Note:** `.env` is listed in `.gitignore` and is never committed to source control.

### Step 4: App Logo & Icons
The logo files are placed in `assets/logo/`:
- `assets/logo/logo.png`: Native splash image and Dashboard header.
- `assets/logo/icon_square.png`: Square adaptive icon for Android.

To regenerate launcher icons and native splash screens anytime you replace the logo:
```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

### Step 5: Android Release Signing Setup
To generate a release signing keystore on Windows, run the following in PowerShell:
```powershell
keytool -genkey -v -keystore D:\Warrantyvault\android\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias warrantyvault
```
Enter a secure password when prompted.

Create `android/key.properties` with your passwords:
```properties
keyAlias=warrantyvault
keyPassword=your_key_password
storeFile=../upload-keystore.jks
storePassword=your_store_password
```
*(If `android/key.properties` is absent, the Gradle build will automatically use the debug signing key so testing release builds remains seamless).*

### Step 6: Run Tests & Analyze
To run all unit tests:
```bash
flutter test --no-pub
```
To verify lint cleanliness:
```bash
flutter analyze --no-pub
```

### Step 7: Run on Android Emulator or Device
Connect an Android device with USB debugging enabled or launch the emulator:
```bash
flutter run
```

### Step 8: Build the Production Release APK
To compile the release APK:
```bash
flutter build apk --release
```
The generated APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Step 9: Install the APK on Your Android Phone
1. Transfer `app-release.apk` to your phone via USB cable, Google Drive, or local file sharing.
2. Open the file on your Android phone.
3. If prompted with *"For your security, your phone is not allowed to install unknown apps from this source"*, tap **Settings** and toggle **"Allow from this source"**.
4. Tap **Install**.
5. Launch **WarrantyVault**. The app immediately opens to the Dashboard with your logo and full offline/online tracking ready.

---

## Preventing Supabase Free Tier Inactivity Pause

On Supabase's free plan, projects that receive no API traffic for **7 consecutive days** are paused to conserve resources.

### What Happens If It Pauses?
- **Zero data loss**: All your data, tables, indexes, and triggers remain completely intact.
- **Zero app disruption**: WarrantyVault continues running from your local Hive cache with full search, filter, edit, and entry creation capabilities.
- **One-click restore**: Simply open your [Supabase Dashboard](https://supabase.com/dashboard) and click **"Restore Project"**. It restores within 1–2 minutes, and your queued changes sync automatically.

### How to Keep It Active Continuously:
1. **Regular App Use**: Opening the app once a week automatically executes a silent background check, keeping the project active.
2. **Automated Ping via GitHub Actions (Recommended)**:
   You can set up a free, private GitHub Action that sends a `GET` request to your Supabase health check endpoint every 3 days:
   ```yaml
   name: Keep Supabase Alive
   on:
     schedule:
       - cron: '0 8 */3 * *' # Every 3 days at 8:00 AM UTC
     workflow_dispatch:
   jobs:
     ping:
       runs-on: ubuntu-latest
       steps:
         - name: Ping Supabase REST
           run: curl -s "${{ secrets.SUPABASE_URL }}/rest/v1/companies?select=id&limit=1" -H "apikey: ${{ secrets.SUPABASE_ANON_KEY }}"
   ```
3. **Free Uptime Monitor**: Add your Supabase REST endpoint (`https://<project-ref>.supabase.co/rest/v1/`) to a free uptime monitor such as [UptimeRobot](https://uptimerobot.com/) or [Cron-Job.org](https://cron-job.org/) with a header `apikey: <your-anon-key>`.
