extends Control

@onready var single_button: Button = %SingleIPButton
@onready var network_button: Button = %NetworkLookupButton
@onready var multi_button: Button = %MultiIPButton
@onready var report_button: Button = %ReportLookupButton
@onready var single_text: TextEdit = %SingleIPText
@onready var network_text: TextEdit = %NetworkLookupText
@onready var multi_text: TextEdit = %MultiIPText
@onready var report_text: TextEdit = %ReportLookupText
@onready var option_button: OptionButton = %ToolOption
@onready var selected_option: String
@onready var requester = get_parent().get_node("%HTTPRequestHandler")

var _pending_ip: bool = false

func _ready():
	get_tool_list()
	single_button.pressed.connect(do_single_IP_Lookup)
	network_button.pressed.connect(do_network_lookup)
	report_button.pressed.connect(do_report_lookup)
	multi_button.pressed.connect(do_multi_lookup)
	option_button.item_selected.connect(swap_selected_tool)
	single_text.text_changed.connect(text_changed_handler.bind(single_text))
	multi_text.text_changed.connect(text_changed_handler.bind(multi_text))
	report_text.text_changed.connect(text_changed_handler.bind(report_text))
	network_text.text_changed.connect(text_changed_handler.bind(network_text))
	if !ConfigHandler.get_config_value("ABUSE_IP_API_KEY") or ConfigHandler.get_config_value("ABUSE_IP_API_KEY") == "...":
		for button in [single_button, multi_button, network_button, report_button]:
			button.disabled = true


func get_tool_list():
	var tool_list = ConfigHandler.get_config_value("TOOLS").split(",")
	selected_option = tool_list[0]
	option_button.clear()
	for item in tool_list:
		option_button.add_item(item)

func swap_selected_tool(index_in):
	selected_option = option_button.get_item_text(index_in)



func _get_date_folder() -> String:
	var dt = Time.get_datetime_dict_from_system(false)
	return "%s_%s_%s" % [dt.year, dt.month, dt.day]

func _build_setup_data(data: Dictionary, folder_string: String, block_value: String) -> Dictionary:
	return {
		"Date": folder_string,
		"IP": data.get("ipAddress"),
		"Entered_By": ConfigHandler.get_config_value("NAME") if ConfigHandler.get_config_value("NAME") else "Blank",
		"Detecting_System": selected_option,
		"Abuse_Score": data.get("abuseConfidenceScore"),
		"Total_Reports": data.get("totalReports"),
		"ISP": data.get("isp"),
		"Country_Code": data.get("countryCode"),
		"Hostnames": data.get("hostnames"),
		"Block/Unblock": block_value
	}

func _write_csv_if_needed(setup_data: Dictionary, folder_string: String, min_score: float, filename: String) -> void:
	if ConfigHandler.get_config_value("LOG_IP_TO_CSV") != "true":
		return
	if float(str(setup_data.get("Abuse_Score", 0))) < min_score:
		return
	var dir_access = DirAccess.open("%s/IPLookups" % OS.get_executable_path().get_base_dir())
	if not dir_access.dir_exists(folder_string):
		dir_access.make_dir(folder_string)
	CsvHelper.write_csv_dict(
		"%s/%s/%s" % [dir_access.get_current_dir(), folder_string, filename],
		setup_data, ",", true
	)

func _emit_invalid_ip(ip: String, append: bool) -> void:
	Globals.emit_signal(
		"output_display_update",
		"[color=red]Improper IP entered:[/color] [color=white]%s[/color]\n\n" % [ip],
		append, "Error"
	)

func _emit_lookup_start(ip: String, append: bool) -> void:
	Globals.emit_signal(
		"output_display_update",
		"[color=green]Doing IP lookup on:[/color] [color=white]%s[/color]\n\n" % [ip],
		append, "Informational"
	)

func _emit_cache_hit(ip: String, append: bool) -> void:
	Globals.emit_signal(
		"output_display_update",
		"[color=yellow][b]Cache hit[/b] for[/color] [color=white]%s[/color][color=yellow] — showing cached result.[/color]\n\n" % [ip],
		append, "Informational"
	)

func _format_cached_ip(entry: Dictionary) -> String:
	var s: String = ""
	for key: String in ["IP", "Country_Code", "Abuse_Score", "ISP", "Hostnames", "Total_Reports"]:
		s += "[color=gray]%s[/color]: [color=white]%s[/color]\n" % [key, entry.get(key, "N/A")]
	return s

