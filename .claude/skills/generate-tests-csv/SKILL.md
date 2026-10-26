---
name: generate-tests-csv
description: 'Generate test cases for a feature by creating a brand-new CSV on every run. Use when user gives a feature name and wants FE/BE scenarios with fixed headers FE/BE(test case),Pass/FAIL,Team,Feature and consistent remaining column values.'
argument-hint: 'Feature name (example: add-entry)'
user-invocable: true
disable-model-invocation: false
---

# Generate Feature Test CSV

## What This Skill Produces
This skill creates a new CSV test-case file for a given feature on every run.

Output behavior:
- Uses the feature name provided by the user.
- Derives scenarios from either branch changes (git diff) or direct feature inspection, depending on context.
- Always creates a new CSV file (does not overwrite existing test-case files unless explicitly requested).
- Writes fixed headers exactly as: FE/BE(test case),Pass/FAIL,Team,Feature.
- Writes each scenario as one row using the same structure for all rows.
- Keeps remaining column values consistent for all generated rows.
- Covers both happy-path and negative-path scenarios.
- Writes plain test descriptions without prefixes like FE Happy, FE Negative, BE Happy, or BE Negative.

## When To Use
Use this skill when the user asks for:
- test cases from branch changes,
- test cases from a feature directly (with or without committed changes),
- CSV-format FE/BE test descriptions,
- feature-specific happy and negative scenarios,
- a fresh CSV each time with fixed headers.

Typical trigger words:
- test cases, CSV, FE/BE column, branch changes, direct feature analysis, happy path, negative path, feature name.

## Required Inputs
- Feature name (for example: add-entry).
- Optional output directory (default: workspace root).

## Output File Naming
- Default file name pattern: <feature-name>-test-cases.csv.
- If file already exists, create a unique name: <feature-name>-test-cases-2.csv, <feature-name>-test-cases-3.csv, etc.

## Procedure
1. Confirm target scope.
- Identify active workspace/repo.
- Resolve output path for a new CSV file.

2. Choose evidence strategy and inspect the feature.
- Prefer branch-delta mode when the user asks for branch-based cases and meaningful committed/staged changes exist.
- Prefer direct-feature mode when changes are uncommitted, git diff is sparse/noisy, or the user asks to generate cases from the feature directly.
- In branch-delta mode:
	- Check current branch and recent commits.
	- Find changed files and feature-related files using fast search.
- In direct-feature mode:
	- Locate feature folders/files by name and usage.
	- Read implementation, related tests, and docs directly, regardless of commit state.
- Read key implementation and docs to extract behavior in either mode.

3. Build scenario set.
- Build happy-path scenarios from expected success flows.
- Build negative-path scenarios from failures, invalid inputs, missing data, fallbacks, and race conditions.
- Include UI behaviour and data behaviour (persistence, recurring posts, cycle math). Hisaab has no backend: use the FE/BE column for UI vs data/logic scenarios.
- Pull edge cases from `docs/UI_DESIGN.md` (states, copy) and from date/money boundaries (payday on the 31st, zero days left, ₹0, the 9-digit cap).

4. Create the CSV file.
- Write the header row exactly: FE/BE(test case),Pass/FAIL,Team,Feature.
- Add one row per scenario in this format:
	- FE/BE(test case): scenario description
	- Pass/FAIL: true
	- Team: Mobile
	- Feature: provided feature name (or user-provided display label)
- Ensure all rows follow the same comma-separated four-column structure.

5. Validate output quality.
- No FE/BE happy/negative prefixes in descriptions.
- No duplicate scenarios.
- Scenarios are directly traceable to analyzed sources (branch delta or direct feature files).
- Coverage includes at least one fallback and one error-handling case.
- CSV remains valid with consistent commas/columns.

## Decision Logic
- Select evidence mode dynamically:
	- Use branch-delta mode when diff context is relevant and available.
	- Use direct-feature mode when uncommitted work exists, diff context is insufficient, or the user explicitly asks for feature-direct generation.
- If no feature-related changes are found: ask for exact files or commit range.
- If branch-delta mode yields weak context: switch to direct-feature mode instead of blocking.
- If feature name contains spaces/special chars: sanitize only for file name, not for Feature column value.
- If user gives a fixed Feature label different from feature name: use user label in Feature column.
- If feature behavior is ambiguous: prioritize code truth over docs and include conservative negative cases.
- Hisaab has no server: never invent API cases.

## Completion Checklist
- Feature name reflected in scenario relevance.
- New CSV file created for this run.
- Header exactly matches FE/BE(test case),Pass/FAIL,Team,Feature.
- Every row uses the same Pass and Team values and a consistent Feature label.
- Happy and negative coverage included.
- Descriptions are concise, implementation-grounded, and prefix-free.

## Example Prompts
- /generate-tests-csv add-entry
- Create a new CSV test-case file for the day blocks on Home.
- Generate a fresh CSV for recurring income catch-up with fixed headers and same row format.
