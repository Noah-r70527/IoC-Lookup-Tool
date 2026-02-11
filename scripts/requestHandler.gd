extends Node

class_name RequestHandler

@onready var requestHandler: HTTPRequest = %HTTPRequestHandler

@onready var ab_ip_key: String = ConfigHandler.get_config_value("ABUSE_IP_API_KEY")
@onready var vt_key: String = ConfigHandler.get_config_value("VT_API_KEY")
@onready var defender_client_id: String = ConfigHandler.get_config_value("DEFENDER_CLIENT_ID")
@onready var defender_client_secret: String = ConfigHandler.get_config_value("DEFENDER_CLIENT_SECRET")
@onready var defender_tenant_id: String = ConfigHandler.get_config_value("DEFENDER_TENANT_ID")

enum RequestType { ABUSEIPDB, VIRUSTOTAL, DEFENDER }

const DEFENDER_API_SCOPE: String = "https://api.securitycenter.microsoft.com/.default"
const SANS_BASE_URL: String = "http://isc.sans.edu/api/"
const SANS_HANDLER: String = "handler?json"
const SANS_ENDPOINTS: Dictionary = {
	"topports": "topports/records"
}

var current_request_type: int = -1
var ab_remaining: String = "..."
var vt_remaining: String = "..."
var defender_token: String = ""
var is_requesting: bool = false


func _ready() -> void:
	if requestHandler and not requestHandler.request_completed.is_connected(_on_request_completed):
		requestHandler.request_completed.connect(_on_request_completed)


func sync_api_keys() -> String:
	ab_ip_key = ConfigHandler.get_config_value("ABUSE_IP_API_KEY")
	vt_key = ConfigHandler.get_config_value("VT_API_KEY")
	defender_client_id = ConfigHandler.get_config_value("DEFENDER_CLIENT_ID")
	defender_client_secret = ConfigHandler.get_config_value("DEFENDER_CLIENT_SECRET")
	defender_tenant_id = ConfigHandler.get_config_value("DEFENDER_TENANT_ID")
	return "Success"


func init_defender_token() -> void:
	if defender_client_id == "" or defender_client_secret == "" or defender_tenant_id == "":
		return
	var temp: Dictionary = await get_defender_token()
	defender_token = temp.get("access_token")

func _start_request(url: String, headers: Array, method: int = HTTPClient.METHOD_GET, body: String = "") -> Dictionary:
	if is_requesting:
		return {"error": "Current request handler is busy."}

	is_requesting = true
	var err: int = requestHandler.request(url, headers, method, body)
	if err != OK:
		is_requesting = false
		return {"error": "Request failed to start.", "code": err}

	var result: Array = await requestHandler.request_completed
	return {"result": result}


func _get_header_value(headers: PackedStringArray, header_name: String) -> String:
	var target: String = header_name.to_lower() + ":"
	for h in headers:
		var s: String = String(h)
		if s.to_lower().begins_with(target):
			return s.split(":", false, 1)[1].strip_edges()
	return ""


func check_response_code(response_code_in: int) -> String:
	match response_code_in:
		200:
			return "Success"
		429:
			return "Rate-Limited"
		404:
			return "Not Found"
		_:
			return "Error"


func update_abuse_count(_count_in: String) -> void:
	pass
	#%ABLookupCount.text = "Remaining Abuse IP DB Lookups:\n%s" % count_in


func update_vt_count(_count_in: String) -> void:
	pass
	#%VTLookupCount.text = "Remaining Virus Total Lookups:\n%s" % count_in


func make_abuseipdb_ip_request(ip_address: String) -> Dictionary:
	if not Helpers.is_valid_ipv4(ip_address) and not Helpers.is_valid_ipv6(ip_address):
		return {"Error": "Invalid input. Please enter a valid IPv4 or IPv6 address."}

	current_request_type = RequestType.ABUSEIPDB

	var base_url: String = "https://api.abuseipdb.com/api/v2/check"
	var url: String = "%s?ipAddress=%s&maxAgeInDays=90" % [base_url, ip_address]
	var headers: Array = [
		"Accept: application/json",
		"Key: %s" % ab_ip_key
	]

	var wrapped: Dictionary = await _start_request(url, headers)
	if wrapped.has("error"):
		return wrapped

	var result: Array = wrapped["result"]
	var response_code: int = result[1]
	var resp_headers: PackedStringArray = result[2]
	var body: PackedByteArray = result[3]

	if check_response_code(response_code) == "Rate-Limited":
		return {"error": "Rate-Limited"}

	ab_remaining = _get_header_value(resp_headers, "X-RateLimit-Remaining")
	if ab_remaining != "":
		update_abuse_count(ab_remaining)

	return JSON.parse_string(body.get_string_from_utf8())


