extends Node

class_name ToolLogger

@onready var file_access: FileAccess 

var LOG_FILE_PATH = "%s/logs/NDRTechSecurityTool.log" % OS.get_executable_path().get_base_dir()

func _ready() -> void:
	var dir_access = DirAccess.open(OS.get_executable_path().get_base_dir())
	if not dir_access.dir_exists("%s/logs" % OS.get_executable_path().get_base_dir()):
		dir_access.make_dir("%s/logs" % OS.get_executable_path().get_base_dir())
	var file_exists: bool = FileAccess.file_exists(LOG_FILE_PATH)
	if file_exists:
		file_access = FileAccess.open(LOG_FILE_PATH, FileAccess.READ_WRITE)
	else:
		file_access = FileAccess.open(LOG_FILE_PATH, FileAccess.WRITE)
	Globals.output_display_update.connect(_write_to_log)
	
func _exit_tree() -> void:
	file_access.close()
	
func _write_to_log(text: String, _append: bool, level="Informational"):
	var line: String = "%s - %s - %s" % [Time.get_datetime_string_from_system(), level, text]
	file_access.store_line(line.replace("\n", " -- "))

	
