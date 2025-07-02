extends Node

var config = ConfigFile.new()
const SETTINGS_FILE_PATH = "user://settings.ini"

func _ready():
	if !FileAccess.file_exists(SETTINGS_FILE_PATH):
		config.set_value("Config", "ABUSE_IP_API_KEY", "")
		config.set_value("Config", "VT_API_KEY", "")
		config.set_value("Config", "Write_To_Csv", "True")
		config.save(SETTINGS_FILE_PATH)
		
	else:
		var result = config.load(SETTINGS_FILE_PATH)

func update_config_setting(key, value):
	config.set_value("Config", key, value)
	
func get_config_value(key):
	config.load(SETTINGS_FILE_PATH)
	return config.get_value("Config", key)
