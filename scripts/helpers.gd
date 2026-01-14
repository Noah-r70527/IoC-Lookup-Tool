extends Node

class_name Helpers

enum IocType { IPAddress, URL }


static func parse_ip_lookup(data_in: Dictionary):
	if data_in.get("Error") or not data_in.get("data"):
		return "Error: %s" % data_in.get("Error")
	var keys_to_print = ['ipAddress', 'countryCode', 'abuseConfidenceScore', 'isp', 'domain', 'hostnames', 'totalReports']
	var results: Dictionary = data_in.get("data")
	var resulting_string = ""
	for key in results:
		if key in keys_to_print:
			resulting_string += "[color=gray]%s[/color]: [color=white]%s[/color]\n" % [key, results[key]]
		
	return resulting_string
	
	
static func parse_multi_ip_lookup(data_in: Dictionary):
	if data_in.get("Error"):
		return "Error: %s" % data_in.get("Error")
		
	var keys_to_print = ['ipAddress', 'countryCode', 'abuseConfidenceScore', 'isp', 'domain', 'hostnames', 'totalReports']
	var results: Dictionary = data_in.get("data")
	var resulting_string = ""
	for key in results:
		if key in keys_to_print:
			resulting_string += "	[color=gray]%s[/color]: [color=white]%s[/color]\n" % [key, results[key]]
		
	return resulting_string
	
	
static func parse_network_lookup(data_in: Dictionary):
	
	if data_in.get("Error"):
		return "Error: %s" % data_in.get("Error")
		
	var keys_to_print = ['networkAddress', 'countryCode', 'abuseConfidenceScore', 'isp', 'domain', 'hostnames', 'totalReports']
	var results: Dictionary = data_in.get("data")
	var resulting_string = ""
	for key in results:
		if key in keys_to_print:
			resulting_string += "[color=gray]%s[/color]: [color=white]%s[/color]\n" % [key, results[key]]
		
	return resulting_string
	
	
static func parse_url_lookup(data_in: Dictionary):
	
	if data_in.get("Error"):
		return "Error: %s" % data_in.get("Error")
		
	var results: Dictionary = data_in.get("data")
	var parsed_results = {
		"ID": results.get("id"),
		"VT Link": "https://www.virustotal.com/gui/domain/%s" % results.get("id"),
		"Total": sum_array(results.get("attributes").get("last_analysis_stats").values()),
		"Malicious": results.get("attributes").get("last_analysis_stats").get("malicious"),
		"Suspicious": results.get("attributes").get("last_analysis_stats").get("suspicious"),
		"Undetected": results.get("attributes").get("last_analysis_stats").get("undetected"),
		"Harmless": results.get("attributes").get("last_analysis_stats").get("harmless"),
		"Timeout": results.get("attributes").get("last_analysis_stats").get("timeout")
	}
	
	var resulting_string = ""
	for key in parsed_results:
		resulting_string += "[color=gray]%s[/color]: [color=white]%s[/color]\n" % [key, parsed_results[key]]
		
	return [resulting_string, parsed_results]
	
	
static func parse_multi_url_lookup(data_in: Dictionary):
	
	if data_in.get("Error"):
		return "Error: %s" % data_in.get("Error")

	var results: Dictionary = data_in.get("data")
	var parsed_results = {
		"ID": results.get("id"),
		"VT Link": "https://www.virustotal.com/gui/domain/%s" % results.get("id"),
		"Total": sum_array(results.get("attributes").get("last_analysis_stats").values()),
		"Malicious": results.get("attributes").get("last_analysis_stats").get("malicious"),
		"Suspicious": results.get("attributes").get("last_analysis_stats").get("suspicious"),
		"Undetected": results.get("attributes").get("last_analysis_stats").get("undetected"),
		"Harmless": results.get("attributes").get("last_analysis_stats").get("harmless"),
		"Timeout": results.get("attributes").get("last_analysis_stats").get("timeout")
	}
	
	var resulting_string = ""
	for key in parsed_results:
		resulting_string += "	[color=gray]%s[/color]: [color=white]%s[/color]\n" % [key, parsed_results[key]]
		
	return [resulting_string, parsed_results]
	
	
static func sum_array(array):
	var sum = 0
	for element in array:
		sum += element
	return sum
	
	
static func is_valid_ipv4(ip: String) -> bool:
	var ipv4_regex = RegEx.new()
	ipv4_regex.compile(r"^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$")
	if !ipv4_regex.search(ip):
		return false

	var parts = ip.split(".")
	for part in parts:
		var num = part.to_int()
		if num < 0 or num > 255:
			return false
	return true
	
	
static func is_valid_ipv6(ip: String) -> bool:
	var ipv6_regex = RegEx.new()
	var pattern = r"""^((?:[0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4}|(?:[0-9A-Fa-f]{1,4}:){1,7}:|:(?::[0-9A-Fa-f]{1,4}){1,7}|(?:[0-9A-Fa-f]{1,4}:){1,6}:[0-9A-Fa-f]{1,4}|(?:[0-9A-Fa-f]{1,4}:){1,5}(?::[0-9A-Fa-f]{1,4}){1,2}|(?:[0-9A-Fa-f]{1,4}:){1,4}(?::[0-9A-Fa-f]{1,4}){1,3}|(?:[0-9A-Fa-f]{1,4}:){1,3}(?::[0-9A-Fa-f]{1,4}){1,4}|(?:[0-9A-Fa-f]{1,4}:){1,2}(?::[0-9A-Fa-f]{1,4}){1,5}|[0-9A-Fa-f]{1,4}:(?::[0-9A-Fa-f]{1,4}){1,6}|::)$"""
	
	ipv6_regex.compile(pattern)
	return ipv6_regex.search(ip) != null
	
static func extract_domain(url: String) -> String:
	if url.begins_with("http://") or url.begins_with("https://"):
		url = url.split("://")[1]
	return url.split("/")[0]
	
	
static func is_valid_domain(domain: String) -> bool:
	var domain_regex = RegEx.new()
	domain_regex.compile(r"^(?!-)(?:[a-zA-Z0-9-]{1,63}\.)+[a-zA-Z]{2,}$")
	return domain_regex.search(domain) != null
	
	
static func parse_hash_lookup(data_in: Dictionary):
	
	if data_in.get("Error"):
		return "Error: %s" % data_in.get("Error")
		
		
static func parse_top_ports(data_in: Dictionary) -> Array[Dictionary]:
	
	if data_in.get("Error"):
		return [{"Parse error": "No values"}]
		
	var parsed_ports: Array[Dictionary]
		
	for key in data_in:
		parsed_ports.append(
			{
				"Port": data_in.get("targetport", "Not found"),
				"Rank": data_in.get("rank", "Not found"),
				"Number of Records": data_in.get("records", "Not found"),
				"Number of Targets": data_in.get("targets", "Not found"),
				"Number of Sources": data_in.get("sources", "Not found")
			}
		)
		
	return parsed_ports
		
	
static func defang_ip(input_ip):
	return input_ip.replace(".", "[.]")
	
	
static func defang_url(input_url):
	return input_url.replace("https", "hxxps").replace(".", "[.]")
	

static func rearm_ip(input_ip):
	return input_ip.replace("[.]", ".")
	
	
static func rearm_url(input_url):
	return input_url.replace("hxxps", "https").replace("[.]", ".")
