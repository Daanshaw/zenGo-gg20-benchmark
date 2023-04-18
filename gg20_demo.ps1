

function Measure-CommandInMilliseconds($scriptBlock) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    &$scriptBlock
    return $sw.Elapsed.TotalMilliseconds
}



# Prompt the user to enter the number of parties and threshold
Write-Host "Enter the number of parties:"
$numberOfParties = Read-Host
Write-Host "Enter the threshold:"
$threshold = Read-Host

$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Create the necessary directories for the example to run
Write-Host "Creating necessary directories..."
New-Item -Path target/release/examples -ItemType Directory -Force | Out-Null
$workingDir = Get-Location
Set-Location target/release/examples

# Start the SM server process
Write-Host "Starting SM server..."
$sm_pid = Start-Process -FilePath "./gg20_sm_manager" -PassThru

# Wait for 5 seconds to ensure that the SM server is ready for connections
Start-Sleep -Seconds 5

# Generate secret shares for each party
Write-Host "Benchmarking key generation..."
$keygenResults = @()
$keygenProcesses = @()
for ($i = 1; $i -le $numberOfParties; $i++) {
    # Benchmark keygen process for each party
    $keygenResults += Measure-CommandInMilliseconds -scriptBlock {
        Write-Host "Starting keygen process for party $i"
        $keygenProcesses += Start-Process -FilePath "./gg20_keygen" -ArgumentList "-t $threshold -n $numberOfParties -i $i --output local-share$i.json" -PassThru
        Start-Sleep -Seconds 1
    }
}

# Wait for all key generation processes to complete
foreach ($process in $keygenProcesses) {
    Write-Host "Waiting for keygen process $($process.Id) to complete..."
    $process.WaitForExit()
    Write-Host "Keygen process $($process.Id) completed."
}

# Define the parties that will participate in signing the message
$parties = 1..$threshold -join ','

# Sign the message with the selected parties
Write-Host "Benchmarking signing..."
$signingResults = @()
$signingProcesses = @()
for ($i = 1; $i -le $threshold; $i++) {
    # Benchmark signing process for each selected party
    $signingResults += Measure-CommandInMilliseconds -scriptBlock {
        Write-Host "Starting signing process for party $i"
        $signingProcesses += Start-Process -FilePath "cmd.exe" -ArgumentList "/c cd '$workingDir/target/release/examples' && gg20_signing -p $parties -d 'hello' -l local-share$i.json" -PassThru
        Start-Sleep -Seconds 1
    }
}

# Wait for all signing processes to complete
foreach ($process in $signingProcesses) {
    Write-Host "Waiting for signing process $($process.Id) to complete..."
    $process.WaitForExit()
    Write-Host "Signing process $($process.Id) completed."
}

# Stop the SM server process
Write-Host "Terminating SM server..."
$sm_process = Get-Process -Id $sm_pid.Id -ErrorAction SilentlyContinue
if ($sm_process) {
    Stop-Process -Id $sm_pid.Id
} else {
    Write-Host "SM server process already terminated."
}

# Output the benchmark results
Write-Host "Benchmark results:"
Write-Host "====================="
# Key generation and signing results...



# Calculate the average benchmark results
$avgKeygen = ($keygenResults | Measure-Object -Sum).Sum / $keygenResults.Count
$avgSigning = ($signingResults | Measure-Object -Sum).Sum / $signingResults.Count

Write-Host "Average key generation time: $($avgKeygen.ToString('F2')) ms"
Write-Host "Average signing time: $($avgSigning.ToString('F2')) ms"

# Calculate the waiting times in seconds
$serverConnectionWaitingTime_s = 5 # 5 seconds for server connection waiting time

# Calculate the elapsed time in seconds
$elapsed_time_s = [decimal]$Stopwatch.Elapsed.TotalSeconds

# Calculate the adjusted elapsed time in seconds
$adjusted_elapsed_time_s = $elapsed_time_s - $serverConnectionWaitingTime_s

# Convert the adjusted elapsed time to milliseconds and nanoseconds
$adjusted_elapsed_time_ms = $adjusted_elapsed_time_s * 1000
$adjusted_elapsed_time_ns = $adjusted_elapsed_time_s * 1000000000

Write-Host "Adjusted elapsed time: $($adjusted_elapsed_time_s.ToString('F2')) seconds"
Write-Host "Adjusted elapsed time: $($adjusted_elapsed_time_ms.ToString('F2')) milliseconds"
Write-Host "Adjusted elapsed time: $($adjusted_elapsed_time_ns.ToString('F2')) nanoseconds"



Write-Host "Press Enter to close the terminal..."
Read-Host