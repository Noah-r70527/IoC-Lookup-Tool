extends Node

func read_csv_dict(file_path: String, delimiter: String = ",") -> Array:
	var rows: Array = []
	if not FileAccess.file_exists(file_path):
		push_error("File not found: %s" % file_path)
		return rows

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: %s" % file_path)
		return rows

	var headers: Array = []
	var line_number := 0
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line == "":
			continue

		var columns := line.split(delimiter, false)
		if line_number == 0:
			headers = columns
		else:
			var row: Dictionary = {}
			for i in range(min(headers.size(), columns.size())):
				row[headers[i]] = columns[i]
			rows.append(row)
		line_number += 1
	file.close()
	return rows


func write_csv_dict(file_path: String, data: Dictionary, delimiter: String = ",", append: bool = true) -> void:
	if data.is_empty():
		push_warning("No data provided to write.")
		return

	var headers = data.keys()
	var file_exists := FileAccess.file_exists(file_path)
	var write_mode := FileAccess.WRITE


	if append and file_exists:
		write_mode = FileAccess.READ_WRITE
	else:
		write_mode = FileAccess.WRITE

	var file := FileAccess.open(file_path, write_mode)
	if file == null:
		push_error("Failed to open file: %s" % file_path)
		return
	
	print(file.get_path())
	if append and file_exists:
		file.seek_end()
	else:
		file.store_line(delimiter.join(headers))
	
	var row_values = []
	for header in headers:
		row_values.append(str(data.get(header, "")))
	file.store_line(delimiter.join(row_values))

	file.close()
