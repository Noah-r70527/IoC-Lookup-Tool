extends HBoxContainer

class_name IndicatorAttributeIndicatorType


@export var attribute_name: String = "Placeholder"
@export var attribute_options: Array[rIndicator.IndicatorType]

func _ready():
	%AttributeLabel.text = attribute_name
	for type in attribute_options:
		var entry_name: String = rIndicator.IndicatorType.keys()[type]
		%AttributeOptions.add_item(entry_name, type)

	
func get_attribute_result() -> rIndicator.IndicatorType:
	var selection_id: int = %AttributeOptions.get_selected_id()
	return selection_id as rIndicator.IndicatorType
