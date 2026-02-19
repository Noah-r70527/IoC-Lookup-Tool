extends Control

@onready var ab_ip_key = ConfigHandler.get_config_value("ABUSE_IP_API_KEY")
@onready var vt_key = ConfigHandler.get_config_value("VT_API_KEY")
@onready var ip_log = ConfigHandler.get_config_value("LOG_IP_TO_CSV")
@onready var url_log = ConfigHandler.get_config_value("LOG_URL_TO_CSV")
@onready var auto_rearm = ConfigHandler.get_config_value("AUTO_REARM")
@onready var config_name = ConfigHandler.get_config_value("NAME")
@onready var defender_client_id = ConfigHandler.get_config_value("DEFENDER_CLIENT_ID")
@onready var defender_client_secret = ConfigHandler.get_config_value("DEFENDER_CLIENT_SECRET")
@onready var defender_tenant_id = ConfigHandler.get_config_value("DEFENDER_TENANT_ID")


signal updated_config(setting_changed)
signal output_text(text)

func _ready():
	%AbuseIPDBAPIKey.text = ab_ip_key
	%VTText.text = vt_key
	%DefenderClientIdText.text = defender_client_id
	%DefenderClientSecretText.text = defender_client_secret
	%DefenderTenantIdText.text = defender_tenant_id
	%NameText.text = config_name if config_name else ""
	%IPCsvCheck.button_pressed = true if ip_log == "true" else false
	%URLCsvCheck.button_pressed = true if url_log == "true" else false
	%AutoDefangButton.button_pressed = true if auto_rearm == "true" else false
	%IPCsvCheck.button_up.connect(toggle_ip_log)
	%URLCsvCheck.button_up.connect(toggle_url_log)
	%AutoDefangButton.button_up.connect(toggle_auto_rearm)
	%AbuseIPDBButton.pressed.connect(update_api_key.bind("ab"))
	%DefenderClientIdButton.pressed.connect(update_api_key.bind("dfci"))
	%DefenderClientSecretButton.pressed.connect(update_api_key.bind("dfcs"))
	%DefenderTenantIdButton.pressed.connect(update_api_key.bind("dfti"))
	%VTButton.pressed.connect(update_api_key.bind("vt"))
	%"Name Button".pressed.connect(update_name)
	%"Add Tool".pressed.connect(add_tool)
	%"Remove Tool".pressed.connect(remove_tool)
	%"List Tools".pressed.connect(list_tools)
	%MinAbuseScoreSlider.drag_ended.connect(on_drag_abuse_end)
	%MinAbuseScoreSlider.value_changed.connect(on_slider_value_change)
	%MinAbuseScoreLabel.text = "Minimum Abuse Confidence Score For Logging: %s" % ConfigHandler.get_config_value("MINABUSESCORE")
	%MinAbuseScoreSlider.value = float(ConfigHandler.get_config_value("MINABUSESCORE"))
	%CacheDaysSlider.drag_ended.connect(on_drag_cache_days_end)
	%CacheDaysSlider.value_changed.connect(on_cache_days_slider_change)
	%CacheDaysText.text = "Cache TTL (Days): %s" % ConfigHandler.get_config_value("CACHE_TTL_DAYS")
	%CacheDaysSlider.value = float(ConfigHandler.get_config_value("CACHE_TTL_DAYS"))
	%CacheMaxSizeSlider.drag_ended.connect(on_drag_cache_max_end)
	%CacheMaxSizeSlider.value_changed.connect(on_cache_max_slider_change)
	%CacheMaxSizeLabel.text = "Maximum Cache Size: %s" % ConfigHandler.get_config_value("CACHE_MAX_SIZE")
	%CacheMaxSizeSlider.value = float(ConfigHandler.get_config_value("CACHE_MAX_SIZE"))
	
	
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
	elif system == "dfci":
		system_string = "DEFENDER_CLIENT_ID"
		key = %DefenderClientIdText.text
	elif system == "dfcs":
		system_string = "DEFENDER_CLIENT_SECRET"
		key = %DefenderClientSecretText.text
	elif system == "dfti":
		system_string = "DEFENDER_TENANT_ID"
		key = %DefenderTenantIdText.text

	ConfigHandler.update_config_setting(system_string, key)
	emit_signal("updated_config", system_string)
	

func toggle_ip_log():
	var updated = "false" if !%IPCsvCheck.button_pressed else "true"
	ConfigHandler.update_config_setting("LOG_IP_TO_CSV", updated)

func toggle_url_log():
	var updated = "false" if !%URLCsvCheck.button_pressed else "true"
	ConfigHandler.update_config_setting("LOG_URL_TO_CSV", updated)
	
func toggle_auto_rearm():
	var updated = "false" if !%AutoDefangButton.button_pressed else "true"
	ConfigHandler.update_config_setting("AUTO_REFANG", updated)
	
func add_tool():
	var current_tools: PackedStringArray = ConfigHandler.get_config_value("TOOLS").split(",")
	var tool_text: String = %ToolText.text
	if tool_text.is_empty():
		return
	var unwanted_chars = ["!", "@", "#", "$", "%", ",", "."]
	for letter in unwanted_chars:
		tool_text.replace(letter, "")
	current_tools.append(tool_text)
	ConfigHandler.update_config_setting("TOOLS", ",".join(current_tools))
	emit_signal("updated_config", "TOOLADD")
	
	
func remove_tool():
	var current_tools: PackedStringArray = ConfigHandler.get_config_value("TOOLS").split(",")
	var tool_text: String = %ToolText.text
	var unwanted_chars = ["!", "@", "#", "$", "%", ",", "."]
	for letter in unwanted_chars:
		tool_text.replace(letter, "")
	if current_tools.find(tool_text) != -1:
		current_tools.remove_at(current_tools.find(tool_text))
	ConfigHandler.update_config_setting("TOOLS", ",".join(current_tools))
	emit_signal("updated_config", "TOOLREMOVE")	
	
	
func list_tools():
	Globals.output_display_update.emit("\n".join(ConfigHandler.get_config_value("TOOLS").split(",")), false, "Informational")
	
	
func on_slider_value_change(_updated_value):
	var value_string = str(%MinAbuseScoreSlider.value).pad_decimals(2)
	%MinAbuseScoreLabel.text = "Minimum Abuse Confidence Score For Logging: %s" % value_string 

func on_drag_abuse_end(_updated_value):
	ConfigHandler.update_config_setting("MINABUSESCORE", str(%MinAbuseScoreSlider.value))
	print(ConfigHandler.get_config_value("MINABUSESCORE"))

func on_cache_days_slider_change(_updated_value):
	%CacheDaysText.text = "Cache TTL (Days): %s" % int(%CacheDaysSlider.value)

func on_drag_cache_days_end(_updated_value):
	ConfigHandler.update_config_setting("CACHE_TTL_DAYS", str(int(%CacheDaysSlider.value)))

func on_cache_max_slider_change(_updated_value):
	%CacheMaxSizeLabel.text = "Maximum Cache Size: %s" % int(%CacheMaxSizeSlider.value)

func on_drag_cache_max_end(_updated_value):
	ConfigHandler.update_config_setting("CACHE_MAX_SIZE", str(int(%CacheMaxSizeSlider.value)))
