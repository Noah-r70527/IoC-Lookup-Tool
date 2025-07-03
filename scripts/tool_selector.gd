extends Control

@export var tool_name: String
@onready var button: Button = %ToolSelectionButton
@export var tool_path: String

signal switch_tool(tool_path)

func _ready(): 
	button.text = tool_name
	button.pressed.connect(on_switch_tool_click)
	
	
func on_switch_tool_click():
	emit_signal("switch_tool", tool_path)
