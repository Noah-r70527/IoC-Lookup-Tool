extends Button

@onready var button: Button = %"Settings Button"
@onready var fileaccess = FileDialog.new()

func _ready():
	button.pressed.connect(on_settings_clicked)
	
	
func on_settings_clicked():
	print('Trying to open settings file..')
	var path = ProjectSettings.globalize_path("user://")
	OS.shell_open(path)

	
	
	
