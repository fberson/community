param (
    [string]$email,
    [string]$benchmark,
    [string]$sharedata, # Changed to string to handle conversion
    [int]$insightinterval
)

try {
    # Convert sharedata to boolean
    $sharedataBool = if ($sharedata -eq 'true') { $true } elseif ($sharedata -eq 'false') { $false } else { throw "Invalid value for sharedata: $sharedata" }
} catch {
    Write-Error "Failed to convert sharedata to boolean: $_"
    throw;
}

try {
    # Convert insightinterval to integer
    $insightintervalInt = [int]$insightinterval
} catch {
    Write-Error "Failed to convert insightinterval to integer: $_"
    throw;
}

try {
    # Log script start
    Add-Content -Path C:\obux\obux_log.txt -Value 'Script execution started';
} catch {
    Write-Error "Failed to log script start: $_"
    throw;
}

try {
    # Ensure the C:\obux directory exists
    if (-not (Test-Path -Path 'C:\obux')) {
        New-Item -ItemType Directory -Path 'C:\obux' -Force | Out-Null;
        if (-not (Test-Path -Path 'C:\obux')) {
            throw "Failed to create C:\obux directory. Check permissions."
        }
        Add-Content -Path C:\obux\obux_log.txt -Value 'Created C:\obux directory';
    } else {
        Add-Content -Path C:\obux\obux_log.txt -Value 'C:\obux directory already exists';
    }
} catch {
    Write-Error "Failed to create or access C:\obux directory: $_"
    throw;
}

try {
    # Log parameters
    Add-Content -Path C:\obux\obux_log.txt -Value "Parameters: email=$email, benchmark=$benchmark, sharedata=$sharedataBool, insightinterval=$insightintervalInt";
} catch {
    Write-Error "Failed to log parameters: $_"
    throw;
}

try {
    # Download the OBUX Bootstrapper installer
    Invoke-WebRequest -Uri https://media.githubusercontent.com/media/OBUX-IT/obux-benchmark/refs/heads/main/OBUXBootstrapper.exe -OutFile C:\obux\OBUXBootstrapper.exe;
    Add-Content -Path C:\obux\obux_log.txt -Value 'Downloaded OBUXBootstrapper.exe';
} catch {
    Write-Error "Failed to download OBUX Bootstrapper: $_"
    throw;
}

try {
    # Run the OBUX Bootstrapper installer
    Start-Process -Wait -FilePath C:\obux\OBUXBootstrapper.exe -ArgumentList "/silent";
    Add-Content -Path C:\obux\obux_log.txt -Value 'OBUX Bootstrapper installation completed';
} catch {
    Write-Error "Failed to run OBUX Bootstrapper installer: $_"
    throw;
}

try {
    # Run the installed OBUX Benchmark executable
    Start-Process -Wait -FilePath "C:\Program Files\OBUX\Wrapper\OBUX Benchmark.exe" -ArgumentList "/silent /email:$email /benchmark:$benchmark /sharedata:$sharedataBool /insightinterval:$insightintervalInt";
    Add-Content -Path C:\obux\obux_log.txt -Value 'OBUX Benchmark execution completed';
} catch {
    Write-Error "Failed to run OBUX Benchmark executable: $_"
    throw;
}
