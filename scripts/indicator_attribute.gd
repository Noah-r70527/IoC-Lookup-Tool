extends HBoxContainer

class_name IndicatorAttribute


@export var attribute_name: String = "Placeholder"
@export var attribute_hint_text: String = ""

func _ready():
	%AttributeLabel.text = attribute_name
	%AttributeText.placeholder_text = attribute_hint_text
	
func get_attribute_text() -> String:
	return %AttributeText.text
