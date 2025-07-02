extends Button


@onready var button = %NetworkLookupButton


func _ready():
	button.pressed.connect(do_network_lookup)
	
func do_network_lookup():
	%OutputDisplay.clear()
	var network = %NetworkLookupText.text
	%OutputDisplay.append_text("[color=green]Doing Network lookup on:[/color] [color=white]%s[/color]\n\n" % network)
	var result: Dictionary = await %HTTPRequest.make_abuseipdb_network_request(network)
	var output = Helpers.parse_url_lookup(result)
	print(output)
	%OutputDisplay.append_text(output)
