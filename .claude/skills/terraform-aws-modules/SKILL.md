```markdown
# terraform-aws-modules Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill covers the development patterns and conventions used in the `terraform-aws-modules` repository, which is written in TypeScript. It outlines file naming, import/export styles, commit message conventions, and testing patterns. This guide is designed to help contributors write consistent, maintainable code and follow best practices in this codebase.

## Coding Conventions

### File Naming
- Use **PascalCase** for file names.
  - Example: `MyModule.ts`, `AwsResourceHandler.ts`

### Import Style
- Use **relative imports** for referencing files within the project.
  - Example:
    ```typescript
    import { AwsResourceHandler } from './AwsResourceHandler';
    ```

### Export Style
- Use **named exports** for all modules.
  - Example:
    ```typescript
    // In AwsResourceHandler.ts
    export function createResource() { ... }
    export const RESOURCE_TYPE = 'aws_instance';
    ```

### Commit Message Style
- Use **conventional commits** with prefixes (e.g., `docs:`).
  - Example: `docs: update usage examples in README`

## Workflows

### Contributing Code
**Trigger:** When adding or updating features, bug fixes, or documentation  
**Command:** `/contribute`

1. Create a new branch from `main`.
2. Make code changes following the coding conventions.
3. Write or update tests as needed.
4. Commit changes using the conventional commit format.
5. Open a pull request for review.

### Writing Documentation
**Trigger:** When updating or adding documentation  
**Command:** `/docs-update`

1. Edit or create documentation files as needed.
2. Use clear, concise language and code examples.
3. Commit with a `docs:` prefix in the message.
4. Submit a pull request for review.

## Testing Patterns

- Test files use the pattern `*.test.*` (e.g., `AwsResourceHandler.test.ts`).
- The specific testing framework is not detected, but tests should be colocated with or near the code they test.
- Example test file:
  ```typescript
  // AwsResourceHandler.test.ts
  import { createResource } from './AwsResourceHandler';

  describe('createResource', () => {
    it('should create a resource with correct type', () => {
      const resource = createResource();
      expect(resource.type).toBe('aws_instance');
    });
  });
  ```

## Commands
| Command         | Purpose                                         |
|-----------------|-------------------------------------------------|
| /contribute     | Start the code contribution workflow            |
| /docs-update    | Begin the documentation update workflow         |
```
