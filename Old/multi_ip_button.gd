extends Button


@onready var button = %MultiIPButton


func _ready():
	if not %HTTPRequest.ab_ip_key:
		button.disabled = true
	button.pressed.connect(do_multi_lookup)
	
func do_multi_lookup():
	%OutputDisplay.clear()
	var ip_list = %MultiIPText.text.split("\n")
	%OutputDisplay.append_text("Starting multi-IP lookup on %s IPs...\n" % len(ip_list))
	await get_tree().create_timer(2.0).timeout
	%OutputDisplay.clear()
	for ip in ip_list:
		%OutputDisplay.append_text("[color=green]Doing IP lookup on:[/color] [color=white]%s[/color]\n" % ip)
		var result: Dictionary = await %HTTPRequest.make_abuseipdb_ip_request(ip)
		var output = Helpers.parse_multi_ip_lookup(result)
		%OutputDisplay.append_text(output)
		
