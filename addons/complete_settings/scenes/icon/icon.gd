extends HBoxContainer
class_name SettingGroupIcon

var texture: Texture2D:
	set(new):
		$TextureRect.texture = new

func get_texture_rect() -> TextureRect:
	return $TextureRect
