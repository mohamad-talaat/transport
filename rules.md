# 10x-Tool-Calls Rules

## Purpose
Enable interactive loop inside a single Agent request to maximize tool call usage.

## Rules
- After completing each task, the AI must:
  1. Run `userinput.py` to collect the next user instruction.
  2. Continue working based on that input without ending the session.
- Repeat this loop until:
  - The user types "exit", OR
  - Tool call limit for the request is reached.
- Always return control back to `userinput.py` after completing a step.
- Do not terminate session unless explicitly told to.

## Notes
- This rule is only useful with tool-call–based quota systems (e.g., Cursor, Windsurf).
- Not intended for token-based pricing APIs.
