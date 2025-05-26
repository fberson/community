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

    # Download the OBUX Bootstrapper installer
    Invoke-WebRequest -Uri https://media.githubusercontent.com/media/OBUX-IT/obux-benchmark/refs/heads/main/OBUXBootstrapper.exe -OutFile C:\obux\OBUXBootstrapper.exe;
    Add-Content -Path C:\obux\obux_log.txt -Value 'Downloaded OBUXBootstrapper.exe';

    # Run the OBUX Bootstrapper installer
    Start-Process -Wait -FilePath C:\obux\OBUXBootstrapper.exe -ArgumentList "/silent";
    Add-Content -Path C:\obux\obux_log.txt -Value 'OBUX Bootstrapper installation completed';

    # Run the installed OBUX Benchmark executable
    Start-Process -Wait -FilePath "C:\Program Files\OBUX\Wrapper\OBUX Benchmark.exe" -ArgumentList "/silent /email:$email /benchmark:$benchmark /sharedata:$sharedataBool /insightinterval:$insightintervalInt";
    Add-Content -Path C:\obux\obux_log.txt -Value 'OBUX Benchmark execution completed';
} catch {
    # Log any errors
    Add-Content -Path C:\obux\obux_log.txt -Value $_.Exception.Message;
    throw;
}
