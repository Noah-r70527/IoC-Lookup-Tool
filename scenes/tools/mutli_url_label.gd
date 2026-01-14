extends Label


@onready var text_box: TextEdit = %MultiURLText

func _ready():
	text_box.text_changed.connect(update_text)
	
func update_text():
	var lines = len(text_box.text.split())
	text = "Multi URL Lookup List Here: (%d lines)" % lines
