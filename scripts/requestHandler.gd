extends Node

@onready var requestHandler = %HTTPRequestHandler

enum RequestType { ABUSEIPDB, VIRUSTOTAL }
enum VTEndpoint { ip_address, domains}
var current_request_type = null
var ab_remaining = 0
var vt_remaining = 0
var ab_ip_key = ConfigHandler.get_config_value("ABUSE_IP_API_KEY")
var vt_key = ConfigHandler.get_config_value("VT_API_KEY")
var ipscore_key = ConfigHandler.get_config_value("IPSCORE_API_KEY")

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
	var body: PackedByteArray = result[3]

	var parse_result = JSON.parse_string(body.get_string_from_utf8())
	return parse_result


func make_ipscore_url_request(input_value) -> Dictionary:
	var test_domain = Helpers.extract_domain(input_value)
	var parsed_domain = input_value.uri_encode()
	if not Helpers.is_valid_domain(test_domain):
		return {"Error": "Invalid input. Please enter a valid domain"}
		
	var baseUrl = "https://www.ipqualityscore.com/api/json/url/%s/%s?key=%s" % [ipscore_key, parsed_domain, ipscore_key]
	requestHandler.request(baseUrl)

	var result = await requestHandler.request_completed
	var body: PackedByteArray = result[3]

	var parse_result = JSON.parse_string(body.get_string_from_utf8())
	return parse_result

func update_abuse_count(count_in):
	%ABLookupCount.text = "Remaining Abuse IP DB Lookups:\n%s" % count_in
	
func update_vt_count(count_in):
	%VTLookupCountBox.text = "Remaining Virus Total Lookups:\n%s" % count_in
	
