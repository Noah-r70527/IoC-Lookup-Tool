extends Control

@onready var tool_box = %ToolBox

func _ready():
	%SettingsButton.pressed.connect(on_settings_clicked)
	%"Quit Button".pressed.connect(quit_program)

	for node in %ToolVbox.get_children():
		node.switch_tool.connect(handle_swap_tool)
	
func handle_swap_tool(tool_scene_path):
	for node in tool_box.get_children():
		print("Clearing Node: %s" % node)
		tool_box.remove_child(node)
	%OutputDisplay.clear()
	%OutputDisplay.append_text("[color=green]Swapping tool to: [/color]%s" % tool_scene_path)
	$%ToolBox.add_child(load(tool_scene_path).instantiate())
	
	
func handle_updated_config(config_name):
	var result = %HTTPRequestHandler.sync_api_keys()
	if result == "Success":
		%OutputDisplay.clear()
		%OutputDisplay.append_text("[color=green]Successfully updated config: [/color]%s" % config_name)
	else:
		%OutputDisplay.clear()
		%OutputDisplay.append_text("[color=red]Failed to sync keys after updating config[/color]")
	

func on_settings_clicked():
	handle_swap_tool("res://scenes/settings/Settings.tscn")
	await get_tree().create_timer(.1).timeout
	%ToolBox.get_child(0).updated_config.connect(handle_updated_config)
	

func quit_program():
	get_tree().quit()
