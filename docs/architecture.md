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

Core runtime files:

- `app.py`: Gradio interface and async lifecycle (`setup`, `process_message`, `reset`).
- `sidekick.py`: `Sidekick` orchestration, `StateGraph` build, routing, `MemorySaver`, evaluator loop.
- `sidekick_tools.py`: Playwright toolkit + search/wiki/python/file + Pushover notification tool.

## System Architecture

```mermaid
flowchart TD
    U["User"] --> UI["Gradio UI (app.py)"]
    UI --> RS["run_superstep() (sidekick.py)"]
    RS --> SG["StateGraph + routing"]

    subgraph GRAPH["LangGraph Execution"]
      W["Worker (LLM + tools binding)"]
      T["ToolNode executor"]
      E["Evaluator (structured output)"]
    end

    SG --> W
    W -->|tool calls| T
    T --> W
    W -->|candidate response| E
    E -->|criteria unmet| W
    E -->|criteria met / user input needed| UI

    RS --- MEM["MemorySaver checkpoint"]

    T --> TOOL_LAYER["Tool Registry (sidekick_tools.py)"]
    TOOL_LAYER --> PLAY["Playwright Chromium automation"]
    TOOL_LAYER --> SEARCH["Serper web search"]
    TOOL_LAYER --> WIKI["Wikipedia lookup"]
    TOOL_LAYER --> PY["Python REPL"]
    TOOL_LAYER --> FILES["File tools rooted at sandbox/"]
    TOOL_LAYER --> PUSH["Pushover API notifications"]
```

## Data Flow

```mermaid
flowchart TD
    A["User enters prompt + success criteria in app.py"] --> B["process_message()"]
    B --> C["Sidekick.run_superstep()"]
    C --> D["Initialize graph state\nmessages, criteria, flags"]
    D --> E["Invoke compiled StateGraph (ainvoke)"]
    E --> F["Worker node executes"]

    F --> G{"Worker produced tool_calls?"}
    G -- "Yes" --> H["ToolNode runs selected tools"]
    H --> F
    G -- "No" --> I["Evaluator node executes"]

    I --> J{"success_criteria_met OR user_input_needed?"}
    J -- "No" --> K["Attach evaluator feedback_on_work"]
    K --> F
    J -- "Yes" --> L["End graph execution"]

    L --> M["Return payload to UI:\nuser message\nassistant response\nevaluator feedback"]
    M --> N["Rendered in Gradio Chatbot"]
```

## Services

```mermaid
flowchart LR
    subgraph INTERNAL["Internal Services"]
      UI["Gradio app runtime"]
      ORCH["LangGraph orchestration (sidekick.py)"]
      MEM["MemorySaver checkpointing"]
    end

    subgraph TOOLING["Tool Services (sidekick_tools.py)"]
      BROWSER["Playwright Chromium"]
      SERPER["Serper search wrapper"]
      WIKI["Wikipedia API wrapper"]
      REPL["Python REPL tool"]
      FM["File management (sandbox/)"]
    end

    subgraph EXTERNAL["Notification Service"]
      PUSH["Pushover API"]
    end

    UI --> ORCH
    ORCH --> MEM
    ORCH --> BROWSER
    ORCH --> SERPER
    ORCH --> WIKI
    ORCH --> REPL
    ORCH --> FM
    ORCH --> PUSH
```

## Components

- `app.py`: Async UI boundary and user interaction handling.
- `sidekick.py`: Graph state definition, nodes: worker/tool/evaluator loop, routing logic, memory checkpointing, run orchestration.
- `sidekick_tools.py`: Centralized tool loading for browser actions (Playwright browser), retrieval, computation, files, and notifications.
- `sandbox/`: Explicit root directory for file management tools (read/write operations)

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

- Playwright Chromium launches headless during setup and is cleaned up on reset/exit by `cleanup()`..
- Session continuity is managed through LangGraph `MemorySaver` with per-instance `thread_id`.
- Evaluator output (`feedback`, `success_criteria_met`, `user_input_needed`) controls graph termination and retry behavior. The Evaluator feedback is fed back into the next worker pass to improve iteration quality.
