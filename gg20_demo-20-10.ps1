$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host "Creating necessary directories..."
New-Item -Path target/release/examples -ItemType Directory -Force | Out-Null
$workingDir = Get-Location
Set-Location target/release/examples

Write-Host "Starting SM server..."
$sm_pid = Start-Process -FilePath "./gg20_sm_manager" -PassThru

# Adding a delay to ensure SM server is ready for connections
Start-Sleep -Seconds 5

Write-Host "Generating keys..."

1..20 | ForEach-Object {
    Start-Process -FilePath "./gg20_keygen" -ArgumentList "-t 10 -n 20 -i $_ --output local-share$($_).json" -PassThru
}

Wait-Process -Id (Get-Process | Where-Object { $_.Path -like '*gg20_keygen*' }).Id

Write-Host "Signing message with 10 parties..."

1..10 | ForEach-Object {
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c cd '$workingDir/target/release/examples' && gg20_signing -p 1,2,3,4,5,6,7,8,9,10 -d 'hello' -l local-share$($_).json"
}

Wait-Process -Id (Get-Process | Where-Object { $_.Path -like '*gg20_signing*' }).Id

Write-Host "Finished signing."

Write-Host "Terminating SM server..."
Stop-Process -Id $sm_pid.Id

$elapsed_time_ms = $Stopwatch.Elapsed.TotalMilliseconds
$elapsed_time_ns = $Stopwatch.Elapsed.Ticks * 100

Write-Host "Elapsed time: $($elapsed_time_ms.ToString('F2')) milliseconds"
Write-Host "Elapsed time: $($elapsed_time_ns.ToString('F2')) nanoseconds"
