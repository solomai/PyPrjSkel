# remove_miniconda.ps1 — Fully uninstall Miniconda and all environments in PowerShell

<#
.SYNOPSIS
    Uninstalls Miniconda and removes all environments (except base), and cleans up shell profiles.
#>

# ANSI color codes (optional in PS, but using Write-Host with -ForegroundColor)

# Default Miniconda install directory
$CondaDir = "$env:USERPROFILE\Miniconda3"

function Remove-AllCondaEnvs {
    Write-Host "Listing all conda environments..." -ForegroundColor Cyan
    # Get env list, skip header and 'base'
    $envs = conda env list | ForEach-Object { ($_ -split '\s+')[0] } | Where-Object { $_ -and $_ -ne 'base' -and $_ -ne '#' }
    if ($envs.Count -eq 0) {
        Write-Host "No environments found to remove." -ForegroundColor Yellow
    } else {
        foreach ($env in $envs) {
            Write-Host "Removing environment: $env" -ForegroundColor Cyan
            conda remove --name $env --all -y
        }
    }
}

Write-Host "Deactivating Conda if active..." -ForegroundColor Cyan
if (Get-Command conda -ErrorAction SilentlyContinue) {
    conda deactivate 2>$null
    Remove-AllCondaEnvs
} else {
    Write-Host "Conda not found; skipping environment removal." -ForegroundColor Yellow
}

Write-Host "Removing Miniconda installation folder..." -ForegroundColor Cyan
if (Test-Path $CondaDir) {
    Remove-Item -Recurse -Force $CondaDir
    Write-Host "Deleted: $CondaDir" -ForegroundColor Green
} else {
    Write-Host "No Miniconda directory found at $CondaDir" -ForegroundColor Yellow
}

# Clean up PowerShell profile scripts
$ProfileFiles = @($PROFILE, "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1")
foreach ($file in $ProfileFiles) {
    if (Test-Path $file) {
        Write-Host "Processing $file..." -ForegroundColor Cyan
        $content = Get-Content $file
        # Remove conda init blocks
        $start = $content.IndexOf('# >>> conda initialize >>>')
        $end   = $content.IndexOf('# <<< conda initialize <<<')
        if ($start -ge 0 -and $end -ge 0) {
            $before = $content[0..($start-1)]
            $after  = $content[($end+1)..($content.Length-1)]
            $new    = $before + $after
            $backup = "$file.bak"
            Copy-Item $file $backup -Force
            $new | Set-Content $file
            Write-Host "Removed conda init block from $file (backup: $backup)" -ForegroundColor Green
        } else {
            Write-Host "No conda init block found in $file." -ForegroundColor Yellow
        }
        # Remove any 'source' lines referencing conda.sh
        $patterned = Get-Content $file | Where-Object { $_ -notmatch 'conda\.sh' }
        if ($patterned.Count -ne $content.Count) {
            $backup2 = "$file.source.bak"
            Copy-Item $file $backup2 -Force
            $patterned | Set-Content $file
            Write-Host "Removed 'source ...\conda.sh' lines from $file (backup: $backup2)" -ForegroundColor Green
        }
    } else {
        Write-Host "$file not found, skipping." -ForegroundColor Yellow
    }
}

Write-Host "Miniconda and all environments have been fully removed." -ForegroundColor Green
Write-Host "IMPORTANT: Restart your PowerShell session to apply changes." -ForegroundColor Yellow
