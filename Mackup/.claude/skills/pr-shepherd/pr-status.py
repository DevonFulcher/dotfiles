#!/usr/bin/env python3
"""pr-status.py — gather open PR data for pr-shepherd using the GitHub API.

Usage: python pr-status.py
Outputs one JSON object per line, one per open PR.
"""

import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request


_TOKEN = None


def get_token():
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        return token
    result = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"Failed to get GitHub token: {result.stderr.strip()}")
    return result.stdout.strip()


def _headers():
    global _TOKEN
    if _TOKEN is None:
        _TOKEN = get_token()
    return {
        "Authorization": f"Bearer {_TOKEN}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }


def rest(path):
    url = f"https://api.github.com/{path.lstrip('/')}"
    req = urllib.request.Request(url, headers=_headers())
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"GET {url} failed {e.code}: {e.read().decode()}")


def rest_paginated(path):
    results = []
    url = f"https://api.github.com/{path.lstrip('/')}"
    while url:
        req = urllib.request.Request(url, headers=_headers())
        try:
            with urllib.request.urlopen(req) as resp:
                data = json.loads(resp.read())
                results.extend(data if isinstance(data, list) else [data])
                link = resp.headers.get("Link", "")
                url = None
                for part in link.split(","):
                    if 'rel="next"' in part:
                        m = re.search(r"<([^>]+)>", part)
                        if m:
                            url = m.group(1)
        except urllib.error.HTTPError as e:
            raise RuntimeError(f"GET {url} failed {e.code}: {e.read().decode()}")
    return results


def graphql(query, **variables):
    payload = json.dumps({"query": query, "variables": variables}).encode()
    headers = {**_headers(), "Content-Type": "application/json"}
    req = urllib.request.Request(
        "https://api.github.com/graphql", data=payload, headers=headers, method="POST"
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"GraphQL query failed {e.code}: {e.read().decode()}")


def get_review_threads(owner, repo, number):
    data = graphql(
        """
        query($owner: String!, $repo: String!, $number: Int!) {
          repository(owner: $owner, name: $repo) {
            pullRequest(number: $number) {
              reviewThreads(first: 50) {
                nodes { id isResolved isOutdated }
              }
            }
          }
        }
        """,
        owner=owner,
        repo=repo,
        number=number,
    )
    return (
        data.get("data", {})
        .get("repository", {})
        .get("pullRequest", {})
        .get("reviewThreads", {})
        .get("nodes", [])
    )


def get_checks(repo_full, head_sha):
    data = rest(f"repos/{repo_full}/commits/{head_sha}/check-runs?per_page=100")
    runs = data.get("check_runs", []) if isinstance(data, dict) else data
    return [
        {
            "name": c["name"],
            "state": c["status"],
            "conclusion": c.get("conclusion"),
            "link": c.get("html_url", ""),
        }
        for c in runs
    ]


def main():
    result = rest("search/issues?q=is:pr+is:open+author:@me&per_page=50")
    if not result.get("items"):
        print("No open PRs found.", file=sys.stderr)
        return
    prs = result["items"]

    for pr in prs:
        repo_url = pr.get("repository_url", "")
        repo_full = "/".join(repo_url.split("/")[-2:])
        number = pr["number"]
        owner, repo = repo_full.split("/", 1)

        repo_info = rest(f"repos/{repo_full}")
        if repo_info.get("archived"):
            continue

        pr_detail = rest(f"repos/{repo_full}/pulls/{number}")
        head_sha = pr_detail.get("head", {}).get("sha", "")

        review_comments = rest_paginated(f"repos/{repo_full}/pulls/{number}/comments?per_page=100")
        review_comments = [
            {"id": c["id"], "node_id": c["node_id"], "user": c["user"]["login"], "body": c["body"][:300], "path": c.get("path")}
            for c in review_comments
        ]

        issue_comments = rest_paginated(f"repos/{repo_full}/issues/{number}/comments?per_page=100")
        issue_comments = [
            {"id": c["id"], "user": c["user"]["login"], "body": c["body"][:300]}
            for c in issue_comments
        ]

        review_threads = get_review_threads(owner, repo, number)
        checks = get_checks(repo_full, head_sha) if head_sha else []

        reviews = rest_paginated(f"repos/{repo_full}/pulls/{number}/reviews?per_page=100")
        reviews = [
            {"user": r["user"]["login"], "state": r["state"], "submitted_at": r["submitted_at"]}
            for r in reviews
        ]

        print(json.dumps({
            "owner": owner,
            "repo": repo,
            "repo_full": repo_full,
            "number": number,
            "title": pr["title"],
            "url": pr.get("html_url", ""),
            "is_draft": pr.get("draft", False),
            "mergeable": pr_detail.get("mergeable") or "UNKNOWN",
            "review_comments": review_comments,
            "issue_comments": issue_comments,
            "review_threads": review_threads,
            "checks": checks,
            "reviews": reviews,
        }))


if __name__ == "__main__":
    main()
