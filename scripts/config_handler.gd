extends Node

var config: ConfigFile = ConfigFile.new()
const SETTINGS_FILE_PATH = "user://ioctoolsettingsupd.ini"
const PASS_FILE_PATH = "user://ioc_enc.ini"
var pass_key: String

const DEFAULT_CONFIG_ENTRIES = {
	"ABUSE_IP_API_KEY": "...",
	"VT_API_KEY": "...",
	"LOG_IP_TO_CSV": "true",
	"LOG_URL_TO_CSV": "true",
	"AUTO_REARM": "true",
	"NAME": "Blank",
	"TOOLS": "Sentinel,Defender,Datadog,Other",
	"HIDDENTOOLS": "",
	"MINABUSESCORE": "0",
	"MINREPORTS": "0"
}

func _ready() -> void:
	pass_key = _get_or_create_pass_key()
	
	var err = config.load_encrypted_pass(SETTINGS_FILE_PATH, pass_key)
	if err != OK:
		print("Config not found or invalid, creating new with defaults")
		_set_defaults()
		_save_config()
	else:
		_fill_missing_defaults()
		_save_config() 

func _set_defaults() -> void:
	for key in DEFAULT_CONFIG_ENTRIES:
		config.set_value("Config", key, DEFAULT_CONFIG_ENTRIES[key])

func _fill_missing_defaults() -> void:
	for key in DEFAULT_CONFIG_ENTRIES:
		if not config.has_section_key("Config", key):
			config.set_value("Config", key, DEFAULT_CONFIG_ENTRIES[key])

func _save_config() -> void:
	var err = config.save_encrypted_pass(SETTINGS_FILE_PATH, pass_key)
	if err != OK:
		push_error("Failed to save encrypted config: %s" % err)

func update_config_setting(key: String, value: Variant) -> void:
	config.set_value("Config", key, value)
	_save_config()

func get_config_value(key: String, default_value: Variant = "") -> Variant:
	return config.get_value("Config", key, default_value)

func _generate_random_string(length: int) -> String:
	var rng = RandomNumberGenerator.new()
	var allowed_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()"
	rng.randomize()
	var random_string = ""
	for i in length:
		random_string += allowed_chars[rng.randi_range(0, allowed_chars.length() - 1)]
	return random_string

func _get_or_create_pass_key() -> String:
	if not FileAccess.file_exists(PASS_FILE_PATH):
		var access = FileAccess.open(PASS_FILE_PATH, FileAccess.WRITE)
		var key = _generate_random_string(100)
		access.store_string(key)
		access.close()
	
	var pass_file = FileAccess.open(PASS_FILE_PATH, FileAccess.READ)
	return pass_file.get_as_text().strip_edges()
