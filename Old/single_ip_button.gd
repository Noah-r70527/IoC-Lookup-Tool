extends Button


@onready var button = %SingleIPButton


func _ready(): 
	button.pressed.connect(do_single_IP_Lookup)
	
	if not %HTTPRequest.ab_ip_key:
		button.disabled = true
	
func do_single_IP_Lookup():
	%OutputDisplay.clear()
	var ip = %SingleIPText.text
	%OutputDisplay.append_text("[color=green]Doing IP lookup on:[/color] [color=white]%s[/color]\n" % ip)
	var result: Dictionary = await %HTTPRequest.make_abuseipdb_ip_request(ip)
	var output = Helpers.parse_ip_lookup(result)
	%OutputDisplay.append_text(output)
