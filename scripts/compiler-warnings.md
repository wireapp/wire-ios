# Compiler warnings on pull requests

The reusable sequential and parallel test workflows collect compiler warnings
from Fastlane's raw `build/*.log` (or `fastlane/build/*.log`) files after tests,
including when tests fail. The reporter uses Ruby's standard library only.

All warnings with a source location in a Git-tracked repository file are
published, including warnings outside the PR's changed lines. Repeated warnings
from multiple targets or architectures are deduplicated by path, line, column,
and message. Dependencies and generated files that are not tracked in Git are
excluded. Warnings without source locations are recorded separately in the report
because they cannot be attached to a source line.

Each test job creates a check on the actual checked-out build revision. Annotations
are appended in batches of 50 using the Checks API, so hundreds of warnings are
not truncated by Actions' per-step annotation limit. Parallel batches have distinct
check names. The check succeeds even when warnings exist; it does not introduce a
new merge requirement. A run with no current build logs gets a neutral check
explaining that collection was unavailable.

The `compiler-warnings-*` artifact contains the complete JSON report, including
repository annotations, warnings without source locations, log names, and the
built revision. The artifact is uploaded even when API publishing fails. Publishing
is best effort and does not change the test job result. Fork PRs save the report
but skip publishing because their tokens do not have check write permissions.

A start marker excludes old logs left on persistent runners. Incremental builds
only report diagnostics actually emitted in that run; this is not an inventory of
warnings in files the compiler did not rebuild. Warnings that lack a standard
`file:line:column: warning: message` (or `file:line: warning: message`) location
cannot be annotated. This does not change the existing lint or formatting checks.

## Local use

From the repository root:

```sh
ruby scripts/annotate_compiler_warnings.rb --start
# Run the normal Fastlane build/tests.
ruby scripts/annotate_compiler_warnings.rb
```

Inspect `build/compiler-warnings.json`. No network request is made unless
`--publish` is supplied. Publishing expects the standard GitHub Actions environment
and `GH_TOKEN` with `checks: write` permission. Avoid retrying individual append
requests: a response lost after GitHub accepted it could otherwise duplicate
annotations. A workflow rerun creates a new check.

Run offline tests, including a 327-warning batching case:

```sh
ruby scripts/tests/annotate_compiler_warnings_test.rb
```
