extends Resource

class_name rIocCache

enum IndicatorType {
	FileSha1,
	FileSha256,
	FileMd5,
	CertificateThumbprint,
	IpAddress,
	DomainName,
	Url
}

@export var iocValue: String
@export var iocType: IndicatorType
@export var iocCacheDate: String


#func to_dict() -> Dictionary:
	#return {
		#"indicatorValue": indicatorValue,
		#"indicatorType": IndicatorType.keys()[indicatorType],
		#"action": IndicatorAction.keys()[indicatorAction],
		#"severity": Severity.keys()[indicatorSeverity], 
		#"description": indicatorDescription,
		#"title": indicatorTitle,
		#"recommendedActions": indicatorRecommendedActions,
		#"expirationTime": indicatorExpirationTime
	#}
