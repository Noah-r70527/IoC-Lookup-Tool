extends Control

@onready var single_button = %SingleIPButton
@onready var network_button = %NetworkLookupButton
@onready var multi_button = %MultiIPButton
@onready var report_button = %ReportLookupButton
@onready var single_text = %SingleIPText
@onready var network_text = %NetworkLookupText
@onready var multi_text = %MultiIPText
@onready var report_text = %ReportLookupText
@onready var option_button = %ToolOption
@onready var selected_option: String = "Sentinel"
@onready var requester = get_parent().get_node("%HTTPRequestHandler")
@onready var output = get_parent().get_node("%OutputDisplay")


func _ready(): 
	single_button.pressed.connect(do_single_IP_Lookup)
	network_button.pressed.connect(do_network_lookup)
	report_button.pressed.connect(do_report_lookup)
	multi_button.pressed.connect(do_multi_lookup)
	option_button.item_selected.connect(swap_selected_tool)
	if !ConfigHandler.get_config_value("ABUSE_IP_API_KEY"):
		for button in [single_button, multi_button, network_button, report_button]:
			button.disabled = true


func swap_selected_tool(index_in):
	selected_option = option_button.get_item_text(index_in)

func do_single_IP_Lookup():
	output.clear()
	var ip = %SingleIPText.text
	output.append_text("[color=green]Doing IP lookup on:[/color] [color=white]%s[/color]\n\n" % ip)
	var result: Dictionary = await requester.make_abuseipdb_ip_request(ip)
	print(result)
	var output_text = Helpers.parse_ip_lookup(result)
	output.append_text(output_text)
	if ConfigHandler.get_config_value("LOG_IP_TO_CSV") == "true":
		var dir_access = DirAccess.open("%s/IPLookups" % OS.get_executable_path().get_base_dir())
		var date_time = Time.get_datetime_dict_from_system(false)
		var folder_string = "%s_%s_%s" % [date_time.year, date_time.month, date_time.day]
		if not dir_access.dir_exists(folder_string):
			dir_access.make_dir(folder_string)
		var temp = result.get("data")
		var setup_data = {
			"Date": folder_string,
			"IP": temp.get("ipAddress"),
			"Entered_By": ConfigHandler.get_config_value("NAME") if ConfigHandler.get_config_value("NAME") else "Blank",
			"Detecting_System": selected_option,
			"Abuse_Score": temp.get("abuseConfidenceScore
			"),
			"Total_Reports": temp.get("totalReports"),
			"ISP": temp.get("isp"),
			"Country_Code": temp.get("countryCode"),
			"Hostnames": temp.get("hostnames"),
			"Block/Unblock": "Block"
		}
		CsvHelper.write_csv_dict("%s/%s/single_lookup.csv" % [dir_access.get_current_dir(), folder_string],   #file name
		[setup_data], # data to write
		",", # delimiter
		true # append to existing file?
		)
		
	
func do_network_lookup():
	pass
	

func do_report_lookup():
	pass
	
	
func do_multi_lookup():
	output.clear()
	var output_list = []
	var ip_list = %MultiIPText.text.split("\n")
	output.append_text("Starting multi-IP lookup on %s IPs...\n\n" % len(ip_list))
	var date_time = Time.get_datetime_dict_from_system(false)
	var folder_string = "%s_%s_%s" % [date_time.year, date_time.month, date_time.day]
	for ip in ip_list:
		output.append_text("[color=green]Doing IP lookup on:[/color] [color=white]%s[/color]\n" % ip)
		var result: Dictionary = await requester.make_abuseipdb_ip_request(ip)
		var output_text = Helpers.parse_multi_ip_lookup(result)
		output.append_text(output_text)
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
				"Block/Unblock": "Block"
			}
			output_list.append(setup_data)
		await get_tree().create_timer(.5).timeout
	
	if ConfigHandler.get_config_value("LOG_IP_TO_CSV") == "true":
		var dir_access = DirAccess.open("%s/IPLookups" % OS.get_executable_path().get_base_dir())
		if not dir_access.dir_exists(folder_string):
			dir_access.make_dir(folder_string)

		CsvHelper.write_csv_dict("%s/%s/multi_lookup.csv" % [dir_access.get_current_dir(), folder_string],   #file name
		output_list, # data to write
		",", # delimiter
		true # append to existing file?
		)

		
	


	
