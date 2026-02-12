extends HBoxContainer

class_name IndicatorAttributeIndicatorAction


@export var attribute_name: String = "Placeholder"
@export var attribute_options: Array[rIndicator.IndicatorAction]

func _ready():
	%AttributeLabel.text = attribute_name
	for action in attribute_options:
		var entry_name: String = rIndicator.IndicatorAction.keys()[action]
		%AttributeOptions.add_item(entry_name, action)

	
func get_attribute_result() -> rIndicator.IndicatorAction:
	var selection_id: int = %AttributeOptions.get_selected_id()
	return selection_id as rIndicator.IndicatorAction
	
