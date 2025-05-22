# Environment Setup

### Prerequisites
- Windows/Linux operating system
- PowerShell (Windows) or Bash (Linux)
- Git

### Environment Configuration
1. Open `environment.yml` and set your project name:
```yaml
name: MY_PROJECT_NAME  # Replace with your project name
```

### Windows Setup

#### Using Setup Script (Recommended)
1. Open PowerShell as Administrator
2. Navigate to project directory
3. Run setup script:
```powershell
.\scripts\setup_env.ps1
```

#### Manual Setup
1. Install Miniconda:
   - Download Miniconda installer from [Miniconda website](https://docs.conda.io/en/latest/miniconda.html)
   - Run installer and follow prompts
   - Restart PowerShell

2. Create and activate environment:
```powershell
conda env create -f environment.yml
conda activate MY_PROJECT_NAME
```

#### VSCode/Cursor Configuration
1. Open project in VSCode/Cursor
2. Press `Ctrl+Shift+P`
3. Type "Python: Select Interpreter"
4. Choose the interpreter from your Conda environment

### Linux Setup

#### Using Setup Script (Recommended)
1. Open terminal
2. Navigate to project directory
3. Make script executable and run:
```bash
chmod +x scripts/setup_env.sh
./scripts/setup_env.sh
```

#### Manual Setup
1. Install Miniconda:
   - Download Miniconda installer
   - Run: `bash Miniconda3-latest-Linux-x86_64.sh`
   - Follow prompts and restart terminal

2. Create and activate environment:
```bash
conda env create -f environment.yml
conda activate MY_PROJECT_NAME
```

#### VSCode/Cursor Configuration
1. Open project in VSCode/Cursor
2. Press `Ctrl+Shift+P`
3. Type "Python: Select Interpreter"
4. Choose the interpreter from your Conda environment

### Environment Management Scripts

- `setup_env`: Automates Miniconda installation and environment setup from environment.yml
- `remove_env`: Removes the current virtual environment based on environment.yml
- `remove_miniconda`: **CAUTION** - Completely removes Miniconda and all environments
- `activate_conda`: Activates the environment in terminal and IDE

### Common Conda Commands

```bash
# Activate environment
conda activate MY_PROJECT_NAME

# Deactivate environment
conda deactivate

# List all environments
conda env list

# Update environment from environment.yml
conda env update -f environment.yml

# Remove environment
conda env remove -n MY_PROJECT_NAME
```
