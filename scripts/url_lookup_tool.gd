extends Control

@onready var single_url_button = %SingleURLButton
@onready var dns_lookup_button = %DNSLookupButton
@onready var multi_url_button = %MultiURLButton
@onready var multi_url_text = %MultiURLText
@onready var dns_lookup_text = %DNSLookupText
@onready var single_url_text = %SingleURLText
@onready var requester = get_parent().get_node("%HTTPRequestHandler")
@onready var output_display = get_parent().get_node("%OutputDisplay")


func _ready(): 
	single_url_button.pressed.connect(do_single_url_Lookup)
	multi_url_button.pressed.connect(do_multi_url_lookup)
	dns_lookup_button.pressed.connect(do_dns_lookup)
	
	if !ConfigHandler.get_config_value("VT_API_KEY"):
		for button in [multi_url_button, single_url_button, dns_lookup_button]:
			button.disabled = true



func do_single_url_Lookup():
	output_display.clear()
	var url = Helpers.extract_domain(single_url_text.text)
	var is_valid = Helpers.is_valid_domain(Helpers.extract_domain(url))
	if not is_valid:
		output_display.append_text("[color=red]Invalid URL Entered:[/color] [color=white]%s[/color]\n\n" % url)
		return 
		
	output_display.append_text("[color=green]Doing URL lookup on:[/color] [color=white]%s[/color]\n\n" % url)
	var result: Dictionary = await requester.make_virustotal_request(url, "Domain")
	var output = Helpers.parse_multi_url_lookup(result)
	output_display.append_text(output[0])
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
		[setup_data], # data to write
		",", # delimiter
		true # append to existing file?
		)
	
func do_dns_lookup():
	output_display.clear()
	var domain = dns_lookup_text.text
	output_display.append_text("[color=green]Doing DNS lookup on:[/color] [color=white]%s[/color]\n\n" % domain)
	var result_ipv4 = IP.resolve_hostname(domain, IP.TYPE_IPV4)
	var result_ipv6 = IP.resolve_hostname(domain, IP.TYPE_IPV6)
	output_display.append_text("[color=green]IPv4 Result:[/color] %s\n[color=green]IPv6 Result:[/color] %s" % [result_ipv4, result_ipv6])

	
func do_multi_url_lookup():
	output_display.clear()
	var url_list = multi_url_text.text.split("\n")
	output_display.append_text("Starting multi-URL lookup on %s domains...\nBecause of Virus Total's Rate-Limiting rules, only one request will go through every 15 seconds.\n\n" % len(url_list))
	var output_list = []
	var date_time = Time.get_datetime_dict_from_system(false)
	var folder_string = "%s_%s_%s" % [date_time.year, date_time.month, date_time.day]
	
	for url in url_list:
		var is_valid = Helpers.is_valid_domain(Helpers.extract_domain(url))
		if not is_valid:
			output_display.append_text("[color=red]Invalid URL Entered:[/color] [color=white]%s[/color]\n\n" % url)
			continue
			 
		output_display.append_text("[color=green]Doing URL lookup on:[/color] [color=white]%s[/color]\n" % url)
		var result: Dictionary = await requester.make_virustotal_request(url, "Domain")
		var output = Helpers.parse_multi_url_lookup(result)
		output_display.append_text(output[0])
		var setup_data = {
			"Date": folder_string
		}
		setup_data.merge(output[1])
		output_list.append(setup_data)
		await get_tree().create_timer(15).timeout

		
	if ConfigHandler.get_config_value("LOG_URL_TO_CSV") == "true":
		var dir_access = DirAccess.open("%s/URLLookups" % OS.get_executable_path().get_base_dir())

		if not dir_access.dir_exists(folder_string):
			dir_access.make_dir(folder_string)
		CsvHelper.write_csv_dict("%s/%s/url_lookups.csv" % [dir_access.get_current_dir(), folder_string],   #file name
		output_list, # data to write
		",", # delimiter
		true # append to existing file?
		)

		
	


	
