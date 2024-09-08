Write-Output "Loading profile..."

Import-Module posh-git
Import-Module PowerShellRun

$env:POSH_GIT_ENABLED=$true

# Set PSReadLineKeyHandler preferences
Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Enter' -Function ValidateAndAcceptLine
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }

# Set PSFzfOption preferences
Set-PsFzfOption -EnableAliasFuzzyEdit
Set-PsFzfOption -EnableAliasFuzzyHistory
Set-PsFzfOption -EnableAliasFuzzySetLocation
Enable-PSRunEntry -Category All

function prompt {
    $p = Split-Path -leaf -path (Get-Location)
    "$p> "
}

function touch($file) {
  if ( Test-Path $file ) {
    Set-FileTime $file
  } else {
    New-Item $file -type file
  }
}

function find-file($name) {
  get-childitem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue -Force | foreach-object {
    write-output($PSItem.FullName)
  }
}
Set-Alias -Name ff -Value find-file

function Backup-File {
    param(
        [string]$FilePath
    )
    Copy-Item $FilePath "$FilePath.$(Get-Date -Format 'yyyyMMddHHmmss')"
}

function tail {
  param($Path, $n = 10, [switch]$f = $false)
  Get-Content $Path -Tail $n -Wait:$f
}

function head {
  param($Path, $n = 10)
  Get-Content $Path -Head $n
}

function uptime {
  if ($PSVersionTable.PSVersion.Major -eq 5) {
      Get-WmiObject win32_operatingsystem | Select-Object @{Name='LastBootUpTime'; Expression={$_.ConverttoDateTime($_.lastbootuptime)}} | Format-Table -HideTableHeaders
  } else {
      net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
  }
}

# System Utilities
function admin {
  if ($args.Count -gt 0) {
      $argList = "& '$args'"
      Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
  } else {
      Start-Process wt -Verb runAs
  }
}

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command with elevated rights.
Set-Alias -Name su -Value admin

# Use fzf to preview and open file with default application
function fzp {
  Invoke-Item (fzf --preview 'type {}')
}#