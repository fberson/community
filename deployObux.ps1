param (
    [string]$email,
    [string]$benchmark,
    [string]$sharedata, # Changed to string to handle conversion
    [int]$insightinterval
)

try {
    # Convert sharedata to boolean
    $sharedataBool = if ($sharedata -eq 'true') { $true } elseif ($sharedata -eq 'false') { $false } else { throw "Invalid value for sharedata: $sharedata" }

    # Convert insightinterval to integer
    $insightintervalInt = [int]$insightinterval

    # Log script start
    Add-Content -Path C:\obux\obux_log.txt -Value 'Script execution started';

    # Ensure the C:\obux directory exists
    if (-not (Test-Path -Path 'C:\obux')) {
        New-Item -ItemType Directory -Path 'C:\obux' | Out-Null;
        Add-Content -Path C:\obux\obux_log.txt -Value 'Created C:\obux directory';
    } else {
        Add-Content -Path C:\obux\obux_log.txt -Value 'C:\obux directory already exists';
    }

    # Log parameters
    Add-Content -Path C:\obux\obux_log.txt -Value "Parameters: email=$email, benchmark=$benchmark, sharedata=$sharedataBool, insightinterval=$insightintervalInt";

    # Download the installer
    Invoke-WebRequest -Uri https://media.githubusercontent.com/media/OBUX-IT/obux-benchmark/refs/heads/main/OBUXBenchmark.zip -OutFile C:\obux\OBUXBootstrapper.zip;
    Add-Content -Path C:\obux\obux_log.txt -Value 'Downloaded OBUXBootstrapper.zip';

    # Extract the installer
    Expand-Archive -Path C:\obux\OBUXBootstrapper.zip -DestinationPath "C:\Program Files\OBUX";
    Add-Content -Path C:\obux\obux_log.txt -Value 'Extracted OBUXBootstrapper.zip to C:\Program Files\OBUX';

    # Run the installer
    Start-Process -Wait -FilePath "C:\Program Files\OBUX\Wrapper\OBUX Benchmark.exe" -ArgumentList "/silent /email:$email /benchmark:$benchmark /sharedata:$sharedataBool /insightinterval:$insightintervalInt";
    Add-Content -Path C:\obux\obux_log.txt -Value 'OBUX installation completed';
} catch {
    # Log any errors
    Add-Content -Path C:\obux\obux_log.txt -Value $_.Exception.Message;
    throw;
}
