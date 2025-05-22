#!/usr/bin/env bash
# setup_env.sh — One-click setup script for Conda environment on Linux/macOS/WSL
# Usage: source Scripts/setup_env.sh
# Must be sourced so that 'conda activate' affects the current shell.

# Ensure the script is sourced, not executed
if [[ "$0" == "$BASH_SOURCE" ]]; then
  echo "Please run this script with: source ${BASH_SOURCE[0]}" >&2
  return 1 2>/dev/null || exit 1
fi

# --- Configuration Variables ---
CONDA_DIR="${HOME}/miniconda3"
CONDA_BIN="${CONDA_DIR}/bin/conda"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_YML="$PROJECT_ROOT/environment.yml"
INSTALLER_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"

# --- ANSI Color Codes for output ---
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'
BOLD='\033[1m'

# --- Load or install Conda and shell functions ---
if ! command -v conda &> /dev/null; then
  if [[ -f "${CONDA_DIR}/etc/profile.d/conda.sh" ]]; then
    source "${CONDA_DIR}/etc/profile.d/conda.sh"
  else
    echo -e "${CYAN}Conda not found. Installing Miniconda...${RESET}"
    tmp_installer="/tmp/miniconda_installer.sh"
    curl -fsSL "$INSTALLER_URL" -o "$tmp_installer"
    bash "$tmp_installer" -b -p "$CONDA_DIR"
    rm -f "$tmp_installer"
    source "${CONDA_DIR}/etc/profile.d/conda.sh"
  fi
else
  # Load shell functions
  if [[ -f "${CONDA_DIR}/etc/profile.d/conda.sh" ]]; then
    source "${CONDA_DIR}/etc/profile.d/conda.sh"
  else
    eval "\$(${CONDA_BIN} shell.bash hook)"
  fi
fi

# Verify conda is available
if ! command -v conda &> /dev/null; then
  echo -e "${RED}Error: conda command not available after initialization.${RESET}" >&2
  return 1
fi

# --- Validate environment.yml ---
if [[ ! -f "$ENV_YML" ]]; then
  echo -e "${RED}Error: environment.yml not found at $ENV_YML${RESET}" >&2
  return 1
fi

# --- Extract environment name ---
ENV_NAME=$(grep -E '^name:' "$ENV_YML" | head -n1 | tr -d '\r' | awk '{print $2}')
if [[ -z "$ENV_NAME" ]]; then
  echo -e "${RED}Error: Could not parse environment name from $ENV_YML${RESET}" >&2
  return 1
fi

echo -e "${GREEN}Setting up Conda environment: $ENV_NAME${RESET}"

# --- Create or update the environment ---
if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  echo -e "${CYAN}Updating existing environment '$ENV_NAME'...${RESET}"
  conda env update --file "$ENV_YML" --prune
else
  echo -e "${CYAN}Creating new environment '$ENV_NAME'...${RESET}"
  conda env create --file "$ENV_YML"
fi

# --- Activate in current shell ---
echo -e "${CYAN}Activating environment: $ENV_NAME${RESET}"
conda activate "$ENV_NAME"

# --- Success Header ---
echo -e "${BOLD}${GREEN}==============================================================${RESET}"
echo -e "${BOLD}${GREEN}Environment setup process finished successfully.${RESET}"
echo -e "${BOLD}${GREEN}==============================================================${RESET}"
echo ""

# --- List installed packages ---
echo -e "--- Installed Packages in '$ENV_NAME' environment: ---"
conda list
echo -e "--- End of Package List ---"
echo ""

# --- Commands Reference ---
echo -e "To activate it, please run:"
echo -e "Activate the environment with:   ${GREEN}${BOLD}conda activate $ENV_NAME${RESET}"
echo -e "Deactivate the environment with: ${CYAN}${BOLD}conda deactivate${RESET}"
echo -e "Environments list:               ${YELLOW}${BOLD}conda env list${RESET}"
echo -e "${BOLD}${GREEN}==============================================================${RESET}"
echo -e "Environment setup process finished successfully."