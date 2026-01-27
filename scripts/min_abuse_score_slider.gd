extends HSlider

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP \
		or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			accept_event()
