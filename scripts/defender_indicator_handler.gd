extends Node

class_name DefenderIndicatorHandler

const REQUIRED_VALUES = [
	"indicatorValue", "indicatorType", "action",
	"severity", "description", "title",
	"recommendedActions", "expirationTime"
]

@onready var requester: RequestHandler = get_parent().get_node("%HTTPRequestHandler")
@onready var dialog_handler: FileDialog = %CsvDialog

var csv_file_path: String

func _ready() -> void:
	%FileDialogButton.pressed.connect(open_file_dialog)
	%AddIndicatorButton.pressed.connect(add_single_indicator)
	%AddIndicators.pressed.connect(multi_add_indicator)
	%FilePathText.text_changed.connect(set_csv_file_path)
	dialog_handler.file_selected.connect(set_csv_file_path)
	dialog_handler.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog_handler.filters = ["*.csv ; CSV Files"]
	dialog_handler.access = FileDialog.ACCESS_FILESYSTEM
	%DownloadTemplate.pressed.connect(download_csv_template)
	
func open_file_dialog() -> void:
	dialog_handler.popup_centered(Vector2i(1000, 500))


func set_csv_file_path(path: String) -> void:
	if not FileAccess.file_exists(path):
		if not %AddIndicators.disabled:
				%AddIndicators.disabled = true
		return
	csv_file_path = path
	%FilePathText.text = csv_file_path
	%AddIndicators.disabled = false

# To-Do - Verify columns contain all required keys.
func load_csv() -> Array:
	var rows: Array =  CsvHelper.read_csv_dict(csv_file_path)
	return rows
	
func multi_add_indicator() -> void:
	var indicator_list = load_csv()
	var itters = 0
	Globals.toggle_progress_visibility.emit()
	for indicator in indicator_list:
		var converted: rIndicator = csv_row_to_indicator(indicator)
		if not converted:
			Globals.output_display_update.emit("[color=red]Failed to create indicator out of row:[/color]\n%s" % [str(indicator)], false, "Error")
			continue
			
		await execute_add_indicator(converted)
		itters += 1
		Globals.emit_signal("progress_bar_update", "IP", itters, len(indicator_list))
		await get_tree().create_timer(1).timeout



func csv_row_to_indicator(row: Dictionary) -> rIndicator:
	var type_str: String = String(row.get("indicatorType", "")).strip_edges()
	var action_str: String = String(row.get("action", "")).strip_edges()
	var severity_str: String = String(row.get("severity", "")).strip_edges()

	var type_value = rIndicator.IndicatorType.get(type_str, null)
	var action_value = rIndicator.IndicatorAction.get(action_str, null)
	var severity_value = rIndicator.Severity.get(severity_str, null)

	if type_value == null:
		push_error("Invalid indicatorType: %s" % type_str)
		return null
	if action_value == null:
		push_error("Invalid action: %s" % action_str)
		return null
	if severity_value == null:
		push_error("Invalid severity: %s" % severity_str)
		return null

	var patched: Dictionary = row.duplicate(true)

	patched["indicatorValue"] = String(patched.get("indicatorValue", "")).strip_edges()
	patched["description"] = String(patched.get("description", "")).strip_edges()
	patched["title"] = String(patched.get("title", "")).strip_edges()
	patched["recommendedActions"] = String(patched.get("recommendedActions", "")).strip_edges()
	patched["expirationTime"] = String(patched.get("expirationTime", "")).strip_edges()
	patched["indicatorType"] = type_value
	patched["action"] = action_value
	patched["severity"] = severity_value

	return setup_indicator(patched)

	



func add_single_indicator() -> void:
	var indicator: rIndicator = setup_indicator(_get_indicator_info())
	execute_add_indicator(indicator)
		

func execute_add_indicator(indicator: rIndicator) -> void:
	var output_string: String = "[color=green]Adding indicator: [/color]\n\n"
	
	for key in indicator.to_dict().keys():
		output_string += "[color=gray]%s[/color] - %s\n" % [key, indicator.to_dict().get(key)]
	Globals.output_display_update.emit(output_string, false, "Informational")
	var result: Dictionary = await requester.create_defender_indicator(indicator)

	if result.get("error"):
		Globals.output_display_update.emit("Error occurred adding indicator: %s" % result.get("error"), false, "Error")
		return
	
	var display_string: String = "[color=green]Successfully added indicator.[/color]\nID: %s\nValue: %s\n Action: %s" % [result.get("id"), result.get("indicatorValue"), result.get("action")]	
	
	Globals.output_display_update.emit(display_string, true, "Informational")


func _get_indicator_info() -> Dictionary:
	return {
		"indicatorValue": %IndicatorValue.get_attribute_text(),
		"indicatorType": %IndicatorType.get_attribute_result(),
		"action": %IndicatorAction.get_attribute_result(),
		"severity": %IndicatorSeverity.get_attribute_result(),
		"description": %IndicatorDescription.get_attribute_text(),
		"title": %IndicatorTitle.get_attribute_text(),
		"recommendedActions": %IndicatorRecommendedAction.get_attribute_text(),
		"expirationTime": %IndicatorExpirationTime.get_attribute_text()
	}

