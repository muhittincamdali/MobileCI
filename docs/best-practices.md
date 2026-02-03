# CI/CD Best Practices for Mobile Apps

Guidelines and recommendations for efficient, secure, and maintainable mobile CI/CD pipelines.

## Table of Contents

- [Pipeline Design](#pipeline-design)
- [Build Optimization](#build-optimization)
- [Testing Strategy](#testing-strategy)
- [Security](#security)
- [Release Management](#release-management)
- [Monitoring & Observability](#monitoring--observability)
- [Team Workflow](#team-workflow)

---

## Pipeline Design

### Keep Pipelines Fast

**Target build times:**
- PR checks: < 10 minutes
- Full CI: < 20 minutes
- Release builds: < 30 minutes

**Strategies:**

1. **Parallelize independent jobs**
   ```yaml
   jobs:
     lint:
       runs-on: ubuntu-latest
     test:
       runs-on: ubuntu-latest
     build-ios:
       runs-on: macos-14
     build-android:
       runs-on: ubuntu-latest
   ```

2. **Use job dependencies wisely**
   ```yaml
   jobs:
     build:
       # Runs first
     test:
       needs: build  # Waits for build
     deploy:
       needs: [build, test]  # Waits for both
   ```

3. **Fail fast**
   ```yaml
   strategy:
     fail-fast: true  # Stop other jobs on failure
   ```

### Use Caching Effectively

```yaml
- name: Cache dependencies
  uses: actions/cache@v4
  with:
    path: |
      ~/.gradle/caches
      ~/.cocoapods
      node_modules
    key: ${{ runner.os }}-${{ hashFiles('**/lockfiles') }}
    restore-keys: |
      ${{ runner.os }}-
```

**Cache priorities:**
1. Dependency managers (npm, pods, gradle)
2. Build outputs (derived data, build cache)
3. Tool installations

### Design for Reproducibility

1. **Pin versions**
   ```yaml
   env:
     XCODE_VERSION: '15.2'  # Not 'latest'
     FLUTTER_VERSION: '3.16.0'
     NODE_VERSION: '20.10.0'
   ```

2. **Use lockfiles**
   - `package-lock.json` / `yarn.lock`
   - `Podfile.lock`
   - `pubspec.lock`
   - Commit all lockfiles

3. **Avoid mutable references**
   ```yaml
   # Bad
   uses: actions/checkout@main
   
   # Good
   uses: actions/checkout@v4
   ```

---

## Build Optimization

### Incremental Builds

1. **Don't clean unnecessarily**
   ```yaml
   # Only clean when needed
   - name: Clean
     if: github.event.inputs.clean == 'true'
     run: ./gradlew clean
   ```

2. **Use build caches**
   ```groovy
   // Android
   org.gradle.caching=true
   org.gradle.parallel=true
   ```

3. **Cache derived data**
   ```yaml
   - uses: actions/cache@v4
     with:
       path: ~/Library/Developer/Xcode/DerivedData
       key: derived-${{ hashFiles('**/*.xcodeproj') }}
   ```

### Resource Management

1. **Use appropriate runners**
   | Task | Runner |
   |------|--------|
   | Lint/Format | ubuntu-latest |
   | Unit tests | ubuntu-latest |
   | iOS build | macos-14 |
   | Android build | ubuntu-latest |

2. **Clean up artifacts**
   ```yaml
   - name: Clean build artifacts
     if: always()
     run: rm -rf build/
   ```

3. **Limit parallelism**
   ```yaml
   strategy:
     max-parallel: 2  # Don't overload runners
   ```

### App Size Optimization

1. **Enable code shrinking**
   ```groovy
   // Android
   minifyEnabled true
   shrinkResources true
   ```

2. **Use app thinning**
   ```ruby
   # iOS Fastlane
   export_options: { thinning: '<thin-for-all-variants>' }
   ```

3. **Monitor size**
   ```yaml
   - name: Check app size
     run: |
       SIZE=$(du -h build/app.ipa | cut -f1)
       echo "App size: $SIZE"
   ```

---

## Testing Strategy

### Test Pyramid

```
        /\
       /  \     E2E Tests (few, slow)
      /----\
     /      \   Integration Tests
    /--------\
   /          \  Unit Tests (many, fast)
  /------------\
```

### PR Checks (Fast Feedback)

1. Linting and formatting
2. Unit tests
3. Build verification
4. Security scans

```yaml
# Run on every PR
on:
  pull_request:
    types: [opened, synchronize]
```

### Nightly Builds (Comprehensive)

1. Full test suite
2. UI/E2E tests
3. Performance tests
4. Code coverage

```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM daily
```

### Test Best Practices

1. **Deterministic tests**
   - No flaky tests
   - Mock external dependencies
   - Use fixed test data

2. **Meaningful coverage**
   ```yaml
   - name: Check coverage
     run: |
       COVERAGE=$(cat coverage.json | jq '.total')
       if [ "$COVERAGE" -lt 70 ]; then
         echo "Coverage below threshold"
         exit 1
       fi
   ```

3. **Retry flaky tests**
   ```yaml
   run: |
     yarn test --retry 2
   ```

---

## Security

### Secret Management

1. **Never hardcode secrets**
   ```bash
   # Bad
   API_KEY="abc123"
   
   # Good
   API_KEY="${{ secrets.API_KEY }}"
   ```

2. **Rotate secrets regularly**
   - Certificates: Before expiry
   - API keys: Every 90 days
   - Passwords: Every 180 days

3. **Limit secret scope**
   ```yaml
   # Environment-specific secrets
   environment: production
   ```

### Dependency Security

1. **Enable Dependabot**
   ```yaml
   # .github/dependabot.yml
   version: 2
   updates:
     - package-ecosystem: npm
       schedule:
         interval: weekly
   ```

2. **Audit dependencies**
   ```yaml
   - name: Security audit
     run: npm audit --audit-level=high
   ```

3. **Pin dependencies**
   - Use lockfiles
   - Review updates before merging

### Code Scanning

1. **Static analysis**
   ```yaml
   - name: CodeQL Analysis
     uses: github/codeql-action/analyze@v3
   ```

2. **Secret scanning**
   - Enable GitHub secret scanning
   - Use pre-commit hooks

---

## Release Management

### Versioning

Use [Semantic Versioning](https://semver.org):

```
MAJOR.MINOR.PATCH

1.0.0 - Initial release
1.1.0 - New feature (backward compatible)
1.1.1 - Bug fix
2.0.0 - Breaking change
```

### Release Process

1. **Feature branches** → develop
2. **Release branch** → final testing
3. **Main branch** → production
4. **Tags** → trigger deployment

```bash
# Create release
git checkout -b release/1.2.0
# Test, fix bugs
git checkout main
git merge release/1.2.0
git tag v1.2.0
git push origin v1.2.0
```

### Staged Rollouts

1. **Internal testing** (Team)
2. **Alpha** (Internal testers)
3. **Beta** (External testers)
4. **Production** (Staged: 10% → 50% → 100%)

```yaml
inputs:
  rollout_percentage:
    description: 'Rollout percentage'
    default: '10'
```

### Rollback Strategy

1. **Keep previous builds** available
2. **Automate rollback** triggers
3. **Monitor crash rates** post-release

---

## Monitoring & Observability

### Build Metrics

Track these metrics:
- Build duration
- Success rate
- Cache hit rate
- Test coverage
- App size

```yaml
- name: Record metrics
  run: |
    echo "::notice::Build time: $DURATION"
    echo "::notice::App size: $SIZE"
```

### Alerting

```yaml
- name: Notify on failure
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {"text": "Build failed: ${{ github.workflow }}"}
```

### Crash Monitoring

Integrate crash reporting:
- Firebase Crashlytics
- Sentry
- Bugsnag

```yaml
- name: Upload dSYMs
  run: |
    firebase crashlytics:symbols:upload build/dSYMs
```

---

## Team Workflow

### Code Review

1. **Require reviews** for protected branches
2. **Use CODEOWNERS** for automatic assignment
3. **Automate checks** before review

### Documentation

1. **Document pipelines** in README
2. **Keep runbooks** up to date
3. **Comment complex steps**

### On-Call

1. **Define escalation** paths
2. **Document recovery** procedures
3. **Regular training** for team

### Continuous Improvement

1. **Review failed builds** weekly
2. **Track metrics** trends
3. **Update tools** regularly
4. **Gather feedback** from team

---

## Checklist

### PR Pipeline
- [ ] Runs in < 10 minutes
- [ ] Includes lint checks
- [ ] Runs unit tests
- [ ] Builds successfully
- [ ] No security issues

### Release Pipeline
- [ ] Automated version bump
- [ ] All tests pass
- [ ] Code signing works
- [ ] Upload to stores works
- [ ] Notifications configured

### Security
- [ ] No hardcoded secrets
- [ ] Dependencies updated
- [ ] Scanning enabled
- [ ] Access controlled

---

## Related Guides

- [Getting Started](./getting-started.md)
- [Code Signing](./code-signing.md)
- [Troubleshooting](./troubleshooting.md)
