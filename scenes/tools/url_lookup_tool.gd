extends Control

@onready var single_url_button = %SingleURLButton
@onready var dns_lookup_button = %DNSLookupButton
@onready var multi_url_button = %MultiURLButton
@onready var multi_url_text = %MultiURLText
@onready var dns_lookup_text = %DNSLookupText
@onready var single_url_text = %SingleURLText
@onready var requester = get_parent().get_node("%HTTPRequestHandler")
@onready var output = get_parent().get_node("%OutputDisplay")


func _ready(): 
	single_url_button.pressed.connect(do_single_url_Lookup)
	multi_url_button.pressed.connect(do_multi_url_lookup)


func do_single_url_Lookup():
	output.clear()
	var url = single_url_text.text
	output.append_text("[color=green]Doing URL lookup on:[/color] [color=white]%s[/color]\n\n" % url)
	var result: Dictionary = await requester.make_ipscore_url_request(url)
	var output_text = Helpers.parse_ipscore(result)
	output.append_text(output_text)
	
func do_dns_lookup():
	pass

	
func do_multi_url_lookup():
	output.clear()
	var url_list = multi_url_text.text.split("\n")
	print(url_list)
	output.append_text("Starting multi-URL lookup on %s domains...\n\n" % len(url_list))
	output.clear()
	for url in url_list:
		output.append_text("[color=green]Doing URL lookup on:[/color] [color=white]%s[/color]\n" % url)
		var result: Dictionary = await requester.make_ipscore_url_request(url)
		var output_text = Helpers.parse_multi_ipscore(result)
		output.append_text(output_text)

		
	


	
