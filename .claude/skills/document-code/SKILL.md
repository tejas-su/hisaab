---
name: document-code
description: Add or improve dartdoc and why-comments across an existing Dart file, class, or folder, following the project's code documentation rules. Use when the user asks to document, add docs/comments to, or review the documentation of Dart/Flutter code.
argument-hint: "File path, class name, or folder to document"
---

Add code-level documentation to: **$ARGUMENTS**

The conventions are in `.claude/rules/code-docs.md`. **Read it first** and apply it exactly; this skill is only the procedure.

Scope: docs *inside Dart files*. Feature-level docs (architecture, flows, behaviour) go in `docs/features/<feature-name>/`; use the `document-feature` skill for those.

## Procedure

1. Read the target file(s) for **$ARGUMENTS**. For a folder, work file by file, starting with the public API (barrel file, pages, blocs, use cases, repositories)
2. List every public class, mixin, enum, extension, typedef, constructor, method, and property
3. Add `///` dartdoc to each one missing it (one sentence minimum, more only when genuinely needed), using the "What to document, by kind" table in the rule
4. Fix existing dartdoc that is wrong, stale, or restates the name
5. Scan for non-obvious logic (workarounds, business rules, timing, `!` unwraps, swallowed errors, `// ignore:`) and add `// why:` comments where they're missing
6. Remove comments the rule forbids (restating code, dividers, commented-out code), but only in the files you were asked to document
7. Make **documentation changes only**: no reformatting, renaming, or refactoring. Any code problems you notice go in the report, not the diff
8. Run `flutter analyze` on the changed files to make sure nothing broke

## Report

- Every symbol documented, grouped by file
- Comments removed or corrected, and why
- Confirm that no logic changed
- Code issues noticed but not fixed (e.g. an un-awaited future in a bloc handler, a swallowed exception)
