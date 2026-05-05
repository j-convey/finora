---
description: Apply when creating new features, refactoring logic, or architectural planning to ensure strict separation of concerns.
applyTo: '**/*.{ts,js,dart,go,py,java}' 
---

# Separation of Concerns (SoC) & SRP Standards

Follow these rules to ensure the codebase remains modular, testable, and organized.

## ## 1. Single Responsibility Principle (SRP)
* **File Atomic Purpose:** Every file must have one primary reason to change. Do not combine business logic, UI rendering, and data fetching in a single file.
* **Component Granularity:** If a component or function exceeds 200 lines, extract sub-logic into dedicated helper files or hooks.
* **Logic Isolation:** Keep "pure" logic (calculations, transformations) separate from "impure" logic (API calls, side effects, database I/O).


## ## 3. Implementation Guardrails
* **No "God Files":** Refuse to append new, unrelated logic to existing large files. Instead, propose a new file and link it.
* **Explicit Dependencies:** Use clear imports/exports. Avoid global state or "magic" variables that obscure the flow of data between concerns.
* **Folder Depth:** Maintain a logical nesting depth. If a single folder contains more than 10 files, decompose it into categorized sub-folders.

> **Note:** Prioritize readability and maintainability over "lines of code" efficiency. It is better to have three small, well-named files than one large, "efficient" one.