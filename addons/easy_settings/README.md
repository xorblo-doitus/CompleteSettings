# EasySettings

Provides helpers to modify ProjectSettings at run time

# How does it work ?
The class EasySettings has some static methods to modify ProjectSettings, and
let bind EasySetting's Listeners that change the setting they are linked to when
the value of their input is changed, and that change the value of their input when
the setting is changed.

## Godot version

Godot 4.1.1, may not work with 4.0, wont work with 3.x
