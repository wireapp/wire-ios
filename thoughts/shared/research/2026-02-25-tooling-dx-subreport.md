# Research Question
Verify whether current tooling and developer experience around extracted feature packages (`WireMessaging`, `WireAuthentication`, `WireCalling`) address critical architecture pain points: fast/safe module creation, dependency guardrails, deterministic codegen, CI/lint gates for missing wiring, and scalable build performance.

## Summary
- The current setup is **not yet tooling-first for module onboarding**: adding a module requires synchronized manual edits across workspace, schemes, CI path filters, and fastlane framework mapping.
- The monorepo uses **multiple hand-maintained graphs** (SPM manifests, fastlane dependency map, CI filters), but there is no automated consistency check between them.
- There is **no automated architecture guardrail layer** for forbidden edges, cycles, or layering policies beyond what the compiler catches from declared target dependencies.
- Codegen is centralized via `WirePlugins` with pinned binary artifacts (good for version pinning), but plugin behavior introduces hidden conventions and brittleness (notably hardcoded `Strings+Generated.swift` post-processing and target-path sensitivity).
- `WireMessaging` currently has a concrete packaging/tooling break: `swift package describe` fails due target source-path mismatch for `WireMessagingDomainSupport`.
- CI path-filtering and test selection are explicitly enumerated; this makes selective testing fast but creates high maintenance overhead and drift risk when new modules/tooling packages are added.
- `WirePlugins` itself is not represented in PR change filters or fastlane framework mapping, so plugin-only changes lack a dedicated CI trigger path.
- Test registration drift is visible in package schemes/test plans (e.g., `WireCallingUITests` references despite only `WireCallingTests` in manifest), indicating weak guardrails for keeping manifests, schemes, and test plans aligned.
- Build optimization currently focuses on dependency download caches (Carthage/SPM) and selective testing; there is no evidence of generated-project or remote-build tooling (Tuist/XcodeGen/Bazel) adoption.

## Detailed Findings

### 1) Module onboarding DX relies on manual multi-file wiring
- Workspace package visibility is explicit in `wire-ios-mono.xcworkspace/contents.xcworkspacedata`, including the latest packages (`WireAuthentication`, `WireMessaging`, `WireCalling`) and shared tooling package (`WirePlugins`) as direct file refs, which implies manual workspace-level registration for new modules.
- PR test selection is hardcoded by folder and scheme in `.github/workflows/test_pr_changes.yml`; adding a new module requires adding a new filter key/pattern.
- Fastlane test routing uses a hand-maintained list (`Framework.all`) plus a manual name-to-scheme mapping table (`to_scheme`) that must be updated for each new multi-target package.
- The app target still uses explicit package product dependency entries in `wire-ios/Wire-iOS.xcodeproj/project.pbxproj`; integrating a new module into app binaries remains explicit project wiring.
- `setup.sh` and `README.md` focus on environment/bootstrap/build, not package/module scaffolding.

### 2) Dependency guardrails: compile-time only, no policy enforcement
- Package manifests declare intra-package target dependencies, which gives compile-time validation for direct edges.
- No CI workflow step was found that enforces architecture constraints such as forbidden module edges, layered dependency rules, or graph cycle checks at repository level.
- Fastlane’s dependency graph used for selective test expansion is maintained separately from `Package.swift` dependency declarations; no synchronizer/validator was found.
- `test_only_frameworks` maps folder names directly and then dereferences `f.scheme` without compacting unknown entries, which is fragile when filters and framework map drift.

### 3) Codegen integration is centralized but has brittle conventions
- `WirePlugins` pins Sourcery/SwiftGen binaries by URL+checksum, which is good for deterministic tool versions.
- `SourceryPlugin` enforces `sourcery.yml` discovery in three locations and writes generated output into plugin work directory (`DERIVED_SOURCES_DIR`).
- `SwiftGenPlugin` always points to `<target>/.swiftgen.yml` and then unconditionally runs a second prebuild step that edits `Strings+Generated.swift` via `sed`.
- The hardcoded post-step (`Strings+Generated.swift`) is an implicit convention: new modules using SwiftGen with different output names/templates can break unless they follow this exact filename.
- In `WireMessaging`, `WireMessagingDomainSupport` currently resolves to a moved source location under `WireMessagingUI/...`, while manifest target path remains default. CLI validation currently fails:
  - `swift package describe` (run in `WireMessaging`) => `Source files for target WireMessagingDomainSupport should be located under 'Sources/WireMessagingDomainSupport'`.

