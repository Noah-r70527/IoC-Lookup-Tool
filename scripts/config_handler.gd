extends Node

var config = ConfigFile.new()
const SETTINGS_FILE_PATH = "user://ioctoolsettingsenc.ini"
const encry = "N|_$AbY7D~0Bsot(PeI/R2qb!rV1Supqpbp/y{ULKyc%sb1$V`"

func _ready():
	if !FileAccess.file_exists(SETTINGS_FILE_PATH):
		config.set_value("Config", "ABUSE_IP_API_KEY", "...")
		config.set_value("Config", "VT_API_KEY", "...")
		config.set_value("Config", "LOG_IP_TO_CSV", "true")
		config.set_value("Config", "LOG_URL_TO_CSV", "true")
		config.set_value("Config", "NAME", "Blank")
		config.set_value("Config", "TOOLS", "Sentinel,Defender,Datadog,Other")
		config.save_encrypted_pass(SETTINGS_FILE_PATH, encry)
	
		
	else:
		config.load_encrypted_pass(SETTINGS_FILE_PATH, encry)
		


func update_config_setting(key, value):
	config.load_encrypted_pass(SETTINGS_FILE_PATH, encry)
	config.set_value("Config", key, value)
	config.save_encrypted_pass(SETTINGS_FILE_PATH, encry)
		
func get_config_value(key):
	config.load_encrypted_pass(SETTINGS_FILE_PATH, encry)
	return config.get_value("Config", key)
