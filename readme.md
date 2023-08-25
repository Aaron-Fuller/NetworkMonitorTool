# Network Diagnostic Script

Clumsy was used for testing this script by simulating network issues:
http://jagt.github.io/clumsy/

This PowerShell script is designed to diagnose common network issues, including ICMP ping failures, high latency, HTTP connectivity problems, TCP port availability, and VPN connectivity status. The results are logged, and any detected issues are printed in the PowerShell console.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Functions Overview](#functions-overview)
- [Configuration](#configuration)
- [Logs](#logs)
- [Contributing](#contributing)
- [License](#license)

## Features

- **ICMP Ping Check**: Detects if there's a failure in ICMP pings to `www.google.com`.
- **Packet Loss Percentage**: If ICMP ping fails, it checks for the percentage of packet loss.
- **High Latency Check**: Determines if the network latency exceeds a specified threshold.
- **HTTP Connectivity**: Checks for successful HTTP connectivity to `www.google.com`.
- **TCP Port Availability**: Verifies if TCP port 80 on `www.google.com` is reachable.
- **VPN Connectivity**: Assesses if the VPN connection is running.
- **Logging**: Logs details of detected issues and rotates log files if they exceed a size of 10MB.

## Prerequisites

- Windows OS (The script is written in PowerShell).
- VPN configurations (if you want to check VPN connectivity).

## Installation

1. Clone this repository or download the script to your local machine.
2. Ensure PowerShell is available on your system.
3. Navigate to the directory containing the script.

## Usage

1. Open PowerShell as an administrator.
2. Navigate to the script's directory.
3. Execute the script:

```powershell .\script_name.ps1```


The script will run in a loop, checking the network parameters and logging any detected issues. Detected issues will also be displayed in the PowerShell console.

## Functions Overview
- Log-ToFile: Logs messages to a specified file and handles file rotation if the size exceeds the limit.
- Check-ICMPPing: Checks ICMP ping to www.google.com and detects any failures.
- Check-PacketLossPercentage: Calculates the percentage of packet loss if ICMP ping fails.
- Check-Latency: Checks for high latency in the network.
- Check-HTTPConnectivity: Verifies HTTP connectivity to www.google.com.
- Check-TCPPortAvailability: Validates if TCP port 80 on www.google.com is available.
- Check-VPNConnectivity: Checks the status of the VPN connection.
- Check-Network: Main function that utilizes the above functions to check various network parameters.
  
## Configuration
Certain parameters in the script can be adjusted for your specific environment:

- Latency Threshold: The threshold for high latency can be adjusted in the Check-Latency function. The default is set to 200 milliseconds.
- Ping Timeout: In functions like Check-ICMPPing, the timeout for a ping request is set to 1000 milliseconds. Adjust as necessary.
- Log Directory: The directory where log files are saved is set to "Logs". Modify this if needed.

## Logs
The script maintains a log file named network_log.txt in a directory called "Logs". If a log file exceeds 10MB, it will be renamed with a timestamp, and a new log file will be created.

## Contributing
Contributions are welcome! Please fork the repository and create a pull request with your changes.

## License
This script is released under the MIT License. Please refer to the LICENSE file for more details.
