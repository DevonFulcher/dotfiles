Systematically find opportunities to add **unique, functional unit tests** to a codebase, leveraging **existing patterns and test data** while ensuring maintainability.

## Instructions

1. **Analyze the Codebase:**

   * Identify untested or under-tested functional areas.
   * Review existing test structure and patterns.
   * Note opportunities to reuse existing mocks, fixtures, and test data.

2. **Select Target Functions or Classes:**

   * Choose targets that have clear functional requirements.
   * Prefer areas with complex logic, high usage, or recent changes.

3. **Design the Test:**

   * Write unique tests that validate functional requirements, avoiding checks for private implementation details.
   * Use dependency injection for mocking to isolate functionality.
   * Update the source code when necessary to make it more testable.
   * Use clear and descriptive test names.

4. **Write the Test:**

   * Follow the codebase’s test conventions (framework, naming, folder structure).
   * Reuse mocks and fixtures where possible; otherwise, add reusable test utilities.
   * Ensure tests are readable and maintainable.
   * Ensure tests cover relevant edge cases and normal flows.

5. **Run the Test:**

   * Execute the test and confirm it fails if the implementation is incorrect.
   * Debug any setup or environment issues.

6. **Iterate:**

   * Re-run the test until it passes.
   * Refactor test for clarity if needed.

## Principles

* Prioritize functional behavior over implementation details.
* Prefer dependency injection for testability.
* Ensure tests are maintainable and consistent with the codebase’s standards.
* Tests should add unique coverage, not duplicate existing tests.
* Leverage and extend existing mocks and test data for consistency and efficiency.
