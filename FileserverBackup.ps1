<#
RoboCopy Backup Script with E-mail Notification

This script runs a robocopy backup and creates a log file.
An e-mail notification along with the attached log file will be sent out.

Variables to change:
 - Source
 - Destination
 - LogFileLocation
 - EmailTo
 - SMTPServer

Original Script Created by Michel Stevelmans (http://michelstevelmans.com)
Edited by Jeff Seto (jeff.seto@hogarthww.com)
#>

# Variables
$Source = "E:\"
$Computer = hostname
$Destination = "\\server\Backup\$Computer\"
$Date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogFileLocation = "\\server\Backup\Logs\$Computer\"
$LogFilename = "BackupLog_$($Date)"
$EmailFrom = "Backup@company.com"
$EmailTo = "BackupLog@company.com"
$EmailBody = "Robocopy backup completed. See attached log file for details."
$EmailSubject = "$Computer $Date Backup Completed"
$SMTPServer = "relay.company.com"
$SMTPPort = "25"
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, $SMTPPort)

# Reset archive bit (required workaround for Windows 2012/8 robocopy)
attrib -a "$($Source)*.*" /S /D

# Run robocopy backup
robocopy $Source $Destination /MIR /COPY:DAT /M /MT:32 /V /W:1 /R:0 /NP /TS /BYTES /XF ".DS_Store" ".apdisk" ".TemporaryItems" "Thumbs.db" /XD "$($Source)`$RECYCLE.BIN" "$($Source)System Volume Information" /LOG:"C:\Logs\backup_report.log"

# Update log filename, copy to share and send e-mail
if (($LastExitCode -eq 0) -or ($LastExitCode -eq 1)){
    Copy-Item "C:\Logs\backup_report.log" "$LogFileLocation$($LogFilename)_SUCCESSFUL.log"
    $EmailSubject += " Successfully."
    $EmailBody += "`r`n`r`nLog file: $LogFileLocation$($LogFilename)_SUCCESSFUL.log"
    $Message = New-Object Net.Mail.MailMessage($EmailFrom, $EmailTo, $EmailSubject, $EmailBody)
    $SMTPClient.Send($Message)
}
else {
    Copy-Item "C:\Logs\backup_report.log" "$LogFileLocation$($LogFilename)_FAILED.log"
    $EmailSubject += " with Errors."
    $EmailBody += "`r`n`r`nLog file: $LogFileLocation$($LogFilename)_FAILED.log"
    $Message = New-Object Net.Mail.MailMessage($EmailFrom, $EmailTo, $EmailSubject, $EmailBody)
    $SMTPClient.Send($Message)
}