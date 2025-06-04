<#
.SYNOPSIS
Automates the deployment and execution of the OBUX Benchmark tool, logs execution details, and uploads results to an Azure Storage Account.

.DESCRIPTION
This script:
1. Validates input parameters.
2. Logs execution events.
3. Downloads and extracts the OBUX Benchmark tool.
4. Executes the benchmark.
5. Uploads resulting CSV files to Azure Blob Storage under a subfolder named after the benchmark name.

.PARAMETER email
Email address to associate with the results.

.PARAMETER benchmark
The benchmark name (used as VM identifier/folder name).

.PARAMETER sharedata
Whether to share data (true/false).

.PARAMETER insightinterval
Time interval in seconds for insights.

.PARAMETER sasToken
SAS token to authorize access to blob storage.

.PARAMETER containername
Name of the blob container in the storage account.

.PARAMETER storageAccountName
Name of the Azure Storage Account (no domain).

.EXAMPLE
powershell -ExecutionPolicy Unrestricted -File deployObux.ps1 -email "user@example.com" -benchmark "VM1" -sharedata "true" -insightinterval 60 -sasToken "<SAS_TOKEN>" -containername "results" -storageAccountName "obuxstorage"
#>

param (
    [string]$email,
    [string]$benchmark,
    [string]$sharedata,
    [int]$insightinterval,
    [string]$storageAccountName,
    [string]$containerName,
    [string]$sasToken  # Now passed directly again, securely
)


# Ensure logging directory exists
$logDir = "C:\obux"
$logFile = "$logDir\obux_log.txt"

if (-not (Test-Path -Path $logDir)) {
    try {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    catch {
        Write-Error "Failed to create log directory: $_"
        exit 1
    }
}

# Log start
try {
    Add-Content -Path $logFile -Value "[$(Get-Date -Format o)] Script execution started"
}
catch {
    Write-Error "Failed to write to log file: $_"
    exit 1
}

# Convert sharedata to boolean
try {
    $sharedataBool = switch ($sharedata.ToLower()) {
        'true' { $true }
        'false' { $false }
        default { throw "Invalid value for sharedata: $sharedata" }
    }
}
catch {
    Write-Error $_
    exit 1
}

# Log parameters
Add-Content -Path $logFile -Value "Parameters: email=$email, benchmark=$benchmark, sharedata=$sharedataBool, insightinterval=$insightinterval"

# Download Benchmark Tool
try {
    $zipPath = "$logDir\OBUXBenchmark.zip"
    Invoke-WebRequest -Uri "https://media.githubusercontent.com/media/OBUX-IT/obux-benchmark/refs/heads/main/OBUXBenchmark.zip" -OutFile $zipPath
    Add-Content -Path $logFile -Value "Downloaded OBUXBenchmark.zip"
}
catch {
    Write-Error "Failed to download benchmark zip: $_"
    exit 1
}

# Extract Benchmark
try {
    Expand-Archive -Path $zipPath -DestinationPath "C:\Program Files\OBUX" -Force
    Add-Content -Path $logFile -Value "Extracted benchmark to C:\Program Files\OBUX"
}
catch {
    Write-Error "Failed to extract benchmark zip: $_"
    exit 1
}

# Run Benchmark
try {
    Start-Process -Wait -FilePath "C:\Program Files\OBUX\Wrapper\OBUX Benchmark.exe" -ArgumentList "/silent /email:$email /benchmark:$benchmark /sharedata:$sharedataBool /insightinterval:$insightinterval"
    Add-Content -Path $logFile -Value "Benchmark executed successfully"
}
catch {
    Write-Error "Failed to run benchmark: $_"
    exit 1
}

# Upload results to Azure Blob Storage
try {
    $resultPath = "C:\Program Files\OBUX\results"
    $csvFiles = Get-ChildItem -Path $resultPath -Filter *.csv

    foreach ($csvFile in $csvFiles) {
        $blobUri = "https://${storageAccountName}.blob.core.windows.net/${containerName}/${benchmark}/$($csvFile.Name)?${sasToken}"
        Add-Content -Path $logFile -Value "Uploading to URI: $blobUri"
        Invoke-RestMethod -Uri $blobUri -Method Put -InFile $csvFile.FullName -Headers @{ "x-ms-blob-type" = "BlockBlob" }
        Add-Content -Path $logFile -Value "Uploaded $($csvFile.Name) to blob storage under ${benchmark}/"
    }
}
catch {
    Write-Error "Failed to upload CSV files to storage account: $_"
    exit 1
}



