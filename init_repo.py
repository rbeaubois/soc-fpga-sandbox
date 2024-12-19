import os, sys, logging
logging.basicConfig(stream=sys.stderr)

# GUI File path
import tkinter as tk
from tkinter.filedialog import askdirectory
tk.Tk().withdraw()

def create_folder_structure(base_dir, structure):
    """
    Create a folder structure in the base_dir, with .gitignore where needed.

    Args:
    - base_dir (str): The base directory where the structure will be created.
    - structure (dict): A dictionary representing the folder structure.
                        Keys are folder names, and values are either:
                            - `None` (for leaf folders),
                            - a dictionary for subfolders, or
                            - `{'gitignore': True}` to add a .gitignore in the folder.
    """
    for folder_name, config in structure.items():
        folder_path = os.path.join(base_dir, folder_name)
        os.makedirs(folder_path, exist_ok=True)
        
        # Check if a .gitignore is needed for this folder
        if isinstance(config, dict) and config.get('gitignore', False):
            create_gitignore(folder_path)
        
        # If the folder has subfolders, recursively create them
        elif isinstance(config, dict):
            create_folder_structure(folder_path, config)
        
        # If it's a leaf node and no subfolder, we don't need to do anything special
    
def create_readme(base_dir):
    """Create a README.md file in the base directory."""
    readme_content = "# Project Title\n\nThis is the initial project structure."
    readme_path = os.path.join(base_dir, "README.md")
    
    with open(readme_path, 'w') as f:
        f.write(readme_content)

def create_changelog(base_dir):
    """Create a CHANGELOG.md file in the docs folder."""
    changelog_content = """# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- 
### Added
### Changed
### Fixed
### Removed 
-->
## [0.1.0] - 01 Oct 2024
### Added
- Initial version released
"""
    changelog_path = os.path.join(base_dir, "docs", "CHANGELOG.md")
    
    with open(changelog_path, 'w') as f:
        f.write(changelog_content)

def create_gitignore(folder_path, is_main=False):
    """Create a .gitignore in the given folder. 
    If is_main=True, creates the main .gitignore for the root directory."""
    
    if is_main:
        # Main .gitignore for the root directory
        gitignore_content = """# Ignore Python bytecode files
*.pyc
*.pyo
__pycache__/

# Ignore editor and IDE files
.vscode/
.idea/

# Ignore virtual environments
venv/
.env/

# Ignore log files
*.log

# Ignore build
build/
"""
    else:
        # .gitignore for subdirectories, ignoring everything except .gitignore
        gitignore_content = """# Ignore everything in this directory
*
# But not this file itself
!.gitignore
"""
    
    gitignore_path = os.path.join(folder_path, ".gitignore")
    
    with open(gitignore_path, 'w') as f:
        f.write(gitignore_content)

def main():
    if len(sys.argv) < 2:
        base_dir = input("Project name: ")
    else:
        base_dir = sys.argv[1]

    create_in_current = input("Do you want to create the project in the current directory? (y/n): ").strip().lower()
    if create_in_current == 'n':
        dirpath = askdirectory()
        base_dir = os.path.join(dirpath, base_dir)

    # Define your folder structure here with gitignore: True where needed
    folder_structure = {
        "docs": None,
        "data": {"gitignore": True},
        "hw": {
            "rtl": {
                "prj": {"gitignore": True},
                "src": {
                    "hdl": None,
                    "xdc": None,
                    "tb": None,
                },
                "tcl": None,
                "waves": None,
            },
            "hls": {
                "prj": {"gitignore": True},
                "src": None
            }
        },
        "sw": {
            "target": {
                "app": {
                    "src": None
                },
                "config": None,
                "data": {"gitignore": True},
                "drivers": None,
                "firmware": None,
                "utility": None,
            },
            "host": None,
            "tests": None,
        },
    }

    # Step 1: Create the folder structure
    create_folder_structure(base_dir, folder_structure)
    
    # Step 2: Create the README.md file
    create_readme(base_dir)
    
    # Step 3: Create the CHANGELOG.md file in docs
    create_changelog(base_dir)
    
    # Step 4: Create the main .gitignore at the root
    create_gitignore(base_dir, is_main=True)
    
    print(f"Folder structure, README.md, CHANGELOG.md, and main .gitignore created at {base_dir}")

if __name__ == "__main__":
    main()
