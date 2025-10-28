param([string]$NewPathEntry)

$RegistryPath = 'registry::HKEY_CURRENT_USER\Environment'

# Prefer env var from caller; fall back to param
$NewPathEntry = if ($env:RAPP_NEW_PATH_ENTRY) { $env:RAPP_NEW_PATH_ENTRY } elseif ($NewPathEntry) { $NewPathEntry } else {
  Write-Error "Provide RAPP_BIN_DIR or -NewPathEntry."
  exit 2
}

Write-Verbose "Adding $NewPathEntry to your user-level PATH"

# Read unexpanded PATH components
$PathEntries = (Get-Item -LiteralPath $RegistryPath).GetValue(
  'Path', '', 'DoNotExpandEnvironmentNames') -split ';' -ne ''

if ($NewPathEntry -in $PathEntries) {
  Write-Verbose "Install directory $NewPathEntry already on PATH!"
  exit 1
}

# Prepend to PATH
$NewPath = (,$NewPathEntry + $PathEntries) -join ';'

# Update registry as REG_EXPAND_SZ
Set-ItemProperty -Type ExpandString -LiteralPath $RegistryPath Path -Value $NewPath

# Broadcast WM_SETTINGCHANGE via dummy env var toggle
$DummyName = 'rapp-' + [guid]::NewGuid().ToString()
[Environment]::SetEnvironmentVariable($DummyName, 'rapp-dummy', 'User')
[Environment]::SetEnvironmentVariable($DummyName, $null, 'User')

Write-Output "Added $NewPathEntry to your user-level PATH"
exit 0
