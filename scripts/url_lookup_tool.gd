extends Control

@onready var single_url_button = %SingleURLButton
@onready var dns_lookup_button = %DNSLookupButton
@onready var multi_url_button = %MultiURLButton
@onready var multi_url_text = %MultiURLText
@onready var dns_lookup_text = %DNSLookupText
@onready var single_url_text = %SingleURLText
@onready var requester = get_parent().get_node("%HTTPRequestHandler")

var _pending: bool = false


func _ready():
	single_url_button.pressed.connect(do_single_url_Lookup)
	multi_url_button.pressed.connect(do_multi_url_lookup)
	dns_lookup_button.pressed.connect(do_dns_lookup)
	if !ConfigHandler.get_config_value("VT_API_KEY") or ConfigHandler.get_config_value("VT_API_KEY") == "...":
		for button in [multi_url_button, single_url_button, dns_lookup_button]:
			button.disabled = true
	single_url_text.text_changed.connect(text_changed_handler.bind(single_url_text))
	multi_url_text.text_changed.connect(text_changed_handler.bind(multi_url_text))
	dns_lookup_text.text_changed.connect(text_changed_handler.bind(dns_lookup_text))


func _get_date_folder() -> String:
	var dt = Time.get_datetime_dict_from_system(false)
	return "%s_%s_%s" % [dt.year, dt.month, dt.day]

func _write_url_csv_if_needed(setup_data: Dictionary, folder_string: String) -> void:
	if ConfigHandler.get_config_value("LOG_URL_TO_CSV") != "true":
		return
	var dir_access = DirAccess.open("%s/URLLookups" % OS.get_executable_path().get_base_dir())
	if not dir_access.dir_exists(folder_string):
		dir_access.make_dir(folder_string)
	CsvHelper.write_csv_dict(
		"%s/%s/url_lookups.csv" % [dir_access.get_current_dir(), folder_string],
		setup_data, ",", true
	)

func _emit_invalid_url(url: String, append: bool) -> void:
	Globals.emit_signal(
		"output_display_update",
		"[color=red]Invalid URL Entered:[/color] [color=white]%s[/color]\n\n" % [url],
		append, "Error"
	)

func _emit_url_lookup_start(url: String, append: bool) -> void:
	Globals.emit_signal(
		"output_display_update",
		"[color=green]Doing URL lookup on:[/color] [color=white]%s[/color]\n\n" % [url],
		append, "Informational"
	)

func _emit_cache_hit(url: String, append: bool) -> void:
	Globals.emit_signal(
		"output_display_update",
		"[color=yellow][b]Cache hit[/b] for[/color] [color=white]%s[/color][color=yellow] — showing cached result.[/color]\n\n" % [url],
		append, "Informational"
	)

func _format_cached_url(entry: Dictionary) -> String:
	var s: String = ""
	for key: String in ["ID", "VT Link", "Total", "Malicious", "Suspicious", "Undetected", "Harmless", "Timeout"]:
		s += "[color=gray]%s[/color]: [color=white]%s[/color]\n" % [key, entry.get(key, "N/A")]
	return s

func _cache_url_result(domain: String, parsed_results: Dictionary, folder_string: String) -> void:
	var entry: Dictionary = {
		"indicatorValue": domain,
		"indicatorType": "DomainName",
		"indicatorCreation": folder_string,
	}
	entry.merge(parsed_results)
	Globals.add_ioc(entry, true)


func do_single_url_Lookup():
	var url: String = Helpers.extract_domain(single_url_text.text)
	if not Helpers.is_valid_domain(url):
		_emit_invalid_url(url, false)
		return

	var cached: Dictionary = Globals.find_in_cache(url)
	if not cached.is_empty():
		_emit_cache_hit(url, false)
		Globals.emit_signal("output_display_update", _format_cached_url(cached), true, "Informational")
		return

	_emit_url_lookup_start(url, false)
	var result: Dictionary = await requester.make_virustotal_request(url, "Domain")
	var output: Array = Helpers.parse_multi_url_lookup(result)
	Globals.emit_signal("output_display_update", output[0], true, "Informational")

	var folder_string: String = _get_date_folder()
	var setup_data: Dictionary = {"Date": folder_string}
	setup_data.merge(output[1])
	_write_url_csv_if_needed(setup_data, folder_string)
	_cache_url_result(url, output[1], folder_string)


func do_dns_lookup():
	var domain = dns_lookup_text.text
	Globals.emit_signal("output_display_update",
		"[color=green]Doing DNS lookup on:[/color] [color=white]%s[/color]\n\n" % [domain],
		false, "Informational")
	var result_ipv4 = IP.resolve_hostname(domain, IP.TYPE_IPV4)
	var result_ipv6 = IP.resolve_hostname(domain, IP.TYPE_IPV6)
	Globals.emit_signal("output_display_update",
		"[color=green]IPv4 Result:[/color] %s\n[color=green]IPv6 Result:[/color] %s" % [result_ipv4, result_ipv6],
		true, "Informational")


func do_multi_url_lookup():
	var url_list = multi_url_text.text.split("\n")
	var folder_string = _get_date_folder()

	Globals.emit_signal("output_display_update",
		"Starting multi-URL lookup on %s domains...\n\n[color=red][b]Because of Virus Total's Rate-Limiting rules, only one request will go through every 15 seconds.[/b][/color]\n\n" % [len(url_list)],
		false, "Informational")
	Globals.emit_signal("toggle_progress_visibility")

	var itters: int = 0
	for url: String in url_list:
		var domain: String = Helpers.extract_domain(url)
		if not Helpers.is_valid_domain(domain):
			_emit_invalid_url(url, true)
			continue

		itters += 1
		Globals.emit_signal("progress_bar_update", "IP", itters, len(url_list))

		var cached: Dictionary = Globals.find_in_cache(domain)
		if not cached.is_empty():
			_emit_cache_hit(domain, true)
			Globals.emit_signal("output_display_update", _format_cached_url(cached) + "\n", true, "Informational")
			continue

		_emit_url_lookup_start(url, true)
		var result: Dictionary = await requester.make_virustotal_request(url, "Domain")

		if result.get("error"):
			Globals.output_display_update.emit("Error occurred while doing multi-lookup: %s" % result.get("error"), false, "Error")
			break

		var output: Array = Helpers.parse_multi_url_lookup(result)
		Globals.emit_signal("output_display_update", output[0] + "\n", true)
		var setup_data: Dictionary = {"Date": folder_string}
		setup_data.merge(output[1])
		_write_url_csv_if_needed(setup_data, folder_string)
		_cache_url_result(domain, output[1], folder_string)

		await get_tree().create_timer(15).timeout

	Globals.emit_signal("toggle_progress_visibility")


func text_changed_handler(sender: TextEdit) -> void:
	if ConfigHandler.get_config_value("AUTO_REARM") == "false":
		return
	if _pending:
		return

	_pending = true
	call_deferred("_apply_rearm", sender)

func _apply_rearm(sender: TextEdit) -> void:
	_pending = false

	var lines: PackedStringArray = sender.text.split("\n", false)
	var any_changed: bool = false

	for i in range(lines.size()):
		var before: String = lines[i]
		var res = Helpers.rearm_url(before)
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
