# activate_conda.ps1
# PowerShell script for automatic conda environment activation

# Set execution policy for current session
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

# Initialize conda
try {
    # Try to initialize conda
    if (Get-Command conda -ErrorAction SilentlyContinue) {
        # Initialize conda for PowerShell
        (& conda "shell.powershell" "hook") | Out-String | Invoke-Expression
        conda activate base 2>$null
    } else {
        Write-Host "Conda not found. Make sure conda is installed and available in PATH." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error initializing conda: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Define path to environment.yml
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvFile = Join-Path (Split-Path -Parent $ScriptDir) "environment.yml"
$EnvName = ""

# Read environment name from environment.yml
if (Test-Path $EnvFile) {
    try {
        $Content = Get-Content $EnvFile -Raw

        # Search for line with name: using regex
        if ($Content -match '(?m)^\s*name\s*:\s*([^\s#]+)') {
            $EnvName = $Matches[1].Trim()
            # Remove quotes if present
            $EnvName = $EnvName -replace '["\x27]', ''
        }

        # Alternative method through lines
        if ([string]::IsNullOrEmpty($EnvName)) {
            $Lines = Get-Content $EnvFile
            foreach ($Line in $Lines) {
                if ($Line -match '^\s*name\s*:\s*(.+)) {
                    $EnvName = $Matches[1].Trim()
                    # Remove comments
                    if ($EnvName -match '^([^#]+)') {
                        $EnvName = $Matches[1].Trim()
                    }
                    # Remove quotes
                    $EnvName = $EnvName -replace '["\x27]', ''
                    break
                }
            }
        }
    }
    catch {
        Write-Host "Error reading environment.yml: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Activate environment
if ([string]::IsNullOrEmpty($EnvName)) {
    Write-Host "environment.yml not found or does not contain environment name" -ForegroundColor Yellow
    Write-Host "Using base conda environment" -ForegroundColor Yellow
} else {
    Write-Host "Activating conda environment: $EnvName" -ForegroundColor Green

    try {
        conda activate $EnvName 2>$null

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error activating environment $EnvName" -ForegroundColor Yellow
            Write-Host "Creating environment from environment.yml..." -ForegroundColor Yellow

            conda env create -f $EnvFile

            if ($LASTEXITCODE -eq 0) {
                conda activate $EnvName
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Environment $EnvName successfully created and activated" -ForegroundColor Green
                } else {
                    Write-Host "Error activating newly created environment $EnvName" -ForegroundColor Red
                }
            } else {
                Write-Host "Error creating environment from $EnvFile" -ForegroundColor Red
            }
        } else {
            Write-Host "Environment $EnvName successfully activated" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Error working with conda: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Show current active environment
try {
    $CurrentEnv = conda info --envs 2>$null | Where-Object { $_ -match '\*' }
    if ($CurrentEnv) {
        Write-Host "Current environment: $($CurrentEnv -replace '\s*\*\s*', ' -> ')" -ForegroundColor Cyan
    }
}
catch {
    # Ignore errors when showing current environment
}