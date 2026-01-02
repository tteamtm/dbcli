#!/usr/bin/env python3
"""
DbCli Installer

Install DbCli executable + deployment scripts into ~/tools/dbcli.
"""

import argparse
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path


class Colors:
    GREEN = '\033[0;32m'
    CYAN = '\033[0;36m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    NC = '\033[0m'


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


def get_dist_dirs():
    system = platform.system()
    if system == "Windows":
        machine = platform.machine().lower()
        is_arm = ("arm" in machine) or ("aarch" in machine)
        return ["dist-win-arm64"] if is_arm else ["dist-win-x64"]
    if system == "Darwin":
        return [
            "dist-macos-x64", "dist-macos-arm64",
            "dist-linux-x64", "dist-linux-arm64",
            "dist-win-x64", "dist-win-arm64",
        ]
    return [
        "dist-linux-x64", "dist-linux-arm64",
        "dist-macos-x64", "dist-macos-arm64",
        "dist-win-x64", "dist-win-arm64",
    ]


def find_executable(script_dir: Path):
    # Priority 1: dist-* directories
    for dist_dir in get_dist_dirs():
        dist_path = script_dir / dist_dir
        if not dist_path.exists():
            continue
        for exe_name in ["dbcli.exe", "dbcli"]:
            exe_path = dist_path / exe_name
            if exe_path.exists():
                print_info(f"Found deployment: {dist_dir}/{exe_name}")
                return exe_path

    # Priority 2: current directory
    for exe_name in ["dbcli.exe", "dbcli"]:
        exe_path = script_dir / exe_name
        if exe_path.exists():
            print_info(f"Found: {exe_name}")
            return exe_path

    # Priority 3: build output directories
    for build_path in [
        "bin/Release/net10.0/win-x64/dbcli.exe",
        "bin/Debug/net10.0/win-x64/dbcli.exe",
    ]:
        exe_path = script_dir / build_path
        if exe_path.exists():
            print_info(f"Found build: {exe_path}")
            return exe_path

    # Priority 4: PATH
    for exe_name in ["dbcli", "dbcli.exe"]:
        exe_path = shutil.which(exe_name)
        if exe_path:
            print_info(f"Found on PATH: {exe_path}")
            return Path(exe_path)

    return None


def resolve_skills_source(script_dir: Path) -> Path:
    script_skills = script_dir / "skills"
    if (script_skills / "INTEGRATION.md").exists() and (script_skills / "dbcli-query" / "SKILL.md").exists():
        return script_skills

    tools_skills = Path.home() / "tools" / "dbcli" / "skills"
    if (tools_skills / "INTEGRATION.md").exists() and (tools_skills / "dbcli-query" / "SKILL.md").exists():
        return tools_skills

    return Path()


def _ps_escape(value: str) -> str:
    # Escape single quotes for PowerShell single-quoted strings.
    return value.replace("'", "''")


def _normalize_parts(parts: list[str]) -> list[str]:
    seen = set()
    result = []
    for part in parts:
        key = part.lower()
        if key in seen:
            continue
        seen.add(key)
        result.append(part)
    return result


def add_to_path_windows(
    install_dir: Path,
    add_to_path: bool,
    fix_user_path: bool,
):
    try:
        result = subprocess.run(
            ['powershell', '-Command', '[Environment]::GetEnvironmentVariable("PATH", "User")'],
            capture_output=True, text=True
        )
        current_path = result.stdout.strip()
        path_entry = str(install_dir)

        parts = [p.strip() for p in current_path.split(';') if p.strip()] if current_path else []
        parts = _normalize_parts(parts)

        if fix_user_path:
            fixed = ";".join(parts)
            if fixed:
                fixed = f"{fixed};"
            if fixed != current_path:
                subprocess.run([
                    'powershell', '-Command',
                    f"[Environment]::SetEnvironmentVariable('PATH', '{_ps_escape(fixed)}', 'User')"
                ], check=True)
                current_path = fixed
                print_success("Normalized user PATH")

        if path_entry in parts:
            print_success("Already in PATH")
            return

        print_warning("DbCli is not in your PATH")
        print_info(f"Location: {install_dir}")

        print_info(
            "Adding to PATH (User, append, automatic)..."
            if add_to_path
            else "Adding to PATH (User, append, default)..."
        )
        parts_no_entry = [p for p in parts if p.lower() != path_entry.lower()]
        new_parts = parts_no_entry + [path_entry]
        new_path = ";".join(new_parts)
        if fix_user_path and new_path:
            new_path = f"{new_path};"
        subprocess.run([
            'powershell', '-Command',
            f"[Environment]::SetEnvironmentVariable('PATH', '{_ps_escape(new_path)}', 'User')"
        ], check=True)
        print_success("Added to PATH")
        print_warning("Restart your terminal for changes to take effect")
    except Exception as e:
        print_error(f"Failed to modify PATH: {e}")
        print_warning(f"Add manually: {install_dir}")


def add_to_path_unix(install_dir: Path, add_to_path: bool):
    home = Path.home()
    profile_file = home / ".profile"
    zshrc_file = home / ".zshrc"
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

    current_path = os.environ.get("PATH", "")
    if str(install_dir) in current_path.split(":"):
        print_success("Already in PATH")
        return

    print_warning("DbCli is not in your PATH")
    print_info(f"Location: {install_dir}")

    print_info("Adding to PATH (automatic)..." if add_to_path else "Adding to PATH (default)...")
    changed_profile = ensure_export_in_file(profile_file)
    if zshrc_file.exists() or os.environ.get("SHELL", "").endswith("zsh"):
        ensure_export_in_file(zshrc_file)

    os.environ["PATH"] = f"{install_dir}:{current_path}" if current_path else str(install_dir)
    if changed_profile:
        print_success(f"Added to PATH in {profile_file}")
    else:
        print_success(f"PATH entry already present in {profile_file}")
    print_warning(f"Run: source {profile_file} (or restart your terminal)")


def install_dbcli(add_to_path: bool, force: bool, fix_user_path: bool):
    print_header("DbCli Install")
    script_dir = Path(__file__).resolve().parent
    exe_path = find_executable(script_dir)
    if not exe_path:
        print_error("DbCli executable not found")
        print_warning("Build the project first: dotnet build -c Release")
        sys.exit(1)

    install_dir = Path.home() / "tools" / "dbcli"
    print_info(f"Installing to: {install_dir}")
    install_dir.mkdir(parents=True, exist_ok=True)

    source_dir = exe_path.parent
    source_resolved = source_dir.resolve()
    install_resolved = install_dir.resolve()

    if source_resolved == install_resolved:
        print_warning("Source and install directory are the same; skipping binary copy")
    else:
        print_info(f"Copying binaries from: {source_dir}")
        for item in source_dir.iterdir():
            if item.name == "skills":
                continue
            dest_path = install_dir / item.name
            if dest_path.exists():
                if dest_path.is_dir():
                    shutil.rmtree(dest_path)
                else:
                    dest_path.unlink()
            if item.is_dir():
                shutil.copytree(item, dest_path)
            else:
                shutil.copy2(item, dest_path)

    for script_name in ["deploy-skills.ps1", "deploy-skills.py", "install-dbcli.ps1", "install-dbcli.py"]:
        script_path = script_dir / script_name
        if script_path.exists():
            dest = install_dir / script_name
            if script_path.resolve() == dest.resolve():
                continue
            shutil.copy2(script_path, dest)
            print(f"  ✓ {script_name}")

    skills_source = resolve_skills_source(script_dir)
    if skills_source and (skills_source / "INTEGRATION.md").exists():
        dest_skills = install_dir / "skills"
        if skills_source.resolve() != dest_skills.resolve():
            if dest_skills.exists():
                shutil.rmtree(dest_skills)
            shutil.copytree(skills_source, dest_skills)
            print("  ✓ skills/ (source)")
        else:
            print_warning("Skills already in tools directory; skipping skills copy")

    for doc_name in ["README.md", "LICENSE"]:
        doc_path = script_dir / doc_name
        if doc_path.exists():
            dest = install_dir / doc_name
            if doc_path.resolve() != dest.resolve():
                shutil.copy2(doc_path, dest)
                print(f"  ✓ {doc_name}")

    print_success(f"Installed {exe_path.name} to {install_dir}")

    if platform.system() == "Windows":
        add_to_path_windows(install_dir, add_to_path, fix_user_path)
    else:
        add_to_path_unix(install_dir, add_to_path)

    print()


def main():
    parser = argparse.ArgumentParser(description="Install DbCli into ~/tools/dbcli")
    parser.add_argument("--add-to-path", action="store_true", help="Force add to PATH")
    parser.add_argument("--fix-user-path", action="store_true", help="Normalize user PATH and ensure trailing ';' (Windows only)")
    parser.add_argument("--force", action="store_true", help="Overwrite existing files (default behavior)")
    args = parser.parse_args()

    install_dbcli(args.add_to_path, args.force, args.fix_user_path)


if __name__ == "__main__":
    main()
