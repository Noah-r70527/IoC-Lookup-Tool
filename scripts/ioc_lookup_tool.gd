extends Control

@onready var tool_box = %ToolBox
@onready var output_display = %OutputDisplay

func _ready():
	var dir_access = DirAccess.open(OS.get_executable_path().get_base_dir())
	if not dir_access.dir_exists("IPLookups"):
		dir_access.make_dir("IPLookups")
	if not dir_access.dir_exists("URLLookups"):
		dir_access.make_dir("URLLookups")

	
	if not ConfigHandler.get_config_value("ABUSE_IP_API_KEY"):
		output_display.append_text("\n\n[color=red]WARNING[/color]: Abuse IP DB API key is missing. You will be unable to perform IP lookups. Please click the settings button, open settings.ini, and add the API key.")

	if not ConfigHandler.get_config_value("IPSCORE_API_KEY"):
			output_display.append_text("\n[color=red]WARNING[/color]: IPScore API key is missing. You will be unable to perform URL lookups. Please click the settings button, open settings.ini, and add the API key.")
	
	%SettingsButton.pressed.connect(on_settings_clicked)
	%"Quit Button".pressed.connect(quit_program)
	for node in %ToolVbox.get_children():
		node.switch_tool.connect(handle_swap_tool)
	
func handle_swap_tool(tool_scene_path):
	var scene_to_tool_name = {
		"res://scenes/tools/IPLookupTool.tscn": "IP Lookup Tool",
		"res://scenes/tools/UrlLookupTool.tscn": "URL Lookup Tool"
	}
	for node in tool_box.get_children():
		print("Clearing Node: %s" % node)
		tool_box.remove_child(node)
	%CurrentToolLabel.text = "Current Tool:\n%s" % scene_to_tool_name.get(tool_scene_path)
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
