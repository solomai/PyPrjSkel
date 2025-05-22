@echo off
setlocal EnableDelayedExpansion

:: Initialize conda
call conda activate base 2>nul
if errorlevel 1 (
    echo Conda not found. Please ensure conda is installed and available in PATH.
    exit /b 1
)

:: Read environment name from environment.yml
set ENV_NAME=
set ENV_FILE=%~dp0..\environment.yml

if exist "!ENV_FILE!" (
    :: Read file line by line and look for name:
    for /f "usebackq tokens=1,* delims=:" %%a in ("!ENV_FILE!") do (
        set line=%%a
        set value=%%b
        :: Remove spaces from beginning and end
        for /f "tokens=* delims= " %%c in ("!line!") do set line=%%c
        if "!line!"=="name" (
            :: Remove spaces and quotes from environment name
            for /f "tokens=* delims= " %%d in ("!value!") do set ENV_NAME=%%d
            set ENV_NAME=!ENV_NAME:"=!
            goto :found_name
        )
    )
    :found_name
)

if "!ENV_NAME!"=="" (
    echo environment.yml not found or does not contain environment name
    echo Using base conda environment
) else (
    echo Activating conda environment: !ENV_NAME!
    call conda activate !ENV_NAME!
    if errorlevel 1 (
        echo Error activating environment !ENV_NAME!
        echo Creating environment from environment.yml...
        call conda env create -f "!ENV_FILE!"
        if errorlevel 1 (
            echo Error creating environment from !ENV_FILE!
        ) else (
            call conda activate !ENV_NAME!
        )
    )
)