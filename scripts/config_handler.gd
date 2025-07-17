extends Node

var config = ConfigFile.new()
const SETTINGS_FILE_PATH = "user://ioctoolsettings.ini"

func _ready():
	if !FileAccess.file_exists(SETTINGS_FILE_PATH):
		config.set_value("Config", "ABUSE_IP_API_KEY", "")
		config.set_value("Config", "VT_API_KEY", "")
		config.set_value("Config", "LOG_IP_TO_CSV", "true")
		config.set_value("Config", "LOG_URL_TO_CSV", "true")
		config.save(SETTINGS_FILE_PATH)
		
	else:
		config.load(SETTINGS_FILE_PATH)

func update_config_setting(key, value):
	config.load(SETTINGS_FILE_PATH)
	config.set_value("Config", key, value)
	config.save(SETTINGS_FILE_PATH)
	
func get_config_value(key):
	config.load(SETTINGS_FILE_PATH)
	return config.get_value("Config", key)
