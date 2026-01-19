extends Label

@onready var text_box: TextEdit = %MultiIPText

func _ready() -> void:
	text_box.text_changed.connect(update_label)
	
func update_label() -> void:
	var lines = len(text_box.text.split("\n"))
	text = "Multi IP Lookup List Here: (%d lines)" % lines
