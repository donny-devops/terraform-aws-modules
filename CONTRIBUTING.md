# Contributing

Thank you for considering contributing to the Terraform AWS Modules collection.

## Development Setup

```bash
git clone https://github.com/donny-devops/terraform-aws-modules.git
cd terraform-aws-modules

# Format and validate
terraform fmt -recursive
terraform validate

# Optional linting
tflint
checkov -d .
```

## Guidelines

- Keep modules small, composable, and secure-by-default.
- Every resource should support a `tags` map.
- Prefer least-privilege IAM, encryption at rest, and private networking.
- Update examples when changing module interfaces.
- Use semantic versioning for releases.

## Pull Requests

1. Branch from `main` (`feat/`, `fix/`, `docs/`, `chore/`).
2. Run `terraform fmt -recursive` and `terraform validate`.
3. Describe the change, any breaking interface updates, and how to test.
4. Open a Pull Request.

By contributing you agree that your contributions are licensed under the MIT License.
