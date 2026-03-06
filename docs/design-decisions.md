# Design Decisions

## Why LangGraph

The task requires explicit control flow (tool use, evaluation, rework). LangGraph provides clear node/edge orchestration rather than implicit agent loops, making behavior easier to reason about and extend.

## Why an Evaluator Loop

A single response pass can fail success criteria even when tools are available. The evaluator provides:

- a binary completion signal
- actionable feedback for retries
- an early stop when user clarification is necessary

This improves reliability for open-ended tasks.

## Why Structured Evaluator Output

`EvaluatorOutput` is a Pydantic schema with:

- `feedback`
- `success_criteria_met`
- `user_input_needed`

Typed outputs reduce brittle parsing and make routing deterministic.

## Why Playwright Tools

Browser automation enables interactions beyond static API calls:

- navigating dynamic websites
- clicking and extracting rendered content
- completing web workflows unavailable via simple HTTP fetch

## Why Gradio + Docker for Demo

Gradio gives a fast interactive interface for agent behavior demonstrations. Docker deployment aligns with Hugging Face Spaces runtime expectations and simplifies reproducibility.

## Tradeoffs

- Current model choice (`gpt-4o-mini`) favors speed/cost over maximal reasoning depth.
- File tools are restricted to `sandbox/`, improving safety but limiting filesystem reach.
- No explicit planner/router node yet; planning is embedded in the worker prompt.
