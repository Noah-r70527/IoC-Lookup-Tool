extends HBoxContainer

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var progress_label: Label = %ProgressLabel

func _ready() -> void:
	visible = false
	Globals.toggle_progress_visibility.connect(toggle_visibility)
	Globals.progress_bar_update.connect(handle_update_prgoress_bar)
	
func handle_update_prgoress_bar(lookup_type: String, current_number: int, max_number: int) -> void:
	var current_value: float = float(current_number) / float((max_number))
	progress_bar.value = current_value
	progress_label.text = "%s Lookups Complete: %s / %s" % [lookup_type, current_number, max_number]
	
func toggle_visibility() -> void:
	progress_label.text = ""
	progress_bar.value = 0
	visible = !visible
