# Development Standards

## Package Management
- Always use `uv` as the package manager, never `pip` directly
- Use `pyproject.toml` for all project configuration and dependencies
- Add dependencies with `uv add <package>`, dev dependencies with `uv add --dev <package>`
- Use `uv run` to execute scripts and tools within the project environment
- Never create `requirements.txt` unless explicitly asked — `pyproject.toml` is the source of truth

## Python
- Use Python 3.11+ syntax and type hints throughout
- Follow PEP 8 style conventions
- Use `pathlib.Path` over `os.path`
- Prefer dataclasses or Pydantic models over plain dicts for structured data
- Use context managers (`with`) for file and resource handling
- Always add docstrings to public functions and classes

## Testing
- Use `pytest` for all tests
- Use `pytest-mock` / `unittest.mock` for mocking — never monkeypatch unless necessary
- Place tests in a `tests/` directory mirroring the source structure
- Name test files `test_<module>.py` and test functions `test_<behaviour>`
- Aim for descriptive test names that explain what is being tested and why it should pass
- Use fixtures in `conftest.py` for shared test setup
- Run tests with `uv run pytest`

## Docker
- Use Docker and Docker Compose for all containerised services
- Write multi-stage Dockerfiles to keep images lean
- Use official Python slim base images e.g. `python:3.11-slim`
- Define services in `docker-compose.yml` with explicit named volumes and networks
- Never hardcode secrets in Dockerfiles or compose files — use environment variables
- Always add a `.dockerignore` file

## Project Structure

- Always follow this layout:

    project/
      src/
        <package>/
      tests/
      docker-compose.yml
      Dockerfile
      pyproject.toml
      .env.example
      .dockerignore
      README.md

## MCP Tools — MANDATORY

You have the following MCP tools available. Use them proactively — do not rely on training data when a tool can give you accurate, current information.

---

### Context7 — REQUIRED before writing any code

You MUST use the Context7 MCP tool in the following situations, no exceptions:

- Before writing ANY code that uses a third party library — resolve the library
  docs via Context7 first, then write the code
- When asked about a library's API, methods, or configuration options
- When generating pyproject.toml dependencies — verify current package names
  and versions via Context7
- When writing Dockerfile or docker-compose.yml — check current base image
  tags and syntax via Context7
- When writing pytest, uv, pydantic, fastapi, or any tool configuration

CRITICAL: You are FORBIDDEN from writing code using any third party library
without first calling Context7 MCP to retrieve current documentation.
Never rely on training data alone for library APIs — always verify with Context7
as APIs change between versions and your training data may be outdated.

#### How to use Context7 — follow these steps every time
1. Call `resolve-library-id` with the library name to get the Context7 ID
2. Call `get-library-docs` with that ID to fetch current documentation
3. Only then write the code based on what the docs actually say

---

### Fetch MCP — REQUIRED for any URL or documentation page

- Use the Fetch MCP tool to retrieve any URLs or documentation pages referenced
  in the conversation
- Never summarise a URL from memory — always fetch it first
- Use Fetch to retrieve API documentation, README files, or any external resource
  the user links to before acting on its contents
- When Fetch and Context7 both apply, use Context7 first for library docs, then
  Fetch for any specific URLs the user has provided

---

### Brave Search MCP — REQUIRED for current information

- Use Brave Search when you need current information that may have changed since
  your training data — package versions, release notes, known issues, CVEs
- Use Brave Search before suggesting a solution to a bug or error to check if
  there are known fixes or GitHub issues for it
- Use Brave Search to find the latest Docker base image tags before writing
  Dockerfiles
- Never guess at current version numbers — always search first

---

### Playwright MCP — REQUIRED for browser and UI tasks

- Use Playwright MCP for any task that involves interacting with a web page,
  filling forms, clicking buttons, or scraping content that requires JavaScript
  rendering
- Use Playwright to verify that a web UI works as expected during development
- Use Playwright to run end-to-end tests against a locally running service
- Prefer Playwright over Fetch when the target page requires JavaScript to render

---

### Memory MCP — REQUIRED for persisting project context

- Use Memory MCP to store important project decisions, architecture choices,
  and conventions at the start of a project or when they are established
- At the start of each session, retrieve stored memories relevant to the current
  task before proceeding
- Store the following types of information in Memory:
  - Project architecture decisions and the reasoning behind them
  - Agreed naming conventions or patterns specific to this project
  - Known issues, workarounds, or technical debt that should be remembered
  - Key environment variables, service names, or configuration values
- When the user says "remember this" or "don't forget", always write it to Memory
- Before asking the user to re-explain project context, check Memory first

---

### Docker MCP — for Docker management tasks

- Use Docker MCP for interacting with Docker containers, images, volumes, and networks
- Prefer Docker MCP over raw `docker` CLI commands when managing container state

---

### MCP Tool Selection Guide

| Situation | Tool to use |
|-----------|-------------|
| Writing code with a library | Context7 first |
| User provides a URL | Fetch |
| Need current version or release info | Brave Search |
| Browser interaction or JS-rendered page | Playwright |
| Recalling project decisions | Memory |
| Checking for known bugs or fixes | Brave Search |
| End-to-end UI testing | Playwright |
| Storing a project decision | Memory |
| Managing Docker containers/images | Docker MCP |