### 4) CI/lint gates do not fully protect package wiring
- Lint/format workflows run global style checks (`swiftlint`, `swiftformat`) but do not validate modular dependency policy or target graph consistency.
- `.swiftlint.yml` excludes `Package.swift`, so manifest-level boundary rules are not linted.
- CI change detection in `test_pr_changes.yml` omits `WirePlugins`, even though it is foundational for module codegen.
- Test-plan/scheme alignment drift is visible:
  - `WireCalling` manifest defines one test target (`WireCallingTests`), but test plan references both `WireCallingUITests` and `WireCallingTests`.
  - `WireMessaging` manifest defines `WireMessagingTests`, while scheme `WireMessagingAll` includes a `WireMessagingUITests` buildable reference.
- No explicit gate was found that asserts: every package target/test target is represented consistently across `Package.swift`, `.xctestplan`, and workspace scheme files.

### 5) Build performance strategy: selective tests + dependency caching, but high maintenance
- PR pipeline uses path-based selective testing with optional dependency expansion (`test_dependencies`), defaulting to no dependency expansion for normal PRs.
- Caching focuses on dependency retrieval (Carthage + Swift package downloads), not compiled module artifact reuse.
- The strategy is efficient for CI time, but relies on multiple manually curated lists (paths, framework map, scheme map), increasing maintenance friction and risk of under-testing.
- No repository evidence was found for generated project/build-system tooling (Tuist/XcodeGen/Bazel); workflow remains Xcode workspace + fastlane orchestration + manual scheme/files graph.

## Code References
- `WireMessaging/Package.swift:67`
- `WireMessaging/Package.swift:72`
- `WireMessaging/Sources/WireMessagingUI/WireMessagingDomainSupport/Sourcery/sourcery.yml:1`
- `WireAuthentication/Package.swift:43`
- `WireCalling/Package.swift:31`
- `WireCalling/Package.swift:65`
- `WirePlugins/Package.swift:12`
- `WirePlugins/Package.swift:14`
- `WirePlugins/Package.swift:35`
- `WirePlugins/Plugins/SourceryPlugin/SourceryPlugin.swift:53`
- `WirePlugins/Plugins/SourceryPlugin/SourceryPlugin.swift:99`
- `WirePlugins/Plugins/SwiftGenPlugin/SwiftGenPlugin.swift:27`
- `WirePlugins/Plugins/SwiftGenPlugin/SwiftGenPlugin.swift:46`
- `WirePlugins/Plugins/SwiftGenPlugin/SwiftGenPlugin.swift:52`
- `WirePlugins/Plugins/SourceryPlugin/README.md:38`
- `WirePlugins/Plugins/SourceryPlugin/README.md:55`
- `WireMessaging/Sources/WireMessagingUI/.swiftgen.yml:4`
- `WireCalling/Sources/WireCallingUI/.swiftgen.yml:4`
- `.github/workflows/test_pr_changes.yml:33`
- `.github/workflows/test_pr_changes.yml:57`
- `.github/workflows/test_pr_changes.yml:102`
- `.github/workflows/_reusable_run_tests.yml:103`
- `.github/workflows/_reusable_run_tests.yml:147`
- `.github/workflows/_reusable_run_tests.yml:153`
- `fastlane/framework.rb:5`
- `fastlane/framework.rb:143`
- `fastlane/Fastfile:91`
- `fastlane/Fastfile:95`
- `fastlane/Fastfile:97`
- `wire-ios-mono.xcworkspace/contents.xcworkspacedata:203`
- `wire-ios-mono.xcworkspace/contents.xcworkspacedata:227`
- `wire-ios-mono.xcworkspace/contents.xcworkspacedata:236`
- `wire-ios-mono.xcworkspace/xcshareddata/xcschemes/WireMessagingAll.xcscheme:61`
- `wire-ios-mono.xcworkspace/xcshareddata/xcschemes/WireMessagingAll.xcscheme:70`
- `wire-ios-mono.xcworkspace/xcshareddata/xcschemes/WireCallingAll.xcscheme:46`
- `WireCalling/Tests/TestPlans/AllTests.xctestplan:20`
- `WireCalling/Package.swift:65`
- `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:2826`
- `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:2840`
- `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:3018`
- `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:3031`
- `setup.sh:75`
- `setup.sh:127`
- `README.md:53`

## Architecture / Design Insights
- The package extraction concept in recent feature modules is structurally strong (feature-sliced targets, codegen plugins, package-level decomposition), but tooling is still **distributed and implicit** rather than **single-source and enforceable**.
- The primary risk is not package-manager choice, but **graph drift** across four independent control planes:
  - package manifests (`Package.swift`),
  - workspace/schemes (`.xcworkspace` + `.xcscheme` + `.xctestplan`),
  - CI path filters/workflows,
  - fastlane framework/scheme maps.
- Without an architecture policy gate, teams can accidentally preserve compile success while still violating intended modular boundaries or skipping relevant tests.
- Codegen tooling is close to reusable infrastructure, but still has hidden assumptions that reduce discoverability and increase onboarding sharp edges for new modules.

