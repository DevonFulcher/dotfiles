#!/usr/bin/env python3
"""pr-status.py — gather PR data for pr-shepherd using the GitHub API.

Usage: python pr-status.py <pr-url>
  pr-url: GitHub PR URL, e.g. https://github.com/owner/repo/pull/123

Outputs one JSON object with all PR data.
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
    body = json.dumps({"query": query, "variables": variables}).encode()
    headers = {**_headers(), "Content-Type": "application/json"}
    req = urllib.request.Request(
        "https://api.github.com/graphql", data=body, headers=headers, method="POST"
    )
    try:
        with urllib.request.urlopen(req) as resp:
            payload = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"GraphQL query failed {e.code}: {e.read().decode()}")
    errs = payload.get("errors")
    if errs:
        raise RuntimeError("GraphQL errors: " + json.dumps(errs))
    return payload


def get_review_threads(owner, repo, number):
    data = graphql(
        """
        query($owner: String!, $repo: String!, $number: Int!) {
          repository(owner: $owner, name: $repo) {
            pullRequest(number: $number) {
              reviewThreads(first: 50) {
                nodes {
                  id
                  isResolved
                  isOutdated
                  comments(first: 100) {
                    nodes {
                      fullDatabaseId
                      author {
                        login
                      }
                      replyTo {
                        id
                      }
                    }
                  }
                }
              }
            }
          }
        }
        """,
        owner=owner,
        repo=repo,
        number=number,
    )
    raw = (
        data.get("data", {})
        .get("repository", {})
        .get("pullRequest", {})
        .get("reviewThreads", {})
        .get("nodes", [])
    )
    out = []
    for node in raw:
        comments = (node.get("comments") or {}).get("nodes") or []
        # REST GET .../pulls/comments/:comment_id uses the same numeric id as GraphQL fullDatabaseId
        comment_summaries = []
        root = {}
        for c in comments:
            if not c:
                continue
            aid = c.get("author") or {}
            login = aid.get("login") if isinstance(aid, dict) else None
            raw_id = c.get("fullDatabaseId")
            if raw_id is None:
                continue
            dbid = int(raw_id)
            is_root = not c.get("replyTo")
            entry = {"id": dbid, "user": login}
            comment_summaries.append(entry)
            if is_root and not root:
                root = entry
        if not root and comment_summaries:
            root = comment_summaries[0]
        out.append(
            {
                "id": node.get("id"),
                "isResolved": node.get("isResolved"),
                "isOutdated": node.get("isOutdated"),
                "comments": comment_summaries,
                "root_comment_id": root.get("id"),
                "root_author": root.get("user"),
            }
        )
    return out


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


def parse_pr_url(url):
    """Parse a GitHub PR URL and return (owner, repo, number)."""
    m = re.match(r"https?://github\.com/([^/]+)/([^/]+)/pull/(\d+)", url.strip())
    if not m:
        raise ValueError(f"Invalid GitHub PR URL: {url!r}\nExpected format: https://github.com/owner/repo/pull/123")
    return m.group(1), m.group(2), int(m.group(3))


def fetch_pr(owner, repo, number):
    repo_full = f"{owner}/{repo}"

    repo_info = rest(f"repos/{repo_full}")
    if repo_info.get("archived"):
        print(f"Repository {repo_full} is archived.", file=sys.stderr)
        sys.exit(1)

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
        "title": pr_detail["title"],
        "url": pr_detail.get("html_url", ""),
        "is_draft": pr_detail.get("draft", False),
        "mergeable": pr_detail.get("mergeable") or "UNKNOWN",
        "review_comments": review_comments,
        "issue_comments": issue_comments,
        "review_threads": review_threads,
        "checks": checks,
        "reviews": reviews,
    }))


def main():
    if len(sys.argv) < 2 or not sys.argv[1].strip():
        print("Usage: python pr-status.py <pr-url>", file=sys.stderr)
        print("Example: python pr-status.py https://github.com/owner/repo/pull/123", file=sys.stderr)
        sys.exit(1)

    pr_url = sys.argv[1].strip()
    owner, repo, number = parse_pr_url(pr_url)
    fetch_pr(owner, repo, number)


if __name__ == "__main__":
    main()
