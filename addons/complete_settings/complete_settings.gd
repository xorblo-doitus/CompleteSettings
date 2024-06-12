class_name CompleteSettings
extends Object


## A staatic singleton allowing easier settings ui creation.
##
## This singleton should normally be self initialized on projet loading trough
## it's _static_init() method. If not, try accessing [CompleteSettings]
## somewhere in a script that get loaded into your game early to trigger the
## _static_init() method.
## [br][br]
## By default, _static_init() calls [method initialize].
## This automatic behaviour can be disabled by adding a project setting
## [code]"addons/complete_settings/auto_initialize"[/code]
## set to [code]false.[/code]


static func _static_init() -> void:
	if ProjectSettings.get_setting("addons/complete_settings/auto_initialize", true):
		initialize()


## Calls [method load_volumes] and [method initialize_keybinds].
static func initialize() -> void:
	load_volumes()
	initialize_keybinds()


## Load volumes from the ProjectSettings.
static func load_volumes():
	for bus_idx in AudioServer.bus_count:
		AudioServer.set_bus_volume_db(
			bus_idx,
			linear_to_db(
				EasySettings.get_setting(
					VolumeSlider.setting_path_prefix + AudioServer.get_bus_name(bus_idx),
					0.0
				)
			)
		)


## Set the current mapping as the default one then load the user's saved keybinds
static func initialize_keybinds() -> void:
	KeybindsSaver.shared.set_current_mapping_as_default()
	KeybindsSaver.shared.load_keybinds()


## Create a restauration point of settings and keybinds.
## See [method cancel], [method apply] & [method validate]
static func start_setting_edition() -> void:
	EasySettings.begin_bulk_setting_change()
	KeybindsSaver.shared.begin_bulk_remap()


## Cancels all modifications since [method start_setting_edition] was called.
static func cancel() -> void:
	EasySettings.cancel_bulk_setting_change()
	KeybindsSaver.shared.cancel_bulk_remap()


## @experimental NOT IMPLEMENTED due to lacking feature in EasySettings and KeybindRemap
## See [method start_setting_edition]
static func apply() -> void:
	pass


## Saves all modifications since [method start_setting_edition] was called.
static func validate() -> void:
	EasySettings.validate_bulk_setting_change()
	KeybindsSaver.shared.validate_bulk_remap()

