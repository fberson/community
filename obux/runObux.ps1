<#
.SYNOPSIS
Executes the OBUX Benchmark tool and uploads results to Azure Blob Storage under a subfolder named after the benchmark name.

.DESCRIPTION
This script:
1. Reads parameters from obux-settings.json.
2. Executes the benchmark.
3. Uploads resulting CSV files to Azure Blob Storage.
#>

# Read parameters from JSON file
try {
    $settingsFilePath = "C:\obux\obux-settings.json"
    $settings = Get-Content -Path $settingsFilePath | ConvertFrom-Json
    $email = $settings.email
    $benchmark = $settings.benchmark
    $sharedata = $settings.sharedata
    $insightinterval = $settings.insightinterval
    $storageAccountName = $settings.storageAccountName
    $containerName = $settings.containerName
    $sasToken = $settings.sasToken
}
catch {
    Write-Error "Failed to read parameters from JSON file: $_"
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

# Run Benchmark
try {
    Start-Process -Wait -FilePath "C:\Program Files\OBUX\Wrapper\OBUX Benchmark.exe" -ArgumentList "/silent /email:$email /benchmark:$benchmark /sharedata:$sharedataBool /insightinterval:$insightinterval"
    Write-Host "Benchmark executed successfully"
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
        Write-Host "Uploading to URI: $blobUri"
        Invoke-RestMethod -Uri $blobUri -Method Put -InFile $csvFile.FullName -Headers @{ "x-ms-blob-type" = "BlockBlob" }
        Write-Host "Uploaded $($csvFile.Name) to blob storage under ${benchmark}/"
    }
}
catch {
    Write-Error "Failed to upload CSV files to storage account: $_"
    exit 1
}
