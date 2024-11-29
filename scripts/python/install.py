import os
import subprocess
import sys


def create_launch_agent(plist_name, plist_content):
    home_dir = os.path.expanduser("~")
    launch_agents_dir = os.path.join(home_dir, "Library", "LaunchAgents")
    os.makedirs(launch_agents_dir, exist_ok=True)
    plist_path = os.path.join(launch_agents_dir, plist_name)
    with open(plist_path, "w") as plist_file:
        plist_file.write(plist_content)
    return plist_path


def load_launch_agent(plist_path):
    try:
        subprocess.run(["launchctl", "load", plist_path], check=True)
        print(f"Launch Agent loaded successfully: {plist_path}")
    except subprocess.CalledProcessError as e:
        print(f"Failed to load Launch Agent: {e}")


def main():
    git_projects_workdir = os.getenv("GIT_PROJECTS_WORKDIR")
    if git_projects_workdir is None:
        print("GIT_PROJECTS_WORKDIR environment variable is not set.", file=sys.stderr)
        sys.exit(1)

    python_path = os.getenv("PYTHON_PATH")
    if python_path is None:
        print("PYTHON_PATH environment variable is not set.", file=sys.stderr)
        sys.exit(1)

    script_path = os.path.join(
        git_projects_workdir, "scripts", "python", "git_daemon.py"
    )
    plist_name = "com.user.git_daemon.plist"
    plist_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.git_daemon</string>

    <key>ProgramArguments</key>
    <array>
        <string>{python_path}</string>
        <string>{script_path}</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardErrorPath</key>
    <string>/tmp/git_daemon.err</string>

    <key>StandardOutPath</key>
    <string>/tmp/git_daemon.out</string>
</dict>
</plist>
"""
    plist_path = create_launch_agent(plist_name, plist_content)
    load_launch_agent(plist_path)
    print("\nSetup complete. git daemon will run in the background at startup.")


if __name__ == "__main__":
    main()
