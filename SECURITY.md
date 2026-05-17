# Security Policy

## Supported Versions

Security updates are provided for the actively maintained `main` branch and the latest tagged module release.

| Version | Supported |
| --- | --- |
| `main` | Yes |
| latest stable release | Yes |
| older releases | No |

## Reporting a Vulnerability

Please do not open public issues for vulnerabilities in infrastructure modules.

Report privately through GitHub private vulnerability reporting if enabled, or contact the maintainer directly.

Please include:

- affected module or Terraform file
- provider version and Terraform version
- risk summary and affected AWS services
- minimal reproduction steps
- suggested least-privilege mitigation, if available

## Scope

In scope:

- overly broad IAM permissions
- public exposure of private infrastructure
- insecure security group defaults
- unencrypted storage or database resources
- unsafe Terraform state handling guidance
- CI/CD workflow risks affecting infrastructure deployment

Out of scope:

- downstream environment changes outside the module defaults
- account-level AWS misconfiguration not caused by this repository
- denial-of-service issues without a practical exploit path

## Security Expectations

- Do not commit Terraform state files, plans containing secrets, AWS credentials, or private keys.
- Prefer remote encrypted state with locking.
- Use least-privilege IAM policies.
- Prefer GitHub Actions OIDC over long-lived AWS access keys.
- Review module outputs to avoid exposing sensitive values.
