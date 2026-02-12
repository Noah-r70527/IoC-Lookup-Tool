extends HBoxContainer

class_name IndicatorAttributeSeverity


@export var attribute_name: String = "Placeholder"
@export var attribute_options: Array[rIndicator.Severity]

func _ready():
	%AttributeLabel.text = attribute_name
	for severity in attribute_options:
		var entry_name: String = rIndicator.Severity.keys()[severity]
		%AttributeOptions.add_item(entry_name, severity)

	
func get_attribute_result() -> rIndicator.Severity:
	var selection_id: int = %AttributeOptions.get_selected_id()
	return selection_id as rIndicator.Severity
