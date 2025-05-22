# setup_env.ps1 - One-click setup script for Conda environment on Windows (PowerShell)

# --- Configuration Variables ---
$condaInstallDir = "$env:USERPROFILE\Miniconda3"
$condaInstallerUrl = "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
$environmentYml = Join-Path $projectRoot "environment.yml"

# --- Function to check if Conda is installed and available ---
function Check-CondaInstalled {
    <#
    .SYNOPSIS
    Checks if Conda is installed and available in the current PowerShell session.
    Attempts to initialize it if found but not active.
    #>
    Write-Host "Checking if Conda is installed and initialized..." -ForegroundColor Cyan
    try {
        # Check if 'conda' command is available in the current session's PATH
        if (Get-Command conda -ErrorAction SilentlyContinue) {
            Write-Host "Conda command is available in this session." -ForegroundColor Green
            return $true
        }

        # If not, check if Miniconda directory exists and attempt to initialize
        if (Test-Path $condaInstallDir) {
            Write-Host "Miniconda directory found: '$condaInstallDir'." -ForegroundColor Cyan
            $condaInitScript = Join-Path $condaInstallDir "shell\condabin\conda-hook.ps1"
            if (Test-Path $condaInitScript) {
                # Source the conda-hook.ps1 script to make conda commands available in current session
                . $condaInitScript # Using dot-sourcing to run in current scope
                Write-Host "Conda initialized from '$condaInitScript'." -ForegroundColor Green
                # Verify after sourcing
                if (Get-Command conda -ErrorAction SilentlyContinue) {
                    Write-Host "Conda command is now available." -ForegroundColor Green
                    return $true
                } else {
                    Write-Host "Conda initialization failed after sourcing hook script." -ForegroundColor Red
                }
            } else {
                Write-Host "Conda hook script not found at '$condaInitScript'." -ForegroundColor Red
            }
        } else {
            Write-Host "Miniconda installation directory not found: '$condaInstallDir'." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "An error occurred during Conda check: $($_.Exception.Message)" -ForegroundColor Red
    }
    return $false
}

# --- Function to install Miniconda ---
function Install-Miniconda {
    <#
    .SYNOPSIS
    Downloads and installs Miniconda.
    .OUTPUTS
    [bool] - True if Miniconda was successfully installed and initialized, False otherwise.
    #>
    Write-Host "Downloading Miniconda from: $condaInstallerUrl" -ForegroundColor Cyan
    $tempInstaller = Join-Path $env:TEMP "Miniconda3-Installer.exe"

    try {
        Invoke-WebRequest -Uri $condaInstallerUrl -OutFile $tempInstaller
        Write-Host "Miniconda installer downloaded to: $tempInstaller" -ForegroundColor Green

        Write-Host "Starting Miniconda installation (this may take a few minutes)..." -ForegroundColor Cyan
        # /S for silent install, /D for destination directory
        $installArgs = @("/S", "/D=`"$condaInstallDir`"", "/RegisterPython=0", "/AddToPath=0")
        $process = Start-Process -FilePath $tempInstaller -ArgumentList $installArgs -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0) {
            Write-Host "Miniconda installation finished successfully." -ForegroundColor Green
            # Attempt to initialize Conda after installation
            if (Check-CondaInstalled) {
                Write-Host "Miniconda installed and initialized in current session." -ForegroundColor Green
                return $true
            } else {
                Write-Host "Miniconda installed, but requires a new terminal or manual initialization. Please restart your terminal." -ForegroundColor Yellow
                return $true # Indicate successful installation, but user action needed
            }
        } else {
            Write-Host "Miniconda installation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "An error occurred during Miniconda installation: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        if (Test-Path $tempInstaller) {
            Remove-Item $tempInstaller -Force
        }
    }
}

# --- Function to setup/update Conda environment ---
function Setup-CondaEnvironment {
    <#
    .SYNOPSIS
    Creates or updates the Conda environment from environment.yml.
    .OUTPUTS
    [bool] - True on success, False otherwise.
    #>
    # NEW: Check and deactivate any currently active Conda environment
    if ($env:CONDA_DEFAULT_ENV) {
        Write-Host "A Conda environment ('$env:CONDA_DEFAULT_ENV') is currently active. Attempting to deactivate it..." -ForegroundColor Yellow
        conda deactivate *>&1 # Redirecting output to avoid clutter, *>&1 for all streams
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Warning: Failed to deactivate current environment. Proceeding with caution." -ForegroundColor Yellow
        } else {
            Write-Host "Successfully deactivated environment '$env:CONDA_DEFAULT_ENV'." -ForegroundColor Green
        }
    }

    if (-not (Test-Path $environmentYml)) {
        Write-Host "Error: environment.yml not found at '$environmentYml'." -ForegroundColor Red
        Write-Host "Please ensure it exists in the project root." -ForegroundColor Yellow
        return $false
    }

    Write-Host "Checking environment.yml for environment name..." -ForegroundColor Cyan
    $envName = (Get-Content $environmentYml | Select-String -Pattern '^name:\s*(\S+)' | ForEach-Object { $_.Matches[0].Groups[1].Value })
    if (-not $envName) {
        Write-Host "Error: Could not find 'name:' in environment.yml. Please ensure it's defined." -ForegroundColor Red
        return $false
    }
    Write-Host "Environment name found: '$envName'." -ForegroundColor Green

    Write-Host "Attempting to create/update Conda environment: '$envName' from '$environmentYml'..." -ForegroundColor Cyan
    try {
        # Check if environment already exists
        $envExists = (conda env list | Select-String -Pattern "$envName\s+" -Quiet)

        if ($envExists) {
            Write-Host "Environment '$envName' already exists. Attempting to update..." -ForegroundColor Cyan
            # Attempt update first
            conda env update --file $environmentYml --prune *>&1
            $condaExitCode = $LASTEXITCODE
            if ($condaExitCode -ne 0) {
                Write-Host "Conda environment update failed with exit code: $condaExitCode. Attempting to remove and recreate..." -ForegroundColor Yellow
                # If update fails, try removal and recreation
                conda env remove --name $envName -y *>&1
                conda env create --file $environmentYml *>&1
                $condaExitCode = $LASTEXITCODE
            }
        } else {
            Write-Host "Environment '$envName' does not exist. Creating..." -ForegroundColor Cyan
            conda env create --file $environmentYml *>&1
            $condaExitCode = $LASTEXITCODE
        }

        if ($condaExitCode -eq 0) {
            Write-Host "Conda environment '$envName' created/updated successfully." -ForegroundColor Green
            Write-Host "Activating environment: $envName" -ForegroundColor Cyan
            conda activate $envName # Activate the environment in the current session
            Write-Host "Environment '$envName' is now active." -ForegroundColor Green
            Show-ActivationMessage $envName # Display a message with activation instructions
            return $true
        } else {
            Write-Host "Conda environment creation/update failed with exit code: $condaExitCode" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "An error occurred during Conda environment setup: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# --- Function to display activation message ---
function Show-ActivationMessage {
    param(
        [string]$envName
    )
    Write-Host ""
    Write-Host "=============================================================="
    Write-Host "Environment setup process finished successfully."
    Write-Host "=============================================================="
    Write-Host ""
    Write-Host "--- Installed Packages in '$envName' environment: ---"
    # Display the list of installed packages in the environment
    $packageListOutput = conda list
    foreach ($line in $packageListOutput) {
        Write-Host $line
    }
    Write-Host "--- End of Package List ---"
    Write-Host ""
    Write-Host "To activate it, please copy and paste the following command into your terminal:"
    Write-Host ""

    # Calculate padding for consistent alignment
    $labelWidth = 33  # Width for the label text
    $commands = @(
        @{ Label = "Activate the environment with:"; Command = "conda activate $envName"; Color = "Green" },
        @{ Label = "Deactivate the environment with:"; Command = "conda deactivate"; Color = "Red" },
        @{ Label = "Environments list:"; Command = "conda env list"; Color = "Yellow" }
    )

    foreach ($cmd in $commands) {
        # Ensure padding is correctly calculated to reach $labelWidth from the start of the line
        # The '  ' prefix is already part of the label
        $padding = " " * [Math]::Max(0, $labelWidth - $cmd.Label.Length)
        Write-Host "$($cmd.Label)" -NoNewline
        Write-Host "$padding$($cmd.Command)" -ForegroundColor $cmd.Color
    }
    Write-Host "=============================================================="
    return $true
}

# --- Main execution flow ---
function Main {
    <#
    .SYNOPSIS
    Main function to orchestrate Conda installation and environment setup.
    #>
    Write-Host "Starting environment setup..." -ForegroundColor Cyan

    if (-not (Check-CondaInstalled)) {
        Write-Host "Conda is not found in the current session. Attempting to install Miniconda." -ForegroundColor Yellow
        if (-not (Install-Miniconda)) {
            Write-Host "Aborting setup due to Miniconda installation failure." -ForegroundColor Red
            return 1
        }
        if (-not (Check-CondaInstalled)) {
            Write-Host "Miniconda was installed, but Conda commands are not yet active in this session." -ForegroundColor Yellow
            Write-Host "Please restart your terminal or open a new one and run this script again to complete the setup." -ForegroundColor Yellow
            return 0
        }
    }

    if (-not (Setup-CondaEnvironment)) {
        Write-Host "Aborting setup due to Conda environment configuration failure." -ForegroundColor Red
        return 1
    }

    Write-Host "Environment setup process finished successfully." -ForegroundColor Green
    return 0
}

# Call the main function
Main