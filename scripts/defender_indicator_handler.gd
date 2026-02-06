extends Node

class_name DefenderIndicatorHandler

const REQUIRED_VALUES = [
	"indicatorValue", "indicatorType", "indicatorAction",
	"indicatorSeverity", "indicatorDescription", "indicatorTitle",
	"indicatorRecommendedActions", "indicatorExpirationTime"
]

func setup_indicator(indicator_values: Dictionary) -> rIndicator:
	var input_keys = indicator_values.keys()
	input_keys.sort()
	REQUIRED_VALUES.sort()
	
	if not input_keys == REQUIRED_VALUES:
		push_error("Input indicator values to not contain all of the required values. \nExpected values: %s\nReceived values: %s" % [REQUIRED_VALUES, input_keys])
		
	for key in indicator_values.keys():
		if key in ["indicatorRecommendedActions"]: continue
		if not indicator_values.get(key):
			push_error("%s is invalid. Couldn't create indicator." % key)
		
	var indicator = rIndicator.new()
	indicator.indicatorValue = indicator_values.get('indicatorValue')
	indicator.indicatorType = indicator_values.get("indicatorType")
	indicator.indicatorAction = indicator_values.get("indicatorAction")
	indicator.indicatorSeverity = indicator_values.get("indicatorSeverity")
	indicator.indicatorDescription = indicator_values.get("indicatorDescription")
	indicator.indicatorTitle = indicator_values.get("indicatorTitle")
	indicator.indicatorRecommendedActions = indicator_values.get("indicatorRecommendedActions")
	indicator.indicatorExpirationTime = indicator_values.get("indicatorExpirationTime")
	
	return indicator
	


	
