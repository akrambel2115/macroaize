# MacroAize

MacroAize is a Flutter calorie, nutrition, and fitness-tracking application. It helps users log meals, scan food, follow nutrition goals, track workouts and progress, and manage subscriptions across iOS, Android, and web.

## Features

- Meal logging, calorie tracking, macro breakdowns, and nutrition history
- Food scanning, barcode lookup, local food data, and USDA-backed search
- Recipes, personalized goals, weight progress, and workout planning
- Firebase authentication, notifications, remote configuration, and cloud synchronization
- RevenueCat subscription management, promotional codes, and usage limits
- English, French, and Arabic localization

## Project layout

```text
assets/       Application images, fonts, animations, and local database assets
functions/    Firebase Cloud Functions written in TypeScript
lib/          Flutter application source code
  app/        Application initialization and Firebase configuration
  features/   Feature-specific domain, data, and presentation code
  shared/     Shared models, services, utilities, and widgets
  screens/    Screen-level UI, bindings, and controllers
test/         Flutter unit and widget tests
tool/         Developer utilities, including local food database generation
```

## Prerequisites

- Flutter SDK compatible with Dart `>=3.7.2 <4.0.0`
- Firebase CLI, authenticated with a Firebase project, for Cloud Functions work
- Node.js 20 for `functions/`
- Firebase, RevenueCat, Google Sign-In, and Apple Sign-In projects configured for the target platforms

## Local setup

1. Install Flutter dependencies:

   ```bash
   flutter pub get
   ```

2. Create the local client configuration file and fill in the applicable values:

   ```bash
   cp .env.example .env
   ```

   On PowerShell, use `Copy-Item .env.example .env`.

3. Configure Firebase for your own project. The committed Firebase configuration identifies the current project; do not use it to deploy an unrelated environment.

4. Run the application:

   ```bash
   flutter run
   ```

## Cloud Functions

Install dependencies and build the Firebase functions:

```bash
cd functions
npm ci
npm run build
```

For local emulator configuration, copy `functions/.env.example` to `functions/.env` and provide non-secret settings. Configure privileged values with Firebase Secret Manager instead of `.env` files:

```bash
firebase functions:secrets:set GEMINI_API_KEY
firebase functions:secrets:set USDA_API_KEY
firebase functions:secrets:set REVENUECAT_REST_API_KEY
firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET
firebase functions:secrets:set RIP_ENCRYPTION_KEY_V1
```

Use `npm run serve` from `functions/` to start the local Firebase emulator, and `npm run deploy` only after configuring the target Firebase project and its secrets.

## Quality checks

```bash
flutter analyze
flutter test

cd functions
npm run lint
npm run build
```

GitHub Actions runs Flutter analysis and tests for pull requests and changes to `main`.

## Security and public-release notes

- `.env` files, local Firebase emulators, keystores, logs, IDE files, and build outputs are excluded from version control.
- Client SDK keys such as Firebase and RevenueCat public keys are not server secrets. Restrict Firebase API keys and OAuth clients in the Google Cloud and Firebase consoles, and enforce authorization with Firebase rules and Cloud Functions.
- Never commit Firebase service-account keys, RevenueCat REST keys, webhook secrets, Gemini keys, USDA keys, signing keys, or production credentials. If a private key was previously exposed outside this repository, rotate it before publication.
- The repository intentionally contains only the public-facing technical documentation required to set up, run, and contribute to the project.

## Contributing

Keep changes focused, run the relevant quality checks, and use [Conventional Commits](https://www.conventionalcommits.org/) for commit messages.
