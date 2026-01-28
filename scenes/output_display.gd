extends RichTextLabel

func _ready():
	meta_clicked.connect(_on_link_clicked)

func _on_link_clicked(meta):
	OS.shell_open(meta)
