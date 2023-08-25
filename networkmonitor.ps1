# Function Definitions

# Log messages to a specified file and handle file rotation if size exceeds limit
function Log-ToFile {
    param (
        [string]$Path,
        [string]$Message
    )

    try {
        Add-Content -Path $Path -Value $Message

        # Check file size and rotate if necessary
        $fileInfo = Get-Item $Path
        if ($fileInfo.Length -gt (10 * 1024 * 1024)) { # Rotate if file size exceeds 10 MB
            $newFilePath = Join-Path $fileInfo.DirectoryName ("network_log_$(Get-Date -Format 'yyyyMMddHHmmss').txt")
            Rename-Item -Path $Path -NewName $newFilePath
        }
    }
    catch {
        Write-Host "Error logging to file: $($_.Exception.Message)"
    }
}

# Check DNS using multiple domains and DNS servers
function Check-DNS {
    $issuesDetected = $false
    $issueMessages = @()
    $domainsToCheck = @("www.google.com", "www.microsoft.com", "www.openai.com")
    $dnsServers = @("8.8.8.8", "8.8.4.4", "208.67.222.222")  # Google and OpenDNS servers

    foreach ($domain in $domainsToCheck) {
        foreach ($server in $dnsServers) {
            # Start a job to check DNS resolution
            $job = Start-Job -ScriptBlock {
                param($domain, $server)
                Resolve-DnsName -Name $domain -Server $server
            } -ArgumentList $domain, $server

            # Wait for job to complete with a 3 second timeout
            Wait-Job $job -Timeout 3

            # If job is still running (i.e., it's hung), stop it
            if ($job.State -eq "Running") {
                Stop-Job $job
                $issueMessages += "DNS resolution timeout for $domain using server $server. Possible network loss."
                $issuesDetected = $true
            } else {
                # Check the result of the job
                $result = Receive-Job -Job $job
                if (-not $result) {
                    $issueMessages += "DNS resolution failed for $domain using server $server."
                    $issuesDetected = $true
                }
            }

            # Clean up the job
            Remove-Job $job
        }
    }

    # Log the DNS issues if any
    if ($issuesDetected) {
        $logMessage = "[$(Get-Date)] DNS check results:`r`n$($issueMessages -join "`r`n")"
        Log-ToFile -Path $logFilePath -Message $logMessage
    }

    return $issuesDetected
}

# ICMP Ping Check
function Check-ICMPPing {
    Write-Host "Running Check-ICMPPing..."
    $issuesDetected = $false
    $issueMessages = @()

    try {
        $ping = New-Object System.Net.NetworkInformation.Ping
        $pingResults = $ping.Send("www.google.com", 1000)  # Set timeout to 1000 milliseconds

        if ($pingResults.Status -ne [System.Net.NetworkInformation.IPStatus]::Success) {
            $issueMessages += "ICMP ping failed: Packet loss detected."
            $issuesDetected = $true
        }
    }
    catch {
        # Adjust the error message to be more user-friendly
        $issueMessages += "ICMP ping error: Unable to send ICMP request. Possible total network loss."
        $issuesDetected = $true
    }

    # Log the ICMP issues if any
    if ($issuesDetected) {
        $logMessage = "[$(Get-Date)] ICMP check results:`r`n$($issueMessages -join "`r`n")"
        Log-ToFile -Path $logFilePath -Message $logMessage
    }

    return $issuesDetected
}

# HTTP Connectivity Check
function Check-HTTPConnectivity {
    Write-Host "Running Check-HTTPConnectivity..."
    $issuesDetected = $false
    $issueMessages = @()

    try {
        $client = New-Object System.Net.WebClient
        $client.DownloadString("http://www.google.com")
    }
    catch {
        $issueMessages += "HTTP connectivity failed."
        $issuesDetected = $true
    }

    # Log the HTTP issues if any
    if ($issuesDetected) {
        $logMessage = "[$(Get-Date)] HTTP connectivity check results:`r`n$($issueMessages -join "`r`n")"
        Log-ToFile -Path $logFilePath -Message $logMessage
    }

    return $issuesDetected
}

# TCP Port Availability Check
function Check-TCPPortAvailability {
    Write-Host "Running Check-TCPPortAvailability..."
    $issuesDetected = $false
    $issueMessages = @()

    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect("www.google.com", 80)
    }
    catch {
        $issueMessages += "TCP port availability failed."
        $issuesDetected = $true
    }

    # Log the TCP port issues if any
    if ($issuesDetected) {
        $logMessage = "[$(Get-Date)] TCP port availability check results:`r`n$($issueMessages -join "`r`n")"
        Log-ToFile -Path $logFilePath -Message $logMessage
    }

    return $issuesDetected
}

# VPN Connectivity Check
function Check-VPNConnectivity {
    Write-Host "Running Check-VPNConnectivity..."
    $issuesDetected = $false
    $issueMessages = @()

    try {
        $vpnConnection = Get-VpnConnection -AllUserConnection
        if ($vpnConnection -ne $null -and $vpnConnection.ConnectionStatus -ne 'Connected') {
            $issueMessages += "VPN connection is not running."
            $issuesDetected = $true
        }
    }
    catch {
        $issueMessages += "Error checking VPN connectivity: $($_.Exception.Message)"
        $issuesDetected = $true
    }

    # Log the VPN issues if any
    if ($issuesDetected) {
        $logMessage = "[$(Get-Date)] VPN connectivity check results:`r`n$($issueMessages -join "`r`n")"
        Log-ToFile -Path $logFilePath -Message $logMessage
    }

    return $issuesDetected
}

# Check various network parameters and log any detected issues
function Check-Network {
    $issuesDetected = $false

    # ICMP Ping Check
    $pingIssues = Check-ICMPPing
    if ($pingIssues) {
        $issuesDetected = $true
    }

    # DNS Check
    $dnsIssues = Check-DNS
    if ($dnsIssues) {
        $issuesDetected = $true
    }

    # HTTP Connectivity Check
    $httpIssues = Check-HTTPConnectivity
    if ($httpIssues) {
        $issuesDetected = $true
    }

    # TCP Port Availability Check
    $tcpPortIssues = Check-TCPPortAvailability
    if ($tcpPortIssues) {
        $issuesDetected = $true
    }

    # VPN Connectivity Check
    $vpnIssues = Check-VPNConnectivity
    if ($vpnIssues) {
        $issuesDetected = $true
    }

    return $issuesDetected
}

# Main Script
$logDirectory = "Logs"
if (-not (Test-Path $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory
}

$logFilePath = Join-Path $logDirectory "network_log.txt"

while ($true) {
    $networkIssues = Check-Network

    if ($networkIssues) {
        $errorDetails = Get-Content -Path $logFilePath -Tail 1
        Write-Host "Network issues detected:`r`n$errorDetails"
    } else {
        Write-Host "No network issues detected."
    }

    Start-Sleep -Seconds 10
}