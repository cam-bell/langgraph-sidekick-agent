# Architecture

## Overview

The system is a LangGraph-driven autonomous task agent exposed through a Gradio chat UI.

Core flow:

1. User submits a task plus optional success criteria in `app.py`.
2. `Sidekick.run_superstep()` invokes the compiled LangGraph with task state.
3. Worker agent in `sidekick.py` decides whether to call tools or produce an answer.
4. If tools are needed, `ToolNode` executes and control returns to the worker.
5. Evaluator agent scores the latest worker answer against success criteria.
6. Graph exits when criteria are met or additional user input is required; otherwise loops back.

## Components

- `app.py`: Async Gradio interface and lifecycle management (`setup`, `process_message`, `reset`).
- `sidekick.py`: Graph state definition, nodes, routing logic, memory checkpointing, run orchestration.
- `sidekick_tools.py`: Tool registry combining Playwright browser tools and utility tools.
- `sandbox/`: File tool root for constrained read/write operations.

## Graph Details

Nodes:

- `worker`: LLM bound to tool schemas.
- `tools`: `ToolNode` executor for tool calls.
- `evaluator`: Structured-output LLM validator.

Routing:

- `worker` -> `tools` if tool calls exist.
- `worker` -> `evaluator` if no tool calls.
- `evaluator` -> `worker` if criteria unmet and no user clarification needed.
- `evaluator` -> `END` if criteria met or user input required.

## Runtime Notes

- Browser is launched headless via Playwright and cleaned up by `cleanup()`.
- Session continuity is managed by LangGraph `MemorySaver` and a per-instance `thread_id`.
- Evaluator feedback is fed back into the next worker pass to improve iteration quality.
