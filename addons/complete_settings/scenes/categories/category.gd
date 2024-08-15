@tool
extends Container
class_name SettingCategory


## A tab for settings.
##
## Inludes utilities like searching and collapsinging/expand all.
## [b]Warning:[/b] Setting entries added as direct child trough editor will
## have their modulate's alpha value reset to 1 if set near to
## [constant EDITOR_PREVIEW_HINDING_ALPHA] as a result of editor preview
## side effect.


const EDITOR_PREVIEW_HINDING_ALPHA = 0.5**14+0.5**15


## If different from empty string, the search will take this locale into account
## too.
@export var base_locale_search: String = "en":
	set(new):
		if new == base_locale_search:
			return
		
		base_locale_search = new
		
		if base_locale_search == "":
			for entry in get_setting_entries():
				entry.remove_meta(&"_cached_base_locale_tr")
		else:
			var current_locale: String = TranslationServer.get_locale()
			for entry in get_setting_entries():
				entry.set_meta(&"_cached_base_locale_tr", tr(entry.setting_name))

@export_group("Nodes")
@export var setting_list: Control
## Call [method collapse_all] when pressed. Can be [code]null[/code]
@export var collapse_all_button: BaseButton:
	set(new_value):
		if collapse_all_button != null:
			collapse_all_button.pressed.disconnect(collapse_all)
		if new_value != null and not new_value.pressed.is_connected(collapse_all):
			new_value.pressed.connect(collapse_all)
		collapse_all_button = new_value
## Call [method expand_all] when pressed. Can be [code]null[/code]
@export var expand_all_button: BaseButton:
	set(new_value):
		if expand_all_button != null:
			expand_all_button.pressed.disconnect(expand_all)
		if new_value != null and not new_value.pressed.is_connected(expand_all):
			new_value.pressed.connect(expand_all)
		expand_all_button = new_value
## Used to search for an entry.
@export var search_bar: LineEdit:
	set(new_value):
		if search_bar != null:
			search_bar.text_changed.disconnect(search)
		if new_value != null and not new_value.text_changed.is_connected(search):
			new_value.text_changed.connect(search)
		search_bar = new_value



func _ready() -> void:
	if setting_list == null:
		push_warning("Setting list is null.")
	else:
		#child_entered_tree.connect(_handle_child)
		pre_sort_children.connect(_handle_children)
		if Engine.is_editor_hint():
			child_exiting_tree.connect(_clean_up_external_control)


func clear_setting_list() -> void:
	for child in setting_list.get_children():
		child.queue_free()


## Collapse all setting categories that are [member setting_list]'s childrens.
func collapse_all() -> void:
	for setting_group in get_setting_groups():
		setting_group.open = false


## Expand all setting categories that are [member setting_list]'s childrens.
func expand_all() -> void:
	for setting_group in get_setting_groups():
		setting_group.open = true


func search(text: String) -> void:
	if text.is_empty():
		for setting_group in get_setting_groups():
			setting_group._search_mode = false
	else:
		for setting_group in get_setting_groups():
			setting_group._search_mode = true
		
		var entries: Array[SettingEntry] = get_setting_entries()
		
		for entry in entries:
			if entry.get_parent():
				entry.get_parent().remove_child(entry)
			
			var score: int = _get_search_score(text, tr(entry.setting_name))
			if base_locale_search != "":
				score = mini(score, _get_search_score(text, get_base_locale_tr(entry)))
			entry.set_meta(&"_search_score", score)
		
		entries.sort_custom(_compare_search_score)
		
		for entry in entries:
			setting_list.add_child(entry)


func _compare_search_score(entry1: SettingEntry, entry2: SettingEntry) -> bool:
	return entry1.get_meta(&"_search_score",  2**64-1) < entry2.get_meta(&"_search_score", 2**64-1)


## Search recursiveley for [SettingGroup]s that are parented to [member setting_list].
## If a node has `broke_setting_search` metadata set to true, it and it's children
## will be ignored. Metadatas can be set in the inspector or trough [method Object.set_meta]
func get_setting_groups() -> Array[SettingGroup]:
	var settting_groups: Array[SettingGroup] = []
	var to_check: Array[Node] = [setting_list]
	
	while to_check:
		var current: Node = to_check.pop_back()
		
		if current.get_meta(&"broke_setting_search", false):
			continue
		
		to_check.append_array(current.get_children())
		
		if current is SettingGroup:
			settting_groups.push_back(current)
	
	return settting_groups


## Search recursiveley for [SettingEntry]s that are parented to [member setting_list].
## If a node has `broke_setting_search` metadata set to true, it and it's children
## will be ignored. Metadatas can be set in the inspector or trough [method Object.set_meta]
func get_setting_entries() -> Array[SettingEntry]:
	var settting_entries: Array[SettingEntry] = []
	var to_check: Array[Node] = [setting_list]
	
	while to_check:
		var current: Node = to_check.pop_back()
		
		if current.get_meta(&"broke_setting_search", false):
			continue
		
		to_check.append_array(current.get_children())
		
		if current is SettingEntry:
			settting_entries.push_back(current)
	
	return settting_entries


