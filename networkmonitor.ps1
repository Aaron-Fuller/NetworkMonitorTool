# Function Definitions
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
        $reply = $ping.Send("www.google.com", $pingTimeout)
        
        if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
            $successfulPings++
            $totalRTT += $reply.RoundtripTime
            $minRTT = [math]::Min($minRTT, $reply.RoundtripTime)
            $maxRTT = [math]::Max($maxRTT, $reply.RoundtripTime)
        }
    }

    $packetLossPercentage = (($pingCount - $successfulPings) / $pingCount) * 100
    $averageRTT = $totalRTT / $successfulPings

    if ($packetLossPercentage -gt 0) {
        $issueMessages += "ICMP ping: $packetLossPercentage% packet loss detected. Avg RTT: $averageRTT ms (Min: $minRTT ms, Max: $maxRTT ms)"
        $issuesDetected = $true
    } elseif ($averageRTT -gt 100) {  # Assuming a threshold of 100ms for high latency.
        $issueMessages += "ICMP ping: High latency detected. Avg RTT: $averageRTT ms (Min: $minRTT ms, Max: $maxRTT ms)"
        $issuesDetected = $true
    }

    # Check DNS resolution
    try {
        Write-Host "Checking DNS resolution..."
        [System.Net.Dns]::GetHostEntry("www.google.com")
    }
    catch {
        $issueMessages += "DNS resolution failed."
        $issuesDetected = $true
    }

    # Check HTTP connectivity
    try {
        Write-Host "Checking HTTP connectivity..."
        $client = New-Object System.Net.WebClient
        $client.DownloadString("http://www.google.com")
    }
    catch {
        $issueMessages += "HTTP connectivity failed."
        $issuesDetected = $true
    }

    # Check TCP port availability
    try {
        Write-Host "Checking TCP port availability..."
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect("www.google.com", 80)
    }
    catch {
        $issueMessages += "TCP port availability failed."
        $issuesDetected = $true
    }

    # Check VPN connectivity if VPN is running
    try {
        Write-Host "Checking VPN connectivity..."
        $vpnConnection = Get-VpnConnection -AllUserConnection
        if ($vpnConnection -ne $null -and $vpnConnection.ConnectionStatus -eq 'Connected') {
            Write-Host "VPN connection is running."
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

while ($true) {
    try {
        Write-Host "Checking network..."
        $networkIssues = Check-Network

        if ($networkIssues) {
            $errorDetails = Get-Content -Path $logFilePath -Tail 1
            Write-Host "Network issues detected:`r`n$errorDetails"
        } else {
            Write-Host "No network issues detected."
            $noIssuesLog = "[$(Get-Date)] No network issues detected."
            Log-ToFile -Path $logFilePath -Message $noIssuesLog
        }

        Write-Host "Waiting for the next check..."
        Start-Sleep -Seconds 10
    }
    catch {
        $errorMessage = "[$(Get-Date)] Error: $($_.Exception.Message)"
        Log-ToFile -Path $logFilePath -Message $errorMessage
    }
}
