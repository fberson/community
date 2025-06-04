<#
.SYNOPSIS
Automates the deployment and execution of the OBUX Benchmark tool, logs execution details, and uploads results to an Azure Storage Account.

.DESCRIPTION
This script performs the following tasks:
1. Converts input parameters to appropriate types.
2. Logs script execution details.
3. Downloads and extracts the OBUX Benchmark tool.
4. Executes the benchmark tool with provided parameters.
5. Uploads CSV results to an Azure Storage Account, organizing them into subfolders matching the VM name.

.PARAMETER email
The email address to associate with the benchmark results.

.PARAMETER benchmark
The name of the benchmark to execute.

.PARAMETER sharedata
Indicates whether to share data (true/false).

.PARAMETER insightinterval
The interval for insights in seconds.

.PARAMETER saastoken
The SAS token for accessing the Azure Storage Account.

.PARAMETER containername
The name of the container in the Azure Storage Account where results will be uploaded.

.EXAMPLE
powershell -ExecutionPolicy Unrestricted -File deployObux.ps1 -email "user@example.com" -benchmark "VM1" -sharedata "true" -insightinterval 60 -saastoken "<SAS_TOKEN>" -containername "results"

.NOTES
Ensure the Azure Storage Account and container are properly configured before running this script.
#>

param (
    [string]$email,
    [string]$benchmark,
    [string]$sharedata,
    [int]$insightinterval,
    [string]$saastoken,
    [string]$containername,
    [string]$storageAccountName
)

# Ensure the C:\obux directory exists before logging
if (-not (Test-Path -Path 'C:\obux')) {
    try {
        New-Item -ItemType Directory -Path 'C:\obux' -Force | Out-Null
    } catch {
        Write-Error "Failed to create C:\obux directory: $_"
        throw
    }
}

try {
    Add-Content -Path C:\obux\obux_log.txt -Value 'Script execution started'
} catch {
    Write-Error "Failed to log script start: $_"
    throw
}

try {
    $sharedataBool = if ($sharedata -eq 'true') {
        $true
    } elseif ($sharedata -eq 'false') {
        $false
    } else {
        throw "Invalid value for sharedata: $sharedata"
    }
} catch {
    Write-Error "Failed to convert sharedata to boolean: $_"
    throw
}

try {
    $insightintervalInt = [int]$insightinterval
} catch {
    Write-Error "Failed to convert insightinterval to integer: $_"
    throw
}

try {
    Add-Content -Path C:\obux\obux_log.txt -Value "Parameters: email=$email, benchmark=$benchmark, sharedata=$sharedataBool, insightinterval=$insightintervalInt"
} catch {
    Write-Error "Failed to log parameters: $_"
    throw
}

try {
    Invoke-WebRequest -Uri https://media.githubusercontent.com/media/OBUX-IT/obux-benchmark/refs/heads/main/OBUXBenchmark.zip -OutFile C:\obux\OBUXBenchmark.zip
    Add-Content -Path C:\obux\obux_log.txt -Value 'Downloaded OBUXBenchmark.zip'
} catch {
    Write-Error "Failed to download OBUX Benchmark ZIP: $_"
    throw
}

try {
    Expand-Archive -Path C:\obux\OBUXBenchmark.zip -DestinationPath "C:\Program Files\OBUX" -Force
    Add-Content -Path C:\obux\obux_log.txt -Value 'Extracted OBUXBenchmark.zip to C:\Program Files\OBUX'
} catch {
    Write-Error "Failed to extract OBUX Benchmark ZIP: $_"
    throw
}

try {
    Start-Process -Wait -FilePath "C:\Program Files\OBUX\Wrapper\OBUX Benchmark.exe" -ArgumentList "/silent /email:$email /benchmark:$benchmark /sharedata:$sharedataBool /insightinterval:$insightintervalInt"
    Add-Content -Path C:\obux\obux_log.txt -Value 'OBUX Benchmark execution completed'
} catch {
    Write-Error "Failed to run OBUX Benchmark executable: $_"
    throw
}

# Upload CSV files to Azure Storage Account
if (-not $storageAccountName) {
    Write-Error "Missing or invalid storageAccountName parameter"
    throw
}

try {
    $csvFiles = Get-ChildItem -Path "C:\Program Files\OBUX\Wrapper\results" -Filter *.csv
    foreach ($csvFile in $csvFiles) {
        $vmFolderUri = "https://${storageAccountName}.blob.core.windows.net/${containername}/${benchmark}"
        $storageUri = "${vmFolderUri}/${csvFile.Name}?${saastoken}"

        # Upload the file
        Invoke-WebRequest -Uri $storageUri -Method Put -InFile $csvFile.FullName -Headers @{"x-ms-blob-type" = "BlockBlob"}

        Add-Content -Path C:\obux\obux_log.txt -Value "Uploaded ${csvFile.Name} to storage account in folder ${benchmark}"
    }
} catch {
    Write-Error "Failed to upload CSV files to storage account: $_"
    throw
}
