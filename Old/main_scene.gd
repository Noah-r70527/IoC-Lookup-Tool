extends Control

@onready var output_display = %OutputDisplay

func _ready():
	if not ConfigHandler.get_config_value("ABUSE_IP_API_KEY"):
		output_display.append_text("\n[color=red]WARNING[/color]: Abuse IP DB API key is missing. You will be unable to perform IP lookups. Please click the settings button, open settings.ini, and add the API key.")
		
	if not ConfigHandler.get_config_value("VT_API_KEY"):
			output_display.append_text("\n[color=red]WARNING[/color]: Virus Total API key is missing. You will be unable to perform IP lookups. Please click the settings button, open settings.ini, and add the API key.")
