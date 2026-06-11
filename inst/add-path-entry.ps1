param([string]$NewPathEntry)

$RegistryPath = 'registry::HKEY_CURRENT_USER\Environment'

# Prefer env var from caller; fall back to param
$NewPathEntry = if ($env:RAPP_NEW_PATH_ENTRY) { $env:RAPP_NEW_PATH_ENTRY } elseif ($NewPathEntry) { $NewPathEntry } else {
  Write-Error "Provide RAPP_BIN_DIR or -NewPathEntry."
  exit 2
}

Write-Verbose "Adding $NewPathEntry to your user-level PATH"

function Normalize-PathEntry([string]$PathEntry) {
  try {
    $PathEntry = (Resolve-Path -LiteralPath $PathEntry -ErrorAction Stop).ProviderPath
  } catch {
  }

  try {
    $PathEntry = [System.IO.Path]::GetFullPath($PathEntry)
  } catch {
  }

  return $PathEntry.TrimEnd('\').ToLowerInvariant()
}

# Read unexpanded PATH components
$PathEntries = (Get-Item -LiteralPath $RegistryPath).GetValue(
  'Path', '', 'DoNotExpandEnvironmentNames') -split ';' -ne ''

$NewPathEntryNorm = Normalize-PathEntry $NewPathEntry
$PathEntryNorms = $PathEntries | ForEach-Object { Normalize-PathEntry $_ }

if ($NewPathEntryNorm -in $PathEntryNorms) {
  Write-Verbose "Install directory $NewPathEntry already on PATH!"
  exit 0
}

# Prepend to PATH
$NewPath = (,$NewPathEntry + $PathEntries) -join ';'

if ($NewPath.Length -gt 32767) {
  $Hint = @(
    "Rapp uses a Windows short path when one is available."
    "Remove stale entries from your user-level PATH or choose a shorter launcher directory with RAPP_BIN_DIR."
    "Windows long-path support does not increase this environment-variable limit."
  ) -join ' '
  $Message = @(
    "Adding $NewPathEntry would make your user-level PATH $($NewPath.Length) characters,"
    "exceeding the Windows environment variable limit of 32767."
    $Hint
  ) -join ' '
  Write-Error $Message
  exit 3
}

# Update registry as REG_EXPAND_SZ
Set-ItemProperty -Type ExpandString -LiteralPath $RegistryPath Path -Value $NewPath

# Broadcast WM_SETTINGCHANGE via dummy env var toggle
$DummyName = 'rapp-' + [guid]::NewGuid().ToString()
[Environment]::SetEnvironmentVariable($DummyName, 'rapp-dummy', 'User')
[Environment]::SetEnvironmentVariable($DummyName, $null, 'User')

Write-Output "Added $NewPathEntry to your user-level PATH"
exit 0
