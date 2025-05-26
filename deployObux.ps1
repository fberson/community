param (
    [string]$email,
    [string]$benchmark,
    [bool]$sharedata,
    [int]$insightinterval
)

try {
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
    Add-Content -Path C:\obux\obux_log.txt -Value "Parameters: email=$email, benchmark=$benchmark, sharedata=$sharedata, insightinterval=$insightinterval";

    # Download the installer
    Invoke-WebRequest -Uri https://github.com/OBUX-IT/obux-benchmark/releases/latest/download/OBUXBootstrapper.zip -OutFile C:\obux\OBUXBootstrapper.zip;
    Add-Content -Path C:\obux\obux_log.txt -Value 'Downloaded OBUXBootstrapper.zip';

    # Extract the installer
    Expand-Archive -Path C:\obux\OBUXBootstrapper.zip -DestinationPath C:\obux\OBUXBootstrapper;
    Add-Content -Path C:\obux\obux_log.txt -Value 'Extracted OBUXBootstrapper.zip';

    # Run the installer
    Set-Locationt C:\obux\OBUXBootstrapper;
    Start-Process -Wait -FilePath .\OBUXBootstrapper.exe -ArgumentList "/silent /email:$email /benchmark:$benchmark /sharedata:$sharedata /insightinterval:$insightinterval";
    Add-Content -Path C:\obux\obux_log.txt -Value 'OBUX installation completed';
} catch {
    # Log any errors
    Add-Content -Path C:\obux\obux_log.txt -Value $_.Exception.Message;
    throw;
}
