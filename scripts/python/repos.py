from abc import ABC
import os
from pathlib import Path


class Repo(ABC):
    def name() -> str: ...
    def unit() -> list[str]: ...
    def path(self) -> Path:
        git_projects_workdir = os.getenv("GIT_PROJECTS_WORKDIR")
        if git_projects_workdir is None:
            raise ValueError("GIT_PROJECTS_WORKDIR environment variable is not set.")
        return Path(git_projects_workdir) / self.name()


class AiCodegeApi(Repo):
    def name(self) -> str:
        return "ai-codegen-api"

    def unit(self) -> list[str]:
        return ["make", "test"]


repos = [AiCodegeApi()]
