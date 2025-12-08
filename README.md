# react2shell-scanner

A command-line tool for detecting CVE-2025-55182 and CVE-2025-66478 in Next.js applications using React Server Components.

For technical details on the vulnerability and detection methodology, see our blog post: https://slcyber.io/research-center/high-fidelity-detection-mechanism-for-rsc-next-js-rce-cve-2025-55182-cve-2025-66478

## How It Works

By default, the scanner sends a crafted multipart POST request containing an RCE proof-of-concept payload that executes a deterministic math operation (`41*271 = 11111`). Vulnerable hosts return the result in the `X-Action-Redirect` response header as `/login?a=11111`.

The scanner tests the root path (`/`) by default. Use `--path` or `--path-file` to test custom paths. If not vulnerable, it follows same-host redirects (e.g., `/` to `/en/`) and tests the redirect destination. Cross-origin redirects are not followed.

### Safe Check Mode

The `--safe-check` flag uses an alternative detection method that relies on side-channel indicators (500 status code with specific error digest) without executing code on the target. Use this mode when RCE execution is not desired.

### WAF Bypass

The `--waf-bypass` flag prepends random junk data to the multipart request body. This can help evade WAF content inspection that only analyzes the first portion of request bodies. The default size is 128KB, configurable via `--waf-bypass-size`. When WAF bypass is enabled, the timeout is automatically increased to 20 seconds (unless explicitly set).

### Vercel WAF Bypass

The `--vercel-waf-bypass` flag uses an alternative payload variant specifically designed to bypass Vercel WAF protections. This uses a different multipart structure with an additional form field.

### Windows Mode

The `--windows` flag switches the payload from Unix shell (`echo $((41*271))`) to PowerShell (`powershell -c "41*271"`) for targets running on Windows.

## Requirements

- Python 3.9+
- requests
- tqdm

## Installation

```
pip install -r requirements.txt
```

## Docker

You can run the scanner inside a Docker container. The container image is small and runs the `scanner.py` directly.

Build the image:

```bash
docker build -t react2shell-scanner .
```

Run a single-host safe check (recommended when testing unknown targets):

```bash
docker run --rm react2shell-scanner -u https://example.com --safe-check
```

Scan a hosts file from your working directory and save results to a file (mount the current directory):

```bash
docker run --rm -v "$(pwd)":/app react2shell-scanner -l hosts.txt --safe-check -o results.json
```

Notes:

- The container runs as a non-root user.
- By default the scanner performs the active RCE PoC when `--safe-check` is not used. Use `--safe-check` to avoid executing payloads on targets you do not control.
- Use `-k/--insecure` if you need to disable SSL verification (opt-in).


## Usage

Scan a single host:

```
python3 scanner.py -u https://example.com
```

Scan a list of hosts:

```
python3 scanner.py -l hosts.txt
```

Scan with multiple threads and save results:

```
python3 scanner.py -l hosts.txt -t 20 -o results.json
```

Scan with custom headers:

```
python3 scanner.py -u https://example.com -H "Authorization: Bearer token" -H "Cookie: session=abc"
```

Use safe side-channel detection:

```
python3 scanner.py -u https://example.com --safe-check
```

Scan Windows targets:

```
python3 scanner.py -u https://example.com --windows
```

Scan with WAF bypass:

```
python3 scanner.py -u https://example.com --waf-bypass
```

Scan custom paths:

```
python3 scanner.py -u https://example.com --path /_next
python3 scanner.py -u https://example.com --path /_next --path /api
python3 scanner.py -u https://example.com --path-file paths.txt
```

## Options

```
-u, --url         Single URL to check
-l, --list        File containing hosts (one per line)
-t, --threads     Number of concurrent threads (default: 10)
--timeout         Request timeout in seconds (default: 10)
-o, --output      Output file for results (JSON)
--all-results     Save all results, not just vulnerable hosts
-k, --insecure    Disable SSL certificate verification
-H, --header      Custom header (can be used multiple times)
-v, --verbose     Show response details for vulnerable hosts
-q, --quiet       Only output vulnerable hosts
--no-color        Disable colored output
--safe-check      Use safe side-channel detection instead of RCE PoC
--windows         Use Windows PowerShell payload instead of Unix shell
--waf-bypass      Add junk data to bypass WAF content inspection
--waf-bypass-size Size of junk data in KB (default: 128)
--path            Custom path to test (can be used multiple times)
--path-file       File containing paths to test (one per line)
```

## Credits

The RCE PoC was originally disclosed by [@maple3142](https://x.com/maple3142) -- we are incredibly grateful for their work in publishing a working PoC.

This tooling originally was built out as a safe way to detect the RCE. This functionality is still available via `--safe-check`, the "safe detection" mode.

- Assetnote Security Research Team - [Adam Kues, Tomais Williamson, Dylan Pindur, Patrik Grobshäuser, Shubham Shah](https://x.com/assetnote)
- [xEHLE_](https://x.com/xEHLE_) - RCE output reflection in resp header
- [Nagli](https://x.com/galnagli)

## Output

Results are printed to the terminal. When using `-o`, vulnerable hosts are saved to a JSON file containing the full HTTP request and response for verification.

## Ethics & Disclaimer

- **Purpose:** This tool is provided to help defenders and researchers detect and verify CVE-2025-55182 / CVE-2025-66478. It exists to improve security by sharing detection techniques and amplifying the work of other security researchers.
- **Authorization Required:** Only run this scanner against systems you own or where you have explicit, written permission to test. Unauthorized scanning may be illegal and unethical.
- **Safe-by-Default Guidance:** When testing unknown targets, prefer the `--safe-check` flag which uses side-channel indicators instead of executing the RCE proof-of-concept. The default RCE PoC mode may execute commands on the target; use it only with explicit authorization.
- **No Warranty / No Guarantees:** This tool is provided "as-is". I do not guarantee its accuracy, completeness, or suitability. Use at your own risk — I accept no liability for damages or unintended consequences arising from its use.
- **Verification Recommended:** Scan results may include false positives or false negatives. Always verify findings manually and follow responsible disclosure practices when reporting vulnerabilities.
- **Maintainer Note:** I maintain this project in my spare time and may not be able to respond promptly to issues or pull requests. I don't have sufficient time to focus on original research; this project packages and shares the work of the original researchers to help defenders. Thank you to the researchers and contributors whose work made this possible.

