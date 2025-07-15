extends Control

func _ready():
	var new_data = [
		{"Name": "Alice", "Age": 30},
		{"Name": "Bob", "Age": 40}
		]
	CsvHelper.write_csv_dict("res://test.csv", new_data)
