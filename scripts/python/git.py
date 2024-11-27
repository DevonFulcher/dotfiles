import os
from pathlib import Path
import re
import sys
import subprocess
from typing import Literal
import toml
from repos import repos
import argparse


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


def git_save(args: argparse.Namespace) -> None:
    git_add_command = ["git", "add"]
    if args.pathspec:
        git_add_command.extend(args.pathspec)
    else:
        git_add_command.append("-A")
    subprocess.run(git_add_command, check=True)

    git_commit_command = [
        "git",
        "commit",
        "-m",
        args.message,
    ]
    if args.no_verify:
        git_commit_command.append("--no-verify")
    commit_result = subprocess.run(git_commit_command, capture_output=True)
    if commit_result.returncode == 0:
        print("code committed")
    else:
        print(str(commit_result.stderr), file=sys.stderr)

    if not args.no_push:
        git_push_command = ["git", "push"]
        if args.force:
            git_push_command.append("-f")
        push_result = subprocess.run(git_push_command, capture_output=True)
        if push_result.returncode == 0:
            print("commit pushed")
        else:
            print(str(push_result.stderr), file=sys.stderr)
    print("git status:")
    subprocess.run(["git", "status"], check=True)


def create_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Git workflow helper")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # PR command
    subparsers.add_parser("pr", help="Create or view a pull request")

    # Clone command
    clone_parser = subparsers.add_parser("clone", help="Clone a repository")
    clone_parser.add_argument("repo_url", help="URL of the repository to clone")

    # Save command
    save_parser = subparsers.add_parser("save", help="Save and push changes")
    save_parser.add_argument("-m", "--message", required=True, help="Commit message")
    save_parser.add_argument(
        "--no-verify", action="store_true", help="Skip pre-commit hooks"
    )
    save_parser.add_argument("-f", "--force", action="store_true", help="Force push")
    save_parser.add_argument(
        "--no-push", action="store_true", help="Skip pushing changes"
    )
    save_parser.add_argument(
        "pathspec", nargs="*", help="Files to stage (defaults to '-A')"
    )

    # Send command
    send_parser = subparsers.add_parser("send", help="Save changes and create PR")
    send_parser.add_argument(
        "-m", "--message", required=True, help="Commit/branch message"
    )
    send_parser.add_argument(
        "--no-verify", action="store_true", help="Skip pre-commit hooks"
    )
    send_parser.add_argument("-f", "--force", action="store_true", help="Force push")
    send_parser.add_argument(
        "--no-push", action="store_true", help="Skip pushing changes"
    )
    send_parser.add_argument(
        "pathspec", nargs="*", help="Files to stage (defaults to '-A')"
    )

    return parser


def main():
    parser = create_parser()
    args = parser.parse_args()

    git_projects_workdir_env_var = os.getenv("GIT_PROJECTS_WORKDIR")
    if git_projects_workdir_env_var is None:
        print("GIT_PROJECTS_WORKDIR environment variable is not set.", file=sys.stderr)
        sys.exit(1)
    git_projects_workdir = Path(git_projects_workdir_env_var)

    match args.command:
        case "pr":
            git_pr(git_projects_workdir)
        case "clone":
            repo_name = re.sub(r"\..*$", "", os.path.basename(args.repo_url))
            clone_path = os.path.join(git_projects_workdir, repo_name)
            subprocess.run(["git", "clone", args.repo_url, clone_path], check=True)
            if os.path.isdir(clone_path):
                git_branches_path = (
                    git_projects_workdir / "dotfiles/config/.git-branches.toml"
                )
                with git_branches_path.open("r") as f:
                    git_branches = toml.loads(f.read())
                os.chdir(clone_path)
                default_branch = get_default_branch()
                git_branches["branches"]["main"] = default_branch
                with open(os.path.join(clone_path, ".git-branches.toml"), "w") as f:
                    toml.dump(git_branches, f)

                subprocess.run(["cursor", "."], check=True)
        case "save":
            git_save(args)
        case "send":
            branch_name_result = subprocess.run(
                ["git", "rev-parse", "--abbrev-ref", "HEAD"],
                check=True,
                capture_output=True,
            )
            current_branch = str(branch_name_result.stdout).strip()
            default_branch = get_default_branch()
            if default_branch == current_branch:
                new_branch_name = args.message.replace(" ", "_")
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
            git_save(args)
            git_pr(git_projects_workdir)


if __name__ == "__main__":
    main()
