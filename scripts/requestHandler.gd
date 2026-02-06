extends Node

@onready var requestHandler: HTTPRequest = %HTTPRequestHandler
@onready var ab_ip_key = ConfigHandler.get_config_value("ABUSE_IP_API_KEY")
@onready var vt_key = ConfigHandler.get_config_value("VT_API_KEY")
@onready var defender_client_id = ConfigHandler.get_config_value("DEFENDER_CLIENT_ID")
@onready var defender_client_secret = ConfigHandler.get_config_value("DEFENDER_CLIENT_SECRET")
@onready var defender_tenant_id = ConfigHandler.get_config_value("DEFENDER_TENANT_ID")

enum RequestType { ABUSEIPDB, VIRUSTOTAL, DEFENDER}
enum VTEndpoint { ip_address, domains}
const DEFENDER_API_SCOPE: String = "https://api.securitycenter.microsoft.com/.default"
const SANS_BASE_URL: String = "http://isc.sans.edu/api/"
const SANS_HANDLER: String = "handler?json"
const SANSEndpont: Dictionary = {
	"topports": "topports/records"
}
var current_request_type = null
var ab_remaining = 0
var vt_remaining = 0
var defender_token
var is_requesting: bool = false


func _ready():
	pass
	
	



func init_defender_token():
	defender_token = await get_defender_token()
	

func sync_api_keys():
		ab_ip_key = ConfigHandler.get_config_value("ABUSE_IP_API_KEY")
		vt_key = ConfigHandler.get_config_value("VT_API_KEY")
		defender_client_id = ConfigHandler.get_config_value("DEFENDER_CLIENT_ID")
		defender_client_secret = ConfigHandler.get_config_value("DEFENDER_CLIENT_SECRET")
		defender_tenant_id = ConfigHandler.get_config_value("DEFENDER_TENANT_ID")
		return "Success"
	
func make_abuseipdb_ip_request(ip_address: String) -> Dictionary:
	
	
	current_request_type = RequestType.ABUSEIPDB
	
	if not Helpers.is_valid_ipv4(ip_address) and not Helpers.is_valid_ipv6(ip_address):
		return {"Error": "Invalid input. Please enter a valid IPv4 or IPv6 address."}
		
	var baseUrl = "https://api.abuseipdb.com/api/v2/check"
	var headers = [
		"Accept: application/json",
		"Key: %s" % ab_ip_key
	]
	var url = "%s?ipAddress=%s&maxAgeInDays=90" % [baseUrl, ip_address]
	is_requesting = true
	requestHandler.request(url, headers)
	var result = await requestHandler.request_completed
	
	if check_response_code(result[1]) == "Rate-Limited":
		return {"error": "Rate-Limited"}
	
	var remaining = result[2][7].split(": ")[1]
	ab_remaining = remaining
	var body: PackedByteArray = result[3]
	var parse_result = JSON.parse_string(body.get_string_from_utf8())
	return parse_result
	
	
func make_abuseipdb_network_request(ip_address: String) -> Dictionary:
	current_request_type = RequestType.ABUSEIPDB
	var baseUrl = "https://api.abuseipdb.com/api/v2/check-block"
	var headers = [
		"Accept: application/json",
		"Key: %s" % ab_ip_key
	]
	var url = "%s?network=%s&maxAgeInDays=90" % [baseUrl, ip_address]
	is_requesting = true
	requestHandler.request(url, headers)

	var result = await requestHandler.request_completed
	
	if check_response_code(result[1]) == "Rate-Limited":
		return {"error": "Rate-Limited"}
		
	var remaining = result[2][7].split(": ")[1]
	ab_remaining = remaining
	update_abuse_count(ab_remaining)
	var body: PackedByteArray = result[3]
	var parse_result = JSON.parse_string(body.get_string_from_utf8())
	return parse_result
	
	
func make_abuseipdb_report_request(ip_address: String) -> Dictionary:
	current_request_type = RequestType.ABUSEIPDB
	
	if not Helpers.is_valid_ipv4(ip_address) and not Helpers.is_valid_ipv6(ip_address):
		return {"Error": "Invalid input. Please enter a valid IPv4 or IPv6 address."}
	
	var baseUrl = "https://api.abuseipdb.com/api/v2/reports"
	var headers = [
		"Accept: application/json",
		"Key: %s" % ab_ip_key
	]
	var url = "%s?ipAddress=%s&maxAgeInDays=90" % [baseUrl, ip_address]
	is_requesting = true
	requestHandler.request(url, headers)
	var result = await requestHandler.request_completed
	
	if check_response_code(result[1]) == "Rate-Limited":
		return {"error": "Rate-Limited"}
		
	var remaining = result[2][7].split(": ")[1]
	ab_remaining = remaining
	update_abuse_count(ab_remaining)
	var body: PackedByteArray = result[3]
	var parse_result = JSON.parse_string(body.get_string_from_utf8())
	return parse_result
	
	
func make_virustotal_request(input_value: String, lookup_type) -> Dictionary:
	var test_domain = Helpers.extract_domain(input_value)
	
	if not Helpers.is_valid_domain(test_domain):
		return {"Error": "Invalid input. Please enter a valid domain"}
		
	current_request_type = RequestType.VIRUSTOTAL
	var baseUrl = ""
	if lookup_type == "IP":
		baseUrl = "https://www.virustotal.com/api/v3/ip_addresses/%s" % test_domain
	elif lookup_type == "Domain":
		baseUrl = "https://www.virustotal.com/api/v3/domains/%s" % test_domain

	var headers = [
		"accept: application/json",
		"x-apikey: %s" % vt_key
	]
	is_requesting = true
	requestHandler.request(baseUrl, headers)
	var result = await requestHandler.request_completed
	
	if check_response_code(result[1]) == "Rate-Limited":
		return {"error": "Rate-Limited"}
		
	var body: PackedByteArray = result[3]

	var parse_result = JSON.parse_string(body.get_string_from_utf8())
	return parse_result
	
	
