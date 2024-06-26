# Function Definitions

# Log messages to a specified file and handle file rotation if size exceeds limit
function LogToFile {
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

# ICMP Ping Check
function CheckICMPPing {
    Write-Host "Running CheckICMPPing..."
    $issuesDetected = $false
    $issueMessages = @()

    try {
        $ping = New-Object System.Net.NetworkInformation.Ping
        $pingResults = $ping.Send("www.google.com", 1000)  # Set timeout to 1000 milliseconds

        if ($pingResults.Status -ne [System.Net.NetworkInformation.IPStatus]::Success) {
            # Check packet loss percentage if ICMP ping failed
            $packetLossPercentage = CheckPacketLossPercentage
            $issueMessages += "ICMP ping failed: Detected $packetLossPercentage% packet loss."
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
        LogToFile -Path $logFilePath -Message $logMessage
    }

    return $issuesDetected
}

# Check Packet Loss Percentage
function CheckPacketLossPercentage {
    Write-Host "Running CheckPacketLossPercentage..."
    $totalPings = 10
    $failedPings = 0
    $ping = New-Object System.Net.NetworkInformation.Ping

    1..$totalPings | ForEach-Object {
        $pingResults = $ping.Send("www.google.com", 1000)  # Set timeout to 1000 milliseconds
        if ($pingResults.Status -ne [System.Net.NetworkInformation.IPStatus]::Success) {
            $failedPings++
        }
    }

    $packetLossPercentage = ($failedPings / $totalPings) * 100
    return $packetLossPercentage
}

# Check for High Latency
function CheckLatency {
    param (
        [int]$threshold = 150  # Default threshold set to 150 milliseconds
    )

    Write-Host "Running CheckLatency..."
    $highLatencyDetected = $false
    $issueMessages = @()

    try {
        $ping = New-Object System.Net.NetworkInformation.Ping
        $pingResults = $ping.Send("www.google.com", 1000)  # Set timeout to 1000 milliseconds

        if ($pingResults.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
            $latency = $pingResults.RoundtripTime
            if ($latency -gt $threshold) {
                $issueMessages += "High latency detected: $latency ms."
                $highLatencyDetected = $true
            }
        }
    }
    catch {
        # Adjust the error message to be more user-friendly
        $issueMessages += "Latency check error: Unable to send ICMP request."
        $highLatencyDetected = $true
    }

    # Log the latency issues if any
    if ($highLatencyDetected) {
        $logMessage = "[$(Get-Date)] Latency check results:`r`n$($issueMessages -join "`r`n")"
        LogToFile -Path $logFilePath -Message $logMessage
    }

    return $highLatencyDetected
}

# HTTP Connectivity Check
function CheckHTTPConnectivity {
    Write-Host "Running CheckHTTPConnectivity..."
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
        LogToFile -Path $logFilePath -Message $logMessage
    }

    return $issuesDetected
}

# TCP Port Availability Check
function CheckTCPPortAvailability {
    Write-Host "Running CheckTCPPortAvailability..."
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
        LogToFile -Path $logFilePath -Message $logMessage
    }

    return $issuesDetected
}


# Check various network parameters and log any detected issues
function CheckNetwork {
    $issuesDetected = $false
    $issueMessages = @()

    # ICMP Ping Check
    $pingIssues = CheckICMPPing
    if ($pingIssues) {
        $issuesDetected = $true
    }

    # Latency Check
    $latencyIssues = CheckLatency
    if ($latencyIssues) {
        $issuesDetected = $true
    }

    # HTTP Connectivity Check
    $httpIssues = CheckHTTPConnectivity
    if ($httpIssues) {
        $issuesDetected = $true
    }

    # TCP Port Availability Check
    $tcpPortIssues = CheckTCPPortAvailability
    if ($tcpPortIssues) {
        $issuesDetected = $true
    }

    # Aggregate all the issue messages
    if ($issuesDetected) {
        $issueMessages += "Network issues detected:`r`n"
        if ($pingIssues) {
            $issueMessages += (Get-Content -Path $logFilePath | Select-Object -Last 1)
        }
        if ($latencyIssues) {
            $issueMessages += (Get-Content -Path $logFilePath | Select-Object -Last 1)
        }
        if ($httpIssues) {
            $issueMessages += (Get-Content -Path $logFilePath | Select-Object -Last 1)
        }
        if ($tcpPortIssues) {
            $issueMessages += (Get-Content -Path $logFilePath | Select-Object -Last 1)
        }
    }

    return $issuesDetected, $issueMessages -join "`r`n"
}

# Main Script
$logDirectory = "Logs"
if (-not (Test-Path $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory
}

$logFilePath = Join-Path $logDirectory "network_log.txt"

# Create an empty log file if it doesn't exist
if (-not (Test-Path $logFilePath)) {
    New-Item -ItemType File -Path $logFilePath
}

while ($true) {
    $networkIssues, $errorDetails = CheckNetwork

    if ($networkIssues) {
        Write-Host $errorDetails
    } else {
        Write-Host "No network issues detected."
    }

    Start-Sleep -Seconds 10
}
