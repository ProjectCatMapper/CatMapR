"""Keep package metadata, changelog and tags aligned after default-branch pushes.

Standard-library-only automation, shared verbatim by CatMapR and CatMapPy.
Only run in a clean, disposable checkout with permission to push to origin.
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import subprocess
import time


VERSION = re.compile(r"(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)")


def git(*args: str, check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(["git", *args], text=True, capture_output=True, check=check)


def version_tuple(value: str) -> tuple[int, int, int]:
    if not VERSION.fullmatch(value):
        raise ValueError(f"Expected a three-part numeric package version, got {value!r}.")
    return tuple(map(int, value.split(".")))


def metadata() -> tuple[str, Path, str, re.Pattern]:
    if Path("DESCRIPTION").is_file():
        path = Path("DESCRIPTION")
        pattern = re.compile(r"^(Version:\s*)([^\r\n]+)$", re.MULTILINE)
        package = re.search(r"^Package:\s*(\S+)$", path.read_text(), re.MULTILINE)
        if not package:
            raise ValueError("DESCRIPTION must contain a Package field.")
        name = package[1]
    else:
        path = Path("pyproject.toml")
        # Limit the version match to [project], excluding build/tool tables.
        pattern = re.compile(r'(^\[project\]\s*\n(?:(?!^\[).)*?^version\s*=\s*")([^"\r\n]+)("[^\r\n]*$)',
                             re.MULTILINE | re.DOTALL)
        name = "CatMapPy"
    text = path.read_text()
    matches = list(pattern.finditer(text))
    if len(matches) != 1:
        raise ValueError(f"{path} must contain exactly one package version.")
    version_tuple(matches[0][2])
    return name, path, text, pattern


def existing_result(commit: str) -> dict[str, str]:
    _name, path, _text, pattern = metadata()
    text = git("show", f"{commit}:{path.as_posix()}").stdout
    version = pattern.search(text)[2]
    tag = f"v{version}"
    tagged = git("rev-parse", "--verify", f"refs/tags/{tag}^{{commit}}", check=False)
    if tagged.returncode or tagged.stdout.strip() != commit:
        raise ValueError("An automatic version commit has a missing or mismatched tag.")
    return {"commit": commit, "version": version, "tag": tag, "changed": "false"}


def release_for_source(source: str) -> str | None:
    # A rerun of the original event must find that event's release even when
    # subsequent pushes have already produced newer releases.
    candidates = git("log", "--format=%H", "--fixed-strings",
                     f"--grep=Package-Source: {source}", "HEAD").stdout.splitlines()
    for commit in candidates:
        body = git("show", "-s", "--format=%B", commit).stdout.splitlines()
        if f"Package-Source: {source}" in body and any(line.startswith("Package-Version: ") for line in body):
            return commit
    # Manual dispatch on an automation-created commit should also be a no-op.
    body = git("show", "-s", "--format=%B", source).stdout.splitlines()
    if any(line.startswith("Package-Version: ") for line in body) and any(line.startswith("Package-Source: ") for line in body):
        return source
    return None


def prepare_version(source: str) -> tuple[str, list[str]]:
    name, path, text, pattern = metadata()
    current = version_tuple(pattern.search(text)[2])
    tags = []
    for tag in git("tag", "--list", "v*").stdout.splitlines():
        if VERSION.fullmatch(tag[1:]):
            tags.append((version_tuple(tag[1:]), tag))
    latest, latest_tag = max(tags) if tags else (current, None)
    # Honor an intentional larger major/minor/patch change. Otherwise allocate
    # the next patch above all existing releases, including historical drift.
    next_version = current if current > latest else (latest[0], latest[1], latest[2] + 1)
    version = ".".join(map(str, next_version))
    match = pattern.search(text)
    updated = text[:match.start(2)] + version + text[match.end(2):]
    news = Path("NEWS.md")
    old_news = news.read_text() if news.exists() else ""
    revisions = f"{latest_tag}..HEAD" if latest_tag else "HEAD"
    subjects = git("log", "--first-parent", "--format=%s", "-20", revisions).stdout.splitlines()
    subjects = [subject for subject in subjects if not subject.startswith("chore(release): ")]
    entry = f"# {name} {version}\n\n" + "".join(f"- {subject}\n" for subject in subjects)
    entry += f"\nAutomatic version update for source commit `{source}`.\n\n"
    # Compute/validate every file before writing any of them.
    updates = {path: updated, news: entry + old_news}
    if name == "CatMapPy" and Path("docs/release-notes.md").is_file():
        updates[Path("docs/release-notes.md")] = entry + old_news
    for target, content in updates.items():
        target.write_text(content)
    return version, [target.as_posix() for target in updates]


def bump(branch: str, source: str, attempts: int = 5) -> dict[str, str]:
    git("check-ref-format", "--branch", branch)
    if git("status", "--porcelain").stdout.strip():
        raise ValueError("Automatic version updates require a clean checkout.")
    source = git("rev-parse", "--verify", f"{source}^{{commit}}").stdout.strip()
    for attempt in range(attempts):
        git("fetch", "origin", f"+refs/heads/{branch}:refs/remotes/origin/{branch}", "--tags")
        git("switch", "--detach", f"refs/remotes/origin/{branch}")
        if git("merge-base", "--is-ancestor", source, "HEAD", check=False).returncode:
            raise ValueError("The triggering source is not on the current default branch.")
        previous = release_for_source(source)
        if previous:
            return existing_result(previous)
        version, paths = prepare_version(source)
        git("add", "--", *paths)
        git("-c", "user.name=github-actions[bot]", "-c",
            "user.email=41898282+github-actions[bot]@users.noreply.github.com",
            "-c", "commit.gpgsign=false", "commit", "-m", f"chore(release): {version}",
            "-m", f"Package-Version: {version}\nPackage-Source: {source}")
        commit = git("rev-parse", "HEAD").stdout.strip()
        tag = f"v{version}"
        git("-c", "user.name=github-actions[bot]", "-c",
            "user.email=41898282+github-actions[bot]@users.noreply.github.com",
            "-c", "tag.gpgsign=false", "tag", "-a", tag, "-m", f"Release {version}")
        pushed = git("push", "--atomic", "origin", f"HEAD:refs/heads/{branch}", f"refs/tags/{tag}", check=False)
        if not pushed.returncode:
            return {"commit": commit, "version": version, "tag": tag, "changed": "true"}
        # A transport error can follow a successful push. Fetch its refs before
        # retrying, so a rerun finds the recorded source and never bumps twice.
        git("tag", "-d", tag)
        if attempt + 1 < attempts:
            time.sleep(attempt + 1)
        else:
            git("fetch", "origin", f"+refs/heads/{branch}:refs/remotes/origin/{branch}", "--tags")
            git("switch", "--detach", f"refs/remotes/origin/{branch}")
            previous = release_for_source(source)
            if previous:
                return existing_result(previous)
    raise RuntimeError("Atomic version push failed after retries; check branch permissions and remote availability.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--branch", required=True)
    parser.add_argument("--source", required=True)
    args = parser.parse_args()
    result = bump(args.branch, args.source)
    output = "".join(f"{key}={value}\n" for key, value in result.items())
    if os.getenv("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a") as handle:
            handle.write(output)
    print(output, end="")


if __name__ == "__main__":
    main()