func make_hash_lookup_request(input_hash) -> Dictionary:
	var base_url = "https://yaraify-api.abuse.ch/api/v1/"
	var headers = [
		"Content-Type: application/json",
		"Accept: application/json"
	]

	var payload = {
		"query": "lookup_hash",
		"search_term": input_hash
	}

	var json_payload = JSON.stringify(payload)
	is_requesting = true
	requestHandler.request(base_url, headers, HTTPClient.METHOD_POST, json_payload)

	var result = await requestHandler.request_completed
	var body: PackedByteArray = result[3]
	var parse_result = JSON.parse_string(body.get_string_from_utf8())
	return parse_result
	
	
func update_abuse_count(count_in):
	%ABLookupCount.text = "Remaining Abuse IP DB Lookups:\n%s" % count_in
	
	
func update_vt_count(count_in):
	%VTLookupCountBox.text = "Remaining Virus Total Lookups:\n%s" % count_in
	
	
func check_response_code(response_code_in):
	match response_code_in:
		200:
			return "Success"
		429:
			return "Rate-Limited"
		404:
			return "Not Found"
		_:
			return "Error"
			
		
func build_sans_url(endpoint_in):
	return "%s/%s/$s" % [SANS_BASE_URL, endpoint_in, SANS_HANDLER]


func sans_api_query(endpoint_in) -> Dictionary:
	var endpoint_value: String = SANSEndpont.get(endpoint_in, "None")
	
	if endpoint_value == "None": return {"Error": "Failed to find endpoint"}
	
	var url: String = build_sans_url(endpoint_value)
	var headers = [
	"User-Agent: Godot-Game-Engine-4.4",
	"CI: %s" % ConfigHandler.get_config_value("CONTACT")
	]
	
	is_requesting = true
	requestHandler.request(url, headers)
	var result = await requestHandler.request_completed
	
	if check_response_code(result[1]) == "Rate-Limited":
		return {"error": "Rate-Limited"}
		
	var body: PackedByteArray = result[3]
	var parse_result = JSON.parse_string(body.get_string_from_utf8())
	return parse_result


func check_release_version() -> Dictionary:
	var url = "https://api.github.com/repos/Noah-r70527/IoC-Lookup-Tool/releases/latest"
	var headers := [
		"Accept: application/vnd.github+json",
		"User-Agent: Godot-Release-Checker"
	]
	
	is_requesting = true
	requestHandler.request(url, headers)
	var result = await requestHandler.request_completed

	var response_code: int = result[1]
	var body: PackedByteArray = result[3]
	var text := body.get_string_from_utf8()

	if response_code == 403 and text.find("rate limit") != -1:
		return {"error": "Rate-Limited"}

	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		push_error("JSON parse failed: %s" % json.get_error_message())
		push_error("At line: %d" % json.get_error_line())
		print(text.left(200))
		return {"error": "Bad JSON", "code": response_code}

	return {"version": json.data.get("tag_name")}


func get_defender_token():
	current_request_type = RequestType.DEFENDER
	if not defender_client_id or not defender_client_secret or not defender_tenant_id:
		return "Unable to get token."
	
	var headers = [ "Content-Type: application/x-www-form-urlencoded" ]
	var body: String = "grant_type=client_credentials" \
	+ "&client_id=%s" % defender_client_id.uri_encode() \
	+ "&client_secret=%s" % defender_client_secret.uri_encode() \
	+ "&scope=%s" % DEFENDER_API_SCOPE.uri_encode() 
	
	var url: String = "https://login.microsoftonline.com/%s/oauth2/v2.0/token" % defender_tenant_id
	is_requesting = true
	requestHandler.request(url, headers, HTTPClient.METHOD_POST, body)
	
	var result = await requestHandler.request_completed
	if check_response_code(result[1]) == "Rate-Limited":
		return {"error": "Rate-Limited"}
	var parse_result = JSON.parse_string(result[3].get_string_from_utf8())
	return parse_result.get("access_token")


func create_defender_indicator(defender_indicator: rIndicator) -> Dictionary:
	
	current_request_type = RequestType.DEFENDER
	
	if defender_token == "Unable to get token.":
		return {"error": "Missing token."}
		
	var indicator: Dictionary = defender_indicator.to_dict()

	var url: String = "https://api.security.microsoft.com/api/indicators"

	var headers = [
		"Accept: application/json",
		"Content-Type: application/json",
		"Authorization: Bearer %s" % defender_token
	]

	var body: String = JSON.stringify(indicator)
	is_requesting = true
	requestHandler.request(url, headers, HTTPClient.METHOD_POST, body)

	var result = await requestHandler.request_completed

	if check_response_code(result[1]) == "Rate-Limited":
		return {"error": "Rate-Limited"}

	var response_text: String = result[3].get_string_from_utf8()
	print(response_text)
	var parsed = JSON.parse_string(response_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"error": "bad_json", "raw": response_text}

	return parsed


func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("request finished")
	is_requesting = false
