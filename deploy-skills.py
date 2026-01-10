#!/usr/bin/env python3
"""
DbCli Skills Deployment Script

Deploy DbCli skills to various AI assistant environments:
- Claude Code
- GitHub Copilot
- OpenAI Codex
        - Workspace (Cursor, Cline/Roo/Kilo, etc.)

Usage:
    python deploy-skills.py --target claude
    python deploy-skills.py --target codex
    python deploy-skills.py --target codex --codex-global-only
    python deploy-skills.py --target all --force
    python deploy-skills.py --install-scripts --target all
    python deploy-skills.py --package-claude-skill dbcli-query --package-out-dir .
    python deploy-skills.py --package-claude-all --package-out-dir .
"""

import os
import sys
import shutil
import argparse
from pathlib import Path
import re
import platform
import subprocess
import tempfile
import zipfile
import time
import stat

# Skills source (set in main)
SKILLS_SOURCE = Path("skills")

# Colors for terminal output
class Colors:
    GREEN = '\033[0;32m'
    CYAN = '\033[0;36m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    NC = '\033[0m'  # No Color

def print_success(msg):
    print(f"{Colors.GREEN}[OK] {msg}{Colors.NC}")

def print_info(msg):
    print(f"{Colors.CYAN}[INFO] {msg}{Colors.NC}")

def print_warning(msg):
    print(f"{Colors.YELLOW}[WARN] {msg}{Colors.NC}")

def print_error(msg):
    print(f"{Colors.RED}[ERR] {msg}{Colors.NC}")

def print_header(title):
    print(f"\n{Colors.CYAN}{'=' * 40}{Colors.NC}")
    print(f"{Colors.CYAN}{title}{Colors.NC}")
    print(f"{Colors.CYAN}{'=' * 40}{Colors.NC}\n")

def rmtree_force(path: Path):
    def _onerror(func, p, _exc_info):
        try:
            os.chmod(p, stat.S_IWRITE)
            func(p)
        except Exception:
            raise

    for attempt in range(3):
        try:
            shutil.rmtree(path, onerror=_onerror)
            return
        except PermissionError:
            if attempt == 2:
                raise
            time.sleep(0.5)

def resolve_skills_source() -> Path:
    """Resolve skills source directory (script dir -> tools/dbcli -> cwd)."""
    script_dir = Path(__file__).resolve().parent
    script_skills = script_dir / "skills"
    if (script_skills / "INTEGRATION.md").exists() and (script_skills / "dbcli-query" / "SKILL.md").exists():
        return script_skills

    tools_skills = Path.home() / "tools" / "dbcli" / "skills"
    if (tools_skills / "INTEGRATION.md").exists() and (tools_skills / "dbcli-query" / "SKILL.md").exists():
        return tools_skills

    cwd_skills = Path("skills")
    if (cwd_skills / "INTEGRATION.md").exists() and (cwd_skills / "dbcli-query" / "SKILL.md").exists():
        return cwd_skills

    return Path()

def get_dbcli_rules_block() -> str:
    """Extract DbCli rules block from INTEGRATION.md."""
    integration_path = SKILLS_SOURCE / "INTEGRATION.md"
    if not integration_path.exists():
        return ""
    content = integration_path.read_text(encoding="utf-8", errors="ignore")
    match = re.search(r'<!-- DBCLI_RULES_START -->\s*([\s\S]*?)\s*<!-- DBCLI_RULES_END -->', content)
    if not match:
        return ""
    return match.group(1).strip()

def append_dbcli_rules_to_file(path: Path, rules_text: str):
    if not rules_text:
        return
    marker = "DBCLI_RULES_START"
    if path.exists():
        existing = path.read_text(encoding="utf-8", errors="ignore")
        if marker in existing:
            return
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.suffix.lower() in {".yml", ".yaml"}:
        commented = "\n".join([f"# {line}" for line in rules_text.splitlines()])
        block = f"\n\n# DBCLI_RULES_START\n{commented}\n# DBCLI_RULES_END\n"
    else:
        block = f"\n\n<!-- DBCLI_RULES_START -->\n{rules_text}\n<!-- DBCLI_RULES_END -->\n"
    with open(path, "a", encoding="utf-8") as f:
        f.write(block)

def append_dbcli_rules(include_copilot: bool = False):
    rules = get_dbcli_rules_block()
    if not rules:
        print_warning("DbCli rules block not found in INTEGRATION.md; skipping rules append")
        return

    rule_files = [
        Path("CLAUDE.md"),
        Path("Claude.md"),
        Path("AGENTS.md"),
        Path("Agents.md"),
        Path(".cursorrules"),
        Path(".vscode") / "context.md",
        Path(".gemini") / "skills.yaml",
        Path(".gemini") / "skills.yml",
    ]

    for file_path in rule_files:
        append_dbcli_rules_to_file(file_path, rules)

    if include_copilot:
        append_dbcli_rules_to_file(Path(".github") / "copilot-instructions.md", rules)

def get_claude_skill_names(skills_source: Path) -> list[str]:
    names: list[str] = []
    for child in skills_source.iterdir():
        if child.is_dir() and (child / "SKILL.md").exists():
            names.append(child.name)
    return sorted(names)

def package_claude_skill_zip(skill_name: str, skills_source: Path, out_dir: Path) -> Path:
    src_dir = skills_source / skill_name
    if not src_dir.exists():
        raise FileNotFoundError(f"Skill not found: {src_dir}")

    out_dir.mkdir(parents=True, exist_ok=True)
    zip_path = out_dir / f"{skill_name}.zip"
    if zip_path.exists():
        zip_path.unlink()

    temp_root = Path(tempfile.mkdtemp(prefix=f"claude-skill-{skill_name}-"))
    try:
        staged_skill_dir = temp_root / skill_name
        shutil.copytree(src_dir, staged_skill_dir)

        has_skill_md = any(p.is_file() and p.name.lower() == "skill.md" for p in staged_skill_dir.iterdir())
        if not has_skill_md:
            print_warning(f"Skill.md not found in skill folder (expected by Claude upload): {staged_skill_dir}")

        # Write ZIP with case-correct Skill.md entry name (Windows FS is case-insensitive).
        with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            zf.writestr(f"{skill_name}/", "")
            for file_path in staged_skill_dir.rglob("*"):
                if not file_path.is_file():
                    continue
                rel = file_path.relative_to(staged_skill_dir).as_posix()
                if file_path.name.lower() == "skill.md":
                    parts = rel.split("/")
                    parts[-1] = "Skill.md"
                    rel = "/".join(parts)
                zf.write(file_path, arcname=f"{skill_name}/{rel}")

        return zip_path
    finally:
        shutil.rmtree(temp_root, ignore_errors=True)

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

def install_scripts(add_to_path=False, skip_path=False):
    """Install dbcli executable + deployment scripts + docs to tools directory"""
    print(f"\n{Colors.CYAN}📦 Installing DbCli (Executable + Scripts){Colors.NC}")
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
    print_info(f"Copying binaries from: {source_dir}")
    
    for item in source_dir.iterdir():
        if item.name != "skills":
            dest_path = install_dir / item.name
            if item.is_dir():
                if dest_path.exists():
                    shutil.rmtree(dest_path)
                shutil.copytree(item, dest_path)
            else:
                shutil.copy2(item, dest_path)

    # Copy deployment scripts from the script directory
    script_dir = Path(__file__).parent.absolute()
    for script_name in ["deploy-skills.ps1", "deploy-skills.py"]:
        script_path = script_dir / script_name
        if script_path.exists():
            shutil.copy2(script_path, install_dir / script_name)
            print(f"  - {script_name}")

    # Copy docs into tools
    for doc_name in ["README.md", "LICENSE"]:
        doc_path = script_dir / doc_name
        if doc_path.exists():
            shutil.copy2(doc_path, install_dir / doc_name)
            print(f"  - {doc_name}")
    
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
        
        if skip_path:
            print_info("Skipping PATH addition (automatic)")
            print_info(f"Use full path: {install_dir / 'dbcli.exe'}")
            return

        if add_to_path:
            print_info("Adding to PATH (automatic)...")
        else:
            print_info("Adding to PATH (default)...")

        # Add to user PATH using PowerShell
        new_path = f"{current_path};{path_entry}" if current_path else path_entry
        subprocess.run([
            'powershell', '-Command',
            f'[Environment]::SetEnvironmentVariable("PATH", "{new_path}", "User")'
        ], check=True)
        print_success("Added to PATH")
        print_warning("Restart your terminal for changes to take effect")
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

        if skip_path:
            print_info("Skipping PATH addition (automatic)")
            print_info(f"Use full path: {install_dir / 'dbcli'}")
            return

        if add_to_path:
            print_info("Adding to PATH (automatic)...")
        else:
            print_info("Adding to PATH (default)...")

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
    except Exception as e:
        print_error(f"Failed to modify PATH: {e}")
        print_warning(f"Add manually to {profile_file}: {path_export}")

def deploy_claude_skills(claude_dir, force=False, copy_exe=False):
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
    if force and claude_skills_dir.exists():
        # Force means "clean update": remove stale files that might not be overwritten.
        rmtree_force(claude_skills_dir)
    claude_skills_dir.mkdir(parents=True, exist_ok=True)
    
    if copy_exe:
        # Copy executable to dbcli/ (top level)
        exe_path = find_executable()
        if exe_path:
            dest_exe = claude_dbcli_dir / exe_path.name
            shutil.copy2(exe_path, dest_exe)
            print(f"  - {exe_path.name} (executable)")
        else:
            print_warning("DbCli executable not found, skipping exe deployment")
    
    # Copy skills to dbcli/skills/ (nested)
    skill_items = [
        "README.md",
        "INTEGRATION.md",
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
        source_path = SKILLS_SOURCE / item
        if source_path.exists():
            dest_path = claude_skills_dir / item
            if source_path.is_dir():
                if dest_path.exists():
                    shutil.rmtree(dest_path)
                shutil.copytree(source_path, dest_path)
            else:
                shutil.copy2(source_path, dest_path)
            print(f"  - skills/{item}")

    print_success(f"Claude Code deployed to {claude_dbcli_dir}")
    print_info("Structure: dbcli/ (exe) + dbcli/skills/ (skills)")
    print_info(f"Skills location: {claude_skills_dir}")
    print_info("Skills will be available in Claude Code after restart")
    append_dbcli_rules()

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
    integration_path = SKILLS_SOURCE / "INTEGRATION.md"
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
            append_dbcli_rules(include_copilot=True)
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
    if force and workspace_skills_dir.exists():
        # Force means "clean update": remove stale files that might not be overwritten.
        rmtree_force(workspace_skills_dir)
    workspace_skills_dir.mkdir(parents=True, exist_ok=True)
    
    # If we're in dbcli repo, copy from current location
    source_dir = SKILLS_SOURCE
    if not source_dir.exists():
        print_error("Cannot find skills source directory")
        print_info("Please copy skills manually or run from dbcli repository")
        return
    
    # Copy all skills
    for item in source_dir.iterdir():
        dest_path = workspace_skills_dir / item.name
        if item.is_dir():
            if dest_path.exists():
                rmtree_force(dest_path)
            shutil.copytree(item, dest_path)
        else:
            shutil.copy2(item, dest_path)

    print_success(f"Workspace skills deployed to {workspace_skills_dir}")
    print_info("Skills available for Cursor, Cline/Roo/Kilo, and other workspace-based assistants")

def deploy_codex_skills(force=False, copy_exe=True, global_only=False):
    """Deploy skills to OpenAI Codex with nested structure"""
    print_info("Deploying to OpenAI Codex...")

    # Skills to deploy (kept in skills/ subdirectory for Codex)
    skill_items = [
        "dbcli-query", "dbcli-exec", "dbcli-db-ddl", "dbcli-tables",
        "dbcli-view", "dbcli-index", "dbcli-procedure",
        "dbcli-export", "dbcli-interactive",
        "README.md", "INTEGRATION.md", "CONNECTION_STRINGS.md"
    ]
    
    # Deploy to USER scope: ~/.codex/skills/dbcli/skills/
    user_codex_dbcli_dir = Path.home() / '.codex' / 'skills' / 'dbcli'
    user_codex_skills_dir = user_codex_dbcli_dir / 'skills'
    
    if user_codex_dbcli_dir.exists():
        if force:
            print_warning(f"Overwriting existing Codex USER dbcli")
            rmtree_force(user_codex_dbcli_dir)
        else:
            print_warning(f"Codex USER dbcli already exists at: {user_codex_dbcli_dir}")
            print_info("Use --force to overwrite")
    
    if not user_codex_dbcli_dir.exists() or force:
        user_codex_dbcli_dir.mkdir(parents=True, exist_ok=True)
        user_codex_skills_dir.mkdir(parents=True, exist_ok=True)
        
        # Copy executable
        exe_path = find_executable()
        if copy_exe and exe_path:
            shutil.copy2(exe_path, user_codex_dbcli_dir / exe_path.name)
            print(f"  - {exe_path.name}")
        
        # Copy skills to nested directory
        for item in skill_items:
            source_path = SKILLS_SOURCE / item
            if source_path.exists():
                dest_path = user_codex_skills_dir / item
                if source_path.is_dir():
                    if dest_path.exists():
                        rmtree_force(dest_path)
                    shutil.copytree(source_path, dest_path)
                else:
                    shutil.copy2(source_path, dest_path)
                print(f"  - skills/{item}")

        print_success(f"Codex USER deployed to: {user_codex_dbcli_dir}")
    
    if global_only:
        print_info("Codex global-only mode: skipping repo deployment")
        return

    # Deploy to REPO scope: ./.codex/skills/dbcli (if in a git repo)
    if Path(".git").exists():
        repo_codex_dbcli_dir = Path(".codex") / "skills" / "dbcli"
        repo_codex_skills_dir = repo_codex_dbcli_dir / "skills"
        
        if repo_codex_dbcli_dir.exists():
            if force:
                print_warning(f"Overwriting existing Codex REPO skills")
                rmtree_force(repo_codex_dbcli_dir)
            else:
                print_info(f"Codex REPO skills already exist at: {repo_codex_dbcli_dir} (skipping)")
                return
        
        if not repo_codex_dbcli_dir.exists() or force:
            repo_codex_dbcli_dir.mkdir(parents=True, exist_ok=True)
            repo_codex_skills_dir.mkdir(parents=True, exist_ok=True)

            # Copy executable
            exe_path = find_executable()
            if copy_exe and exe_path:
                shutil.copy2(exe_path, repo_codex_dbcli_dir / exe_path.name)
            
            for item in skill_items:
                source_path = SKILLS_SOURCE / item
                if source_path.exists():
                    dest_path = repo_codex_skills_dir / item
                    if source_path.is_dir():
                        shutil.copytree(source_path, dest_path, dirs_exist_ok=True)
                    else:
                        shutil.copy2(source_path, dest_path)

            print_success(f"Codex REPO deployed to: {repo_codex_dbcli_dir}")
            print_info("Consider committing .codex/ to repository for team sharing")

    append_dbcli_rules()

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
            print_info("DbCli is not installed. Re-run with: --install-scripts")
    except FileNotFoundError:
        print_warning("DbCli not found in PATH")
        print_info("Install DbCli: python3 deploy-skills.py --install-scripts --target all --force")

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
        '--install-scripts',
        action='store_true',
        help='Install DbCli executable + deployment scripts to ~/tools/dbcli'
    )
    parser.add_argument(
        '--add-to-path',
        action='store_true',
        help='Force add to PATH (default when --install-scripts)'
    )
    parser.add_argument(
        '--codex-global-only',
        action='store_true',
        help='Deploy Codex skills to user profile only (~/.codex) and skip repo/workspace outputs'
    )
    parser.add_argument(
        '--package-claude-skill',
        action='append',
        default=[],
        help='Create a Claude Web/App upload ZIP for a single skill (repeatable)'
    )
    parser.add_argument(
        '--package-claude-all',
        action='store_true',
        help='Package all skills as separate Claude upload ZIPs'
    )
    parser.add_argument(
        '--package-out-dir',
        default='.',
        help='Output directory for Claude upload ZIPs (default: .)'
    )
    
    args = parser.parse_args()

    if args.codex_global_only and args.target != 'codex':
        print_error("--codex-global-only is only supported with --target codex")
        sys.exit(1)

    if args.claude_dir is None:
        script_dir = Path(__file__).resolve().parent
        cwd = Path.cwd().resolve()
        repo_root = resolve_repo_root([script_dir, cwd])
        args.claude_dir = str((repo_root / '.claude') if repo_root else (Path.home() / '.claude'))
    
    if args.package_claude_all or args.package_claude_skill:
        print_header("Claude Skills Packaging")
    else:
        print_header("DbCli Skills Deployment")
    
    # Step 0: Install executable + scripts if requested
    if args.install_scripts:
        install_script = Path(__file__).resolve().parent / "install-dbcli.py"
        if install_script.exists():
            cmd = [sys.executable, str(install_script)]
            if args.add_to_path:
                cmd.append("--add-to-path")
            if args.force:
                cmd.append("--force")
            subprocess.run(cmd, check=True)
        else:
            install_scripts(args.add_to_path, args.skip_path)
    
    # Resolve skills source
    skills_source = resolve_skills_source()
    if not skills_source or not (skills_source / "INTEGRATION.md").exists():
        print_error("skills/ directory not found")
        print_info("Install scripts with skills into tools (--install-scripts) or run from dbcli repository root")
        sys.exit(1)

    global SKILLS_SOURCE
    SKILLS_SOURCE = skills_source

    # Claude Web/App packaging-only mode
    if args.package_claude_all or args.package_claude_skill:
        if args.package_claude_all and args.package_claude_skill:
            print_error("Use either --package-claude-all or --package-claude-skill (not both)")
            sys.exit(1)

        out_dir = Path(args.package_out_dir).resolve()
        if args.package_claude_all:
            skill_names = get_claude_skill_names(SKILLS_SOURCE)
        else:
            skill_names = args.package_claude_skill

        if not skill_names:
            print_error("No skills to package")
            sys.exit(1)

        print_info(f"Skills source: {SKILLS_SOURCE}")
        print_info(f"Output dir: {out_dir}")

        ok = True
        for name in skill_names:
            try:
                created = package_claude_skill_zip(name, SKILLS_SOURCE, out_dir)
                print_success(f"Created: {created}")
            except Exception as e:
                ok = False
                print_error(str(e))

        if not ok:
            sys.exit(1)

        print_info('Upload these ZIPs in Claude: Settings > Capabilities > Skills > "Upload skill"')
        return
    
    # Execute deployments
    if args.target in ['claude', 'all']:
        deploy_claude_skills(args.claude_dir, args.force, copy_exe=False)
        if args.target == 'all':
            print()
    
    if args.target in ['copilot', 'all']:
        deploy_copilot_instructions(args.force)
        if args.target == 'all':
            print()
    
    if args.target in ['codex', 'all']:
        deploy_codex_skills(args.force, copy_exe=False, global_only=args.codex_global_only)
        if args.target == 'all':
            print()
    
    if args.target in ['workspace', 'all']:
        deploy_workspace_skills(args.force)
    
    # Verify installation
    verify_dbcli()
    
    # Final summary
    print_header("Deployment Complete!")
    
    print(f"{Colors.CYAN}Deployed to: {args.target}{Colors.NC}\n")
    
    if args.target in ['claude', 'all']:
        print(f"{Colors.CYAN}Claude Code:{Colors.NC}")
        print(f"  Location: {Path(args.claude_dir) / 'skills' / 'dbcli'}")
        print(f"  Skills: {Path(args.claude_dir) / 'skills' / 'dbcli' / 'skills'}")
        print(f"  Usage: Restart Claude Code, then skills auto-available\n")
    
    if args.target in ['copilot', 'all']:
        print(f"{Colors.CYAN}GitHub Copilot:{Colors.NC}")
        print(f"  Location: .github/copilot-instructions.md")
        print(f"  Usage: Copilot reads automatically from workspace\n")
    
    if args.target in ['codex', 'all']:
        print(f"{Colors.CYAN}OpenAI Codex:{Colors.NC}")
        print(f"  USER: {Path.home() / '.codex' / 'skills' / 'dbcli'}")
        print(f"  USER Skills: {Path.home() / '.codex' / 'skills' / 'dbcli' / 'skills'}")
        if not args.codex_global_only:
            print(f"  REPO: .codex/skills/dbcli (if in git repo)")
            print(f"  REPO Skills: .codex/skills/dbcli/skills (if in git repo)")
        print(f"  Usage: Restart Codex, skills auto-available\n")
    
    if args.target in ['workspace', 'all']:
        print(f"{Colors.CYAN}Workspace Skills:{Colors.NC}")
        print(f"  Location: skills/dbcli/")
        print(f"  Usage: Available to Cursor, Cline/Roo/Kilo, etc.\n")
    
    print(f"{Colors.CYAN}Next steps:{Colors.NC}")
    print(f"{Colors.NC}1. Restart your AI assistant (if needed){Colors.NC}")
    print(f"{Colors.NC}2. Test a skill:{Colors.NC}")
    print(f"   Ask: 'Query my SQLite database for all users'")
    print(f"{Colors.NC}3. See skills/INTEGRATION.md for platform-specific usage{Colors.NC}")
    print()

if __name__ == '__main__':
    main()
