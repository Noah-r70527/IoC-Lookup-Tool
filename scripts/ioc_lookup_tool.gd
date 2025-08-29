extends Control

@onready var tool_box = %ToolBox
@onready var output_display = %OutputDisplay
var current_tool: String = "IP Lookup Tool"


func _ready():

	var dir_access = DirAccess.open(OS.get_executable_path().get_base_dir())
	if not dir_access.dir_exists("IPLookups"):
		dir_access.make_dir("IPLookups")
	if not dir_access.dir_exists("URLLookups"):
		dir_access.make_dir("URLLookups")

	
	if not ConfigHandler.get_config_value("ABUSE_IP_API_KEY"):
		output_display.append_text("\n\n[color=red]WARNING[/color]: Abuse IP DB API key is missing. You will be unable to perform IP lookups. Please click the settings button, open settings.ini, and add the API key.")

	if not ConfigHandler.get_config_value("VT_API_KEY"):
			output_display.append_text("\n[color=red]WARNING[/color]: Virus Total API key is missing. You will be unable to perform URL lookups. Please click the settings button, open settings.ini, and add the API key.")
	
	%SettingsButton.pressed.connect(on_settings_clicked)
	%"Quit Button".pressed.connect(quit_program)
	for node in %ToolVbox.get_children():
		node.switch_tool.connect(handle_swap_tool)
	
func handle_swap_tool(tool_scene_path):
	var scene_to_tool_name = {
		"res://scenes/tools/IPLookupTool.tscn": "IP Lookup Tool",
		"res://scenes/tools/UrlLookupTool.tscn": "URL Lookup Tool",
		"res://scenes/settings/Settings.tscn": "Settings",
		"res://scenes/tools/HashLookupTool.tscn": "Hash Lookup Tool",
		"res://scenes/tools/DefangTool.tscn": "Defang Tool"
	}
	
	if scene_to_tool_name.get(tool_scene_path) == current_tool:
		return
		
	for node in tool_box.get_children():
		tool_box.remove_child(node)
	%CurrentToolLabel.text = "Current Tool:\n%s" % scene_to_tool_name.get(tool_scene_path)
	current_tool = scene_to_tool_name.get(tool_scene_path)
	%OutputDisplay.clear()
	%OutputDisplay.append_text("[color=green]Swapping tool to: [/color]%s" % scene_to_tool_name.get(tool_scene_path))
	$%ToolBox.add_child(load(tool_scene_path).instantiate())
	
	
func handle_updated_config(config_name):
	
	if config_name == "NAME":
		%OutputDisplay.clear()
		%OutputDisplay.append_text("[color=green]Successfully updated name[/color]")
		return
		
	if config_name == "TOOLADD":
		%OutputDisplay.clear()
		%OutputDisplay.append_text("[color=green]Successfully added tool[/color]")
		return

	if config_name == "TOOLREMOVE":
		%OutputDisplay.clear()
		%OutputDisplay.append_text("[color=green]Successfully removed tool[/color]")
		return

		
	var result = %HTTPRequestHandler.sync_api_keys()
	if result == "Success":
		%OutputDisplay.clear()
		%OutputDisplay.append_text("[color=green]Successfully updated config: [/color]%s" % config_name)
	else:
		%OutputDisplay.clear()
		%OutputDisplay.append_text("[color=red]Failed to sync keys after updating config[/color]")
	

func handle_output_text(text_in):
	%OutputDisplay.clear()
	%OutputDisplay.append_text("[color=green]Current tools in config: [/color]\n\n")
	%OutputDisplay.append_text(text_in)


func on_settings_clicked():
	handle_swap_tool("res://scenes/settings/Settings.tscn")
	await get_tree().create_timer(.1).timeout
	%ToolBox.get_child(0).updated_config.connect(handle_updated_config)
	%ToolBox.get_child(0).output_text.connect(handle_output_text)
	

func quit_program():
	get_tree().quit()
