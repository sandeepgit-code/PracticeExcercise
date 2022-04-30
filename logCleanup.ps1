# Create a folder in Current Working Directory
Set-Variable FolderToCreate -option Constant -value "Logs"
if (!(Test-Path $FolderToCreate -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $FolderToCreate
}

# Create Files
$startDateStr = "2022-1-1"
$endDateStr = "2022-12-1"
$startDate = Get-Date $startDateStr
$endDate = Get-Date $endDateStr
while($startDate -ne $endDate) {
    $strDate = $startDate.ToString("yyyyMMdd")
    $logFilePath = 'Log_' + $strDate + '.txt' 
    $strDate >> $FolderToCreate\$logfilepath
    $startDate = $startDate.AddMonths(1)
}

# Get Files Older than 30 Days
$deleteDate = (Get-Date).AddDays(-30).Date
$deletedFiles = Get-ChildItem -Path $FolderToCreate -Filter 'Log_*.txt' -File | 
    Where-Object { $_.BaseName -match '(\d{8})'} | 
    ForEach-Object {
        $file = $_.FullName
        try {
            $date = [datetime]::ParseExact($Matches[1], 'yyyyMMdd', $null)
            if ($date -lt $deleteDate) { 
                $_
            }
        }
        catch {
            Write-Warning "File $file contains an invalid date"
        }
    }

# Store Deleted Files in A File
$deleteFile = "Delete.txt"
$deletedFiles | select name, length > $deleteFile

# Total Folder Size
$totalFolderSize = (Get-ChildItem -Path $FolderToCreate | measure Length -s).sum
"Total Size of the Folder " + $totalFolderSize + " Bytes"

# Get the Total Size of Deleted Files
$totalDeletedSize = 0
foreach( $deletedFile in $deletedFiles ) {
    $totalDeletedSize = $totalDeletedSize + $deletedFile.length
}
"Total Size of Deleted Items " + $totalDeletedSize + " Bytes"

# Get Free Space Percentage
$freeSpace = (($totalFolderSize - $totalDeletedSize) / $totalFolderSize) * 100
"Free Space " + $freeSpace + "%"

# Delete Files stored in Array
foreach( $deletedFile in $deletedFiles ) {
    Remove-Item $FolderToCreate\$deletedFile
}

# Install AWS Tools
# https://docs.aws.amazon.com/powershell/latest/userguide/pstools-getting-set-up-windows.html#ps-installing-awstools
# Install-Module -Name AWS.Tools.Installer
# Install-AWSToolsModule AWS.Tools.S3 -CleanUp

# Set AWS Credentials
# Set-AWSCredential `
#                  -AccessKey `
#                  -SecretKey `
#                  -StoreAs PowershellProfile

# Upload Files to S3
$absoluteFilePath = Resolve-Path $deleteFile  | select -ExpandProperty Path 
Write-S3Object -BucketName powershell-example -CannedACLName bucket-owner-full-control -File $absoluteFilePath -Key $deleteFile -ProfileName PowershellProfile