## Suggested Next Step (Detailed Example - Module Lifecycle Automation Harness)
### Build one automation path for create/edit/sync of modules
- Why this pilot:
  - Module onboarding/editing currently requires manual synchronization across workspace refs, CI filters, fastlane framework mapping, schemes, and test plans.
  - Drift in those control planes is already visible in current package/scheme/test-plan state.
  - Evidence:
    - `wire-ios-mono.xcworkspace/contents.xcworkspacedata:206`
    - `.github/workflows/test_pr_changes.yml:33`
    - `fastlane/framework.rb:5`
    - `wire-ios-mono.xcworkspace/xcshareddata/xcschemes/WireCallingAll.xcscheme:46`
    - `WireCalling/Tests/TestPlans/AllTests.xctestplan:20`

### Recommended direction
- Run a time-boxed project-generation decision spike now (Tuist/XcodeGen).
- Prefer generated-project single-source graph if the spike confirms it covers current workflows with acceptable migration cost.
- Keep current stack (SPM + workspace + fastlane + GitHub Actions) with custom automation only if blockers are explicit and documented.

### Proposed harness capabilities
1. `doctor` (read-only consistency validation):
   - checks package/workspace/CI/fastlane/scheme/test-plan consistency,
   - detects missing wiring and drift before merge.
2. `sync` (safe metadata reconciliation):
   - updates CI paths-filter, fastlane framework/scheme map, workspace package refs, and package-level scheme/test-plan stubs from package metadata.
3. `scaffold` (module bootstrap):
   - creates standard package skeleton,
   - generates optional codegen config files (`.swiftgen.yml`, `sourcery.yml`),
   - runs `sync` automatically.

If Tuist/XcodeGen is adopted:
- use project-generation manifests as the primary graph source,
- keep `doctor` as a guardrail layer for CI/test/codegen conventions not covered by generator defaults.

If current stack is kept:
- use full `doctor` + `sync` + `scaffold` harness as the primary anti-drift mechanism.

### Example usage flow
```bash
# validate graph consistency
mise x module-harness doctor

# bootstrap a new feature package
mise x module-harness scaffold --name WireExample --type feature

# synchronize metadata after target changes
mise x module-harness sync --package WireCalling
```

### Immediate first fix inside this pilot
- Fix current `WireMessaging` manifest/source-layout mismatch before enforcing stricter gates:
  - `WireMessaging/Package.swift:67`
  - `WireMessaging/Sources/WireMessagingUI/WireMessagingDomainSupport/Sourcery/sourcery.yml:1`

### Incremental rollout plan
1. Run a 1-2 week Tuist/XcodeGen spike and publish a short decision record (adopt / defer + reasons).
2. Fix current `WireMessaging` manifest/source-layout mismatch.
3. Implement `doctor` and run in CI as non-blocking for one week.
4. If generator adopted: integrate generation into CI and keep `doctor` for non-generator checks.
5. If generator deferred: implement `sync` + `scaffold`, then flip `doctor` to blocking.
6. Add dedicated `WirePlugins` trigger in PR tests so plugin-only changes always run validation.

### Scope note (important)
- This pilot addresses tooling/DX and metadata drift.
- It prioritizes evaluating Tuist/XcodeGen now, but does not force adoption when blockers are material.
- It does **not** replace architecture dependency-direction checks (separate guardrail track).

### Validation gate
- New module creation/edit is doable through one command path without manual CI/fastlane/workspace edits.
- `doctor` reports zero drift on default branch.
- PRs fail fast when module metadata wiring is incomplete.
- Time-to-onboard a module improves versus current manual baseline.

## Related Notes
- `thoughts/shared/research/2026-02-24-public-interface-subreport.md`
- `thoughts/shared/research/2026-02-24-di-container-subreport.md`
- `thoughts/shared/research/2026-02-24-messaging-calling-locality-subreport.md`
- `thoughts/shared/research/2026-02-25-shared-modules-subreport.md`
- `thoughts/shared/research/2026-02-25-data-model-ownership-subreport.md`

## Open Questions / Follow-ups
- Should package metadata (package graph, scheme map, CI filters) be generated from `Package.swift` to remove manual drift points?
- Should `WirePlugins` become a first-class CI trigger with dedicated plugin validation tests?
- Should there be an explicit architecture-check job (forbidden edges/layers/cycles) that runs on every PR, separate from style linting?
- Should SwiftGen plugin post-processing be made template/output aware (instead of hardcoded `Strings+Generated.swift`) to avoid hidden constraints for new modules?
- Should package onboarding include a single scaffold command that creates:
  - package skeleton,
  - default `.swiftgen.yml`/`sourcery.yml`,
  - workspace entry,
  - `*All.xcscheme`,
  - CI `paths-filter` entry,
  - fastlane framework/scheme mapping?
- Should scheme/test-plan consistency be validated automatically against `Package.swift` declared targets?
