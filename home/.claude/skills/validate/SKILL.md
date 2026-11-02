---
name: validate
description: Perform a production-quality code review for correctness, design coherence, and adherence to existing project patterns.
---

Perform a production-quality code review. Be direct, specific, and practical, providing actionable insights while maintaining a high production-quality standard. For Python changes, read and apply the shared [Python skill](../python/SKILL.md). Proceed with the review in this structured manner:

1. First, search the codebase for relevant details, including:
   - Related modules, functions, and patterns
   - Existing architectural and style conventions
   - Any prior implementation that the code affects or is similar to
   - Include agent context such as the `.cursor` directory, `.claude` directory, `CLAUDE.md` and `AGENTS.md` files
2. Describe the code covering:
   - The overall modification
   - The intent or objective driving it
   - How the implementation does or does not fulfill that intent
3. Validate the proposed code on the following dimensions:

   **Design & Coherence:**
   - Ensure the patterns are as simple as possible for the requirements they satisfy.
   - Prefer reusing and extending existing patterns rather than inventing new ones; check that the existing pattern actually fits the problem.
   - Determine whether slight behavior changes would result in large simplifications: simple code leads to simple behavior leads to better outcomes. Describe the behavior change and its compatibility costs as a proposal, rather than silently changing the contract.
   - Justify abstractions and extension points with current callers and requirements. If they support planned work, require a comment explaining what is coming and what it will change.
   - Keep each rule and invariant in one clear owner; flag parallel implementations and duplicated sources of truth that can drift.
   - Prefer removing unnecessary states, branches, flags, and special cases over adding layers that hide them. Understand why each exists before recommending its removal.
   - Judge simplicity by how easily callers and maintainers can understand the behavior, not just by line count. Keep suggested changes within the reviewed scope.

   **Code Quality & Clarity:**
   - Readability: Clear logic flow, appropriate abstraction levels, self-documenting code
   - Naming: Consistent, descriptive variable/function/class names without typos
   - Simplicity: Minimal complexity, avoiding over-engineering or premature optimization
   - Dead code: Unused variables, functions, unreachable code paths or source code that is only referenced in tests
   - Style: Adherence to project coding conventions and formatting standards
   - Documentation: Appropriate comments for complex logic, updated docstrings

   **Performance & Resource Management:**
   - Algorithmic efficiency: Big-O complexity, data structure choices
   - Scalability: Behavior under increased load, horizontal/vertical scaling considerations
   - Resource usage: Memory leaks, CPU efficiency, I/O optimization, connection pooling
   - Caching strategies: Appropriate use of caching where beneficial

   **Security & Robustness:**
   - Security vulnerabilities: Input validation, injection attacks, authentication/authorization
   - Error handling: Graceful degradation, proper exception handling, no information leakage
   - Thread safety: Race conditions, deadlocks, proper synchronization primitives
   - Data integrity: Transactional consistency, validation, sanitization

   **Maintainability & Architecture:**
   - Code structure: Appropriate separation of concerns, SOLID principles
   - API design: Backward compatibility, versioning strategy, clear contracts
   - Dependencies: Minimal external dependencies, version pinning, upgrade impact assessment
   - Extensibility: Extension points justified by current requirements or explicitly documented planned work
   - Technical debt: Not introducing shortcuts that will cause problems later

   **Testing & Quality Assurance:**
   - Test coverage: Unit tests for business logic, integration tests for interactions
   - Test quality: Edge cases, error conditions, boundary values
   - CI/CD integration: Automated test execution, quality gates, deployment automation
   - Testability: Code designed to be easily testable, appropriate use of mocks/stubs

   **Observability & Operations:**
   - Logging: Structured logs at appropriate levels (INFO, WARN, ERROR), no sensitive data
   - Monitoring: Metrics, health checks, performance indicators
   - Debugging: Sufficient context for troubleshooting production issues
   - User experience: Response times, error messages, consistency, graceful degradation
4. Identify any hidden risks, unhandled edge cases, or non-obvious design trade-offs.
5. Output a **numbered list of issues** (if any), each with:
   - A concise description of the problem
   - Why it matters
   - A suggested fix

At the end of your analysis, clearly indicate whether you would approve this code for production or if additional changes are required. Summarize your reasoning.