func _cache_ip_result(ip: String, setup_data: Dictionary, folder_string: String) -> void:
	var entry: Dictionary = {
		"indicatorValue": ip,
		"indicatorType": "IpAddress",
		"indicatorCreation": folder_string,
	}
	entry.merge(setup_data)
	Globals.add_ioc(entry, true)


func do_single_IP_Lookup():
	var ip: String = %SingleIPText.text
	if not (Helpers.is_valid_ipv4(ip) or Helpers.is_valid_ipv6(ip)):
		_emit_invalid_ip(ip, false)
		return

	var cached: Dictionary = Globals.find_in_cache(ip)
	if not cached.is_empty():
		_emit_cache_hit(ip, false)
		Globals.emit_signal("output_display_update", _format_cached_ip(cached), true, "Informational")
		return

	_emit_lookup_start(ip, false)
	var result: Dictionary = await requester.make_abuseipdb_ip_request(ip)
	Globals.emit_signal("output_display_update", Helpers.parse_ip_lookup(result), true, "Informational")

	if result.get("data"):
		var folder_string: String = _get_date_folder()
		var setup_data: Dictionary = _build_setup_data(result.get("data"), folder_string, "Block")
		var min_score: float = float(ConfigHandler.get_config_value("MINABUSESCORE"))
		_write_csv_if_needed(setup_data, folder_string, min_score, "single_lookup.csv")
		_cache_ip_result(ip, setup_data, folder_string)


# To-Do
func do_network_lookup():
	pass

# To-Do
func do_report_lookup():
	pass


func do_multi_lookup():
	var ip_list: Array = %MultiIPText.text.split("\n")
	var min_score: float = float(ConfigHandler.get_config_value("MINABUSESCORE"))
	var folder_string: String = _get_date_folder()

	Globals.emit_signal("output_display_update",
		"Starting multi-IP lookup on %s IPs...\n\n" % [len(ip_list)], false, "Informational")
	Globals.emit_signal("toggle_progress_visibility")

	var itters: int = 0
	for ip: String in ip_list:
		if not (Helpers.is_valid_ipv4(ip) or Helpers.is_valid_ipv6(ip)):
			_emit_invalid_ip(ip, true)
			continue

		itters += 1
		Globals.emit_signal("progress_bar_update", "IP", itters, len(ip_list))

		var cached: Dictionary = Globals.find_in_cache(ip)
		if not cached.is_empty():
			_emit_cache_hit(ip, true)
			Globals.emit_signal("output_display_update", _format_cached_ip(cached) + "\n", true, "Informational")
			continue

		_emit_lookup_start(ip, true)
		var result: Dictionary = await requester.make_abuseipdb_ip_request(ip)

		if result.get("error"):
			Globals.output_display_update.emit("Error occurred while doing multi-lookup: %s" % result.get("error"), false, "Error")
			break

		Globals.emit_signal("output_display_update", Helpers.parse_multi_ip_lookup(result) + "\n", true, "Informational")

		if result.get("data"):
			var setup_data: Dictionary = _build_setup_data(result.get("data"), folder_string, "Block/Unblock")
			_write_csv_if_needed(setup_data, folder_string, min_score, "multi_lookup.csv")
			_cache_ip_result(ip, setup_data, folder_string)

		await get_tree().create_timer(1).timeout

	Globals.emit_signal("toggle_progress_visibility")


func text_changed_handler(sender: TextEdit) -> void:
	if ConfigHandler.get_config_value("AUTO_REARM") == "false":
		return
	if _pending_ip:
		return

	_pending_ip = true
	call_deferred("_apply_rearm_ip", sender)

func _apply_rearm_ip(sender: TextEdit) -> void:
	_pending_ip = false

	var lines: PackedStringArray = sender.text.split("\n", false)
	var any_changed: bool = false

	for i in range(lines.size()):
		var before: String = lines[i]
		var res = Helpers.rearm_ip(before)
		var after: String = res[0]

		if after != before:
			lines[i] = after
			any_changed = true

	if !any_changed:
		return

	var line: int = sender.get_caret_line()
	var col: int = sender.get_caret_column()

	sender.text = "\n".join(lines)

	line = clamp(line, 0, sender.get_line_count() - 1)
	col = clamp(col, 0, sender.get_line(line).length())
	sender.set_caret_line(line)
	sender.set_caret_column(col)
