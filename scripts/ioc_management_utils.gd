extends Node

class_name IocManagementUtils


var cached_ioc: Array


func init_ioc_array() -> void:
	cached_ioc = load_from_json()
	


func save_to_json(file_path: String = "%s/cached//save_file.json" % OS.get_executable_path().get_base_dir()):
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	for ioc in cached_ioc:
		file.store_line(JSON.stringify(ioc))
	file.close()
	
	
func load_from_json(file_path: String = "%s/cached//save_file.json" % [OS.get_executable_path().get_base_dir()]):
	
	var rows = []
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: %s" % file_path)
		return rows
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var json = JSON.parse_string(line)
		rows.append(json)

	file.close()
	return rows


func add_ioc(ioc_json: Dictionary) -> bool:
	cached_ioc.append(ioc_json)
	return true
	
func remove_ioc(ioc_value: String) -> bool:
	var updated_array = []
	for ioc in cached_ioc:
		if not ioc.get("indicatorValue") == ioc_value:
			updated_array.append(ioc)
	cached_ioc = updated_array
	return true
		
