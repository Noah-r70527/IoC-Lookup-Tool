extends Node

@onready var ip_defang_text = %IPDefangText
@onready var ip_defang_button = %IPDefangButton
@onready var url_defang_text = %DefangURLText
@onready var url_defang_button = %DefangURLButton


func _ready():
	ip_defang_button.pressed.connect(handle_defang_ips)
	url_defang_button.pressed.connect(handle_defang_urls)
	
	
func handle_defang_ips():
	var dir_access = DirAccess.open(OS.get_executable_path().get_base_dir())
	if not dir_access.dir_exists("DefangedOutput"):
		dir_access.make_dir("DefangedOutput")
	var defang_ip_list = ip_defang_text.text.split("\n")
	Globals.emit_signal(
		"output_display_update",
		"Attempting to defang [color=green]%s[/color] IP addresses.\n\n" % [len(defang_ip_list)], 
		false
	)
	for line in defang_ip_list:
		if Helpers.is_valid_ipv4(line):
			var temp = Helpers.defang_ip(line)
			CsvHelper.write_csv_dict("%s/DefangedOutput/defanged_ips.csv" % dir_access.get_current_dir(), {"ip": temp})

	Globals.emit_signal("output_display_update", 
	"[color=green]Finshed[/color]\n\n Wrote output to: \n%s/DefangedOutput" % [dir_access.get_current_dir()], false
	)
	
	
func handle_defang_urls():
	var defang_url_list = url_defang_text.text.split("\n")
	var dir_access = DirAccess.open("%s" % OS.get_executable_path().get_base_dir())
	if not dir_access.dir_exists("DefangedOutput"):
		dir_access.make_dir("DefangedOutput")
	Globals.emit_signal(
		"output_display_update", 
		["Attempting to defang [color=green]%s[/color] URLs.\n\n" % [len(defang_url_list)], false]
		)
	for line in defang_url_list:
		var temp = Helpers.defang_url(line)
		CsvHelper.write_csv_dict("%s/DefangedOutput/defanged_urls.csv" % dir_access.get_current_dir(), temp)

	Globals.emit_signal(
		"output_display_update", 
		["[color=green]Finshed[/color]\n\n Wrote output to: \n%s/DefangedOutput" % [dir_access.get_current_dir()], false]
		)
