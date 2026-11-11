# WPB-27203 investigation — temporary notes

Updated: 2026-11-11. Remove this temporary file before the final implementation PR.

## Objective and tickets

Fix [WPB-27203](https://wearezeta.atlassian.net/browse/WPB-27203),
“[iOS] Last word in message is not rendered in chat bubble”, without reintroducing
[WPB-29736](https://wearezeta.atlassian.net/browse/WPB-29736), the long-message
rendering regression that prompted the previous fix's revert.

## Current checkout

- Worktree: `/Users/christoph/.codex/worktrees/0fb8/wire-ios`.
- Branch: `fix/WPB-27203-fix-list-message-rendering`.
- Base at the time these notes were written: `4e8ec2bee0`, matching the locally
  recorded `github/develop`. No remote fetch was performed for this check.
- The original fix and both revert commits below are ancestors of this HEAD.
- The latest change to `LinkInteractionTextView.swift` is the cherry-picked revert.
- The user pushed the branch to the main repository. Use remote `github`
  (`wireapp/wire-ios`) for future pushes, not `caldrian` (`caldrian/wire-ios`).
  The user may delete that fork later; deletion is not part of this task.
- An existing local modification to `.ruby-version` was present before these
  notes. Leave it untouched and exclude it from this documentation commit.
- No implementation changes or automated tests have been performed in this chat.

## Relevant history

| Change | Commit | PR |
| --- | --- | --- |
| Original fix | `967c56620bed1c8bc05b19bc68477c0078c0be10` | [#5356](https://github.com/wireapp/wire-ios/pull/5356) |
| Revert | `7eb2560568814113cdc2ced0d8391b8def549b93` | [#5502](https://github.com/wireapp/wire-ios/pull/5502) |
| Cherry-picked revert | `1823c8646847fb565c52aeb0b1b1bcfe333bfcd5` | [#5503](https://github.com/wireapp/wire-ios/pull/5503) |

The original fix changed 76 files, including snapshot references, a test file,
project configuration, and AGENTS.md. Reverting the revert would restore its
broader contents, not just the text sizing code. The GitHub CLI could not retrieve
the PR discussion due to network access; the Jira tickets were read in the browser.

## Original bug and reproduction

Send these as **two separate single-line messages**:

```text
1. One two
```

```text
- One two
```

The ticket reports the last word being omitted from the visible bubble. Lists
with two or more items reportedly render correctly. The ticket lists iOS 26.5.2
and records successful QA of the old fix in Playground 4.30.0 (19346).

Initially, both messages rendered fully in the simulator. The assistant visually
verified this on an iPhone SE (3rd generation), iOS 26.5. At that point, the branch
was at `be1e41226e`: it contained the original fix but neither revert, and the
sizing overrides were present in source. This was not a valid reverted baseline.

The user subsequently moved to the same commit as `github/develop` and reported
that the original issue now reproduces. That latest reproduction is user-confirmed;
the assistant has not yet inspected its layout values or captured it visually.

## Regression that caused the revert

WPB-29736 reports that opening a conversation containing a long release changelog
shows blank space in place of the message while reactions remain visible.
Scrolling up reveals the text. It was reported as reproducible every time in
Beta 4.31.0 (19475).

The ticket explicitly connects the revert to PR #5356. A closing comment confirms
the issue stopped appearing in RC 4.31 after the changes were reverted.
Attachments include videos and logs, but these have not been downloaded or
analyzed. The exact triggering changelog has not yet been obtained, and this
regression has not been reproduced locally during this investigation.

## Previous implementation

File: `wire-ios/Wire-iOS/Sources/UserInterface/Components/Views/LinkInteractionTextView.swift`.

The old fix added:

1. A `lastLayoutWidth` property and a `layoutSubviews()` override that invalidates
   intrinsic content size whenever `bounds.width` changes. This invalidation was
   not restricted to list messages.
2. An `intrinsicContentSize` override for attributed text containing a tab, unless
   `textContainer.maximumNumberOfLines` was nonzero. It used
   `NSAttributedString.boundingRect` to calculate natural width and height,
   measuring height at a narrower current bounds width when available, and
   returned rounded-up dimensions.

The explanation recorded in the old code is that list prefixes use explicit tab
stops (`1.\t` or `•\t`), and UITextView underestimates the width needed. Rendering
then wraps the last word onto a second line while the allocated height remains
one line, clipping the word rather than removing it from the message.

**This is a working hypothesis inherited from the old implementation, not an
independently verified root cause.** We still need to compare measured size,
actual text layout, and final bounds in the reproducing build. Likewise, neither
the width invalidation nor boundingRect calculation has been proven to cause the
long-message regression; both need investigation.

## Previous tests and coverage gap

The original PR added
`wire-ios/Wire-iOS Tests/ConversationCell/ConversationTextMessageTableViewSnapshotTests.swift`.
It covered ordered and unordered single-item lists at widths 320, 375, and 414,
plus wrapping plain text at width 320.

The helper created a UITableView and a real message cell adapter, then manually
called `systemLayoutSizeFitting`, assigned the cell frame, laid it out, and took
a snapshot. Despite its description, it did not populate a table view and exercise
initial conversation display, scrolling, or cell reuse. It therefore did not cover
the lifecycle implicated by WPB-29736. Those tests were removed by the revert.

## Findings (2026-11-11, diagnostic test on iPhone SE 3rd gen, iOS 26.5 simulator)

Temporary, uncommitted diagnostic: `Wire-iOS Tests/ConversationCell/WPB27203DiagnosticTests.swift`
(registered in `project.pbxproj` membership exceptions for `Wire-iOS-Tests`; run with
`-testPlan AllTests -only-testing:Wire-iOS-Tests/WPB27203DiagnosticTests`; the
`UnitTests` plan targets `Wire-iOS UnitTests` instead). It hosts real cells in a
`UITableView` with automatic row heights and logs frame, line fragments, and styles.
The snapshot base class fails on 2x simulators, but the logs are still produced.

**Root cause (measured):** UITextView's intrinsic width is `usedRect.width` and ignores
`usedRect.minX`. When *every* line fragment is indented, the frame is too narrow by
that indent; the text rewraps at the narrower width while the height stays as measured,
so the last line is clipped.

- `1. One two` → `"1.\tOne two"`, firstLineHeadIndent 10.17, headIndent/tab 32.83.
  Needed width 96.39; frame 86.5 (= 96.39 − 10.17, rounded to pixel). Line 1 holds
  `"1.\tOne "`, `two` falls out. Same at 320/375/414.
- Two-item lists work because the 1pt blank `\n` between items has indent 0, which
  pulls `usedRect.minX` to 0. Same for a paragraph before the list.
- Also affected: single-paragraph blockquote `> One two` (indent 10) and a long
  wrapping single list item at 320 (last word `labore` lost).
- The 1pt trailing newline appended by `markdown(from:)` for lists is removed by
  `removeTrailingWhitespace()` in message formatting, so that workaround is inert.
- Tabs themselves are not the cause; the old fix's explanation was approximately right
  but the mechanism is the leading indent.

**Experiments (temporary code in `LinkInteractionTextView`):**

- Overriding `sizeThatFits` with the correction has *no* effect on Auto Layout.
- Overriding `intrinsicContentSize` as `super` + minimum paragraph indent (pixel ceil),
  skipped when any paragraph has indent 0, fixes all affected cases (single-item ordered and
  unordered lists, blockquote, long single item at 320/375), and leaves unaffected cases
  unchanged. It does not read `bounds` and does not invalidate in `layoutSubviews`.
- `super.intrinsicContentSize` alternates between the real measurement and a
  `(65536, 20.5)` placeholder; the correction just adds to the placeholder (harmless).

## Implementation status (2026-11-11, uncommitted)

- Fix: `LinkInteractionTextView.intrinsicContentSize` = `super` + smallest paragraph indent
  (pixel ceil); unchanged when any paragraph has indent 0. No `bounds` dependency, no
  `layoutSubviews` override. The dead 1pt trailing newline in `markdown(from:)` was kept:
  labels (system messages) also use that function, so removing it is out of scope.
- Tests: `Wire-iOS Tests/ConversationCell/ConversationTextMessageTableLayoutTests.swift`
  (+ pbxproj membership line, 16 reference images). Real self-sizing `UITableView` in a
  scene-attached window; asserts all characters fit, plus snapshots. Cases: single-item
  ordered/unordered list, blockquote, RTL single item, long wrapping item (320/375/414,
  received + sent), and a reconstructed Android 4.39.0 beta changelog (first display, scroll
  steps, reuse, scroll back, reload; same "top" reference each time).
- Run on iPhone 17 / iOS 26.5 (3x). With fix: 6/6 new tests pass; the existing text
  snapshot suites (67 tests) pass without reference changes. Without fix: all 6 new tests
  fail (e.g. `only "1.\tOne " of "1.\tOne two" fits into (86.3, 22)`), including RTL.
- Harness pitfalls found: reference PNGs are LFS pointers until `git lfs checkout`;
  descriptions/cells hold messages weakly (keep them alive, call `updateMessage`);
  sceneless windows drop tall UITextView content from snapshots.
- Known trade-off: RTL single-item lists get ~10pt extra trailing space in the bubble.
- Not yet done: manual check in the simulator app; PR.

## Agreed direction and next steps

Start from current develop with the revert in place. Use the old fix as a reference
and, if useful, a temporary diagnostic experiment; do not blindly restore the PR.

1. Inspect current text styling, bubble constraints, and self-sizing measurement.
2. Reproduce the short-list failure in a focused test and inspect actual width,
   calculated height, and rendered line layout to establish the root cause.
3. Obtain the triggering changelog if possible; otherwise use a clearly labeled
   synthetic long message containing paragraphs and multiple lists.
4. Cover initial display of a long message, reopening the conversation, scrolling,
   and reuse. A standalone cell snapshot alone is insufficient for this regression.
5. If needed, isolate the old width invalidation and custom measurement changes
   independently to determine how they affect each reproduction.
6. Propose a focused correction, then validate both bugs and relevant existing
   message rendering tests using the repository's test workflow.

No production fix has been chosen yet. Follow AGENTS.md: discuss broad, high-risk,
multi-file, or still-debatable implementation changes before making them.

The assistant should drive the investigation proactively, perform available checks,
and provide exact commands or simulator steps only when user action is needed.
The user should not have to repeatedly ask what happens next.
