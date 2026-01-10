---
description: Review code changes for bugs, best practices, and improvements
---

# Code Review

Review the current staged or unstaged changes in the repository. Analyze the code for:

1. **Bugs & Logic Errors**: Look for potential crashes, nil pointer issues, race conditions, or incorrect logic
2. **Swift/iOS Best Practices**: Check for proper memory management (retain cycles), correct use of optionals, proper async/await usage
3. **Security Issues**: API keys in code, insecure data handling, missing input validation
4. **Performance**: Inefficient algorithms, unnecessary work on main thread, memory leaks
5. **Code Quality**: Naming conventions, code organization, DRY violations, unclear logic

## Process

1. First run `git diff` to see unstaged changes and `git diff --cached` for staged changes
2. Analyze each changed file
3. Provide feedback organized by severity:
   - **Critical**: Must fix before merging (bugs, security issues)
   - **Warning**: Should fix (performance, best practices)
   - **Suggestion**: Nice to have (style, minor improvements)

Be specific with line numbers and provide code examples for fixes when helpful.
