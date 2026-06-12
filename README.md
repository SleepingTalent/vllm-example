# Claude Project Template

A starting point for Python projects that use Claude Code with a structured spec-driven development workflow. Drop this template into any new repo to get consistent standards, slash commands, and a repeatable feature-delivery process from idea through to implementation.

---

## What's Included

| Path | Purpose |
|------|---------|
| `CLAUDE.md` | Project-wide instructions Claude follows automatically — coding standards, MCP tool rules, project structure |
| `.claude/commands/` | Slash commands available in Claude Code sessions |
| `.claude/skills/` | The skill logic backing each slash command |
| `.mcp.json.example` | Template for configuring MCP servers (copy to `.mcp.json` and fill in credentials) |

---

## Slash Commands

The template ships with a suite of commands that walk a feature from rough idea to merged code. They are designed to be used in order, though each can also be called independently.

### `/brainstorm-spec`

**When to use:** You have a rough idea but aren't sure how to approach it yet — before writing any spec or code.

Runs a structured dialogue to explore the problem space. Claude asks one focused question at a time, presents 2–4 concrete options at each decision point, and applies YAGNI to keep scope tight. By the end you have a clear, validated design ready to be formalised.

Trigger phrases: *"let's brainstorm"*, *"I have an idea"*, *"help me think through"*, *"what are my options"*

---

### `/create-spec`

**When to use:** You know what you want to build and need a formal written specification before implementation starts.

Generates a structured set of spec documents in `.claude/specs/YYYY-MM-DD-spec-name/`:

- `spec.md` — main requirements document (always created)
- `spec-lite.md` — condensed 1–3 sentence summary for AI context (always created)
- `sub-specs/technical-spec.md` — technical requirements and dependencies (always created)
- `sub-specs/database-schema.md` — schema changes and migrations (only if DB changes needed)
- `sub-specs/api-spec.md` — endpoints, parameters, responses (only if API changes needed)

Trigger phrases: *"create a spec"*, *"write up the spec"*, *"formalise this"*, *"document this feature"*

> Can be called directly from an idea, or as the natural follow-on after `/brainstorm-spec`.

---

### `/create-tasks`

**When to use:** You have an approved spec and want to break it into a concrete, ordered task list before writing any code.

Reads the spec documents and produces a `tasks.md` file in the same spec folder. Tasks are ordered for TDD — tests are defined before implementation. Requires `spec.md` to contain `Status: approved`.

Trigger phrases: *"create tasks"*, *"generate tasks"*, *"break this into tasks"*, *"what do I need to build"*

---

### `/execute-tasks`

**When to use:** You have a `tasks.md` and want Claude to implement the entire spec end-to-end, one task at a time.

Orchestrates the full implementation run: picks up each uncompleted parent task in order, delegates to `/execute-task` for the actual work, runs integration and regression checks between tasks, and calls final quality gates when everything is done. Can be resumed mid-way if a session is interrupted.

Trigger phrases: *"execute all tasks"*, *"implement the spec"*, *"run the tasks"*, *"let's build this"*, *"start implementation"*

---

### `/execute-task`

**When to use:** You want to implement one specific numbered task from `tasks.md` rather than running the whole list.

Works through all subtasks for the given parent task using a TDD workflow — reads the spec for context, writes tests first, implements to make them pass, then marks subtasks complete as it goes. Useful for resuming after a blocker or for implementing tasks selectively.

Trigger phrases: *"execute task 2"*, *"implement task 1"*, *"work on task 3"*

---

## Typical Workflow

```
/brainstorm-spec   # explore and validate the idea
       ↓
/create-spec       # formalise into spec documents
       ↓           # (review and add "Status: approved" to spec.md)
/create-tasks      # break spec into ordered implementation tasks
       ↓           # (review tasks.md before starting)
/execute-tasks     # implement everything, task by task
```

Each step produces a persistent artefact (spec files, tasks.md, committed code) so work can be paused and resumed across sessions without losing context.

---

## Development Standards

See `CLAUDE.md` for the full rules Claude follows in this project. Key points:

- **Package manager:** `uv` only — no `pip`, no `requirements.txt`
- **Python:** 3.11+, type hints, PEP 8, `pathlib.Path`, Pydantic/dataclasses over dicts
- **Tests:** `pytest` in `tests/`, TDD, fixtures in `conftest.py`, run with `uv run pytest`
- **Docker:** multi-stage Dockerfiles, `python:3.11-slim` base, no hardcoded secrets
- **Project layout:** `src/<package>/`, `tests/`, `pyproject.toml` as the single source of truth

---

## MCP Tools

Copy `.mcp.json.example` to `.mcp.json` and configure the servers you need. The tools Claude is required to use:

| Tool | When Claude must use it |
|------|------------------------|
| **Context7** | Before writing any code that uses a third-party library |
| **Fetch** | When a URL or documentation page is referenced |
| **Brave Search** | For current version numbers, release notes, or known issues |
| **Playwright** | Any browser interaction or JS-rendered page |
| **Memory** | Persisting and recalling project decisions across sessions |
| **Docker MCP** | Managing containers, images, volumes, and networks |

---

## Getting Started

1. Copy this template into your new project directory
2. Copy `.mcp.json.example` → `.mcp.json` and fill in your MCP server credentials
3. Open the project in Claude Code
4. Start with `/brainstorm-spec` or jump straight to `/create-spec` if you already know what you're building
