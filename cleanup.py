#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
from pathlib import Path

def is_text_file(file_path):
    """
    Check if a file is a text file.
    Excludes binary files and some system files.
    """
    # File extensions that are definitely text files
    text_extensions = {
        '.txt', '.py', '.js', '.html', '.css', '.json', '.xml', '.csv',
        '.md', '.rst', '.yml', '.yaml', '.ini', '.cfg', '.log', '.sql',
        '.sh', '.bat', '.ps1', '.php', '.rb', '.java', '.cpp', '.c',
        '.h', '.hpp', '.cs', '.go', '.rs', '.swift', '.kt', '.scala',
        '.r', '.m', '.pl', '.lua', '.tcl', '.vb', '.fs', '.clj',
        '.hs', '.elm', '.dart', '.ts', '.jsx', '.tsx', '.vue', '.svelte'
    }

    # Files without extension that are usually text
    text_names = {
        'README', 'LICENSE', 'CHANGELOG', 'CONTRIBUTING', 'AUTHORS',
        'INSTALL', 'NEWS', 'TODO', 'COPYING', 'Makefile', 'Dockerfile'
    }

    file_path = Path(file_path)

    # Check extension
    if file_path.suffix.lower() in text_extensions:
        return True

    # Check filename
    if file_path.name in text_names:
        return True

    # Try to open file as text
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            # Read first 1024 bytes for checking
            sample = f.read(1024)
            # Check for null bytes (binary file indicator)
            if '\0' in sample:
                return False
            return True
    except (UnicodeDecodeError, PermissionError, OSError):
        return False

def trim_trailing_whitespace(file_path):
    """
    Remove trailing whitespace from each line in a file.
    Returns True if the file was modified.
    """
    try:
        # Read file
        with open(file_path, 'r', encoding='utf-8', newline='') as f:
            lines = f.readlines()

        # Process lines
        modified = False
        new_lines = []

        for line in lines:
            # Remove trailing spaces while preserving newline character
            if line.endswith('\n'):
                trimmed = line.rstrip() + '\n'
            elif line.endswith('\r\n'):
                trimmed = line.rstrip() + '\r\n'
            else:
                trimmed = line.rstrip()

            new_lines.append(trimmed)

            # Check if line was changed
            if trimmed != line:
                modified = True

        # Write file only if there were changes
        if modified:
            with open(file_path, 'w', encoding='utf-8', newline='') as f:
                f.writelines(new_lines)
            return True

        return False

    except Exception as e:
        print(f"Error processing file {file_path}: {e}")
        return False

def process_directory(root_dir='.', exclude_dirs=None):
    """
    Process all files in directory and subdirectories.
    """
    if exclude_dirs is None:
        exclude_dirs = {
            '.git', '.svn', '.hg', '__pycache__', 'node_modules',
            '.venv', 'venv', 'env', '.env', 'build', 'dist',
            '.idea', '.vscode', '.DS_Store'
        }

    root_path = Path(root_dir).resolve()
    processed_files = 0
    modified_files = 0

    print(f"Starting to process directory: {root_path}")
    print("-" * 50)

    # Recursively walk through all files
    for file_path in root_path.rglob('*'):
        # Skip directories
        if file_path.is_dir():
            continue

        # Skip excluded directories
        if any(part in exclude_dirs for part in file_path.parts):
            continue

        # Check if file is text
        if not is_text_file(file_path):
            continue

        try:
            # Process file
            relative_path = file_path.relative_to(root_path)
            was_modified = trim_trailing_whitespace(file_path)

            processed_files += 1
            if was_modified:
                modified_files += 1
                print(f"✓ Processed: {relative_path}")
            else:
                print(f"  No changes: {relative_path}")

        except Exception as e:
            print(f"✗ Error {file_path.relative_to(root_path)}: {e}")

    print("-" * 50)
    print(f"Processing completed!")
    print(f"Total files processed: {processed_files}")
    print(f"Files modified: {modified_files}")

def main():
    """
    Main script function.
    """
    # Can pass directory path as argument
    if len(sys.argv) > 1:
        root_directory = sys.argv[1]
    else:
        root_directory = '.'  # Current directory

    if not os.path.exists(root_directory):
        print(f"Error: Directory '{root_directory}' does not exist!")
        sys.exit(1)

    if not os.path.isdir(root_directory):
        print(f"Error: '{root_directory}' is not a directory!")
        sys.exit(1)

    try:
        process_directory(root_directory)
    except KeyboardInterrupt:
        print("\nProcessing interrupted by user.")
        sys.exit(1)
    except Exception as e:
        print(f"Critical error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()