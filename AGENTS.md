# AGENTS.md

## Overview
This is a Godot 2D RPG learning project with two versions: `godot-3/` (Godot 3.x) and `godot-4/` (Godot 4.x).

## Project Structure

- **godot-3/**: Godot 3.x version with C# support (.mono folder)
- **godot-4/**: Godot 4.x version (GDScript only)

## Running the Project
Open either `godot-3/project.godot` or `godot-4/project.godot` in the Godot editor. There are no command-line build/test commands—this is a game engine project.

## Entry Points
- **godot-3**: Main scene is `UI/Menu.tscn`
- **godot-4**: Main scene is defined via UID in `project.godot`

## Key Differences
- godot-3 uses `config_version=4`, godot-4 uses `config_version=5`
- Input actions differ between versions
- Physics layers: godot-3 has 6 layers, godot-4 defaults to engine defaults

## Working Here
- Edit .gd (GDScript) files or .tscn (scene) files in either folder
- Asset workflow: import via Godot editor, don't manually edit .import files
- Changes to project.godot should preserve config_version format