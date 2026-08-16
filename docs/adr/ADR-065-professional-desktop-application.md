# ADR-065 — Professional Desktop Application

## Status

Accepted.

## Context

The certified FLCAD Reverse AI platform requires a definitive Windows desktop shell. The shell must integrate, but never change, engineering modules G-001 through G-012.

## Decision

The official product is **FLCAD Reverse AI**, subtitle **Engineering Intelligence Platform**, version **0.9.1 Alpha**, by **FLCAD MODEL**. Desktop presentation is isolated under `lib/app/desktop`; it initializes the existing application bootstrap but neither imports nor modifies certified engineering APIs.

Startup validates assets through `DesktopAssetManager`, initializes the project and engineering services, loads `settings.json`, and presents a restrained seven-stage splash sequence lasting approximately two seconds. The First Run Wizard captures language, light/dark theme and default directory, then records completion so it does not run again.

The Home Dashboard owns project entry points, import entry points, recent projects, settings and optional engineering tips. The definitive workspace is a reusable five-region shell: Explorer, Viewport, Property Inspector, Engineering Assistant and Status Bar. Its module selector exposes AI Engineering, Recognition, Primitive Intelligence, Engineering Features, Smart References, Reconstruction Strategy, Interactive Assistant and Engineering Knowledge without changing their behavior.

All UI colors derive from `ThemeData` and `ColorScheme`. Branding assets are referenced only through the official Asset Manager; absolute runtime asset paths are prohibited. Settings persist as JSON in the application-support configuration directory.

The Windows runner publishes product/company/version/copyright metadata, the official icon and a 1440×900 initial window. CMake emits `FLCAD Reverse AI.exe` and prepares sibling `assets`, `runtime`, `config`, `plugins` and `OpenCascade` directories for future installation.

## Branding

The mark visualizes a triangular scanned mesh transforming into a smooth CAD surface. The palette uses deep navy, cobalt and electric cyan. Typography uses the native professional Segoe UI family, avoiding a bundled-font licensing dependency.

## Consequences

Future desktop changes must preserve the shell regions, reusable components, Asset Manager, Theme Manager and settings contract. Engineering algorithms, DNA, playbooks, references, recognition and knowledge behavior remain outside this ADR and unchanged by B-001B.
