extends Resource

class_name rIndicator


enum IndicatorType {
	FileSha1,
	FileSha256,
	FileMd5,
	CertificateThumbprint,
	IpAddress,
	DomainName,
	Url
}

enum IndicatorAction {
	Warn,
	Block,
	Audit,
	Alert,
	AlertAndBlock,
	BlockAndRemediate,
	Allowed
}

enum Severity {
	Informational,
	Low,
	Medium,
	High
}




@export var indicatorValue: String
@export var indicatorType: IndicatorType
@export var indicatorAction: IndicatorAction = IndicatorAction.Block
@export var indicatorSeverity: Severity = Severity.High
@export var indicatorDescription: String = "Malicious Indicator."
@export var indicatorTitle: String = "Block Malicious Indicator."
@export var indicatorRecommendedActions: String
@export var indicatorExpirationTime: String = "2050-01-01T00:00:00Z"

func to_dict() -> Dictionary:
	return {
		"indicatorValue": indicatorValue,
		"indicatorType": IndicatorType.keys()[indicatorType],
		"indicatorAction": IndicatorAction.keys()[indicatorAction],
		"indicatorSeverity": Severity.keys()[indicatorSeverity], 
		"indicatorDescription": indicatorDescription,
		"indicatorTitle": indicatorTitle,
		"indicatorRecommendedActions": indicatorRecommendedActions,
		"indicatorExpirationTime": indicatorExpirationTime
	}
