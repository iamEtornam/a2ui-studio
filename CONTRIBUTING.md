# Contributing to A2UI Studio

Thank you for your interest in contributing to **A2UI Studio**! Whether you are fixing a bug, adding a new A2UI v1.0 catalog component, improving cross-platform support, or refining documentation, your help is welcome.

## Table of Contents

- [Ways to Contribute](#ways-to-contribute)
- [Development Setup](#development-setup)
- [Project Architecture](#project-architecture)
- [Adding A2UI Catalog Components](#adding-a2ui-catalog-components)
- [Code Quality & Testing](#code-quality--testing)
- [Security Guidelines](#security-guidelines)
- [Pull Request Process](#pull-request-process)
- [License](#license)

---

## Ways to Contribute

- **Report a Bug**: Open an issue on [GitHub Issues](https://github.com/iamEtornam/a2ui-studio/issues) with clear reproduction steps, expected vs. actual behavior, target platform (macOS, Web, iOS, Android), and Flutter/Dart versions (`flutter --version`).
- **Suggest a Feature or Component**: Open an issue describing the use case, proposed UX, and how it fits into A2UI Studio (e.g., new `StudioCatalog` widgets, AI provider integrations, or workspace tools).
- **Submit a Pull Request**: Fork the repository, make your changes on a dedicated branch, and open a PR against `main`.

---

## Development Setup

### Prerequisites

- **Flutter SDK** `3.38+` (Dart `3.14+`)
- Target platform toolchains:
  - **macOS Desktop**: Xcode + CocoaPods
  - **Web**: Chrome
  - **iOS / Android**: Xcode / Android Studio
- An AI backend for testing live generation:
  - **Desktop**: A signed-in local CLI (`agy`, `claude`, `codex`, `gemini`, or `ollama`), or
  - **Any platform**: A [Google Gemini API key](https://aistudio.google.com/apikey)

### Getting Started

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/<your-username>/a2ui-studio.git
   cd a2ui-studio
   ```

2. **Add the upstream remote**
   ```bash
   git remote add upstream https://github.com/iamEtornam/a2ui-studio.git
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   flutter run -d macos   # or -d chrome / mobile device
   ```

---

## Project Architecture

A2UI Studio follows a layered Flutter architecture under `lib/`:

- `lib/domain/models/` — Immutable data models (`AiModelInfo`, `ChatSession`, `InstalledCli`, `MiniApp`, `StudioSettings`).
- `lib/data/services/` — External and platform integrations (`A2uiAiService`, `LocalCliService`, `LocalNotificationService`, `StorageService`).
- `lib/data/repositories/` — `StudioRepository`, the single source of truth for sessions, library items, and settings.
- `lib/ui/core/` — Reusable A2UI runtime (`A2uiSanitizer`, `A2uiSurfaceHost`, `StudioCatalog`), themes (Obsidian Kinetic Dark / Lumen Kinetic Light), and shared widgets.
- `lib/ui/features/` — Feature modules (`chat_sessions`, `workspace`, `library`, `device_preview`, `settings`, `studio`).

Keep UI widgets focused on presentation, business logic in `StudioViewModel` / repositories, and platform I/O behind services with Web-safe stubs where needed.

---

## Adding A2UI Catalog Components

If you are adding a new interactive mini-app component:

1. Define the component schema and builder in `lib/ui/core/a2ui/studio_catalog.dart`.
2. Ensure the component handles missing or malformed properties gracefully and respects both Dark and Light themes.
3. Verify compatibility with `A2uiSanitizer` (`lib/ui/core/a2ui/a2ui_sanitizer.dart`) and the A2UI v1.0 protocol.
4. Add unit/widget tests covering rendering and user interaction.

---

## Code Quality & Testing

Before submitting a pull request, run all checks locally and ensure they pass with zero warnings or errors:

```bash
# Format Dart code
dart format .

# Run static analysis (flutter_lints)
flutter analyze

# Run unit and widget tests
flutter test
```

If your changes affect Web or Desktop platform code, also verify the relevant build succeeds:

```bash
flutter build web
flutter build macos
```

---

## Security Guidelines

Please preserve the project's security invariants in every contribution:

- **Never commit secrets**: Do not commit API keys, signing certificates, or `.env` files.
- **API key handling**: Always pass Gemini API keys in the `x-goog-api-key` HTTP header (never in query parameters), and do not persist API keys to Web `localStorage`.
- **CLI execution**: `LocalCliService` must keep its strict binary allowlist, model identifier validation, and execution timeouts.
- **A2UI sandbox**: Maintain strict A2UI v1.0 sanitization via `A2uiSanitizer` and keep `openUrl` disabled on untrusted surfaces.

If you discover a security vulnerability, please avoid posting exploit details in a public issue and contact the maintainer privately.

---

## Pull Request Process

1. Create a descriptive feature or fix branch from `main`:
   ```bash
   git checkout -b feat/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```
2. Keep commits focused and write clear commit messages.
3. Include tests for new functionality or bug fixes.
4. Update `README.md` or screenshots if you introduce user-facing changes.
5. Open a Pull Request against `main` with:
   - A concise summary of what changed and why.
   - Any related issue numbers (e.g., `Fixes #12`).
   - Screenshots or screen recordings for UI changes.

---

## License

By contributing to A2UI Studio, you agree that your contributions will be licensed under the [MIT License](LICENSE).
