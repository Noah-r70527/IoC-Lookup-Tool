extends Node

@onready var encode_text: TextEdit = %EncodeText
@onready var decode_text: TextEdit = %DecodeText
@onready var encode_button: Button = %EncodeButton
@onready var decode_button: Button = %DecodeButton

func _ready() -> void:
	encode_button.pressed.connect(encode_user_text)
	decode_button.pressed.connect(decode_user_text)
	
	
func encode_user_text() -> void:
	var text: String = encode_text.text
	if text.is_empty():
		Globals.output_display_update.emit(
		"[color=red]No text found in the encode text box[/color]" ,
		false,
		"Error"
	)
	
	var encoded = Marshalls.utf8_to_base64(text)
	Globals.output_display_update.emit(
		"[color=green]Encoded text: [/color]\n\n %s" % encoded,
		false,
		"Informational"
	)


func decode_user_text() -> void:
	var text: String = decode_text.text
	if text.is_empty():
		Globals.output_display_update.emit(
		"[color=red]No text found in the decode text box[/color]" ,
		false,
		"Error"
	)
	
	var decoded = Marshalls.base64_to_utf8(text)
	Globals.output_display_update.emit(
		"[color=green]Decoded text: [/color]\n\n %s" % decoded,
		false,
		"Informational"
	)
