# Contributing to MobileCI

First off, thank you for considering contributing to MobileCI! Every contribution helps make mobile CI/CD better for everyone.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Getting Started](#getting-started)
- [Template Guidelines](#template-guidelines)
- [Pull Request Process](#pull-request-process)
- [Style Guide](#style-guide)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

- Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md)
- Include the workflow YAML and error logs
- Specify the runner OS and version

### Suggesting Templates

- Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md)
- Describe the use case clearly
- Provide example workflow if possible

### Improving Documentation

- Fix typos or unclear instructions
- Add examples for existing templates
- Improve secrets setup guides

### Adding Templates

- Follow the template structure conventions
- Include all required comments and documentation
- Test on a real project before submitting

## Getting Started

1. **Fork** the repository
2. **Clone** your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/MobileCI.git
   cd MobileCI
   ```
3. **Create a branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Make your changes**
5. **Test your changes** in a real GitHub Actions workflow
6. **Commit** using conventional commits:
   ```bash
   git commit -m "feat(ios): add xcresult parsing step"
   ```
7. **Push** and create a pull request

## Template Guidelines

### Structure

Every workflow template should include:

1. **Header comment** with description, required secrets, and usage
2. **Trigger configuration** with clear defaults
3. **Environment variables** section marked with `CUSTOMIZE` comments
4. **Jobs** with descriptive names
5. **Caching** where applicable
6. **Artifact uploads** for build outputs

### Required Sections

```yaml
# ============================================================================
# Template: [Name]
# Description: [What it does]
# Platform: [iOS/Flutter/React Native/Shared]
# Required Secrets: [List]
# Usage: Copy to .github/workflows/ in your project
# ============================================================================

name: [Descriptive Name]

on:
  # Trigger configuration

# ===== CUSTOMIZE START =====
env:
  # User-configurable variables
# ===== CUSTOMIZE END =====

jobs:
  # Job definitions
```

### Naming Conventions

- File names: `kebab-case.yml`
- Job names: `kebab-case`
- Step names: Descriptive, starting with a verb
- Environment variables: `UPPER_SNAKE_CASE`

### Caching

Always include caching for:
- Package managers (SPM, CocoaPods, Gradle, npm, pub)
- Build artifacts where possible
- Use `actions/cache@v4`

### Error Handling

- Use `continue-on-error` sparingly and only with justification
- Include `timeout-minutes` on long-running jobs
- Upload logs/artifacts on failure using `if: failure()`

## Pull Request Process

1. Fill out the pull request template completely
2. Ensure all templates have proper header comments
3. Update README.md if adding new templates
4. Link any related issues
5. Wait for review from a maintainer

### Review Criteria

- [ ] Template follows the structure guidelines
- [ ] All secrets are documented
- [ ] Caching is implemented
- [ ] Template has been tested on a real project
- [ ] README is updated
- [ ] No hardcoded values (use environment variables)

## Style Guide

### YAML

- 2-space indentation
- Use `>-` for multi-line strings
- Quote strings that could be interpreted as booleans or numbers
- Comment non-obvious steps

### Shell Scripts

- Use `#!/bin/bash` shebang
- Include `set -euo pipefail`
- Quote all variables
- Add usage/help functions
- Include error handling

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(ios): add code signing workflow
fix(flutter): correct pub cache path
docs: update React Native setup guide
chore: update action versions
```

### Scopes

- `ios` — iOS templates
- `flutter` — Flutter templates
- `rn` — React Native templates
- `shared` — Shared templates
- `fastlane` — Fastlane files
- `scripts` — Shell scripts

---

Thank you for contributing! 🚀
