import os
from pathlib import Path
import re
import sys
import subprocess
from typing import Literal
import toml
from repos import repos


def get_default_branch() -> Literal["main", "master"]:
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


def git_pr(git_projects_workdir: Path):
    view_pr = subprocess.run(["gh", "pr", "view", "--web"])
    if view_pr.returncode == 0:
        return

    # Run the tests of this repo
    repo_name = Path(os.getcwd()).parts[: len(git_projects_workdir.parts) + 1][-1]
    filtered_repos = list(filter(lambda r: r.name() == repo_name, repos))
    if filtered_repos:
        start_dir = os.getcwd()
        repo = filtered_repos[0]
        os.chdir(repo.path())
        unit_result = subprocess.run(repo.unit())
        os.chdir(start_dir)
        if unit_result.returncode != 0:
            print(
                "Unit tests failed. Exiting without creating a PR.",
                file=sys.stderr,
            )
            sys.exit(1)

    # Compress the branch
    subprocess.run(["git-town", "compress"], check=True)

    # Create a pr
    subprocess.run(
        ["git-town", "propose"],
    )


def git_save(git_args: list[str]):
    git_save_args = git_args[1:]
    subprocess.run(["git", "add", "-A"], check=True)
    if git_save_args:
        git_commit_command = [
            "git",
            "commit",
            "-m",
            git_save_args[0],
        ]
        flags = git_save_args[1:]
        if "--no-verify" in flags:
            git_commit_command.append("--no-verify")
        commit_result = subprocess.run(git_commit_command, capture_output=True)
        if commit_result.returncode == 0:
            print("code committed")
        else:
            print(str(commit_result.stderr), file=sys.stderr)
    git_push_command = ["git", "push"]
    if "-f" in git_save_args or "--force" in git_save_args:
        git_push_command.append("-f")
    push_result = subprocess.run(git_push_command, capture_output=True)
    if push_result.returncode == 0:
        print("commit pushed")
    else:
        print(str(push_result.stderr), file=sys.stderr)
    print("git status:")
    subprocess.run(["git", "status"], check=True)


def main():
    # Get all command line arguments except the script name
    git_args = sys.argv[1:]
    git_projects_workdir_env_var = os.getenv("GIT_PROJECTS_WORKDIR")
    if git_projects_workdir_env_var is None:
        print("GIT_PROJECTS_WORKDIR environment variable is not set.", file=sys.stderr)
        sys.exit(1)
    git_projects_workdir = Path(git_projects_workdir_env_var)

    match git_args:
        case ["pr", *_]:
            git_pr(git_projects_workdir)
        case ["clone", repo_url]:
            repo_name = re.sub(r"\..*$", "", os.path.basename(repo_url))
            clone_path = os.path.join(git_projects_workdir, repo_name)
            subprocess.run(["git", "clone", repo_url, clone_path], check=True)
            if os.path.isdir(clone_path):
                git_branches_path = (
                    git_projects_workdir / "/dotfiles/config/.git-branches.toml"
                )
                with git_branches_path.open("r") as f:
                    git_branches = toml.loads(f.read())
                os.chdir(clone_path)
                default_branch = get_default_branch()
                git_branches["branches"]["main"] = default_branch
                with open(os.path.join(clone_path, ".git-branches.toml"), "w") as f:
                    toml.dump(git_branches, f)

                subprocess.run(["cursor", "."], check=True)
        case ["save", *_]:
            git_save(git_args)
        case ["send", *_]:
            git_send_args = git_args[1:]
            if not git_send_args:
                print(
                    "Please provide a message as the first argument.", file=sys.stderr
                )
                sys.exit(1)
            branch_name_result = subprocess.run(
                ["git", "rev-parse", "--abbrev-ref", "HEAD"],
                check=True,
                capture_output=True,
            )
            current_branch = str(branch_name_result.stdout).strip()
            default_branch = get_default_branch()
            if default_branch == current_branch:
                new_branch_name = git_send_args[0].replace(" ", "_")
                print(
                    "On a default branch. "
                    + f"Creating a new branch called {new_branch_name}"
                )
                subprocess.run(
                    ["git-town", "append", new_branch_name],
                    check=True,
                )
            else:
                print(
                    "Not on a default branch. "
                    + f"Continuing from this branch: {current_branch}"
                )
            git_save(git_args)
            git_pr(git_projects_workdir)
        case _:
            print("Unrecognized command.", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
