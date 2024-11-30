import os
from pathlib import Path
import re
import sys
import subprocess
from typing import Literal
import toml
from repos import current_repo, repos, current_repo_name
import argparse
from env_var import get_git_projects_workdir


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


def get_current_branch_name() -> str:
    return subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


def git_pr():
    view_pr = subprocess.run(["gh", "pr", "view", "--web"])
    if view_pr.returncode == 0:
        return
    current_repo().unit()
    subprocess.run(["git-town", "compress"])
    subprocess.run(
        ["git-town", "propose"],
    )


def git_save(args: argparse.Namespace) -> None:
    current_org = os.getenv("CURRENT_ORG")
    if current_org:
        current_branch = get_current_branch_name()
        default_branch = get_default_branch()
        remote_url = subprocess.run(
            ["git", "remote", "get-url", "origin"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        # Extract org from GitHub URL (handles both HTTPS and SSH formats)
        org_match = re.search(r"[:/]([^/]+)/[^/]+$", remote_url)
        if (
            org_match
            and org_match.group(1) == current_org.replace("_", "-")
            and current_branch == default_branch
        ):
            print(
                "Cannot commit to the default branch"
                + " for a repo of the current organization.",
                file=sys.stderr,
            )
            sys.exit(1)

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

    git_projects_workdir = get_git_projects_workdir()

    match args.command:
        case "pr":
            git_pr()
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
            current_branch = get_current_branch_name()
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
            git_pr()


if __name__ == "__main__":
    main()
