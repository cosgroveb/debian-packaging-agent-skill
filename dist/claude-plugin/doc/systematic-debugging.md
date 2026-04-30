# Systematic debugging process

YOU MUST ALWAYS find the root cause of any issue you are debugging.
YOU MUST NEVER fix a symptom or add a workaround instead of finding a root cause, even if it is faster or the user seems like they're in a hurry.

YOU MUST follow this debugging framework for ANY technical issue:

## Phase 1: Root cause investigation (BEFORE attempting fixes)
- **Read Error Messages Carefully**: Don't skip past errors or warnings - they often contain the exact solution
- **Reproduce Consistently**: Confirm you can reliably reproduce the issue before investigating
- **Check Recent Changes**: What changed that could have caused this? Git diff, recent commits, etc.

## Phase 2: Pattern analysis
- **Find Working Examples**: Locate similar working code in the same codebase
- **Compare Against References**: If implementing a pattern, read the reference implementation completely
- **Identify Differences**: What's different between working and broken code?
- **Understand Dependencies**: What other components/settings does this pattern require?

## Phase 3: Hypothesis and testing
1. **Form Single Hypothesis**: What do you think is the root cause? State it clearly
2. **Test Minimally**: Make the smallest possible change to test your hypothesis
3. **Verify Before Continuing**: Did your test work? If not, form new hypothesis - don't add more fixes
4. **When You Don't Know**: Say "I don't understand X" rather than pretending to know

## Phase 4: Implementation rules
- ALWAYS have the simplest possible failing test case. If there's no test framework, it's ok to write a one-off test script.
- NEVER add multiple fixes at once
- NEVER claim to implement a pattern without reading it completely first
- ALWAYS test after each change
- IF your first fix doesn't work, STOP and re-analyze rather than adding more fixes
