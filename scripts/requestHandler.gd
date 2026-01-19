extends Node

@onready var requestHandler: HTTPRequest = %HTTPRequestHandler
@onready var ab_ip_key = ConfigHandler.get_config_value("ABUSE_IP_API_KEY")
@onready var vt_key = ConfigHandler.get_config_value("VT_API_KEY")

enum RequestType { ABUSEIPDB, VIRUSTOTAL }
enum VTEndpoint { ip_address, domains}
const SANS_BASE_URL: String = "http://isc.sans.edu/api/"
const SANS_HANDLER: String = "handler?json"
const SANSEndpont: Dictionary = {
	"topports": "topports/records"
}
var current_request_type = null
var ab_remaining = 0
var vt_remaining = 0

func _ready():

	pass

func sync_api_keys():
		ab_ip_key = ConfigHandler.get_config_value("ABUSE_IP_API_KEY")
		vt_key = ConfigHandler.get_config_value("VT_API_KEY")
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
	
	requestHandler.request(url, headers)
	var result = await requestHandler.request_completed
	
	if check_response_code(result[1]) == "Rate-Limited":
		return {"error": "Rate-Limited"}
		
	var body: PackedByteArray = result[3]
	var parse_result = JSON.parse_string(body.get_string_from_utf8())
	return parse_result
