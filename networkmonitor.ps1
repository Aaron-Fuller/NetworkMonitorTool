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

# Check various network parameters and log any detected issues
function Check-Network {
    $issuesDetected = $false
    $issueMessages = @() # Array to hold issue messages

    # Enhanced ICMP ping to check for packet loss and latency
    $pingCount = 5
    $pingTimeout = 1000  # 1 second in milliseconds
    $ping = New-Object System.Net.NetworkInformation.Ping

    $successfulPings = 0
    $totalRTT = 0
    $minRTT = [int]::MaxValue
    $maxRTT = 0

    for ($i = 0; $i -lt $pingCount; $i++) {
        try {
            $reply = $ping.Send("www.google.com", $pingTimeout)
            
            if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                $successfulPings++
                $totalRTT += $reply.RoundtripTime
                $minRTT = [math]::Min($minRTT, $reply.RoundtripTime)
                $maxRTT = [math]::Max($maxRTT, $reply.RoundtripTime)
            }
        }
        catch {
            $issueMessages += "ICMP ping error: Unable to send ping request. Network might be down."
            $issuesDetected = $true
            break  # Exit the loop early since there's no point in sending more pings
        }
    }

    # Calculate average RTT if there are successful pings
    if ($successfulPings -gt 0) {
        $averageRTT = $totalRTT / $successfulPings
    } else {
        $averageRTT = 0
    }

    # Log packet loss or high latency if detected
    $packetLossPercentage = (($pingCount - $successfulPings) / $pingCount) * 100
    if ($packetLossPercentage -gt 0) {
        $issueMessages += "ICMP ping: $packetLossPercentage% packet loss detected. Avg RTT: $averageRTT ms (Min: $minRTT ms, Max: $maxRTT ms)"
        $issuesDetected = $true
    } elseif ($averageRTT -gt 100) {  # Assuming a threshold of 100ms for high latency.
        $issueMessages += "ICMP ping: High latency detected. Avg RTT: $averageRTT ms (Min: $minRTT ms, Max: $maxRTT ms)"
        $issuesDetected = $true
    }

    # Check DNS resolution
    try {
        [System.Net.Dns]::GetHostEntry("www.google.com")
    }
    catch {
        $issueMessages += "DNS resolution failed."
        $issuesDetected = $true
    }

    # Check HTTP connectivity
    try {
        $client = New-Object System.Net.WebClient
        $client.DownloadString("http://www.google.com")
    }
    catch {
        $issueMessages += "HTTP connectivity failed."
        $issuesDetected = $true
    }

    # Check TCP port availability
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect("www.google.com", 80)
    }
    catch {
        $issueMessages += "TCP port availability failed."
        $issuesDetected = $true
    }

    # Check VPN connectivity if VPN is running
    try {
        $vpnConnection = Get-VpnConnection -AllUserConnection
        if ($vpnConnection -ne $null -and $vpnConnection.ConnectionStatus -eq 'Connected') {
            # No issues with VPN
        } else {
            $issueMessages += "VPN connection is not running."
        }
    }
    catch {
        $issueMessages += "Error checking VPN connectivity: $($_.Exception.Message)"
    }

    # Log all issue messages
    $logMessage = "[$(Get-Date)] Network check results:`r`n$($issueMessages -join "`r`n")"
    Log-ToFile -Path $logFilePath -Message $logMessage

    return $issuesDetected
}

# Main Script
$logDirectory = "Logs"
if (-not (Test-Path $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory
}

$logFilePath = Join-Path $logDirectory "network_log.txt"

$backoffTime = 10  # Start with a 10 second delay

while ($true) {
    $networkIssues = Check-Network

    if ($networkIssues) {
        $errorDetails = Get-Content -Path $logFilePath -Tail 1
        Write-Host "Network issues detected:`r`n$errorDetails"
        $backoffTime = [Math]::Min(300, $backoffTime * 2)  # Double the backoff time, but cap it at 300 seconds (5 minutes)
    } else {
        Write-Host "No network issues detected."
        $backoffTime = 10  # Reset backoff time to 10 seconds
    }

    Start-Sleep -Seconds $backoffTime
}