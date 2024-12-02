from abc import ABC, abstractmethod
import argparse
import os
from pathlib import Path
import subprocess
from env_var import get_git_projects_workdir


class Repo(ABC):
    @abstractmethod
    def name() -> str: ...
    @abstractmethod
    def unit_cmd() -> list[str]: ...
    @abstractmethod
    def run_cmd() -> list[str]: ...

    def _run(self, cmd: list[str]) -> None:
        os.chdir(self.path())
        subprocess.run(cmd, check=True)

    def run(self) -> None:
        self._run(self.run_cmd())

    def unit(self) -> None:
        self._run(self.unit_cmd())

    def path(self) -> Path:
        git_projects_workdir = os.getenv("GIT_PROJECTS_WORKDIR")
        if git_projects_workdir is None:
            raise ValueError("GIT_PROJECTS_WORKDIR environment variable is not set.")
        return Path(git_projects_workdir) / self.name()


class AiCodegeApi(Repo):
    def name(self) -> str:
        return "ai-codegen-api"

    def unit_cmd(self) -> list[str]:
        return ["make", "test"]

    def run_cmd(self) -> list[str]:
        return ["make", "dev"]


repos = [AiCodegeApi()]


def current_repo_name() -> str:
    git_projects_workdir = get_git_projects_workdir()
    return Path(os.getcwd()).parts[: len(git_projects_workdir.parts) + 1][-1]


def current_repo() -> Repo | None:
    repo_name = current_repo_name()
    filtered_repos = list(filter(lambda r: r.name() == repo_name, repos))
    if not filtered_repos:
        return None
    if len(filtered_repos) != 1:
        raise ValueError("Unexpected result for repo search")
    return filtered_repos[0]


def main():
    parser = argparse.ArgumentParser(description="Repo-specific common dev tasks.")
    parser.add_argument("task", help="The task to complete for this repo.")
    args = parser.parse_args()
    repo = current_repo()
    match args.task:
        case "unit":
            repo.unit()
        case "run":
            repo.run()
        case _:
            raise ValueError("Unrecognized dev task")


if __name__ == "__main__":
    main()
