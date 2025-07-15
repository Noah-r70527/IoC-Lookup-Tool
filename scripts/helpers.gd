extends Node

# { "data": { "ipAddress": "1.1.1.1", "isPublic": true, "ipVersion": 4.0, "isWhitelisted": true, "abuseConfidenceScore": 0.0, "countryCode": "AU", "usageType": "Content Delivery Network", "isp": "APNIC and Cloudflare DNS Resolver project", "domain": "cloudflare.com", "hostnames": ["one.one.one.one"], "isTor": false, "totalReports": 130.0, "numDistinctUsers": 28.0, "lastReportedAt": "2025-07-01T17:31:31+00:00" } }

func parse_ip_lookup(data_in: Dictionary):
	if data_in.get("Error"):
		return "Error: %s" % data_in.get("Error")
	var keys_to_print = ['ipAddress', 'countryCode', 'abuseConfidenceScore', 'isp', 'domain', 'hostnames', 'totalReports']
	var results: Dictionary = data_in.get("data")
	var resulting_string = ""
	for key in results:
		if key in keys_to_print:
			resulting_string += "[color=gray]%s[/color]: [color=white]%s[/color]\n" % [key, results[key]]
		
	return resulting_string
	

func parse_multi_ip_lookup(data_in: Dictionary):
	if data_in.get("Error"):
		return "Error: %s" % data_in.get("Error")
		
	var keys_to_print = ['ipAddress', 'countryCode', 'abuseConfidenceScore', 'isp', 'domain', 'hostnames', 'totalReports']
	var results: Dictionary = data_in.get("data")
	var resulting_string = ""
	for key in results:
		if key in keys_to_print:
			resulting_string += "	[color=gray]%s[/color]: [color=white]%s[/color]\n" % [key, results[key]]
		
	return resulting_string

func parse_network_lookup(data_in: Dictionary):
	
	if data_in.get("Error"):
		return "Error: %s" % data_in.get("Error")
		
	var keys_to_print = ['networkAddress', 'countryCode', 'abuseConfidenceScore', 'isp', 'domain', 'hostnames', 'totalReports']
	var results: Dictionary = data_in.get("data")
	var resulting_string = ""
	for key in results:
		if key in keys_to_print:
			resulting_string += "[color=gray]%s[/color]: [color=white]%s[/color]\n" % [key, results[key]]
		
	return resulting_string
		
		
func parse_url_lookup(data_in: Dictionary):
	
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
		
	return resulting_string
	
	
func parse_multi_url_lookup(data_in: Dictionary):
	
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
		
	return resulting_string
	
	
func parse_ipscore(data_in: Dictionary):
	if data_in.get("Error"):
		return "Error: %s" % data_in.get("Error")
		
	var parsed_results = {
		"Domain": data_in.get("domain"),
		"Reported for spam": data_in.get("spamming"),
		"Reported for malware": data_in.get("malware"),
		"Reported for phishing": data_in.get("phishing"),
		"Risk Score": data_in.get("risk_score"),
		"Country Code": data_in.get("country_code")
	}
	
	var resulting_string = ""
	for key in parsed_results:
		resulting_string += "[color=gray]%s[/color]: [color=white]%s[/color]\n" % [key, parsed_results[key]]
	
	return resulting_string
	
	
func parse_multi_ipscore(data_in: Dictionary):
	if data_in.get("Error"):
		return "Error: %s" % data_in.get("Error")
		
	var parsed_results = {
		"Domain": data_in.get("domain"),
		"Reported for spam": data_in.get("spamming"),
		"Reported for malware": data_in.get("malware"),
		"Reported for phishing": data_in.get("phishing"),
		"Risk Score": data_in.get("risk_score"),
		"Country Code": data_in.get("country_code")
	}
	
	var resulting_string = ""
	for key in parsed_results:
		resulting_string += "	[color=gray]%s[/color]: [color=white]%s[/color]\n" % [key, parsed_results[key]]
	
	return resulting_string
	
func sum_array(array):
	var sum = 0
	for element in array:
		sum += element
	return sum
	
	
func is_valid_ipv4(ip: String) -> bool:
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
	
	
func is_valid_ipv6(ip: String) -> bool:
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
	
	
func extract_domain(url: String) -> String:
	if url.begins_with("http://") or url.begins_with("https://"):
		url = url.split("://")[1]
	return url.split("/")[0]
	
	
func is_valid_domain(domain: String) -> bool:
	var domain_regex = RegEx.new()
	domain_regex.compile(r"^(?!-)(?:[a-zA-Z0-9-]{1,63}\.)+[a-zA-Z]{2,}$")
	return domain_regex.search(domain) != null


func handle_write_ip_csv():
	pass
