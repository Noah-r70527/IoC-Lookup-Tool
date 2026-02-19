# IoC Lookup Tool

A lightweight Indicator of Compromise (IoC) investigation tool built entirely with the Godot Engine using GDScript. Designed for cybersecurity analysts, SOC teams, and system administrators who need a fast, offline-capable desktop tool for querying and managing IoCs without spinning up a Python environment or using a browser.

---

## Features

### IP Lookup Tool
- **Single IP lookup** — queries AbuseIPDB for abuse confidence score, ISP, country, hostnames, and total reports
- **Multi-IP lookup** — paste a newline-separated list and look up each in sequence (1-second delay between requests to respect rate limits)
- **Cache-aware** — checks the local IoC cache before making an API call; shows a yellow "cache hit" notice if the result is already stored
- **CSV logging** — optionally writes results to `IPLookups/{date}/single_lookup.csv` or `multi_lookup.csv`, filtered by a configurable minimum abuse score
- **Tool/source selector** — choose which detection system (e.g. Sentinel, Defender, Datadog) generated the indicator for logging purposes
- **Progress bar** for multi-IP operations

### URL / Domain Lookup Tool
- **Single URL lookup** — extracts the domain from any URL and queries VirusTotal for detection statistics (Total, Malicious, Suspicious, Undetected, Harmless, Timeout)
- **Multi-URL lookup** — batch lookup with a 15-second delay between requests to comply with VirusTotal's free-tier rate limits
- **DNS lookup** — resolves a hostname to its IPv4 and IPv6 addresses using the system resolver
- **Cache-aware** — same cache logic as the IP tool; keyed on the extracted domain
- **CSV logging** — optionally writes results to `URLLookups/{date}/url_lookups.csv`
- **Progress bar** for multi-URL operations

### Hash Lookup Tool
- **Single hash lookup** via VirusTotal (MD5, SHA-1, SHA-256)
- Multi-hash batch lookup *(in development)*

### Microsoft Defender Indicator Tool
- **Add a single indicator** via a form with fields for value, type, action, severity, description, title, recommended actions, and expiration time
- **Bulk add indicators from CSV** — select a CSV file and submit all rows to the Defender API in sequence
- **Supported indicator types**: IpAddress, DomainName, Url, FileMd5, FileSha1, FileSha256, CertificateThumbprint
- **Input validation** — verifies IP format, domain validity, URL prefix, and hash format (via regex) before submitting to the API
- **CSV template download** — downloads the required column layout directly from the repository
- Requires Microsoft Defender for Endpoint API credentials (Client ID, Client Secret, Tenant ID)

### Defang Tool
- **Defang IPs** — converts valid IPv4 addresses to non-clickable format and writes results to `DefangedOutput/defanged_ips.csv`
- **Defang URLs** — converts URLs to defanged format and writes results to `DefangedOutput/defanged_urls.csv`

---

## IoC Cache

Results from IP and URL lookups are stored locally in a JSON file (`cached/save_file.json` next to the executable).

- **Cache hit notification** — a yellow banner is shown in the output panel when a previously looked-up value is returned from cache instead of making an API call
- **TTL expiry** — cached entries older than the configured TTL are ignored and a fresh API call is made
- **Max size enforcement** — when the cache exceeds the configured limit, the oldest entries are evicted automatically
- Both TTL and max size are configurable via sliders in the Settings panel

---

## Auto-Rearm (Auto-Defang)

When enabled, any defanged IoC pasted into a text input (e.g. `1[.]2[.]3[.]4` or `hxxps://example[.]com`) is automatically re-fanged so it can be submitted to the API correctly. Caret position is preserved after the replacement.

---

## Settings

All settings are stored in an encrypted config file (`user://ioctoolsettingsupd.ini`) and filled with defaults on first launch.

| Setting | Description |
|---|---|
| AbuseIPDB API Key | Required for all IP lookups |
| VirusTotal API Key | Required for URL and hash lookups |
| Defender Client ID | Required for Defender Indicator Tool |
| Defender Client Secret | Required for Defender Indicator Tool |
| Defender Tenant ID | Required for Defender Indicator Tool |
| Analyst Name | Logged to CSV as `Entered_By` |
| Log IP Lookups to CSV | Toggle CSV output for IP lookups |
| Log URL Lookups to CSV | Toggle CSV output for URL lookups |
| Auto-Defang (Rearm) | Toggle automatic re-fanging of pasted IoCs |
| Minimum Abuse Score | Minimum score required to write an IP result to CSV (0–100) |
| Cache TTL (Days) | How long a cached result is considered valid before expiring (default: 7) |
| Maximum Cache Size | Maximum number of IoC entries stored in the local cache (default: 1000) |
| Tool Management | Add, remove, and list the detection system names shown in the IP tool dropdown |

---

## Output

- Color-coded BBCode output in a scrollable panel
- Log level filtering: **All**, **Informational**, **Error**
- Progress bar visible during multi-item operations

### Output File Structure

```
<executable directory>/
├── IPLookups/
│   └── {YYYY_M_D}/
│       ├── single_lookup.csv
│       └── multi_lookup.csv
├── URLLookups/
│   └── {YYYY_M_D}/
│       └── url_lookups.csv
├── DefangedOutput/
│   ├── defanged_ips.csv
│   └── defanged_urls.csv
└── cached/
    └── save_file.json
```

---

## Requirements

- Windows (exported Godot binary — no Godot installation required to run)
- API keys as needed per tool:
  - [AbuseIPDB](https://www.abuseipdb.com/) — for IP lookups
  - [VirusTotal](https://www.virustotal.com/) — for URL and hash lookups
  - Microsoft Entra app registration with Defender for Endpoint permissions — for the Defender Indicator Tool

---

## Built With

- [Godot Engine 4](https://godotengine.org/) — UI and runtime
- GDScript — all application logic
- No external dependencies or runtime installations required