func make_abuseipdb_network_request(network: String) -> Dictionary:
	current_request_type = RequestType.ABUSEIPDB

	var base_url: String = "https://api.abuseipdb.com/api/v2/check-block"
	var url: String = "%s?network=%s&maxAgeInDays=90" % [base_url, network]
	var headers: Array = [
		"Accept: application/json",
		"Key: %s" % ab_ip_key
	]

	var wrapped: Dictionary = await _start_request(url, headers)
	if wrapped.has("error"):
		return wrapped

	var result: Array = wrapped["result"]
	var response_code: int = result[1]
	var resp_headers: PackedStringArray = result[2]
	var body: PackedByteArray = result[3]

	if check_response_code(response_code) == "Rate-Limited":
		return {"error": "Rate-Limited"}

	ab_remaining = _get_header_value(resp_headers, "X-RateLimit-Remaining")
	if ab_remaining != "":
		update_abuse_count(ab_remaining)

	return JSON.parse_string(body.get_string_from_utf8())


func make_abuseipdb_report_request(ip_address: String) -> Dictionary:
	if not Helpers.is_valid_ipv4(ip_address) and not Helpers.is_valid_ipv6(ip_address):
		return {"Error": "Invalid input. Please enter a valid IPv4 or IPv6 address."}

	current_request_type = RequestType.ABUSEIPDB

	var base_url: String = "https://api.abuseipdb.com/api/v2/reports"
	var url: String = "%s?ipAddress=%s&maxAgeInDays=90" % [base_url, ip_address]
	var headers: Array = [
		"Accept: application/json",
		"Key: %s" % ab_ip_key
	]

	var wrapped: Dictionary = await _start_request(url, headers)
	
	if wrapped.has("error"):
		return wrapped

	var result: Array = wrapped["result"]
	var response_code: int = result[1]
	var resp_headers: PackedStringArray = result[2]
	var body: PackedByteArray = result[3]

	if check_response_code(response_code) == "Rate-Limited":
		return {"error": "Rate-Limited"}

	ab_remaining = _get_header_value(resp_headers, "X-RateLimit-Remaining")
	if ab_remaining != "":
		update_abuse_count(ab_remaining)

	return JSON.parse_string(body.get_string_from_utf8())


func make_virustotal_request(input_value: String, lookup_type: String) -> Dictionary:
	if is_requesting:
		return {"error": "Current request handler is busy."}

	var value: String = input_value.strip_edges()
	var base_url: String = ""

	if lookup_type == "IP":
		if not Helpers.is_valid_ipv4(value) and not Helpers.is_valid_ipv6(value):
			return {"Error": "Invalid input. Please enter a valid IPv4 or IPv6 address."}
		base_url = "https://www.virustotal.com/api/v3/ip_addresses/%s" % value
	elif lookup_type == "Domain":
		var domain: String = Helpers.extract_domain(value)
		if not Helpers.is_valid_domain(domain):
			return {"Error": "Invalid input. Please enter a valid domain"}
		base_url = "https://www.virustotal.com/api/v3/domains/%s" % domain
	else:
		return {"Error": "Invalid lookup type. Use 'IP' or 'Domain'."}

	current_request_type = RequestType.VIRUSTOTAL

	var headers: Array = [
		"Accept: application/json",
		"x-apikey: %s" % vt_key
	]

	var wrapped: Dictionary = await _start_request(base_url, headers)
	if wrapped.has("error"):
		return wrapped

	var result: Array = wrapped["result"]
	var response_code: int = result[1]
	var resp_headers: PackedStringArray = result[2]
	var body: PackedByteArray = result[3]

	if check_response_code(response_code) == "Rate-Limited":
		return {"error": "Rate-Limited"}

	vt_remaining = _get_header_value(resp_headers, "X-RateLimit-Remaining")
	if vt_remaining != "":
		update_vt_count(vt_remaining)

	return JSON.parse_string(body.get_string_from_utf8())


func make_hash_lookup_request(input_hash: String) -> Dictionary:
	var base_url: String = "https://yaraify-api.abuse.ch/api/v1/"
	var headers: Array = [
		"Content-Type: application/json",
		"Accept: application/json"
	]
	var payload: Dictionary = {
		"query": "lookup_hash",
		"search_term": input_hash
	}
	var json_payload: String = JSON.stringify(payload)

	var wrapped: Dictionary = await _start_request(base_url, headers, HTTPClient.METHOD_POST, json_payload)
	if wrapped.has("error"):
		return wrapped

	var result: Array = wrapped["result"]
	var body: PackedByteArray = result[3]
	return JSON.parse_string(body.get_string_from_utf8())