func get_base_locale_tr(entry: SettingEntry) -> String:
	if entry.has_meta(&"_cached_base_locale_tr"):
		return entry.get_meta(&"_cached_base_locale_tr")
	
	var current_locale = TranslationServer.get_locale()
	TranslationServer.set_locale(base_locale_search)
	var base_locale_tr: String = tr(entry.setting_name)
	TranslationServer.set_locale(current_locale)
	
	entry.set_meta(&"_cached_base_locale_tr", base_locale_tr)
	return base_locale_tr


const _SEARCH_SCORE_CATEGORY_GAP: int = 1_000_000_000
# Calculate the difference between two strings. Case insensitive.
static func _get_search_score(search: String, to_compare: String) -> int:
	search = search.to_lower()
	to_compare = to_compare.to_lower()
	
	if search == to_compare:
		return 0
	elif search in to_compare:
		return _SEARCH_SCORE_CATEGORY_GAP + _levenshtein_distance(search, to_compare)
	elif search.is_subsequence_of(to_compare):
		return _SEARCH_SCORE_CATEGORY_GAP * 2 + _levenshtein_distance(search, to_compare)
	else:
		return _SEARCH_SCORE_CATEGORY_GAP * 3 + _levenshtein_distance(search, to_compare)


# Taken and modified from https://github.com/ShatReal/Search-Bar-Demo/blob/257d1e6e1000ea9dbe58980fbf8bb48851ee5d88/main.gd#L33C1-L53C18
static func _levenshtein_distance(str1: String, str2: String) -> int:
	var rows_count: int = len(str1)
	var columns_count: int = len(str2)
	var matrix: Array[Array] = []
	
	# Create matrix rows and columns
	for row_idx in range(1, rows_count + 1):
		matrix.append([row_idx])
	matrix.insert(0, range(0, columns_count + 1))
	
	# Fill matrix
	for column_idx in range(1, columns_count + 1):
		for row_idx in range(1, rows_count + 1):
			matrix[row_idx].insert(
				column_idx,
				min(
					matrix[row_idx-1][column_idx] + 1,
					matrix[row_idx][column_idx-1] + 1,
					matrix[row_idx-1][column_idx-1] + (0 if str1[row_idx-1] == str2[column_idx-1] else 1)
				)
			)
	
	# Result is in the bottom-right corner
	return matrix[-1][-1]


func _handle_children() -> void:
	for child in get_children():
		_handle_child(child)


func _handle_child(child: Node) -> void:
	if not child is Control:
		return
	
	if child.owner == self:
		_handle_true_child_control(child)
	else:
		_handle_external_child_control(child)


func _handle_true_child_control(control: Control) -> void:
	var rect: Rect2 = control.get_rect()
	
	if control.size_flags_horizontal & SIZE_EXPAND_FILL:
		rect.position.x = 0
		rect.end.x = size.x
	if control.size_flags_vertical & SIZE_EXPAND_FILL:
		rect.position.y = 0
		rect.end.y = size.y
	
	if rect != control.get_rect():
		fit_child_in_rect(control, rect)


func _handle_external_child_control(control: Control) -> void:
	if Engine.is_editor_hint():
		_editor_preview_external_child_control(control)
		return
	else:
		control.reparent(setting_list, false)
		_apply_backed_up_alpha_if_necessary(control)


var _editor_preview_clones: Dictionary = {}
func _editor_preview_external_child_control(control: Control) -> void:
	if control in _editor_preview_clones:
		_editor_preview_clones[control].queue_free()
	
	var clone: Control = control.duplicate()
	_editor_preview_clones[control] = clone
	
	if not is_equal_approx(control.modulate.a, EDITOR_PREVIEW_HINDING_ALPHA):
		control.set_meta(&"_setting_category_editor_backed_up_alpha", control.modulate.a)
	control.modulate.a = EDITOR_PREVIEW_HINDING_ALPHA
	clone.modulate.a = _get_backed_up_alpha(control)
	
	setting_list.add_child(clone)


func _clean_up_external_control(control: Control) -> void:
	if control in _editor_preview_clones:
		_editor_preview_clones[control].queue_free()
		_editor_preview_clones.erase(control)
	_apply_backed_up_alpha_if_necessary(control)
	control.remove_meta(&"_setting_category_editor_backed_up_alpha")


func _apply_backed_up_alpha_if_necessary(node: Node) -> void:
	# KEEPME (This condition prevent loosing alpha when no editor preview
	# was performed after editing modulate.a)
	if is_equal_approx(node.modulate.a, EDITOR_PREVIEW_HINDING_ALPHA):
		node.modulate.a = _get_backed_up_alpha(node)
		node.remove_meta(&"_setting_category_editor_backed_up_alpha")


func _get_backed_up_alpha(node: Node) -> float:
	if node.has_meta(&"_setting_category_editor_backed_up_alpha"):
		return node.get_meta(&"_setting_category_editor_backed_up_alpha")
	
	return 1 
