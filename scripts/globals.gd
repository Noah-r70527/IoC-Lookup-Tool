extends Node

signal output_display_update(text: String, append: bool)
signal progress_bar_update(lookup_type: String, current_number: int, max_number: int)
signal toggle_progress_visibility

var version: String = "v1.5"

var SCENE_TO_TOOL_NAME = {
	"res://scenes/tools/IPLookupTool.tscn": "IP Lookup Tool",
	"res://scenes/tools/UrlLookupTool.tscn": "URL Lookup Tool",
	"res://scenes/settings/Settings.tscn": "Settings",
	"res://scenes/tools/HashLookupTool.tscn": "Hash Lookup Tool",
	"res://scenes/tools/DefangTool.tscn": "Defang Tool"
}

func return_scene_dict() -> Dictionary:
	return SCENE_TO_TOOL_NAME

func return_version() -> String:
	return version
