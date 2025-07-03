extends Button


@onready var button = %SingleURLButton


func _ready():
	if not %HTTPRequest.vt_key:
		button.disabled = true
	button.pressed.connect(do_single_url_lookup)
	
func do_single_url_lookup():
	%OutputDisplay.clear()
	var url = %SingleURLText.text
	%OutputDisplay.append_text("[color=green]Doing URL lookup on:[/color] [color=white]%s[/color]\n\n" % url)
	var result: Dictionary = await %HTTPRequest.make_virustotal_request(url, "Domain")
	var output = Helpers.parse_url_lookup(result)
	print(output)
	%OutputDisplay.append_text(output)
