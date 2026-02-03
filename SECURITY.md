# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security seriously. CI/CD systems handle sensitive credentials and deployment pipelines.

### How to Report

1. **Do NOT** open a public issue
2. Email details to the repository owner
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 7 days
- **Resolution Timeline**: Depends on severity
  - Critical: 24-48 hours
  - High: 7 days
  - Medium: 30 days
  - Low: 90 days

### Disclosure Policy

- We follow responsible disclosure
- Credit will be given to reporters (unless anonymity is requested)
- Please allow reasonable time for fixes before public disclosure

## Security Best Practices

When using these templates:

1. **Never commit secrets** - Use GitHub Secrets or environment variables
2. **Use least privilege** - Grant only necessary permissions
3. **Rotate credentials** - Regularly update API keys and certificates
4. **Audit access** - Review who has repository access
5. **Enable branch protection** - Require PR reviews for sensitive branches
6. **Use Dependabot** - Keep dependencies updated
7. **Review workflow changes** - PRs modifying workflows need extra scrutiny

## CI/CD Security Checklist

- [ ] All secrets stored in GitHub Secrets
- [ ] No hardcoded credentials in workflows
- [ ] Branch protection enabled on main
- [ ] PR reviews required
- [ ] CODEOWNERS file configured
- [ ] Dependabot enabled
- [ ] Workflow permissions minimized

## Contact

For security concerns, contact the maintainer through GitHub.

---

Thank you for helping keep this project secure! 🔒
