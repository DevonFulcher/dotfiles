from abc import ABC, abstractmethod
import os
from pathlib import Path
import subprocess
import sys

from env_var import get_git_projects_workdir


class Repo(ABC):
    @abstractmethod
    def name() -> str: ...
    @abstractmethod
    def unit_cmd() -> list[str]: ...

    def unit(self) -> None:
        os.chdir(self.path())
        subprocess.run(self.unit_cmd(), check=True)

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


repos = [AiCodegeApi()]


def current_repo_name() -> str:
    git_projects_workdir = get_git_projects_workdir()
    return Path(os.getcwd()).parts[: len(git_projects_workdir.parts) + 1][-1]


def current_repo() -> Repo:
    repo_name = current_repo_name()
    filtered_repos = list(filter(lambda r: r.name() == repo_name, repos))
    if len(filtered_repos) != 1:
        raise ValueError("Unexpected result for repo search")
    return filtered_repos[0]
