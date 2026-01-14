extends Node

@onready var ip_defang_text = %IPDefangText
@onready var ip_defang_button = %IPDefangButton
@onready var url_defang_text = %DefangURLText
@onready var url_defang_button = %DefangURLButton
@onready var output = get_parent().get_node("%OutputDisplay")


func _ready():
	ip_defang_button.pressed.connect(handle_defang_ips)
	url_defang_button.pressed.connect(handle_defang_urls)
	
	
func handle_defang_ips():
	output.clear()
	var list_writer: Array = []
	var defang_ip_list = ip_defang_text.text.split("\n")
	output.append_text("Attempting to defang [color=green]%s[/color] IP addresses.\n\n" % len(defang_ip_list))
	for line in defang_ip_list:
		if Helpers.is_valid_ipv4(line):
			var temp = defang_ip(line)
			list_writer.append({"defanged_IP": temp})
	var dir_access = DirAccess.open("%s" % OS.get_executable_path().get_base_dir())
	if not dir_access.dir_exists("DefangedOutput"):
		dir_access.make_dir("DefangedOutput")
	CsvHelper.write_csv_dict("%s/DefangedOutput/defanged_ips.csv" % dir_access.get_current_dir(), list_writer)
	output.append_text("[color=green]Finshed[/color]\n\n Wrote output to: \n%s/DefangedOutput" % dir_access.get_current_dir())
	
	
func handle_defang_urls():
	var list_writer: Array = []
	var defang_url_list = url_defang_text.text.split("\n")
	output.append_text("Attempting to defang [color=green]%s[/color] URLs.\n\n" % len(defang_url_list))
	for line in defang_url_list:
		var temp = defang_url(line)
		list_writer.append({"defanged_URL": temp})
	var dir_access = DirAccess.open("%s" % OS.get_executable_path().get_base_dir())
	if not dir_access.dir_exists("DefangedOutput"):
		dir_access.make_dir("DefangedOutput")
	CsvHelper.write_csv_dict("%s/DefangedOutput/defanged_urls.csv" % dir_access.get_current_dir(), list_writer)
	output.append_text("[color=green]Finshed[/color]\n\n Wrote output to: \n%s/DefangedOutput" % dir_access.get_current_dir())
