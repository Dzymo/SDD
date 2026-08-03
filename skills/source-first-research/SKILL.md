---
name: source-first-research
description: Use when researching external libraries or local code with Context7 or CodeGraph and when either source is unavailable or stale.
---

# Source-First Research

1. For external libraries, use Context7 first. Resolve the library, select the
   requested version, and query one focused concept.
2. For structural local-code questions, use CodeGraph when its index is healthy.
   For exact text, documentation, unindexed files, or stale results, use Glob,
   Grep, and Read instead.
3. If Context7 is unavailable, make one fallback retrieval attempt using an
   official source for low-risk work. If it also fails, state that verified
   external evidence is unavailable. Do not fill the gap with model memory.
4. If CodeGraph is unavailable, stale, or unindexed, state the limitation and
   return only evidence obtained with the available local inspection tools. If
   no such tool is exposed, state that direct local evidence is unavailable.
5. Every research result must identify its source and distinguish verified facts
   from remaining uncertainty.
