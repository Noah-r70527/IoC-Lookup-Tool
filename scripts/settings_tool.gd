extends Control

@onready var ab_ip_key = ConfigHandler.get_config_value("ABUSE_IP_API_KEY")
@onready var vt_key = ConfigHandler.get_config_value("VT_API_KEY")
@onready var ip_log = ConfigHandler.get_config_value("LOG_IP_TO_CSV")
@onready var url_log = ConfigHandler.get_config_value("LOG_URL_TO_CSV")
@onready var config_name = ConfigHandler.get_config_value("NAME")

signal updated_config(setting_changed)

func _ready():
	%AbuseIPDBAPIKey.text = ab_ip_key
	%VTText.text = vt_key
	%NameText.text = config_name if config_name else ""
	%IPCsvCheck.button_pressed = true if ip_log == "true" else false
	%URLCsvCheck.button_pressed = true if url_log == "true" else false
	%IPCsvCheck.button_up.connect(toggle_ip_log)
	%URLCsvCheck.button_up.connect(toggle_url_log)
	%AbuseIPDBButton.pressed.connect(update_api_key.bind("ab"))
	%VTButton.pressed.connect(update_api_key.bind("vt"))
	%"Name Button".pressed.connect(update_name)
	

func update_name():
	ConfigHandler.update_config_setting("NAME", %NameText.text)
	emit_signal("updated_config", "NAME")
	
func update_api_key(system):
	var system_string = ""
	var key = ""
	if system == "ab":
		system_string = "ABUSE_IP_API_KEY"
		key = %AbuseIPDBAPIKey.text
	elif system == "vt":
		system_string = "VT_API_KEY"
		key = %VTText.text


	print(system_string, key)
	ConfigHandler.update_config_setting(system_string, key)
	print(ConfigHandler.get_config_value(system_string))
	emit_signal("updated_config", system_string)
	

func toggle_ip_log():
	var updated = "false" if !%IPCsvCheck.button_pressed else "true"
	ConfigHandler.update_config_setting("LOG_IP_TO_CSV", updated)
	print(ConfigHandler.get_config_value("LOG_IP_TO_CSV"))

func toggle_url_log():
	var updated = "false" if !%URLCsvCheck.button_pressed else "true"
	ConfigHandler.update_config_setting("LOG_URL_TO_CSV", updated)
	print(ConfigHandler.get_config_value("LOG_URL_TO_CSV"))

	
