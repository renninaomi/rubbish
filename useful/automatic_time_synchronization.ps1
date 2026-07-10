# automatic_time_synchronization.ps1

# Ensure Windows Time service is running
$service = Get-Service w32time
if ($service.Status -ne 'Running') {
    Start-Service w32time
}

# Define at least three different time servers
$servers = @(
    "time.windows.com",
    "time.apple.com",
    "ntp.aliyun.com"
)

$maxRounds = 2          # Max polling rounds
$targetSuccesses = 3    # Target success count threshold
$totalSuccesses = 0     # Current success counter

Write-Host "Starting time synchronization..." -ForegroundColor Cyan

for ($round = 1; $round -le $maxRounds; $round++) {
    Write-Host "`n--- Round $round ---" -ForegroundColor Yellow
    
    foreach ($server in $servers) {
        # Sync each server 2 times
        for ($attempt = 1; $attempt -le 2; $attempt++) {
            Write-Host "Attempting sync with $server (Attempt $attempt)..."
            
            # Configure manual peer
            w32tm /config /manualpeerlist:"$server" /syncfromflags:manual /reliable:no /update | Out-Null
            
            # Force resync
            $result = w32tm /resync 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Success: $server" -ForegroundColor Green
                $totalSuccesses++
            } else {
                Write-Host "  Failed: $server" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "Round $round completed. Total successes: $totalSuccesses" -ForegroundColor Cyan
    
    if ($totalSuccesses -ge $targetSuccesses) {
        Write-Host "Target reached. Stopping." -ForegroundColor Green
        break
    }
    
    if ($round -lt $maxRounds) {
        Write-Host "Successes < 3. Re-polling..." -ForegroundColor Magenta
    } else {
        Write-Host "Max rounds reached." -ForegroundColor Red
    }
}

# Final result summary
Write-Host "`n--- Sync Result Summary ---" -ForegroundColor White
Write-Host "Total attempts: $($servers.Count * 2) (2 per server)"
Write-Host "Total successes: $totalSuccesses"

if ($totalSuccesses -ge $targetSuccesses) {
    Write-Host "Result: SUCCESS" -ForegroundColor Green
} else {
    Write-Host "Result: FAILED - Target not reached within $maxRounds rounds." -ForegroundColor Red
}
