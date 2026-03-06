# Evaluation

## Goal

Evaluate whether the assistant output satisfies user-defined success criteria for each run.

## Method

The evaluator receives:

- full conversation history (user + assistant)
- success criteria text
- latest assistant response

It returns structured feedback:

- `success_criteria_met`: completion gate
- `user_input_needed`: clarification/stuck gate
- `feedback`: retry guidance

## Pass/Retry/Stop Logic

- Pass: if `success_criteria_met == true`, end run.
- Retry: if criteria unmet and no user input needed, loop back to worker with evaluator feedback.
- Stop for clarification: if `user_input_needed == true`, end run and surface the question/blocker.

## What This Enables

- Iterative improvement without user micromanagement.
- Transparent rationale via visible evaluator feedback in chat.
- Better alignment to outcome-focused prompts compared with one-shot outputs.

## Current Gaps

- No benchmark dataset or automated scoring harness yet.
- No token/latency metrics logging in the app UI.
- No adversarial prompt tests for evaluator robustness.

## Suggested Next Evaluation Steps

1. Add fixed task suites and expected outcomes.
2. Track loop count, tool calls, latency, and completion rate.
3. Compare one-shot vs evaluator-loop success rates.