func setup_indicator(indicator_values: Dictionary) -> rIndicator:
	var missing: Array[String] = []
	for k in REQUIRED_VALUES:
		if not indicator_values.has(k):
			missing.append(k)

	var extra: Array[String] = []
	for k in indicator_values.keys():
		if not REQUIRED_VALUES.has(k):
			extra.append(k)

	if missing.size() > 0 or extra.size() > 0:
		push_error(
			"Input indicator values do not match required values.\nMissing: %s\nExtra: %s"
			% [missing, extra]
		)
		return null

	for key in REQUIRED_VALUES:

		if key == "recommendedActions":
			continue

		var v = indicator_values.get(key)

		if v == null:
			push_error("%s is invalid (null). Couldn't create indicator." % key)
			return null

		if v is String and v.strip_edges().is_empty():
			push_error("%s is invalid (empty string). Couldn't create indicator." % key)
			return null

	var value: String = String(indicator_values["indicatorValue"]).strip_edges()
	var t: int = int(indicator_values["indicatorType"])

	match t:
		rIndicator.IndicatorType.IpAddress:
			if not Helpers.is_valid_ipv4(value) and not Helpers.is_valid_ipv6(value):
				push_error("indicatorValue is not a valid IP address: %s" % value)
				Globals.output_display_update.emit("indicatorValue is not a valid IP address: %s" % [value], false, "Error")

				return null

		rIndicator.IndicatorType.DomainName:
			var domain := Helpers.extract_domain(value)
			if not Helpers.is_valid_domain(domain):
				push_error("indicatorValue is not a valid domain name: %s" % value)
				Globals.output_display_update.emit("indicatorValue is not a valid domain name: %s" % [value], false, "Error")
				return null
			value = domain

		rIndicator.IndicatorType.Url:
			if not (value.begins_with("http://") or value.begins_with("https://")):
				push_error("indicatorValue must start with http:// or https:// for Url type: %s" % value)
				Globals.output_display_update.emit("indicatorValue must start with http:// or https:// for Url type: %s" % [value], false, "Error")

				return null

		rIndicator.IndicatorType.FileMd5:
			var re_md5 := RegEx.new()
			re_md5.compile("^[A-Fa-f0-9]{32}$")
			if re_md5.search(value) == null:
				push_error("indicatorValue is not a valid MD5 hash: %s" % value)
				Globals.output_display_update.emit("indicatorValue is not a valid MD5 hash: %s" % [value], false, "Error")

				return null

		rIndicator.IndicatorType.FileSha1:
			var re_sha1 := RegEx.new()
			re_sha1.compile("^[A-Fa-f0-9]{40}$")
			if re_sha1.search(value) == null:
				push_error("indicatorValue is not a valid SHA1 hash: %s" % value)
				Globals.output_display_update.emit("indicatorValue is not a valid SHA1 hash: %s" % [value], false, "Error")
				return null

		rIndicator.IndicatorType.FileSha256:
			var re_sha256 := RegEx.new()
			re_sha256.compile("^[A-Fa-f0-9]{64}$")
			if re_sha256.search(value) == null:
				push_error("indicatorValue is not a valid SHA256 hash: %s" % value)
				Globals.output_display_update.emit("indicatorValue is not a valid SHA256 hash: %s" % [value], false, "Error")
				return null

		rIndicator.IndicatorType.CertificateThumbprint:
			var re_thumb := RegEx.new()
			re_thumb.compile("^[A-Fa-f0-9]{40}$")
			if re_thumb.search(value) == null:
				push_error("indicatorValue is not a valid certificate thumbprint (expected 40 hex): %s" % value)				
				Globals.output_display_update.emit("indicatorValue is not a valid certificate thumbprint (expected 40 hex): %s" % [value], false, "Error")
				return null

	indicator_values["indicatorValue"] = value

	var indicator: rIndicator = rIndicator.new()
	indicator.indicatorValue = indicator_values["indicatorValue"]
	indicator.indicatorType = indicator_values["indicatorType"]
	indicator.indicatorAction = indicator_values["action"]
	indicator.indicatorSeverity = indicator_values["severity"]
	indicator.indicatorDescription = indicator_values["description"]
	indicator.indicatorTitle = indicator_values["title"]
	indicator.indicatorRecommendedActions = indicator_values.get("recommendedActions", "")
	indicator.indicatorExpirationTime = indicator_values["expirationTime"]

	return indicator


func download_csv_template() -> void:
	var url: String = "https://raw.githubusercontent.com/Noah-r70527/IoC-Lookup-Tool/test/assets/DefenderIndicatorTemplateCsv/indicator_template_csv.csv"
	var path: String = "template.csv"
	await requester.download_template_csv(url, path)
	if FileAccess.file_exists(path):
		Globals.output_display_update.emit("Successfully downloaded the template.", false, "Informational")
	else: 
		Globals.output_display_update.emit("Failed to download the template.", false, "Error")
