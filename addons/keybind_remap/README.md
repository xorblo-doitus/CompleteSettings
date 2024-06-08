# KeybindRemap

Utility scenes to help remapping keybinds.


## Intallation

Download only `res://addons/keybind_remap` and `res://addons/ActionIcon`,
then enable the addon in `Project → Project Settings → Plugins`. (Enabling
Action Icon is not necessary)


## Localization

Default translations can be found in `res://addons/keybind_remap/translations`


## Godot version

Godot 4.2.2, may not work with 4.0, wont work with 3.x


## Development Status

Mostly complete. Some improvements are still possible.


## Images

### Input Mapper

This control shows the event of an action (defined by action name and event index). Clicking on it brings up [the input chooser dialog](#input-chooser).

![An input mapper showing `shift+Q`, informing that `Q` is actually `A` because hte user has an AZERTY keyboard, and allowing to reset the keybind to default.](/addons/keybind_remap/.readme_images/.input_mapper.png)

### Input Chooser

This dialog let you modify a keybind by detecting the keys you press.

![Input chooser previewing pressed keys, with a toggle setting allowing to choose if physical key or normal key should be used.](/addons/keybind_remap/.readme_images/.input_chooser.png)


## Credits:
	
See [credits](CREDITS.md) file.


## See also :

A good in-game key remapping addon:
https://github.com/Orama-Interactive/Keychain
