---
name: tdd
description: >
  Enforce strict Test-Driven Development using the Red-Green-Refactor cycle with
  dedicated subagents (tdd-test-writer, tdd-implementer, tdd-refactorer) for
  context isolation. Manual only: run with /tdd <feature>.
disable-model-invocation: true
---

# Test-Driven Development Skill

Enforce strict TDD using Red-Green-Refactor with dedicated subagents. Each phase
runs in an isolated context to prevent "context pollution" — the #1 failure mode
when LLMs attempt TDD.

## Pre-flight check

Before starting any TDD cycle, verify the project is ready:

1. Confirm a test framework is configured and runnable. Run the project's test
   command (e.g. `npm test`, `pytest`, `go test ./...`, `cargo test`) to verify
   it works. If it fails or no test command exists, STOP and tell the user:
   "The project needs a working test setup before TDD can begin. Would you like
   help setting one up?"

2. Ask the user (via the AskUserQuestion tool) to confirm or provide:
   - **Language / runtime** (if not obvious from the project)
   - **Test framework** and the exact command to run a single test file
   - **Test file location convention** (e.g. `__tests__/`, `tests/`, co-located
     `*.test.ts`, `*_test.go`)
   - **Any project-specific testing patterns** they want followed

   If the project has a CLAUDE.md with this information already, skip the
   questions and confirm what you found.

3. Store the answers as context for the subagents in this session.

## Mandatory workflow

Every new feature MUST follow this strict 3-phase cycle. Do NOT skip phases.
Do NOT combine phases. Each phase uses a dedicated subagent for context isolation.

### Phase 1: RED — Write a failing test

```
🔴 RED PHASE: Delegating to tdd-test-writer...
```

Invoke the `tdd-test-writer` subagent with:
- Feature requirement from user request
- Test framework and run command from pre-flight
- Test file location convention

The subagent returns:
- Test file path
- Failure output confirming the test fails
- Summary of what the test verifies

**Gate: Do NOT proceed to Green phase until test failure is confirmed.**

If the test passes immediately, it is not a valid RED test. Ask the user to
clarify the requirement, or have the test writer revise.

### Phase 2: GREEN — Write minimal implementation

```
🟢 GREEN PHASE: Delegating to tdd-implementer...
```

Invoke the `tdd-implementer` subagent with:
- Test file path from RED phase
- Feature requirement context
- Test run command

The subagent returns:
- Files modified
- Success output confirming the test passes
- Implementation summary

**Gate: Do NOT proceed to Refactor phase until the test passes.**

If the implementer modified the test file, FLAG THIS to the user immediately.
This is a TDD violation — the test was committed in RED and must not change
during GREEN.

### Phase 3: REFACTOR — Improve with confidence

```
🔵 REFACTOR PHASE: Delegating to tdd-refactorer...
```

Invoke the `tdd-refactorer` subagent with:
- Test file path
- Implementation files from GREEN phase
- Test run command

The subagent returns either:
- Changes made + test success output, OR
- "No refactoring needed" with reasoning

**Gate: Cycle complete when refactor phase returns with passing tests.**

## Vertical slicing

Work in thin vertical slices. Each TDD cycle should cover ONE behavior:

```
Feature 1, Behavior A: 🔴 → 🟢 → 🔵 ✓
Feature 1, Behavior B: 🔴 → 🟢 → 🔵 ✓
Feature 1, Edge case:  🔴 → 🟢 → 🔵 ✓
```

After each cycle, briefly report what was completed and ask the user if they
want to continue to the next behavior or adjust direction.

## Commit strategy

After each completed 🔴→🟢→🔵 cycle:
- Suggest a descriptive commit message
- If the user agrees, commit the changes

After the RED phase specifically, suggest committing the failing test separately.
This creates a safety net — if GREEN modifies the test, the diff shows it.

## Phase violations — NEVER do these

- Write implementation code before a failing test exists
- Proceed to GREEN without seeing RED fail
- Modify a test during the GREEN phase
- Skip the REFACTOR evaluation
- Start a new behavior's cycle before completing the current one
- Write more than one test at a time in RED (vertical slicing — one test per cycle)
- Generate tests in bulk and then implement (horizontal slicing — this defeats TDD)

## When to use plan mode instead

If the user's request is large or ambiguous, suggest entering Plan Mode first
(Shift+Tab) to break the feature into a list of behaviors before starting TDD
cycles. TDD works best when each cycle has a clear, single behavior to verify.
