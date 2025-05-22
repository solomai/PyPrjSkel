#!/bin/bash

# Initialize conda
if command -v conda &> /dev/null; then
    eval "$(conda shell.bash hook)"
else
    echo "Conda not found. Please ensure conda is installed and available in PATH."
    exit 1
fi

# Read environment name from environment.yml
ENV_FILE="$(dirname "$0")/../environment.yml"
ENV_NAME=""

if [ -f "$ENV_FILE" ]; then
    # Use awk for more precise YAML parsing
    ENV_NAME=$(awk '
        /^[[:space:]]*name[[:space:]]*:/ {
            # Remove "name:" and spaces
            sub(/^[[:space:]]*name[[:space:]]*:[[:space:]]*/, "")
            # Remove quotes if present
            gsub(/["'\''']/, "")
            # Remove comments
            sub(/#.*$/, "")
            # Remove trailing spaces
            gsub(/[[:space:]]*$/, "")
            print $0
            exit
        }
    ' "$ENV_FILE")

    # Alternative method if awk fails
    if [ -z "$ENV_NAME" ]; then
        ENV_NAME=$(grep -E "^[[:space:]]*name[[:space:]]*:" "$ENV_FILE" | \
                   sed -E 's/^[[:space:]]*name[[:space:]]*:[[:space:]]*//' | \
                   sed -E 's/["\x27]//g' | \
                   sed -E 's/#.*$//' | \
                   sed -E 's/[[:space:]]*$//')
    fi
fi

if [ -z "$ENV_NAME" ]; then
    echo "environment.yml not found or does not contain environment name"
    echo "Using base conda environment"
else
    echo "Activating conda environment: $ENV_NAME"
    conda activate "$ENV_NAME" 2>/dev/null

    if [ $? -ne 0 ]; then
        echo "Error activating environment $ENV_NAME"
        echo "Creating environment from environment.yml..."
        conda env create -f "$ENV_FILE"
        if [ $? -eq 0 ]; then
            conda activate "$ENV_NAME"
        else
            echo "Error creating environment from $ENV_FILE"
        fi
    fi
fi