# Convetions

In general, follow the existing code style.
We can try auto formatters like Ruff, but they can have some undesired results and we would want them for Dart and Unreal too.

- Use spaces (instead of tabs; set your editor to convert tabs to spaces) for indent. Indent 2 to 4 spaces (following existing style; 2 spaces for Flutter, 4 spaces for python & Unreal C++).
- Variable & function naming
    - Prefix (file) global variables with an underscore, e.g. _my_global
    - Capitalize functions, camelCase variables, e.g. `def GetSlug(title, maxChars = 40):`
    - Use full words that are self-explanatory (code should be understandable without separate comments for the most part. DO add comments for describing unique things or sections of code). E.g. `myLongVariableName` NOT `myLongVarNm`
- Use automated tests (all new code should include at least one test, and any bug should include an automated test). Continuous Integration should auto run tests and require them to pass to merge.

That is it; otherwise use common sense and prioritize readable, maintainable, performant, well tested code.
Rule of thumb: a code reviewer should easily be able to understand your code (on the first try) and should not have to manually test or confirms it works (automated tests should do this). Code reviewers should just be a sanity check and focus on higher level code architecture and ensuring clarity.

NOTE: To keep consistency across ALL code bases, the variable & function naming goes AGAINST language specific defaults (e.g. snake_case for python). For a single codebase, language / community defaults are preferred, but when working across code, changing conventions leads to errors and inconsistency. For example, python defaults to snake_case and frontends typically use camelCase. As we go across the boundary, which do we use? We will end up with inconsistency somewhere. We could write functions at the API boundary to convert to and from snake_case and camelCase, but that is extra code to write, maintain and test. Instead by using camelCase EVERYWHERE (in database, backend, and frontend), we keep 100% consistency.
