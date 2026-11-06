<#
.SYNOPSIS
  Post-deployment verification for a banking microservice.
.DESCRIPTION
  Retries the health and readiness endpoints, checks the reported version,
  and fails the release if the service is not healthy within the timeout.
#>
param(
    [Parameter(Mandatory)] [string] $BaseUrl,
    [string] $Slot = "",
    [int] $TimeoutSeconds = 300,
    [string] $ExpectedVersion = $env:BUILD_BUILDNUMBER
)

$ErrorActionPreference = "Stop"
$headers = @{}
if ($Slot) { $headers["x-slot"] = $Slot }
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)

foreach ($path in "/healthz", "/readyz") {
    $ok = $false
    while (-not $ok -and (Get-Date) -lt $deadline) {
        try {
            $r = Invoke-RestMethod -Uri "$BaseUrl$path" -Headers $headers -TimeoutSec 10
            $ok = $r.status -in @("ok", "ready")
        } catch {
            Write-Host "Waiting for $path ... $($_.Exception.Message)"
            Start-Sleep -Seconds 10
        }
    }
    if (-not $ok) { Write-Error "$path did not become healthy within $TimeoutSeconds s" }
    Write-Host "##[section]$path healthy"
}

if ($ExpectedVersion) {
    $info = Invoke-RestMethod -Uri "$BaseUrl/version" -Headers $headers
    if ($info.version -ne $ExpectedVersion) {
        Write-Error "Version mismatch: expected $ExpectedVersion, got $($info.version)"
    }
    Write-Host "##[section]Version $ExpectedVersion verified"
}
