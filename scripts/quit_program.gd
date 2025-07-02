extends Button

@onready var button = %"Quit Program"

func _ready():
	button.pressed.connect(self.quit_program)
	
func quit_program():
	get_tree().quit()
