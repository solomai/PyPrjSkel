#!/bin/bash
# remove_miniconda.sh - Fully uninstall Miniconda and all environments on Linux/macOS/WSL (Bash/Zsh)

if [[ "$0" == "$BASH_SOURCE" ]]; then
  echo "Please run this script with: source ${BASH_SOURCE[0]}" >&2
  return 1 2>/dev/null || exit 1
fi

# --- Configuration Variables ---
CONDA_INSTALL_DIR="${HOME}/miniconda3"

# --- ANSI Color Codes ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m' # Reset to default colors
BOLD='\033[1m'

# --- Function to remove all Conda environments (except base) ---
remove_all_conda_envs() {
    echo -e "${CYAN}Listing all conda environments...${RESET}"
    local env_names=()

    # Get env list, filter out comments and base, then extract names
    # Using 'conda env list --json' for more robust parsing
    if [ -f "${CONDA_INSTALL_DIR}/bin/conda" ]; then
        CONDA_ENVS_JSON=$("${CONDA_INSTALL_DIR}/bin/conda" env list --json 2>/dev/null)

        # Use Python to parse JSON and extract environment names (paths)
        # Then, extract the actual name from the path.
        # Filter out 'base' environment.
        mapfile -t env_paths < <(python -c "import json; import sys; data = json.loads(sys.stdin.read()); for env in data.get('envs', []): print(env)" <<< "${CONDA_ENVS_JSON}")

        for env_path in "${env_paths[@]}"; do
            # Extract environment name from path (last component)
            local env_name=$(basename "${env_path}")
            if [[ -n "$env_name" && "$env_name" != "base" && "$env_name" != "root" ]]; then
                # Check if it's a named environment (not just default base path)
                if [[ "$env_path" != "$CONDA_INSTALL_DIR" ]]; then # If it's not the base install path
                    env_names+=("$env_name")
                fi
            fi
        done
    else
        echo -e "${YELLOW}Conda executable not found, skipping environment listing.${RESET}"
    fi

    if [ ${#env_names[@]} -eq 0 ]; then
        echo -e "${YELLOW}No additional environments found to remove.${RESET}"
    else
        echo -e "${CYAN}Found environments to remove: ${env_names[*]}.${RESET}"
        for env in "${env_names[@]}"; do
            echo -e "${CYAN}Removing environment: ${env}${RESET}"
            if "${CONDA_INSTALL_DIR}/bin/conda" remove --name "${env}" --all -y >/dev/null 2>&1; then
                echo -e "${GREEN}Successfully removed environment: ${env}${RESET}"
            else
                echo -e "${YELLOW}Warning: Failed to remove environment ${env}. It might be in use or corrupted.${RESET}"
            fi
        done
    fi
}

# --- Main execution flow ---

echo ""
echo -e "${BOLD}==============================================================${RESET}"
echo -e "${BOLD} Starting Miniconda uninstallation process...${RESET}"
echo -e "${BOLD}==============================================================${RESET}"
echo ""

echo -e "${CYAN}Deactivating Conda if active...${RESET}"
# Check if conda command exists and try to deactivate
if command -v conda &>/dev/null; then
    conda deactivate 2>/dev/null # Deactivate, suppress errors if not active
    remove_all_conda_envs
else
    echo -e "${YELLOW}Conda command not found; skipping environment removal.${RESET}"
fi

echo ""
echo -e "${CYAN}Removing Miniconda installation folder: ${CONDA_INSTALL_DIR}...${RESET}"
if [ -d "$CONDA_INSTALL_DIR" ]; then
    rm -rf "$CONDA_INSTALL_DIR"
    echo -e "${GREEN}Deleted: ${CONDA_INSTALL_DIR}${RESET}"
else
    echo -e "${YELLOW}No Miniconda directory found at ${CONDA_INSTALL_DIR}${RESET}"
fi

echo ""
echo -e "${CYAN}Cleaning up shell profile scripts...${RESET}"

# Define common shell profile files
# Add other common shell profiles as needed (e.g., ~/.bash_profile for macOS, ~/.profile)
PROFILE_FILES=(
    "${HOME}/.bashrc"
    "${HOME}/.zshrc"
    "${HOME}/.condarc" # Conda config file
    "${HOME}/.profile" # For some Linux distributions
    "${HOME}/.bash_profile" # For some macOS/Linux setups
)

for profile_file in "${PROFILE_FILES[@]}"; do
    if [ -f "$profile_file" ]; then
        echo -e "${CYAN}Processing ${profile_file}...${RESET}"

        # Create a backup
        cp "$profile_file" "${profile_file}.bak"
        echo -e "${GREEN}Backed up ${profile_file} to ${profile_file}.bak${RESET}"

        # Use sed to remove conda init blocks and 'source conda.sh' lines
        # -i.bak creates a backup like cp but directly modifies in place
        # '\# >>> conda initialize >>>', '/# <<< conda initialize <<<' remove block
        # '/conda.sh/d' removes lines containing 'conda.sh'
        # The '.bak' suffix for sed needs to be handled carefully, on Linux it's usually just -i, on macOS -i ''
        # We will use temporary file to be safe.

        TEMP_CLEAN_FILE=$(mktemp)

        # Remove conda init block:
        sed '/# >>> conda initialize >>>/,/# <<< conda initialize <<</d' "$profile_file" > "$TEMP_CLEAN_FILE"

        # Remove lines that might source conda.sh or include old conda paths (if any remained)
        # Apply this to the already processed temp file
        sed -i.bak '/conda\.sh/d;/\/miniconda3\/bin/d' "$TEMP_CLEAN_FILE"

        # Check if changes were made and move temp file back
        if ! cmp -s "$profile_file" "$TEMP_CLEAN_FILE" >/dev/null 2>&1; then
             mv "$TEMP_CLEAN_FILE" "$profile_file"
             echo -e "${GREEN}Removed conda references from ${profile_file}.${RESET}"
        else
             rm "$TEMP_CLEAN_FILE"
             echo -e "${YELLOW}No conda references found or file was already clean in ${profile_file}.${RESET}"
        fi
        rm -f "${TEMP_CLEAN_FILE}.bak" # Remove sed's temporary backup
    else
        echo -e "${YELLOW}${profile_file} not found, skipping.${RESET}"
    fi
done

echo ""
echo -e "${BOLD}${GREEN}==============================================================${RESET}"
echo -e "${BOLD}${GREEN}  Miniconda and all environments have been fully removed!${RESET}"
echo -e "${BOLD}${GREEN}==============================================================${RESET}"
echo ""
echo -e "${BOLD}${YELLOW}IMPORTANT: Please RESTART YOUR TERMINAL (or open a new one)${RESET}"
echo -e "${BOLD}${YELLOW}           to ensure all changes are applied.${RESET}"
echo ""