extends Control

@onready var single_hash_text = %SingleHashText
@onready var single_hash_button = %SingleHashButton
@onready var multi_hash_text = %MultiHashText
@onready var multi_hash_button = %MultiHashButton
@onready var requester = get_parent().get_node("%HTTPRequestHandler")
@onready var output = get_parent().get_node("%OutputDisplay")


func _ready(): 
	single_hash_button.pressed.connect(on_single_hash_clicked)
	multi_hash_button.pressed.connect(on_multi_hash_clicked)
	
	
func on_single_hash_clicked():
	var hash_text = single_hash_text.text
	var result = await requester.make_hash_lookup_request(hash_text)
	
func on_multi_hash_clicked():
	pass
