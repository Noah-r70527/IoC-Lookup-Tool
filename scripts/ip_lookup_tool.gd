extends Control

@onready var single_button = %SingleIPButton
@onready var network_button = %NetworkLookupButton
@onready var multi_button = %MultiIPButton
@onready var report_button = %ReportLookupButton
@onready var single_text = %SingleIPText
@onready var network_text = %NetworkLookupText
@onready var multi_text = %MultiIPText
@onready var report_text = %ReportLookupText
@onready var requester = get_parent().get_node("%HTTPRequestHandler")
@onready var output = get_parent().get_node("%OutputDisplay")


func _ready(): 
	single_button.pressed.connect(do_single_IP_Lookup)
	network_button.pressed.connect(do_network_lookup)
	report_button.pressed.connect(do_report_lookup)
	multi_button.pressed.connect(do_multi_lookup)


func do_single_IP_Lookup():
	output.clear()
	var ip = %SingleIPText.text
	output.append_text("[color=green]Doing IP lookup on:[/color] [color=white]%s[/color]\n\n" % ip)
	var result: Dictionary = await requester.make_abuseipdb_ip_request(ip)
	print(result)
	var output_text = Helpers.parse_ip_lookup(result)
	output.append_text(output_text)
	
func do_network_lookup():
	pass
	

func do_report_lookup():
	pass
	
	
func do_multi_lookup():
	output.clear()
	var ip_list = %MultiIPText.text.split("\n")
	output.append_text("Starting multi-IP lookup on %s IPs...\n\n" % len(ip_list))
	for ip in ip_list:
		output.append_text("[color=green]Doing IP lookup on:[/color] [color=white]%s[/color]\n" % ip)
		var result: Dictionary = await requester.make_abuseipdb_ip_request(ip)
		var output_text = Helpers.parse_multi_ip_lookup(result)
		output.append_text(output_text)
		await get_tree().create_timer(.5).timeout

		
	


	
