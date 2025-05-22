# remove_env.ps1 - Script to remove a specific Conda environment based on environment.yml

# --- Configuration Variables ---
# Determine project root based on script location (Scripts folder)
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
$environmentYml = Join-Path $projectRoot "environment.yml"

# --- Function to check if Conda is installed and available ---
function Check-CondaInstalled {
    <#
    .SYNOPSIS
    Checks if Conda is installed and available in the current PowerShell session.
    Attempts to initialize it if found but not active.
    #>
    # Assuming Miniconda is installed in the default location for the current user
    $condaInstallDir = "$env:USERPROFILE\Miniconda3"

    Write-Host "Checking if Conda is installed and initialized..."
    try {
        # Check if 'conda' command is available in the current session's PATH
        if (Get-Command conda -ErrorAction SilentlyContinue) {
            Write-Host "Conda command is available in this session."
            return $true
        }

        # If not, check if Miniconda directory exists and attempt to initialize
        if (Test-Path $condaInstallDir) {
            Write-Host "Miniconda directory found: '$condaInstallDir'."
            $condaInitScript = Join-Path $condaInstallDir "shell\condabin\conda-hook.ps1"
            if (Test-Path $condaInitScript) {
                # Source the conda-hook.ps1 script to make conda commands available in current session
                . $condaInitScript # Using dot-sourcing to run in current scope
                Write-Host "Conda initialized from '$condaInitScript'."
                # Verify after sourcing
                if (Get-Command conda -ErrorAction SilentlyContinue) {
                    Write-Host "Conda command is now available."
                    return $true
                } else {
                    Write-Host "Conda initialization failed after sourcing hook script."
                }
            } else {
                Write-Host "Conda hook script not found at '$condaInitScript'."
            }
        } else {
            Write-Host "Miniconda installation directory not found: '$condaInstallDir'."
        }
    } catch {
        Write-Host "An error occurred during Conda check: $($_.Exception.Message)"
    }
    return $false
}

# --- Main execution flow ---
function Main {
    Write-Host "Starting Conda environment removal process..."

    # Ensure Conda is available in the current session
    if (-not (Check-CondaInstalled)) {
        Write-Host "Error: Conda is not found or not initialized in this session. Cannot remove environment." -ForegroundColor Red
        Write-Host "Please ensure Miniconda is installed and correctly configured." -ForegroundColor Yellow
        return 1
    }

    # Verify environment.yml exists
    if (-not (Test-Path $environmentYml)) {
        Write-Host "Error: environment.yml not found at '$environmentYml'." -ForegroundColor Red
        Write-Host "Cannot determine environment name. Please ensure it exists in the project root." -ForegroundColor Yellow
        return 1
    }

    # Get environment name from environment.yml
    Write-Host "Checking environment.yml for environment name..."
    $envName = (Get-Content $environmentYml | Select-String -Pattern '^name:\s*(\S+)' | ForEach-Object { $_.Matches[0].Groups[1].Value })
    if (-not $envName) {
        Write-Host "Error: Could not find 'name:' in environment.yml. Please ensure it's defined." -ForegroundColor Red
        return 1
    }
    Write-Host "Environment name found: '$envName'."

    # Check if the environment actually exists before attempting to remove
    Write-Host "Checking if environment '$envName' exists..."
    $envExists = (conda env list | Select-String -Pattern "$envName\s+" -Quiet)

    if (-not $envExists) {
        Write-Host "Environment '$envName' does not exist. Nothing to remove." -ForegroundColor Yellow
        return 0
    }

    Write-Host "Deactivating environment '$envName' if it is active..." -ForegroundColor Cyan
    # Conda deactivate is needed if the environment is currently active to allow removal
    if ((Get-Command conda -ErrorAction SilentlyContinue) -and ($env:CONDA_DEFAULT_ENV -eq $envName)) {
        conda deactivate *>&1
        Write-Host "Environment '$envName' deactivated." -ForegroundColor Green
    } else {
        Write-Host "Environment '$envName' is not currently active or conda is not fully loaded." -ForegroundColor Yellow
    }

    Write-Host "Attempting to remove Conda environment: '$envName'..." -ForegroundColor Cyan
    try {
        # FIX: Removed '--all' argument as it's not valid for 'conda env remove'
        # Use -y for non-interactive confirmation
        # Use *>&1 to show all output streams for transparency
        conda env remove --name $envName -y *>&1
        $condaExitCode = $LASTEXITCODE

        if ($condaExitCode -eq 0) {
            Write-Host "Conda environment '$envName' removed successfully." -ForegroundColor Green
        } else {
            Write-Host "Error: Conda environment removal failed with exit code: $condaExitCode" -ForegroundColor Red
            Write-Host "Please check the output above for details." -ForegroundColor Yellow
            return 1
        }
    } catch {
        Write-Host "An error occurred during environment removal: $($_.Exception.Message)" -ForegroundColor Red
        return 1
    }

    Write-Host "=============================================================="
    Write-Host "Conda environment removal process finished."
    Write-Host "=============================================================="
    return 0
}

# Call the main function
Main