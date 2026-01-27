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


func _ready(): 
	get_tool_list()
	single_button.pressed.connect(do_single_IP_Lookup)
	network_button.pressed.connect(do_network_lookup)
	report_button.pressed.connect(do_report_lookup)
	multi_button.pressed.connect(do_multi_lookup)
	option_button.item_selected.connect(swap_selected_tool)
	if !ConfigHandler.get_config_value("ABUSE_IP_API_KEY") or ConfigHandler.get_config_value("ABUSE_IP_API_KEY") == "...":
		for button in [single_button, multi_button, network_button, report_button]:
			button.disabled = true
	
	single_text.text_changed.connect(text_changed_handler.bind(single_text))
	multi_text.text_changed.connect(text_changed_handler.bind(multi_text))
	report_text.text_changed.connect(text_changed_handler.bind(report_text))
	network_text.text_changed.connect(text_changed_handler.bind(network_text))

func get_tool_list():
	var tool_list = ConfigHandler.get_config_value("TOOLS").split(",")
	selected_option = tool_list[0]
	option_button.clear()
	for item in tool_list:
		option_button.add_item(item)
	
func swap_selected_tool(index_in):
	selected_option = option_button.get_item_text(index_in)

func do_single_IP_Lookup():
	var ip = %SingleIPText.text
	if not (Helpers.is_valid_ipv4(ip) or Helpers.is_valid_ipv6(ip)):
			Globals.emit_signal(
				"output_display_update",
				["[color=red]Improper IP entered:[/color] [color=white]%s[/color]\n\n" % [ip],
				false]
			)
			return
			
	Globals.emit_signal(
		"output_display_update",
		"[color=green]Doing IP lookup on:[/color] [color=white]%s[/color]\n\n" % [ip], 
		false
		)
		
	var result: Dictionary = await requester.make_abuseipdb_ip_request(ip)
	var output_text = Helpers.parse_ip_lookup(result)
	Globals.emit_signal("output_display_update", output_text, true)
	if result.get("data"):
		var temp = result.get("data")
		var date_time = Time.get_datetime_dict_from_system(false)
		var folder_string = "%s_%s_%s" % [date_time.year, date_time.month, date_time.day]
		var setup_data = {
			"Date": folder_string,
			"IP": temp.get("ipAddress"),
			"Entered_By": ConfigHandler.get_config_value("NAME") if ConfigHandler.get_config_value("NAME") else "Blank",
			"Detecting_System": selected_option,
			"Abuse_Score": temp.get("abuseConfidenceScore"),
			"Total_Reports": temp.get("totalReports"),
			"ISP": temp.get("isp"),
			"Country_Code": temp.get("countryCode"),
			"Hostnames": temp.get("hostnames"),
			"Block/Unblock": "Block"
		}
		var min_score: float = float(ConfigHandler.get_config_value("MINABUSESCORE"))
		if ConfigHandler.get_config_value("LOG_IP_TO_CSV") == "true" and float(setup_data.get("Abuse_Score") >= min_score):
			var dir_access = DirAccess.open("%s/IPLookups" % OS.get_executable_path().get_base_dir())
			if not dir_access.dir_exists(folder_string):
				dir_access.make_dir(folder_string)
			CsvHelper.write_csv_dict("%s/%s/single_lookup.csv" % [dir_access.get_current_dir(), folder_string],   #file name
			setup_data, # data to write
			",", # delimiter
			true # append to existing file?
			)
				
		
	
func do_network_lookup():
	pass
	

func do_report_lookup():
	pass
	
	
func do_multi_lookup():
	var ip_list = %MultiIPText.text.split("\n")
	var write_to_csv: bool = ConfigHandler.get_config_value("LOG_IP_TO_CSV") == "true"
	var min_score: float = float(ConfigHandler.get_config_value("MINABUSESCORE"))
	var date_time = Time.get_datetime_dict_from_system(false)
	var folder_string: String = "%s_%s_%s" % [date_time.year, date_time.month, date_time.day]
	var dir_access: DirAccess
	if write_to_csv:
		dir_access = DirAccess.open("%s/IPLookups" % OS.get_executable_path().get_base_dir())
		if not dir_access.dir_exists(folder_string):
			dir_access.make_dir(folder_string)
	Globals.emit_signal(
		"output_display_update",
		"Starting multi-IP lookup on %s IPs...\n\n" % [len(ip_list)], false
		)
	for ip in ip_list:
		
		if not (Helpers.is_valid_ipv4(ip) or Helpers.is_valid_ipv6(ip)):
			Globals.emit_signal(
				"output_display_update", 
				"[color=red]Improper IP entered:[/color] [color=white]%s[/color]\n\n" % [ip],
				true
			)
			continue
		Globals.emit_signal(
			"output_display_update",
			"[color=green]Doing IP lookup on:[/color] [color=white]%s[/color]\n" % [ip],
			true
		)
		var result: Dictionary = await requester.make_abuseipdb_ip_request(ip)
		
		if result.get("error"):
			break
			
		var output_text = Helpers.parse_multi_ip_lookup(result)
		Globals.emit_signal("output_display_update", output_text + "\n", true)
		if result.get("data"):
			var temp = result.get("data")
			var setup_data = {
				"Date": folder_string,
				"IP": temp.get("ipAddress"),
				"Entered_By": ConfigHandler.get_config_value("NAME") if ConfigHandler.get_config_value("NAME") else "Blank",
				"Detecting_System": selected_option,
				"Abuse_Score": temp.get("abuseConfidenceScore"),
				"Total_Reports": temp.get("totalReports"),
				"ISP": temp.get("isp"),
				"Country_Code": temp.get("countryCode"),
				"Hostnames": temp.get("hostnames"),
				"Block/Unblock": "Block/Unblock"
			}
			var abuse_score = float(setup_data.get("Abuse_Score", "0"))
			if abuse_score >= min_score and write_to_csv:
				CsvHelper.write_csv_dict("%s/%s/multi_lookup.csv" % [dir_access.get_current_dir(), folder_string],   #file name
				setup_data, # data to write
				",", # delimiter
				true # append to existing file?
				)
		await get_tree().create_timer(.5).timeout


		
func text_changed_handler(_sender: TextEdit) -> void:
	
	if ConfigHandler.get_config_value("AUTO_REARM") == "false":
		return
	var temp = Helpers.rearm_ip(_sender.text)
	if temp[1]:
		_sender.text =  temp[0]
