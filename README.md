# Lynx-Library-UI (improved)

This repository contains an improved UI library for Roblox plus a compatibility adapter that provides a Section API similar to older versions.

What's new in this update:
- Element handles returned from element creators (Toggle, Button, Label, Slider, Keybind, InputBox, Dropdown) with Set/Get methods.
- Adapter now returns element handles when creating elements inside Sections.
- Adapter supports two-column layout: use `Side = "Right"` for sections on the right column.
- DropdownFunctions include `Refresh` and `GetSelected`.

Usage:
1. Put `src/ui_library.lua` as a ModuleScript (or load it via raw URL).
2. Put `src/adapter.lua` as a ModuleScript and require it to use the Section API.
3. Example: see `examples/test_example.lua`.
