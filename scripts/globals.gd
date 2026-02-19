extends Node

signal output_display_update(text: String, append: bool, log_level: String)
signal progress_bar_update(lookup_type: String, current_number: int, max_number: int)
signal toggle_progress_visibility

var version: String = "v%s" % ProjectSettings.get_setting("application/config/version")
var ioc_management_utils: IocManagementUtils

var SCENE_TO_TOOL_NAME = {
	"res://scenes/tools/IPLookupTool.tscn": "IP Lookup Tool",
	"res://scenes/tools/UrlLookupTool.tscn": "URL Lookup Tool",
	"res://scenes/settings/Settings.tscn": "Settings",
	"res://scenes/tools/HashLookupTool.tscn": "Hash Lookup Tool",
	"res://scenes/tools/DefangTool.tscn": "Defang Tool",
	"res://scenes/tools/DefenderIndicatorTool.tscn": "Defender Indicator Tool"
}

func _ready() -> void:
	ioc_management_utils = IocManagementUtils.new()
	ioc_management_utils.init_ioc_array()

func return_scene_dict() -> Dictionary:
	return SCENE_TO_TOOL_NAME

func return_version() -> String:
	return version
	
func return_ioc_cache() -> Array:
	return ioc_management_utils.cached_ioc
	
func save_ioc_cache() -> void:
	ioc_management_utils.save_to_json()
	
func add_ioc(ioc_json: Dictionary, force_save: bool) -> void:
	ioc_management_utils.add_ioc(ioc_json)
	var cache_max_size: int = int(ConfigHandler.get_config_value("CACHE_MAX_SIZE", "1000"))
	if ioc_management_utils.cached_ioc.size() > cache_max_size:
		ioc_management_utils.cached_ioc = ioc_management_utils.cached_ioc.slice(ioc_management_utils.cached_ioc.size() - cache_max_size)
	if force_save:
		ioc_management_utils.save_to_json()
	
func remove_ioc(ioc_value: String, force_save: bool) -> void:
	ioc_management_utils.remove_ioc(ioc_value)
	if force_save:
		ioc_management_utils.save_to_json()

func find_in_cache(value: String) -> Dictionary:
	var ttl_days: int = int(ConfigHandler.get_config_value("CACHE_TTL_DAYS", "7"))
	var now: float = Time.get_unix_time_from_system()
	for entry: Dictionary in ioc_management_utils.cached_ioc:
		if entry.get("indicatorValue") != value:
			continue
		var creation: String = entry.get("indicatorCreation", "")
		if creation.is_empty():
			return entry
		var parts: PackedStringArray = creation.split("_")
		if parts.size() < 3:
			return entry
		var cache_time: float = Time.get_unix_time_from_datetime_dict({
			"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]),
			"hour": 0, "minute": 0, "second": 0
		})
		if (now - cache_time) / 86400.0 <= float(ttl_days):
			return entry
	return {}
