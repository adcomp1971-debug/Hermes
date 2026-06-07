# Security Policy

## Reporting a Vulnerability

We take the security of **Hermes Box** seriously. If you discover a security vulnerability, **please do not open a public GitHub issue**. Instead, report it privately.

### How to Report

- **Email**: security@nousresearch.com
- **Alternative**: Contact the maintainers directly via the [Nous Research Discord](https://discord.gg/nousresearch) in a private channel.

Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested mitigation (if known)

## Response Timeline

- **Acknowledgment**: Within 48 hours of your report.
- **Triage and investigation**: Usually within 5 business days.
- **Fix deployment**: Depends on severity — critical issues are prioritized and patched within days.
- **Public disclosure**: Coordinated with the reporter; typically after a fix is released.

## Security Practices

- **Secrets management**: All sensitive configuration (API keys, tokens) must be set via environment variables or a `.env` file. Never commit secrets to the repository.
- **Input validation**: User-supplied input is sanitized and validated to prevent injection attacks.
- **Dependencies**: Regularly updated and scanned for known vulnerabilities via automated tooling.
- **Least privilege**: The Hermes Box container runs with the minimum set of capabilities required. Review `docker-compose.yml` for specifics.
- **Network isolation**: Tailscale integration is optional; when enabled, the service is only accessible over your private Tailnet.

## Responsible Disclosure

We request that you:
1. Give us a reasonable time to fix the issue before public disclosure.
2. Do not exploit the vulnerability beyond what is necessary to demonstrate it.
3. Act in good faith — we will not pursue legal action against researchers who follow this policy.

## Supported Versions

| Version | Supported          |
|---------|---------------------|
| latest  | ✅ Fully supported  |
| < 1.0   | ⚠️ Pre-release only |

Thank you for helping keep Hermes Box and its users safe.
