# Lynx-Library-UI (improved)

Improved UI library for Roblox with a compatibility adapter that provides Section(...) API so older scripts can work with minimal changes.

Files added:
- src/ui_library.lua  (improved library)
- src/adapter.lua     (compatibility adapter for Sections)
- examples/test_example.lua (example usage and test)

Usage:
- Option A (local ModuleScripts): place `ui_library` and `adapter` ModuleScripts in ReplicatedStorage and require them.
- Option B (HTTP): load `src/ui_library.lua` from raw.githubusercontent and optionally use Adapter as a ModuleScript.
