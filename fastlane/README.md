fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios prepare_for_development

```sh
[bundle exec] fastlane ios prepare_for_development
```

Prepare for development

### ios prepare_for_release

```sh
[bundle exec] fastlane ios prepare_for_release
```

Fetch dependencies and prepare for building a release

### ios build

```sh
[bundle exec] fastlane ios build
```

Build for testing

### ios test

```sh
[bundle exec] fastlane ios test
```

Test without building

### ios build_for_release

```sh
[bundle exec] fastlane ios build_for_release
```

Build for release to AppStore or App Center/S3

### ios build_for_release_without_symbols

```sh
[bundle exec] fastlane ios build_for_release_without_symbols
```

Build for release to AppStore without symbols

### ios upload_app_store

```sh
[bundle exec] fastlane ios upload_app_store
```

Upload to AppStore

### ios upload_testflight

```sh
[bundle exec] fastlane ios upload_testflight
```

Upload to TestFlight

### ios create_version

```sh
[bundle exec] fastlane ios create_version
```

Create a new version but not submit for review. Usage: Create release_note.txt in fastlane/metadata/en-US & de-DE folders. Then call $fastlane create_version app_version:X.XX

### ios submit_review

```sh
[bundle exec] fastlane ios submit_review
```

Submit for review with release note. Usage: Create release_note.txt in fastlane/metadata/en-US & de-DE folders. Then call $fastlane submit_review app_version:X.XX

### ios upload_s3

```sh
[bundle exec] fastlane ios upload_s3
```

Upload to S3 (Automation builds)

### ios upload_app_center

```sh
[bundle exec] fastlane ios upload_app_center
```

Upload for internal use

### ios upload_app_center_appstore

```sh
[bundle exec] fastlane ios upload_app_center_appstore
```

Upload dSYMs for AppStore crash tracking

### ios upload_dsyms_datadog

```sh
[bundle exec] fastlane ios upload_dsyms_datadog
```

Upload dsyms to Datadog

### ios security_plans

```sh
[bundle exec] fastlane ios security_plans
```

Run security plans

### ios post_test

```sh
[bundle exec] fastlane ios post_test
```

Run post-test tasks

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