func build_sans_url(endpoint_in: String) -> String:
	return "%s%s/%s" % [SANS_BASE_URL, endpoint_in, SANS_HANDLER]


func sans_api_query(endpoint_key: String) -> Dictionary:
	var endpoint_value: String = String(SANS_ENDPOINTS.get(endpoint_key, ""))
	if endpoint_value == "":
		return {"Error": "Failed to find endpoint"}

	var url: String = build_sans_url(endpoint_value)
	var headers: Array = [
		"User-Agent: Godot-Game-Engine-4.4",
		"CI: %s" % String(ConfigHandler.get_config_value("CONTACT"))
	]

	var wrapped: Dictionary = await _start_request(url, headers)
	if wrapped.has("error"):
		return wrapped

	var result: Array = wrapped["result"]
	var response_code: int = result[1]
	var body: PackedByteArray = result[3]

	if check_response_code(response_code) == "Rate-Limited":
		return {"error": "Rate-Limited"}

	return JSON.parse_string(body.get_string_from_utf8())


func check_release_version() -> Dictionary:
	if is_requesting:
		return {"error": "Current request handler is busy."}

	var url: String = "https://api.github.com/repos/Noah-r70527/IoC-Lookup-Tool/releases/latest"
	var headers: Array = [
		"Accept: application/vnd.github+json",
		"User-Agent: Godot-Release-Checker"
	]

	var wrapped: Dictionary = await _start_request(url, headers)
	if wrapped.has("error"):
		return wrapped

	var result: Array = wrapped["result"]
	var response_code: int = result[1]
	var body: PackedByteArray = result[3]
	var text: String = body.get_string_from_utf8()

	if response_code == 403 and text.find("rate limit") != -1:
		return {"error": "Rate-Limited"}

	var json: JSON = JSON.new()
	var err: int = json.parse(text)
	if err != OK:
		push_error("JSON parse failed: %s" % json.get_error_message())
		push_error("At line: %d" % json.get_error_line())
		return {"error": "Bad JSON", "code": response_code}

	return {"version": String(json.data.get("tag_name", ""))}


func get_defender_token() -> Dictionary:
	current_request_type = RequestType.DEFENDER

	if defender_client_id == "" or defender_client_secret == "" or defender_tenant_id == "":
		return {"error": "Missing client credentials."}

	var url: String = "https://login.microsoftonline.com/%s/oauth2/v2.0/token" % defender_tenant_id
	var headers: Array = ["Content-Type: application/x-www-form-urlencoded"]

	var body: String = "grant_type=client_credentials" \
	+ "&client_id=%s" % defender_client_id.uri_encode() \
	+ "&client_secret=%s" % defender_client_secret.uri_encode() \
	+ "&scope=%s" % DEFENDER_API_SCOPE.uri_encode()

	var wrapped: Dictionary = await _start_request(url, headers, HTTPClient.METHOD_POST, body)
	if wrapped.has("error"):
		return wrapped

	var result: Array = wrapped["result"]
	var response_code: int = result[1]
	var text: String = result[3].get_string_from_utf8()

	if check_response_code(response_code) == "Rate-Limited":
		return {"error": "Rate-Limited"}

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"error": "bad_json", "raw": text}

	var token: String = String(parsed.get("access_token", ""))
	if token == "":
		return {"error": "Missing access_token", "raw": parsed}

	return {"access_token": token}


func create_defender_indicator(defender_indicator: rIndicator) -> Dictionary:
	current_request_type = RequestType.DEFENDER
	
	if not defender_indicator:
		return {"error": "Indicator was null or invalid."}

	if defender_token == "" or defender_token == "Unable to get token.":
		return {"error": "Missing token."}

	var url: String = "https://api.security.microsoft.com/api/indicators"
	var headers: Array = [
		"Accept: application/json",
		"Accept-Encoding: identity", 
		"Content-Type: application/json",
		"Authorization: Bearer %s" % defender_token
	]
	var indicator: Dictionary = defender_indicator.to_dict()
	var body: String = JSON.stringify(indicator)

	var wrapped: Dictionary = await _start_request(url, headers, HTTPClient.METHOD_POST, body)
	if wrapped.has("error"):
		return wrapped

	var result: Array = wrapped["result"]
	var response_code: int = result[1]
	var text: String = result[3].get_string_from_utf8()

	if check_response_code(response_code) == "Rate-Limited":
		return {"error": "Rate-Limited"}

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"error": "bad_json", "raw": text}

	return parsed


func _on_request_completed(_result: int, _response_code: int, 
_headers: PackedStringArray, _body: PackedByteArray) -> void:
	is_requesting = false


func download_template_csv(link, path):
	requestHandler.set_download_file(path)
	var request = requestHandler.request(link)
	if request != OK:
		push_error("Http request error")
