#!/usr/bin/env python3
"""
DbCli Skills Deployment Script

Deploy DbCli skills to various AI assistant environments:
- Claude Code
- GitHub Copilot
- OpenAI Codex
- Workspace (Cursor, Windsurf, Continue, etc.)

Usage:
    python deploy-skills.py --target claude
    python deploy-skills.py --target codex
    python deploy-skills.py --target all --force
    python deploy-skills.py --install-exe --add-to-path --target all
"""

import os
import sys
import shutil
import argparse
from pathlib import Path
import re
import platform
import subprocess

# Colors for terminal output
class Colors:
    GREEN = '\033[0;32m'
    CYAN = '\033[0;36m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    NC = '\033[0m'  # No Color

def print_success(msg):
    print(f"{Colors.GREEN}✅ {msg}{Colors.NC}")

def print_info(msg):
    print(f"{Colors.CYAN}ℹ️  {msg}{Colors.NC}")

def print_warning(msg):
    print(f"{Colors.YELLOW}⚠️  {msg}{Colors.NC}")

def print_error(msg):
    print(f"{Colors.RED}❌ {msg}{Colors.NC}")

def print_header(title):
    print(f"\n{Colors.CYAN}{'=' * 40}{Colors.NC}")
    print(f"{Colors.CYAN}{title}{Colors.NC}")
    print(f"{Colors.CYAN}{'=' * 40}{Colors.NC}\n")

def check_skills_directory():
    """Check if skills directory exists"""
    if not Path("skills/README.md").exists():
        print_error("skills/ directory not found")
        print_info("Please run this script from the dbcli repository root")
        sys.exit(1)

def find_executable():
    """Find dbcli executable with priority: dist-* > current dir > build output"""
    script_dir = Path(__file__).parent.absolute()
    
    # Priority 1: Check dist-* deployment directories
    system = platform.system()
    if system == "Windows":
        machine = platform.machine().lower()
        is_arm = ("arm" in machine) or ("aarch" in machine)
        dist_dirs = ["dist-win-arm64"] if is_arm else ["dist-win-x64"]
    elif system == "Darwin":
        dist_dirs = [
            "dist-macos-x64", "dist-macos-arm64",
            "dist-linux-x64", "dist-linux-arm64",
            "dist-win-x64", "dist-win-arm64",
        ]
    else:
        # Linux/WSL and other Unix-like platforms
        dist_dirs = [
            "dist-linux-x64", "dist-linux-arm64",
            "dist-macos-x64", "dist-macos-arm64",
            "dist-win-x64", "dist-win-arm64",
        ]
    
    for dist_dir in dist_dirs:
        dist_path = script_dir / dist_dir
        if dist_path.exists():
            for exe_name in ["dbcli.exe", "dbcli"]:
                exe_path = dist_path / exe_name
                if exe_path.exists():
                    print_info(f"Found deployment: {dist_dir}/{exe_name}")
                    return exe_path
    
    # Priority 2: Check current directory
    for exe_name in ["dbcli.exe", "dbcli"]:
        exe_path = script_dir / exe_name
        if exe_path.exists():
            print_info(f"Found: {exe_name}")
            return exe_path
    
    # Priority 3: Try build output directories
    build_paths = [
        "bin/Release/net10.0/win-x64/dbcli.exe",
        "bin/Debug/net10.0/win-x64/dbcli.exe"
    ]
    
    for build_path in build_paths:
        exe_path = script_dir / build_path
        if exe_path.exists():
            print_info(f"Found build: {exe_path}")
            return exe_path
    
    return None

def install_executable(add_to_path=False, skip_path=False):
    """Install dbcli executable to tools directory"""
    print(f"\n{Colors.CYAN}📦 Installing DbCli Executable{Colors.NC}")
    print(f"{Colors.CYAN}{'-' * 30}{Colors.NC}\n")
    
    exe_path = find_executable()
    if not exe_path:
        print_error("DbCli executable not found")
        print_warning("Build the project first: dotnet build -c Release")
        sys.exit(1)
    
    # Copy to target installation directory
    install_dir = Path.home() / "tools" / "dbcli"
    print_info(f"Installing to: {install_dir}")
    
    install_dir.mkdir(parents=True, exist_ok=True)
    
    # Copy all files from source directory (exclude skills)
    source_dir = exe_path.parent
    print_info(f"Copying from: {source_dir}")
    
    for item in source_dir.iterdir():
        if item.name != "skills":
            dest_path = install_dir / item.name
            if item.is_dir():
                if dest_path.exists():
                    shutil.rmtree(dest_path)
                shutil.copytree(item, dest_path)
            else:
                shutil.copy2(item, dest_path)
    
    print_success(f"Installed {exe_path.name} to {install_dir}")
    
    # Add to PATH (platform-specific)
    if platform.system() == "Windows":
        add_to_path_windows(install_dir, add_to_path, skip_path)
    else:
        add_to_path_unix(install_dir, add_to_path, skip_path)
    
    print()

def add_to_path_windows(install_dir, add_to_path, skip_path):
    """Add directory to Windows PATH"""
    try:
        # Check if already in PATH
        result = subprocess.run(
            ['powershell', '-Command', '[Environment]::GetEnvironmentVariable("PATH", "User")'],
            capture_output=True, text=True
        )
        current_path = result.stdout.strip()
        path_entry = str(install_dir)
        
        if path_entry in current_path.split(';'):
            print_success("Already in PATH")
            return
        
        print_warning("DbCli is not in your PATH")
        print_info(f"Location: {install_dir}")
        
        should_add = False
        if add_to_path:
            should_add = True
            print_info("Adding to PATH (automatic)...")
        elif skip_path:
            print_info("Skipping PATH addition (automatic)")
        else:
            print(f"\n  To use 'dbcli' from any directory, add it to PATH.")
            response = input("  Add to PATH? (Y/n): ").strip().lower()
            should_add = response == "" or response.startswith("y")
        
        if should_add:
            # Add to user PATH using PowerShell
            new_path = f"{current_path};{path_entry}" if current_path else path_entry
            subprocess.run([
                'powershell', '-Command',
                f'[Environment]::SetEnvironmentVariable("PATH", "{new_path}", "User")'
            ], check=True)
            print_success("Added to PATH")
            print_warning("Restart your terminal for changes to take effect")
        else:
            print_info("Skipped PATH addition")
            print_info(f"Use full path: {install_dir / 'dbcli.exe'}")
    except Exception as e:
        print_error(f"Failed to modify PATH: {e}")
        print_warning(f"Add manually: {install_dir}")

def add_to_path_unix(install_dir, add_to_path, skip_path):
    """Add directory to Unix PATH (Linux/macOS)"""
    install_dir = Path(install_dir)
    home = Path.home()
    profile_file = home / ".profile"  # login shells (bash -l) read this on most distros
    zshrc_file = home / ".zshrc"

    # Prepend so the installed dbcli takes priority.
    path_export = f'export PATH="{install_dir}:$PATH"'

    def ensure_export_in_file(rc_path: Path) -> bool:
        rc_path.parent.mkdir(parents=True, exist_ok=True)
        if rc_path.exists():
            try:
                content = rc_path.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                content = rc_path.read_text(errors="ignore")
            if str(install_dir) in content:
                return False

        with open(rc_path, 'a', encoding="utf-8") as f:
            f.write(f"\n# DbCli\n{path_export}\n")
        return True
    
    try:
        # If already in current process PATH, we're done.
        current_path = os.environ.get("PATH", "")
        if str(install_dir) in current_path.split(":" ):
            print_success("Already in PATH")
            return

        print_warning("DbCli is not in your PATH")
        print_info(f"Location: {install_dir}")

        should_add = False
        if add_to_path:
            should_add = True
            print_info("Adding to PATH (automatic)...")
        elif skip_path:
            print_info("Skipping PATH addition (automatic)")
        else:
            print("\n  To use 'dbcli' from any directory, add it to PATH.")
            response = input("  Add to PATH? (Y/n): ").strip().lower()
            should_add = response == "" or response.startswith("y")

        if should_add:
            changed_profile = ensure_export_in_file(profile_file)

            # If user uses zsh, also add there.
            shell = os.environ.get("SHELL", "")
            if zshrc_file.exists() or shell.endswith("zsh"):
                ensure_export_in_file(zshrc_file)

            # Update current process PATH so subsequent steps in this run can find dbcli.
            os.environ["PATH"] = f"{install_dir}:{current_path}" if current_path else str(install_dir)

            if changed_profile:
                print_success(f"Added to PATH in {profile_file}")
            else:
                print_success(f"PATH entry already present in {profile_file}")

            print_warning(f"Run: source {profile_file} (or restart your terminal)")
        else:
            print_info("Skipped PATH addition")
            print_info(f"Use full path: {install_dir / 'dbcli'}")
    except Exception as e:
        print_error(f"Failed to modify PATH: {e}")
        print_warning(f"Add manually to {profile_file}: {path_export}")

def deploy_claude_skills(claude_dir, force=False):
    """Deploy skills to Claude Code with nested structure"""
    print_info("Deploying to Claude Code...")
    
    claude_dbcli_dir = Path(claude_dir) / "skills" / "dbcli"
    claude_skills_dir = claude_dbcli_dir / "skills"
    
    # Check if already exists
    if claude_dbcli_dir.exists() and not force:
        print_warning(f"Claude dbcli already exists at {claude_dbcli_dir}")
        response = input("Overwrite? (y/N): ").strip().lower()
        if response != 'y':
            print_info("Skipping Claude deployment")
            return
    
    # Create directories
    claude_dbcli_dir.mkdir(parents=True, exist_ok=True)
    claude_skills_dir.mkdir(parents=True, exist_ok=True)
    
    # Copy executable to dbcli/ (top level)
    exe_path = find_executable()
    if exe_path:
        dest_exe = claude_dbcli_dir / exe_path.name
        shutil.copy2(exe_path, dest_exe)
        print(f"  ✓ {exe_path.name} (executable)")
    else:
        print_warning("DbCli executable not found, skipping exe deployment")
    
    # Copy skills to dbcli/skills/ (nested)
    skill_items = [
        "README.md",
        "CONNECTION_STRINGS.md",
        "dbcli-query",
        "dbcli-exec",
        "dbcli-db-ddl",
        "dbcli-tables",
        "dbcli-export",
        "dbcli-view",
        "dbcli-index",
        "dbcli-procedure",
        "dbcli-interactive"
    ]
    
    for item in skill_items:
        source_path = Path("skills") / item
        if source_path.exists():
            dest_path = claude_skills_dir / item
            if source_path.is_dir():
                if dest_path.exists():
                    shutil.rmtree(dest_path)
                shutil.copytree(source_path, dest_path)
            else:
                shutil.copy2(source_path, dest_path)
            print(f"  ✓ skills/{item}")
    
    
    integration_path = claude_skills_dir / "INTEGRATION.md"
    if integration_path.exists():
        integration_path.unlink()

    print_success(f"Claude Code deployed to {claude_dbcli_dir}")
    print_info("Structure: dbcli/ (exe) + dbcli/skills/ (skills)")
    print_info("Skills will be available in Claude Code after restart")

def deploy_copilot_instructions(force=False):
    """Deploy GitHub Copilot instructions"""
    print_info("Deploying GitHub Copilot instructions...")
    
    github_dir = Path(".github")
    instructions_file = github_dir / "copilot-instructions.md"
    
    # Create .github if not exists
    github_dir.mkdir(exist_ok=True)
    
    # Check if already exists
    if instructions_file.exists() and not force:
        print_warning("copilot-instructions.md already exists")
        response = input("Overwrite? (y/N): ").strip().lower()
        if response != 'y':
            print_info("Skipping Copilot deployment")
            return
    
    # Read template from INTEGRATION.md
    integration_path = Path("skills/INTEGRATION.md")
    if not integration_path.exists():
        print_error("INTEGRATION.md not found")
        return
    
    with open(integration_path, 'r', encoding='utf-8') as f:
        integration_content = f.read()
    
    # Extract Copilot section
    pattern = r'```markdown\s*([\s\S]*?)\s*```'
    copilot_section = re.search(r'## 2\. GitHub Copilot Integration[\s\S]*?(?=## 3\.)', integration_content)
    
    if copilot_section:
        copilot_text = copilot_section.group(0)
        match = re.search(pattern, copilot_text)
        
        if match:
            instructions_content = match.group(1)
            with open(instructions_file, 'w', encoding='utf-8') as f:
                f.write(instructions_content)
            print_success(f"GitHub Copilot instructions created at {instructions_file}")
            print_info("Copilot will use these instructions automatically")
        else:
            print_error("Could not extract Copilot instructions template")
    else:
        print_error("Could not find Copilot section in INTEGRATION.md")

def deploy_workspace_skills(force=False):
    """Deploy skills to workspace directory"""
    print_info("Deploying to workspace skills directory...")
    
    workspace_skills_dir = Path("skills/dbcli")
    
    # Check if this IS the skills directory
    if Path("skills/dbcli-query").exists():
        print_warning("Already in skills root directory")
        print_info("For workspace deployment, run from a different project directory")
        return
    
    # Create skills directory structure
    workspace_skills_dir.mkdir(parents=True, exist_ok=True)
    
    # If we're in dbcli repo, copy from current location
    source_dir = Path("skills")
    if not source_dir.exists():
        print_error("Cannot find skills source directory")
        print_info("Please copy skills manually or run from dbcli repository")
        return
    
    # Copy all skills (excluding docs not required in install artifacts)
    for item in source_dir.iterdir():
        if item.name == "INTEGRATION.md":
            continue
        dest_path = workspace_skills_dir / item.name
        if item.is_dir():
            if dest_path.exists():
                shutil.rmtree(dest_path)
            shutil.copytree(item, dest_path)
        else:
            shutil.copy2(item, dest_path)
    
    
    integration_path = workspace_skills_dir / "INTEGRATION.md"
    if integration_path.exists():
        integration_path.unlink()

    print_success(f"Workspace skills deployed to {workspace_skills_dir}")
    print_info("Skills available for Cursor, Windsurf, Continue, and other workspace-based assistants")

def deploy_codex_skills(force=False):
    """Deploy skills to OpenAI Codex with nested structure"""
    print_info("Deploying to OpenAI Codex...")

    # Skills to deploy (kept in skills/ subdirectory for Codex)
    skill_items = [
        "dbcli-query", "dbcli-exec", "dbcli-db-ddl", "dbcli-tables",
        "dbcli-view", "dbcli-index", "dbcli-procedure",
        "dbcli-export", "dbcli-interactive",
        "README.md", "CONNECTION_STRINGS.md"
    ]
    
    # Deploy to USER scope: ~/.codex/skills/dbcli/skills/
    user_codex_dbcli_dir = Path.home() / '.codex' / 'skills' / 'dbcli'
    user_codex_skills_dir = user_codex_dbcli_dir / 'skills'
    
    if user_codex_dbcli_dir.exists():
        if force:
            print_warning(f"Overwriting existing Codex USER dbcli")
            shutil.rmtree(user_codex_dbcli_dir)
        else:
            print_warning(f"Codex USER dbcli already exists at: {user_codex_dbcli_dir}")
            print_info("Use --force to overwrite")
    
    if not user_codex_dbcli_dir.exists() or force:
        user_codex_dbcli_dir.mkdir(parents=True, exist_ok=True)
        user_codex_skills_dir.mkdir(parents=True, exist_ok=True)
        
        # Copy executable
        exe_path = find_executable()
        if exe_path:
            shutil.copy2(exe_path, user_codex_dbcli_dir / exe_path.name)
            print(f"  ✓ {exe_path.name}")
        
        # Copy skills to nested directory
        for item in skill_items:
            source_path = Path("skills") / item
            if source_path.exists():
                dest_path = user_codex_skills_dir / item
                if source_path.is_dir():
                    if dest_path.exists():
                        shutil.rmtree(dest_path)
                    shutil.copytree(source_path, dest_path)
                else:
                    shutil.copy2(source_path, dest_path)
                print(f"  ✓ skills/{item}")
        
        
        integration_path = user_codex_skills_dir / "INTEGRATION.md"
        if integration_path.exists():
            integration_path.unlink()

        print_success(f"Codex USER deployed to: {user_codex_dbcli_dir}")
    
    # Deploy to REPO scope: ./.codex/skills/dbcli (if in a git repo)
    if Path(".git").exists():
        repo_codex_dbcli_dir = Path(".codex") / "skills" / "dbcli"
        repo_codex_skills_dir = repo_codex_dbcli_dir / "skills"
        
        if repo_codex_dbcli_dir.exists():
            if force:
                print_warning(f"Overwriting existing Codex REPO skills")
                shutil.rmtree(repo_codex_dbcli_dir)
            else:
                print_info(f"Codex REPO skills already exist at: {repo_codex_dbcli_dir} (skipping)")
                return
        
        if not repo_codex_dbcli_dir.exists() or force:
            repo_codex_dbcli_dir.mkdir(parents=True, exist_ok=True)
            repo_codex_skills_dir.mkdir(parents=True, exist_ok=True)

            # Copy executable
            exe_path = find_executable()
            if exe_path:
                shutil.copy2(exe_path, repo_codex_dbcli_dir / exe_path.name)
            
            for item in skill_items:
                source_path = Path("skills") / item
                if source_path.exists():
                    dest_path = repo_codex_skills_dir / item
                    if source_path.is_dir():
                        shutil.copytree(source_path, dest_path, dirs_exist_ok=True)
                    else:
                        shutil.copy2(source_path, dest_path)
            
            integration_path = repo_codex_skills_dir / "INTEGRATION.md"
            if integration_path.exists():
                integration_path.unlink()

            print_success(f"Codex REPO deployed to: {repo_codex_dbcli_dir}")
            print_info("Consider committing .codex/ to repository for team sharing")

def verify_dbcli():
    """Verify DbCli is installed"""
    print("")
    print_info("Verifying DbCli installation...")
    
    try:
        import subprocess
        result = subprocess.run(['dbcli', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            version = result.stdout.strip()
            print_success(f"DbCli is installed: {version}")
        else:
            print_warning("DbCli command not found in PATH")
            print_info("DbCli is not installed. Re-run with: --install-exe --add-to-path")
    except FileNotFoundError:
        print_warning("DbCli not found in PATH")
        print_info("Install DbCli: python3 deploy-skills.py --install-exe --add-to-path --target all --force")

def main():
    def resolve_repo_root(start_dirs):
        for start_dir in start_dirs:
            current = start_dir
            while True:
                if (current / 'dbcli.sln').exists() or (current / '.git').exists():
                    return current

                parent = current.parent
                if parent == current:
                    break
                current = parent
        return None

    parser = argparse.ArgumentParser(
        description='Deploy DbCli skills to AI assistant environments'
    )
    parser.add_argument(
        '--target',
        choices=['claude', 'copilot', 'codex', 'workspace', 'all'],
        default='all',
        help='Target environment to deploy to (default: all)'
    )
    parser.add_argument(
        '--claude-dir',
        default=None,
        help='Custom Claude directory (default: repo ./.claude if detected, otherwise ~/.claude)'
    )
    parser.add_argument(
        '--force',
        action='store_true',
        help='Overwrite existing installations without prompting'
    )
    parser.add_argument(
        '--install-exe',
        action='store_true',
        help='Install DbCli executable to ~/tools/dbcli'
    )
    parser.add_argument(
        '--add-to-path',
        action='store_true',
        help='Automatically add to PATH without prompting'
    )
    parser.add_argument(
        '--skip-path',
        action='store_true',
        help='Skip adding to PATH without prompting'
    )
    
    args = parser.parse_args()

    if args.claude_dir is None:
        script_dir = Path(__file__).resolve().parent
        cwd = Path.cwd().resolve()
        repo_root = resolve_repo_root([script_dir, cwd])
        args.claude_dir = str((repo_root / '.claude') if repo_root else (Path.home() / '.claude'))
    
    print_header("DbCli Skills Deployment")
    
    # Step 0: Install executable if requested
    if args.install_exe:
        install_executable(args.add_to_path, args.skip_path)
    
    # Check prerequisites
    check_skills_directory()
    
    # Execute deployments
    if args.target in ['claude', 'all']:
        deploy_claude_skills(args.claude_dir, args.force)
        if args.target == 'all':
            print()
    
    if args.target in ['copilot', 'all']:
        deploy_copilot_instructions(args.force)
        if args.target == 'all':
            print()
    
    if args.target in ['codex', 'all']:
        deploy_codex_skills(args.force)
        if args.target == 'all':
            print()
    
    if args.target in ['workspace', 'all']:
        deploy_workspace_skills(args.force)
    
    # Verify installation
    verify_dbcli()
    
    # Final summary
    print_header("Deployment Complete! ✅")
    
    print(f"{Colors.CYAN}Deployed to: {args.target}{Colors.NC}\n")
    
    if args.target in ['claude', 'all']:
        print(f"{Colors.CYAN}Claude Code:{Colors.NC}")
        print(f"  Location: {Path(args.claude_dir) / 'skills' / 'dbcli'}")
        print(f"  Usage: Restart Claude Code, then skills auto-available\n")
    
    if args.target in ['copilot', 'all']:
        print(f"{Colors.CYAN}GitHub Copilot:{Colors.NC}")
        print(f"  Location: .github/copilot-instructions.md")
        print(f"  Usage: Copilot reads automatically from workspace\n")
    
    if args.target in ['codex', 'all']:
        print(f"{Colors.CYAN}OpenAI Codex:{Colors.NC}")
        print(f"  USER: {Path.home() / '.codex' / 'skills' / 'dbcli'}")
        print(f"  REPO: .codex/skills/dbcli (if in git repo)")
        print(f"  Usage: Restart Codex, skills auto-available\n")
    
    if args.target in ['workspace', 'all']:
        print(f"{Colors.CYAN}Workspace Skills:{Colors.NC}")
        print(f"  Location: skills/dbcli/")
        print(f"  Usage: Available to Cursor, Windsurf, Continue, etc.\n")
    
    print(f"{Colors.CYAN}Next steps:{Colors.NC}")
    print(f"{Colors.NC}1. Restart your AI assistant (if needed){Colors.NC}")
    print(f"{Colors.NC}2. Test a skill:{Colors.NC}")
    print(f"   Ask: 'Query my SQLite database for all users'")
    print(f"{Colors.NC}3. See skills/README.md for platform-specific usage{Colors.NC}")
    print()

if __name__ == '__main__':
    main()
