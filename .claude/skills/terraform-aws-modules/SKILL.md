```markdown
# terraform-aws-modules Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches the core development patterns and conventions used in the `terraform-aws-modules` repository, which is implemented in TypeScript. You'll learn about file naming, import/export styles, commit message conventions, and how to write and run tests. This guide is ideal for contributors aiming to maintain consistency and quality in the codebase.

## Coding Conventions

### File Naming
- Use **snake_case** for all file names.
  - Example: `my_module.ts`, `user_profile.test.ts`

### Import Style
- Use **relative imports** for internal modules.
  - Example:
    ```typescript
    import { myFunction } from './utils';
    ```

### Export Style
- Use **named exports** for all modules.
  - Example:
    ```typescript
    export function myFunction() { /* ... */ }
    export const MY_CONSTANT = 42;
    ```

### Commit Messages
- Follow the **Conventional Commits** format.
- Use the `chore` prefix for maintenance tasks.
  - Example:
    ```
    chore: update dependencies to latest versions
    ```

## Workflows

### Code Contribution
**Trigger:** When adding or updating code
**Command:** `/contribute`

1. Create or update files using snake_case naming.
2. Use relative imports and named exports.
3. Write or update corresponding test files with the `.test.` pattern.
4. Commit changes using the conventional commit format (e.g., `chore: ...`).
5. Open a pull request for review.

### Writing Tests
**Trigger:** When adding new features or fixing bugs
**Command:** `/add-test`

1. Create a test file named with the `.test.` pattern (e.g., `my_module.test.ts`).
2. Write tests for all exported functions and components.
3. Use the project's preferred testing framework (see Testing Patterns below).
4. Run tests locally to ensure correctness.

### Dependency Updates
**Trigger:** When updating dependencies or performing maintenance
**Command:** `/update-deps`

1. Update dependency versions as needed.
2. Test the codebase to ensure compatibility.
3. Commit with a message like: `chore: update dependencies`
4. Open a pull request.

## Testing Patterns

- **Test File Naming:** Use the `.test.` infix in filenames (e.g., `example.test.ts`).
- **Framework:** The specific testing framework is not detected, but standard TypeScript test runners (like Jest or Mocha) are likely.
- **Test Location:** Place test files alongside the modules they test or in a dedicated test directory.
- **Example Test:**
  ```typescript
  import { myFunction } from './my_module';

  describe('myFunction', () => {
    it('should return true for valid input', () => {
      expect(myFunction('valid')).toBe(true);
    });
  });
  ```

## Commands
| Command        | Purpose                                      |
|----------------|----------------------------------------------|
| /contribute    | Steps for contributing code                  |
| /add-test      | Steps for writing and adding new tests       |
| /update-deps   | Steps for updating dependencies              |
```
