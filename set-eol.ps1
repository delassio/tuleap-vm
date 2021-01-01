# set-eol.ps1
# Change the line endings of a text file to: Windows (CR/LF), Unix (LF) or Mac (CR)
#
# Requires PowerShell 7.0 or greater:
#Requires –Version 7

# Syntax
#     ./set-eol.ps1 -lineEnding {mac|unix|win} -file FullFilename

#     mac, unix or win  : The file endings desired.
#     FullFilename      : The full pathname of the file to be modified.

#     example:
#     ./set-eol win "c:\demo\data.txt"

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
    [ValidateSet("mac","unix","win")] 
    [string]$lineEnding,
  [Parameter(Mandatory=$True)]
    [string]$file
)

# Convert the friendly name into a PowerShell EOL character
Switch ($lineEnding) {
  "mac"  { $eol="`r" }
  "unix" { $eol="`n" }
  "win"  { $eol="`r`n" }
} 

# Replace CR+LF with LF
$text = [IO.File]::ReadAllText($file) -replace "`r`n", "`n"
[IO.File]::WriteAllText($file, $text)

# Replace CR with LF
$text = [IO.File]::ReadAllText($file) -replace "`r", "`n"
[IO.File]::WriteAllText($file, $text)

#  At this point all line-endings should be LF.

# Replace LF with intended EOL char
if ($eol -ne "`n") {
  $text = [IO.File]::ReadAllText($file) -replace "`n", $eol
  [IO.File]::WriteAllText($file, $text)
}

Write-Host "File $file Changed to  $lineEnding line endings"