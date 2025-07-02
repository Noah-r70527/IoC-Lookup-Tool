extends Node

# { "data": { "ipAddress": "1.1.1.1", "isPublic": true, "ipVersion": 4.0, "isWhitelisted": true, "abuseConfidenceScore": 0.0, "countryCode": "AU", "usageType": "Content Delivery Network", "isp": "APNIC and Cloudflare DNS Resolver project", "domain": "cloudflare.com", "hostnames": ["one.one.one.one"], "isTor": false, "totalReports": 130.0, "numDistinctUsers": 28.0, "lastReportedAt": "2025-07-01T17:31:31+00:00" } }

static func parse_ip_lookup(data_in: Dictionary):
	if data_in.get("Error"):
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
		
	var keys_to_print = ['ID', 'VT Link', 'Total', 'Malicious', 'Suspicious', 
	'Undetected', 'Harmless', 'Timeout']
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
		
	return resulting_string
	
	
static func parse_multi_url_lookup(data_in: Dictionary):
	
	if data_in.get("Error"):
		return "Error: %s" % data_in.get("Error")
		
	var keys_to_print = ['ID', 'VT Link', 'Total', 'Malicious', 'Suspicious', 
	'Undetected', 'Harmless', 'Timeout']
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
		
	return resulting_string
	
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
	var pattern = r"""^(
		(?:[0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4} |
		(?:[0-9A-Fa-f]{1,4}:){1,7}: |
		:(?::[0-9A-Fa-f]{1,4}){1,7} |
		(?:[0-9A-Fa-f]{1,4}:){1,6}:[0-9A-Fa-f]{1,4} |
		(?:[0-9A-Fa-f]{1,4}:){1,5}(?::[0-9A-Fa-f]{1,4}){1,2} |
		(?:[0-9A-Fa-f]{1,4}:){1,4}(?::[0-9A-Fa-f]{1,4}){1,3} |
		(?:[0-9A-Fa-f]{1,4}:){1,3}(?::[0-9A-Fa-f]{1,4}){1,4} |
		(?:[0-9A-Fa-f]{1,4}:){1,2}(?::[0-9A-Fa-f]{1,4}){1,5} |
		[0-9A-Fa-f]{1,4}:(?::[0-9A-Fa-f]{1,4}){1,6} |
		:: # compressed all-zero
	)$"""
	
	pattern = pattern.replace("\n", "").replace(" ", "")  
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
