import os
from pathlib import Path
import re
import sys
import subprocess
import toml
from repos import repos


def get_default_branch():
    try:
        # Check if 'main' branch exists
        subprocess.run(
            ["git", "rev-parse", "--verify", "main"],
            check=True,
            capture_output=True,
            text=True,
        )
        return "main"
    except subprocess.CalledProcessError:
        try:
            # Check if 'master' branch exists
            subprocess.run(
                ["git", "rev-parse", "--verify", "master"],
                check=True,
                capture_output=True,
                text=True,
            )
            return "master"
        except subprocess.CalledProcessError:
            print("Neither 'main' nor 'master' branch exists.", file=sys.stderr)
            sys.exit(1)


def main():
    # Get all command line arguments except the script name
    git_args = sys.argv[1:]
    git_projects_workdir = os.getenv("GIT_PROJECTS_WORKDIR")
    if git_projects_workdir is None:
        print("GIT_PROJECTS_WORKDIR environment variable is not set.", file=sys.stderr)
        sys.exit(1)

    match git_args:
        case ["pr", *_]:
            result = subprocess.run(["gh", "pr", "view", "--web"])
            if result.returncode != 0:
                # Run the tests of this repo
                repo_name = Path(os.getcwd()).parts[
                    : len(Path(git_projects_workdir).parts) + 1
                ][-1]
                filtered_repos = list(filter(lambda r: r.name() == repo_name, repos))
                if filtered_repos:
                    start_dir = os.getcwd()
                    repo = filtered_repos[0]
                    os.chdir(repo.path())
                    subprocess.run(repo.unit())
                    os.chdir(start_dir)

                # Create a pr
                result = subprocess.run(
                    ["git-town", "propose"],
                )
        case ["clone", repo_url]:
            repo_name = re.sub(r"\..*$", "", os.path.basename(repo_url))
            clone_path = os.path.join(git_projects_workdir, repo_name)
            subprocess.run(["git", "clone", repo_url, clone_path], check=True)
            if os.path.isdir(clone_path):
                git_branches_path = Path(
                    f"{git_projects_workdir}/dotfiles/config/.git-branches.toml"
                )
                with git_branches_path.open("r") as f:
                    git_branches = toml.loads(f.read())
                os.chdir(clone_path)
                default_branch = get_default_branch()
                git_branches["branches"]["main"] = default_branch
                with open(os.path.join(clone_path, ".git-branches.toml"), "w") as f:
                    toml.dump(git_branches, f)

                subprocess.run(["cursor", "."], check=True)
        case _:
            print("Unrecognized command.", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
