extends Popup
class_name InputChooser


## A GUI to choose an [InputEvent]
##
## Does not change event own it's own. But rather emit [signal choosed] when
## event has been selected.
## You can build a custom scene, taking exemple of
## [code]res://addons/keybind_remap/input_chooser/default_input_chooser.tscn[/code].


## Emitted when [method close] has been called with [code]success=true[/code].
signal choosed(new_event: InputEvent)


## When building a custom chooser scene, set this so it knows wich node to use.
@export var input_display: InputDisplay:
	set(new):
		if input_display and input_display.gui_input.is_connected(_on_input_display_gui_input):
			input_display.gui_input.disconnect(_on_input_display_gui_input)
		input_display = new
		if input_display:
			input_display.gui_input.connect(_on_input_display_gui_input)
## When building a custom chooser scene, set this so it knows wich node to use.
@export var confirm_button: BaseButton:
	set(new):
		if confirm_button and confirm_button.pressed.is_connected(_on_confirm_button_pressed):
			confirm_button.pressed.disconnect(_on_confirm_button_pressed)
		confirm_button = new
		if confirm_button:
			confirm_button.pressed.connect(_on_confirm_button_pressed)
## When building a custom chooser scene, set this so it knows wich node to use.
@export var cancel_button: BaseButton:
	set(new):
		if cancel_button and cancel_button.pressed.is_connected(_on_cancel_button_pressed):
			cancel_button.pressed.disconnect(_on_cancel_button_pressed)
		cancel_button = new
		if cancel_button:
			cancel_button.pressed.connect(_on_cancel_button_pressed)
## When building a custom chooser scene, set this so it knows wich node to use.
@export var physical_toggle: BaseButton:
	set(new):
		if physical_toggle and physical_toggle.toggled.is_connected(_on_physical_toggle_toggled):
			physical_toggle.toggled.disconnect(_on_physical_toggle_toggled)
		physical_toggle = new
		if physical_toggle:
			physical_toggle.toggled.connect(_on_physical_toggle_toggled.unbind(1))


var _available: bool = true
var _last_event: InputEvent


func _init() -> void:
	popup_hide.connect(_on_popup_hide)


## Request a remap for the given [param event]. Will not modify [param event] instance.
## Make sure to connect to [signal choosed] with [constant Object.CONNECT_ONE_SHOT]
## in order to trigger your event changing logic.
func request_remap(event: InputEvent) -> bool:
	if _available:
		_remap(event)
		return true
	
	return false


func _remap(event: InputEvent) -> void:
	_available = false
	input_display.input_event = event.duplicate() if event else null
	_last_event = event.duplicate() if event else null
	input_display.grab_focus.call_deferred()
	if event is InputEventKey:
		physical_toggle.set_pressed_no_signal(event.keycode == 0 and event.physical_keycode != 0)
	popup_centered()


func _on_popup_hide() -> void:
	if not _available:
		popup_centered.call_deferred()


func _on_input_display_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion and event.is_pressed() and not event.is_echo():
		_last_event = event.duplicate()
		_setup_physical(event)
		if event.is_match(input_display.input_event) and not event is InputEventMouse:
			confirm_button.grab_focus.call_deferred()
		input_display.input_event = event
		_force_refresh()


func _on_confirm_button_pressed() -> void:
	close(true)


func _on_cancel_button_pressed() -> void:
	close(false)
	

func _on_physical_toggle_toggled() -> void:
	if _last_event:
		input_display.input_event = _setup_physical(_last_event.duplicate())
		_force_refresh()


## Close Window.
## [br] If [param success] is [code]true[/code] will modify the event,
## else will cancel modification.
func close(success: bool) -> void:
	_available = true
	hide()
	
	choosed.emit(fetch_result() if success else null)


func _setup_physical(event: InputEvent) -> InputEvent:
	if event is InputEventKey:
		event.unicode = 0
		if physical_toggle.button_pressed:
			if event.physical_keycode == 0:
				event.physical_keycode = DisplayServer.keyboard_get_keycode_from_physical(event.keycode)
			event.keycode = 0
		else:
			event.physical_keycode = 0
	return event


func _force_refresh() -> void:
	input_display.input_icon.force_refresh()


## Get the current, unfinal, result.
func fetch_result() -> InputEvent:
	return _setup_physical(input_display.input_event)
