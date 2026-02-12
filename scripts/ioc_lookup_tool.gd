extends Control

@onready var tool_box = %ToolBox
@onready var output_display = %OutputDisplay
@onready var requester = %HTTPRequestHandler
var current_tool: String = "IP Lookup Tool"


func _ready():
	print(Globals.version)
	Globals.output_display_update.connect(handle_output_text)
	Helpers._init_create_dirs()

	if not ConfigHandler.get_config_value("ABUSE_IP_API_KEY"):
		output_display.append_text("\n\n[color=red]WARNING[/color]: Abuse IP DB API key is missing. You will be unable to perform IP lookups. Please click the settings button, open settings.ini, and add the API key.")

	if not ConfigHandler.get_config_value("VT_API_KEY"):
			output_display.append_text("\n[color=red]WARNING[/color]: Virus Total API key is missing. You will be unable to perform URL lookups. Please click the settings button, open settings.ini, and add the API key.")

	%SettingsButton.pressed.connect(on_settings_clicked)
	%"Quit Button".pressed.connect(quit_program)
	%test.pressed.connect(test_button)
	for node in %ToolVbox.get_children():
		node.switch_tool.connect(handle_swap_tool)
	await requester.init_defender_token()
	if requester.defender_token != "Unable to get token.":
		Globals.emit_signal("output_display_update", 
		"\n\n[color=cyan]Defender Token Aquired.[/color]",
		true,
		"Informational"
		)
		
	var version: Dictionary = await requester.check_release_version()
	if version.has("version") and version.get("version") != Globals.version:
		Globals.emit_signal("output_display_update", 
		"\n\n[color=red]Updated version available:[/color] [url]https://github.com/Noah-r70527/IoC-Lookup-Tool/releases/latest[/url]",
		true,
		"Informational"
		)
	
func handle_swap_tool(tool_scene_path):
	
	var scene_to_tool_name = Globals.return_scene_dict()
	if scene_to_tool_name.get(tool_scene_path) == current_tool:
		return null

	for node in tool_box.get_children():
		tool_box.remove_child(node)
		
	%CurrentToolLabel.text = "Current Tool:\n%s" % scene_to_tool_name.get(tool_scene_path)
	current_tool = scene_to_tool_name.get(tool_scene_path)
	%OutputDisplay.clear()
	%OutputDisplay.append_text("[color=green]Swapping tool to: [/color]%s" % scene_to_tool_name.get(tool_scene_path))
	$%ToolBox.add_child(load(tool_scene_path).instantiate())
	return "Swapped"
	
	
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
	

func handle_output_text(text_in, append, _loglevel):
	if !append:
		%OutputDisplay.clear()
	%OutputDisplay.append_text(text_in)


func on_settings_clicked():
	var result = handle_swap_tool("res://scenes/settings/Settings.tscn")
	if result:
		await get_tree().create_timer(.1).timeout
		%ToolBox.get_child(0).updated_config.connect(handle_updated_config)
		%ToolBox.get_child(0).output_text.connect(handle_output_text)

func quit_program():
	get_tree().quit()
	
func test_button():
	pass
