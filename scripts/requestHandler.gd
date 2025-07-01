extends HTTPRequest

@onready var requestHandler = %HTTPRequest
@onready var baseUrl = "https://api.abuseipdb.com/api/v2/check"

func _ready():
	
	var headers = {
		"Accept": "application/json",
		"Key": "d59c3efe7bb00aa50c02817726c791fe2775808f14bbec65d2f0e7db0cfe37ce1e5a60d3148d916f"
	}
	
	var urlBuild = "%s?%s=%s&maxAgeInDays=%s" % [baseUrl, "ipAddress", "8.8.8.8", "90"]
	print("Sending request to %s" % urlBuild)
	requestHandler.request_completed.connect(_on_request_completed)
	requestHandler.request(urlBuild)

func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	print(json)
