# Contributing to Highball

Thanks for your interest in contributing to Highball! This document explains how to contribute.

## Getting Started

1. **Fork the repository** and clone it locally
2. **Install dependencies**:
   - Xcode 15+
   - [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
3. **Generate the Xcode project**: `xcodegen generate`
4. **Open and build**: `open Highball.xcodeproj`

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/padaron/highball/issues) to avoid duplicates
2. Use the **Bug Report** template
3. Include:
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable
   - macOS version

### Requesting Features

1. Check [existing issues](https://github.com/padaron/highball/issues) first
2. Use the **Feature Request** template
3. Explain the problem you're solving
4. Describe your proposed solution

### Submitting Code

#### 1. Find or Create an Issue

Every code change needs an issue. Comment on the issue to let others know you're working on it.

Look for issues labeled `good-first-issue` if you're new to the project.

#### 2. Create a Branch

```bash
git checkout main
git pull
git checkout -b fix/42-description  # or feat/42-description
```

Branch naming:
- `fix/<issue>-<description>` for bugs
- `feat/<issue>-<description>` for features
- `refactor/<issue>-<description>` for refactors
- `chore/<issue>-<description>` for maintenance

#### 3. Make Your Changes

- Follow existing code style
- Keep changes focused on the issue
- Test your changes manually

#### 4. Commit with Conventional Commits

```bash
git commit -m "fix(api): handle rate limit responses (#42)"
```

Format: `<type>(<scope>): <description> (#issue)`

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

#### 5. Push and Create a PR

```bash
git push -u origin fix/42-description
gh pr create --fill
```

In your PR description:
- Summarize what changed
- Reference the issue with `Closes #42`
- List any testing you did

#### 6. Address Review Feedback

Make requested changes, push new commits. Once approved, a maintainer will merge.

## Code Style

- **Swift**: Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- **SwiftUI**: Use declarative patterns, keep views small
- **Naming**: Clear, descriptive names over comments

## Project Structure

```
Highball/
├── Models/          # Data types
├── Services/        # API, state management
├── Views/           # SwiftUI views
└── HighballApp.swift
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed architecture.

## Questions?

Open an issue with your question, or check existing issues for answers.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
