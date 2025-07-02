extends Button


@onready var button = %MultiURLButton


func _ready():
	if not %HTTPRequest.vt_key:
		button.disabled = true
	button.pressed.connect(do_multi_url_lookup)
	
func do_multi_url_lookup():
	%OutputDisplay.clear()
	var url_list = %MultiURLText.text.split("\n")
	%OutputDisplay.append_text("Starting multi-URL lookup on %s domains...\n" % len(url_list))
	await get_tree().create_timer(2.0).timeout
	%OutputDisplay.clear()
	for url in url_list:
		%OutputDisplay.append_text("[color=green]Doing URL lookup on:[/color] [color=white]%s[/color]\n" % url)
		var result: Dictionary = await %HTTPRequest.make_virustotal_request(url, "Domain")
		var output = Helpers.parse_multi_url_lookup(result)
		%OutputDisplay.append_text(output)
		
