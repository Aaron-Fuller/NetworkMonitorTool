## Network Monitoring Script

This PowerShell script is designed to monitor network connectivity for a remote work environment and log any detected issues. The script performs various checks, including ICMP ping, DNS resolution, HTTP connectivity, and TCP port availability. It also includes a basic check for VPN connectivity if a VPN connection is running.

## Purpose

In a fully remote work environment, maintaining reliable network connectivity is crucial for ensuring smooth operations. This script helps monitor network health and identifies potential issues that might affect remote employees' productivity.

## Features

- Regularly checks network connectivity using ICMP ping, DNS resolution, HTTP connectivity, and TCP port availability.
- Logs detected network issues to a log file, including timestamp and details of the issue.
- Supports log rotation to manage log file size.

## Usage

1. **Requirements**: Make sure you have PowerShell installed on the system where you intend to run this script.

2. **Configuration**: The script doesn't require extensive configuration. However, you can adjust the log directory and log rotation settings in the script if needed.

3. **Running the Script**: Open a PowerShell terminal and navigate to the directory containing the script. Run the script using the command:

   ```powershell
   .\NetworkMonitoringScript.ps1
   ```

4. **Termination**: The script runs indefinitely, periodically checking network connectivity. To stop the script, press `Ctrl + C` in the PowerShell terminal.

## Customization

- You can customize the network checks in the `Check-Network` function to match your network environment's specifics.
- Adjust log rotation settings based on your preferred file size and retention policies.

## Notifications and Improvements

- To receive notifications about network issues, consider integrating a notification mechanism (e.g., email, Slack, or SMS).
- Enhance the script to support more advanced checks, such as checking for specific services or endpoints relevant to your remote work setup.
- Regularly review and adapt the script based on feedback and changing network conditions.

## Disclaimer

This script provides basic network monitoring functionality and may require further adaptation to fully meet the needs of your remote work environment. Test the script in a controlled environment before deploying it to production.

## Author

Aaron Fuller
aaron.fuller@pharmacentra.com
08/24/2023
