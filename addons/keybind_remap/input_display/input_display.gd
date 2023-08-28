extends HBoxContainer
class_name InputDisplay


## A scene displaying more information about an [InputEvent] then [InputIcon]
##
## Displays modifiers (shift, alt, ctrl, and super), says if physical, and can
## say which physical key it corresponds to.


## See [member InputIcon.input_idx].
@export var input_idx: int:
	set(new):
		if input_icon: input_icon.input_idx = new
		else: _ready_sets[&"input_idx"] = new
	get:
		if input_icon: return input_icon.input_idx
		else: return 0
## The action this displays.
@export var action_name: StringName:
	set(new):
		if input_icon: input_icon.action_name = new
		else: _ready_sets[&"action_name"] = new
	get:
		if input_icon: return input_icon.action_name
		else: return &""
## See [member InputIcon.input_event]
@export var input_event: InputEvent:
	set(new):
		if input_icon: input_icon.input_event = new
		else: _ready_sets[&"input_event"] = new
	get:
		if input_icon: return input_icon.input_event
		else: return null

## Style box drown around this when focused.
@export var focus_style_box: StyleBox
## Modulate for the physical icon [TextureRect]
@export var physical_icon_modulate: Color = Color(1, 1, 1, 0.75):
	set(new):
		physical_icon_modulate = new
		if physical_icon: physical_icon.modulate = physical_icon_modulate
		else: _ready_sets[&"physical_icon_modulate"] = new
## When key is physical, displays the letter that the player see on it's keyboard.
@export var display_true_key: bool = true:
	set(new):
		if new != display_true_key:
			display_true_key = new
			adapt_to(input_icon.input_event)

@onready var input_icon: InputIcon = $InputIcon
@onready var fallback_label: Label = $FallbackLabel
@onready var modifiers: HBoxContainer = $Modifiers
@onready var physical_icon: TextureRect = $InputIcon/PhysicalIcon
@onready var true_key: HBoxContainer = $TrueKey


# property_name: StringName → value: Variant
var _ready_sets: Dictionary = {}
func _ready() -> void:
	for property_name in _ready_sets:
		set(property_name, _ready_sets[property_name])
	_ready_sets.clear()


## Displays the given [param event]
func adapt_to(event: InputEvent) -> void:
	if input_icon.texture == InputIcon.blank:
		display_fallback(event)
	else:
		display(event)


## Display an event when icon exists.
## [br][br]
## [b]Note: [/b]Prefer using [method adapt_to]
func display(event: InputEvent) -> void:
	input_icon.show()
	fallback_label.hide()
	
	_clear_children(modifiers)
	_clear_children(true_key)
	
	if event is InputEventWithModifiers:
		if event.ctrl_pressed:
			_new_modifier_texture_rect().texture = preload("res://addons/ActionIcon/Keyboard/Ctrl.png")
		if event.alt_pressed:
			_new_modifier_texture_rect().texture = preload("res://addons/ActionIcon/Keyboard/Alt.png")
		if event.shift_pressed:
			_new_modifier_texture_rect().texture = preload("res://addons/ActionIcon/Keyboard/Shift.png")
		if event.meta_pressed:
			_new_modifier_texture_rect().texture = preload("res://addons/ActionIcon/Keyboard/Command.png")
	
	physical_icon.visible = event is InputEventKey and event.keycode == 0 and event.physical_keycode != 0
	if display_true_key and physical_icon.visible:
		var true_keycode: int = DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
		if true_keycode != event.physical_keycode:
			var true_event: InputEventKey = InputEventKey.new()
			true_event.keycode = true_keycode
			if input_icon.get_keyboard(true_keycode) == null:
				var new_label: Label = Label.new()
				new_label.text = "(%s)" % true_event.as_text()
				true_key.add_child(new_label)
			else:
				var new_label: Label = Label.new()
				new_label.text = "("
				true_key.add_child(new_label)
				
				var true_key_display:  = InputIcon.new()
				true_key_display.input_event = true_event
				
				true_key.add_child(true_key_display)
				
				new_label = Label.new()
				new_label.text = ")"
				true_key.add_child(new_label)
	
	modifiers.visible = modifiers.get_child_count()


## Display an event when icon does not exist.
## [br][br]
## [b]Note: [/b]Prefer using [method adapt_to]
func display_fallback(event: InputEvent) -> void:
	_clear_children(true_key)
	_clear_children(modifiers)
	input_icon.hide()
	modifiers.hide()
	fallback_label.show()
	fallback_label.text = event.as_text()


func _on_input_icon_input_changed(input_event) -> void:
	adapt_to.call_deferred(input_event)


func _new_modifier_texture_rect() -> TextureRect:
	var new_plus_label: Label = Label.new()
	new_plus_label.text = "+"
	
	var new: TextureRect = InputIcon._default_size_setup(TextureRect.new())
	
	modifiers.add_child(new)
	modifiers.add_child(new_plus_label)
	
	return new


func _draw() -> void:
	if has_focus():
		if focus_style_box:
			draw_style_box(focus_style_box, get_rect())


func _on_focus_entered() -> void:
	_set_focus(true)


static func _clear_children(_node: Node) -> void:
	for child in _node.get_children():
		child.queue_free()
		_node.remove_child(child)


func _on_focus_exited() -> void:
	_set_focus(false)


func _set_focus(focused: bool) -> void:
	queue_redraw()
