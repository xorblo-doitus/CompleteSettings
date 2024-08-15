# CompleteSettings

A premade UI containing settings that can fit any projects (Audio, keybinds etc...)


## Intallation

Download only `res://addons/complete_settings`.


## Example

An example setting menu can be found at `addons/complete_settings/scenes/settings/example.tscn`.
You can duplicate the scene then start from here to customize your GUI.


## Localization

Seek for `.csv` files in `translations` folders for default translations. (There are translation folders from multiple addons)
You can also just define translations for keys in the main translation file of your project.


## Theme type variations

- MarginMedium: A medium margin around tab in the settings.
- SettingsScrollContainer: The scroll container containing the setting list.
- SettingsVBoxContainer: The vertical box container containing the setting list.
  - KeybindsVBoxContainer: Sub-type specific to keybinds category (with higher separation on default theme for better readability)


## Godot version

Godot 4.2.2 & 4.3


## See also :

A good in-game key remapping addon
https://github.com/Orama-Interactive/Keychain
