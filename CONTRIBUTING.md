# Contributing to Hermes Box

Thank you for considering contributing to **Hermes Box**! We welcome all contributions — bug reports, feature requests, documentation improvements, and code changes.

## How to Contribute

### 1. Reporting Bugs & Feature Requests

- Open a [GitHub Issue](https://github.com/nousresearch/hermes-box/issues)
- Use a clear, descriptive title
- For bugs: include steps to reproduce, expected vs actual behavior, and environment details (OS, Python version, Docker version)
- For features: describe the use case and proposed behavior

### 2. Discuss Before Building

For non-trivial changes, open an issue first to discuss the design. This saves effort and ensures alignment with project goals before you start coding.

### 3. PR Process

1. **Fork** the repository and create a branch from `main`.
2. **Develop** your change with clear, incremental commits.
3. **Test** your changes — run existing tests and add new ones where appropriate.
4. **Keep it focused** — one feature or fix per PR. Avoid unrelated changes.
5. **Open a Pull Request** against the `main` branch.
6. Ensure the PR description explains **what** and **why**.
7. A maintainer will review. Expect discussion and possibly requested changes.
8. Once approved, your PR will be squashed and merged.

### 4. Code Style

- **Python**: Follow [PEP 8](https://peps.python.org/pep-0008/). Use `ruff` for linting.
- **YAML**: 2-space indentation, no trailing whitespace.
- **Shell scripts**: Use `shellcheck` for validation.
- **Commit messages**: Use conventional commits — e.g. `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`.

### 5. Testing

- Run all tests before submitting: `python -m pytest tests/`
- Add unit tests for new logic.
- When applicable, include integration/e2e tests for workflows.
- Ensure existing tests continue to pass.

### 6. Documentation

- Update `docs/` when adding or changing features.
- Update `ARCHITECTURE.md` for structural changes.
- Keep `.env.example` in sync with any new configuration variables.

## Code of Conduct

Be respectful and constructive. Harassment, trolling, and personal attacks will not be tolerated.
