#!/bin/bash
# remove_env.sh - Script to remove a specific Conda environment based on environment.yml

if [[ "$0" == "$BASH_SOURCE" ]]; then
  echo "Please run this script with: source ${BASH_SOURCE[0]}" >&2
  return 1 2>/dev/null || exit 1
fi

# --- Configuration Variables ---
# Determine project root based on script location (Scripts folder)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENT_YML="$PROJECT_ROOT/environment.yml"

# --- Function to check if Conda is installed and available ---
check_conda_installed() {
    echo "Checking if Conda is installed and initialized..."

    # Check if conda command is available
    if command -v conda &> /dev/null; then
        echo "Conda command is available in this session."
        return 0
    fi

    # Check if Miniconda is installed in default location
    CONDA_INSTALL_DIR="$HOME/miniconda3"
    if [ -d "$CONDA_INSTALL_DIR" ]; then
        echo "Miniconda directory found: '$CONDA_INSTALL_DIR'"
        CONDA_INIT_SCRIPT="$CONDA_INSTALL_DIR/etc/profile.d/conda.sh"

        if [ -f "$CONDA_INIT_SCRIPT" ]; then
            # Source the conda initialization script
            source "$CONDA_INIT_SCRIPT"
            echo "Conda initialized from '$CONDA_INIT_SCRIPT'"

            # Verify after sourcing
            if command -v conda &> /dev/null; then
                echo "Conda command is now available."
                return 0
            else
                echo "Conda initialization failed after sourcing init script."
            fi
        else
            echo "Conda init script not found at '$CONDA_INIT_SCRIPT'"
        fi
    else
        echo "Miniconda installation directory not found: '$CONDA_INSTALL_DIR'"
    fi

    return 1
}

# --- Main execution flow ---
main() {
    echo "Starting Conda environment removal process..."

    # Ensure Conda is available in the current session
    if ! check_conda_installed; then
        echo -e "\e[31mError: Conda is not found or not initialized in this session. Cannot remove environment.\e[0m"
        echo -e "\e[33mPlease ensure Miniconda is installed and correctly configured.\e[0m"
        return 1
    fi

    # Verify environment.yml exists
    if [ ! -f "$ENVIRONMENT_YML" ]; then
        echo -e "\e[31mError: environment.yml not found at '$ENVIRONMENT_YML'.\e[0m"
        echo -e "\e[33mCannot determine environment name. Please ensure it exists in the project root.\e[0m"
        return 1
    fi

    # Get environment name from environment.yml
    echo "Checking environment.yml for environment name..."
    ENV_NAME=$(grep "^name:" "$ENVIRONMENT_YML" | sed -E 's/^name:[[:space:]]*([^[:space:]]+).*/\1/')

    if [ -z "$ENV_NAME" ]; then
        echo -e "\e[31mError: Could not find 'name:' in environment.yml. Please ensure it's defined.\e[0m"
        return 1
    fi
    echo "Environment name found: '$ENV_NAME'"

    # Check if the environment actually exists before attempting to remove
    echo "Checking if environment '$ENV_NAME' exists..."
    if ! conda env list | grep -q "^$ENV_NAME[[:space:]]"; then
        echo -e "\e[33mEnvironment '$ENV_NAME' does not exist. Nothing to remove.\e[0m"
        return 0
    fi

    echo -e "\e[36mDeactivating environment '$ENV_NAME' if it is active...\e[0m"
    # Conda deactivate is needed if the environment is currently active to allow removal
    if [ "$CONDA_DEFAULT_ENV" = "$ENV_NAME" ]; then
        conda deactivate
        echo -e "\e[32mEnvironment '$ENV_NAME' deactivated.\e[0m"
    else
        echo -e "\e[33mEnvironment '$ENV_NAME' is not currently active.\e[0m"
    fi

    echo -e "\e[36mAttempting to remove Conda environment: '$ENV_NAME'...\e[0m"
    if conda env remove --name "$ENV_NAME" -y; then
        echo -e "\e[32mConda environment '$ENV_NAME' removed successfully.\e[0m"
    else
        echo -e "\e[31mError: Conda environment removal failed.\e[0m"
        echo -e "\e[33mPlease check the output above for details.\e[0m"
        return 1
    fi

    echo "=============================================================="
    echo "Conda environment removal process finished."
    echo "=============================================================="
    return 0
}

# Call the main function
main
