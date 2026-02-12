extends Control

@onready var single_url_button = %SingleURLButton
@onready var dns_lookup_button = %DNSLookupButton
@onready var multi_url_button = %MultiURLButton
@onready var multi_url_text = %MultiURLText
@onready var dns_lookup_text = %DNSLookupText
@onready var single_url_text = %SingleURLText
@onready var requester = get_parent().get_node("%HTTPRequestHandler")

var _pending := false


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




func do_single_url_Lookup():
	var url = Helpers.extract_domain(single_url_text.text)
	var is_valid = Helpers.is_valid_domain(Helpers.extract_domain(url))
	if not is_valid:
		Globals.emit_signal(
			"output_display_update", 
			"[color=red]Invalid URL Entered:[/color] [color=white]%s[/color]\n\n" % [url], 
			false,
			"Error"
			)
		return 
		
	Globals.emit_signal(
		"output_display_update", 
		"[color=green]Doing URL lookup on:[/color] [color=white]%s[/color]\n\n" % [url], 
		false,
		"Informational"
		)
	var result: Dictionary = await requester.make_virustotal_request(url, "Domain")
	var output = Helpers.parse_multi_url_lookup(result)
	Globals.emit_signal("output_display_update", output[0], true, "Informational")
	var date_time = Time.get_datetime_dict_from_system(false)
	var folder_string = "%s_%s_%s" % [date_time.year, date_time.month, date_time.day]
	if ConfigHandler.get_config_value("LOG_URL_TO_CSV") == "true":
		var dir_access = DirAccess.open("%s/URLLookups" % OS.get_executable_path().get_base_dir())
		if not dir_access.dir_exists(folder_string):
			dir_access.make_dir(folder_string)
		var setup_data = {
			"Date": folder_string
		}
		setup_data.merge(output[1])
		CsvHelper.write_csv_dict("%s/%s/url_lookups.csv" % [dir_access.get_current_dir(), folder_string],   #file name
		setup_data, # data to write
		",", # delimiter
		true # append to existing file?
		)
	
func do_dns_lookup():
	var domain = dns_lookup_text.text
	Globals.emit_signal(
		"output_display_update", 
		"[color=green]Doing DNS lookup on:[/color] [color=white]%s[/color]\n\n" % [domain], false, "Informational")
	var result_ipv4 = IP.resolve_hostname(domain, IP.TYPE_IPV4)
	var result_ipv6 = IP.resolve_hostname(domain, IP.TYPE_IPV6)
	Globals.emit_signal(
		"output_display_update", 
		"[color=green]IPv4 Result:[/color] %s\n[color=green]IPv6 Result:[/color] %s" % [result_ipv4, result_ipv6], 
		true,
		"Informational"
		)

	
func do_multi_url_lookup():
	var dir_access: DirAccess
	var write_to_csv: bool = ConfigHandler.get_config_value("LOG_URL_TO_CSV") == "true"
	var url_list = multi_url_text.text.split("\n")
	Globals.emit_signal(
		"output_display_update", 
		"Starting multi-URL lookup on %s domains...\n
		[color=red][b]Because of Virus Total's Rate-Limiting rules, only one request will go through every 15 seconds.[/b][/color]
		\n\n" % [len(url_list)], 
		false,
		"Informational"
		)
	var date_time = Time.get_datetime_dict_from_system(false)
	var folder_string = "%s_%s_%s" % [date_time.year, date_time.month, date_time.day]
	if write_to_csv:
		dir_access = DirAccess.open("%s/URLLookups" % OS.get_executable_path().get_base_dir())
		if not dir_access.dir_exists(folder_string):
			dir_access.make_dir(folder_string)
			
	Globals.emit_signal("toggle_progress_visibility")
	var itters = 0	
	for url in url_list:
		
		var is_valid = Helpers.is_valid_domain(Helpers.extract_domain(url))
		if not is_valid:
			Globals.emit_signal(
				"output_display_update", 
				"[color=red]Invalid URL Entered:[/color] [color=white]%s[/color]\n\n" % [url],
				true,
				"Error"
				)
			continue
			 
		Globals.emit_signal(
			"output_display_update", 
			"[color=green]Doing URL lookup on:[/color] [color=white]%s[/color]\n" % [url],
			true,
			"Informational"
			)
		var result: Dictionary = await requester.make_virustotal_request(url, "Domain")
		itters += 1
		Globals.emit_signal("progress_bar_update", "IP", itters, len(url_list))
		
		if result.get("error"):
			Globals.output_display_update.emit("Error occurred while doing multi-lookup: %s" % result.get("error"), false, "Error")
			break
			
		var output = Helpers.parse_multi_url_lookup(result)
		Globals.emit_signal("output_display_update", output[0], true)
		var setup_data = {
			"Date": folder_string
		}
		setup_data.merge(output[1])
		if write_to_csv and dir_access:
			CsvHelper.write_csv_dict("%s/%s/url_lookups.csv" % [dir_access.get_current_dir(), folder_string],   #file name
		setup_data, # data to write
		",", # delimiter
		true # append to existing file?
		)
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

	var lines := sender.text.split("\n", false)
	var any_changed := false

	for i in range(lines.size()):
		var before := lines[i]
		var res = Helpers.rearm_url(before)
		var after: String = res[0]

		if after != before:
			lines[i] = after
			any_changed = true

	if !any_changed:
		return

	var line := sender.get_caret_line()
	var col := sender.get_caret_column()

	sender.text = "\n".join(lines)

	line = clamp(line, 0, sender.get_line_count() - 1)
	col = clamp(col, 0, sender.get_line(line).length())
	sender.set_caret_line(line)
	sender.set_caret_column(col)
