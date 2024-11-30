import os
from pathlib import Path
import sys


def get_env_var_or_exit(env_var_name: str) -> str:
    env_var = os.getenv(env_var_name)
    if env_var is None:
        print(f"{env_var_name} environment variable is not set.", file=sys.stderr)
        sys.exit(1)
    return env_var


def get_git_projects_workdir() -> Path:
    return Path(get_env_var_or_exit("GIT_PROJECTS_WORKDIR"))
