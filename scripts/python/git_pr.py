from dataclasses import dataclass
import datetime
import logging
import os
import yaml
import subprocess
import json

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)

CACHE_DIR = "~/.cache/git-helper"
PR_FILE = "pr.yaml"


@dataclass
class PrInfo:
    id: str
    title: str
    description: str
    reviewers: list[str]
    base_branch: str
    is_draft: bool


def store_pr_info(pr_info: PrInfo):
    cache_dir = os.path.expanduser(CACHE_DIR)
    os.makedirs(cache_dir, exist_ok=True, parents=True)
    pr_file = os.path.join(cache_dir, PR_FILE)
    existing_data = []
    if os.path.exists(pr_file):
        with open(pr_file, "r") as f:
            try:
                existing_data = yaml.safe_load(f) or []
                if not isinstance(existing_data, list):
                    existing_data = [existing_data]
            except yaml.YAMLError:
                existing_data = []
    existing_data.append(
        {
            "timestamp": datetime.now().isoformat(),
            "id": pr_info.id,
            "pr_title": pr_info.title,
            "pr_description": pr_info.description,
            "pr_reviewers": pr_info.reviewers,
            "base_branch": pr_info.base_branch,
            "is_draft": pr_info.is_draft,
        }
    )
    with open(pr_file, "w") as f:
        yaml.dump(existing_data, f)


def read_pr_info() -> list[PrInfo]:
    cache_dir = os.path.expanduser(CACHE_DIR)
    pr_file = os.path.join(cache_dir, PR_FILE)

    if not os.path.exists(pr_file):
        logging.info("No PR file found")
        return []

    try:
        with open(pr_file, "r") as f:
            data = yaml.safe_load(f) or []
            if not isinstance(data, list):
                data = [data]
        return data
    except yaml.YAMLError as e:
        logging.error(f"Error reading PR file: {e}")
        return []


def get_pr_info_from_gh(pr_id: str) -> PrInfo | None:
    result = subprocess.run(
        [
            "gh",
            "pr",
            "list",
            "--search",
            f'"id:{pr_id}"',
            "--author",
            "@me",
            "--json",
            "title,body,reviewers,baseRefName,isDraft",
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    prs = json.loads(result.stdout)
    if not prs:
        logging.info(f"No PR found with id: {pr_id}")
        return None
    if len(prs) > 1:
        logging.error(f"Found multiple PRs with id: {pr_id}")
        return None
    pr = prs[0]
    return PrInfo(
        id=pr_id,
        title=pr["title"],
        description=pr["body"],
        reviewers=pr["reviewers"],
        base_branch=pr["baseRefName"],
        is_draft=pr["isDraft"],
    )


def create_draft_pr(pr: PrInfo) -> bool:
    try:
        pr_full_title = f"id:{pr.id} {pr.title}"
        subprocess.run(
            [
                "gh",
                "pr",
                "create",
                "--title",
                f'"{pr_full_title}"',
                "--body",
                f'"{pr.description}"',
                "--assignee",
                '"@me"',
                "--base",
                pr.base_branch,
                "--draft",
            ],
            check=True,
        )
        logging.info(f"Created draft PR: {pr_full_title}")
        return True

    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to create PR: {e}")
        return False


def process_prs(prs: list[PrInfo]):
    if not prs:
        logging.info("No PRs found.")
        return

    logging.info(f"Found {len(prs)} PRs.")
    for pr in prs:
        logging.info(f"Processing PR: {pr.id} {pr.title}")
        existing_pr = get_pr_info_from_gh(pr.id)
        if existing_pr:
            if existing_pr.is_draft:
                logging.info("PR already exists and is a draft")
            else:
                pass
        else:
            if create_draft_pr(pr):
                logging.info("Successfully created draft PR")

