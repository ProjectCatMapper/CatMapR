"""Exercise version automation against temporary local Git remotes."""

from contextlib import contextmanager
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "version_package.py"
spec = importlib.util.spec_from_file_location("version_package", SCRIPT)
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


def git_at(cwd, *args):
    return subprocess.run(["git", "-C", str(cwd), *args], check=True,
                          capture_output=True, text=True).stdout.strip()


@contextmanager
def working_directory(path):
    previous = Path.cwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(previous)


class VersionAutomationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.remote = self.root / "origin.git"
        self.repo = self.root / "checkout"
        git_at(self.root, "init", "--bare", "--initial-branch=main", str(self.remote))
        git_at(self.root, "clone", str(self.remote), str(self.repo))
        git_at(self.repo, "config", "user.name", "Test Author")
        git_at(self.repo, "config", "user.email", "test@example.invalid")

    def seed(self, kind="r", version=None, tag=None):
        version = version or ("0.1.19" if kind == "r" else "0.1.1")
        if kind == "r":
            (self.repo / "DESCRIPTION").write_text(f"Package: CatMapR\nVersion: {version}\nTitle: Test\n")
        else:
            (self.repo / "pyproject.toml").write_text(
                f'[project]\nname = "catmappy"\nversion = "{version}"\n\n[tool.example]\nversion = "9.0.0"\n')
            (self.repo / "docs").mkdir()
            (self.repo / "docs/release-notes.md").write_text("old notes\n")
        (self.repo / "NEWS.md").write_text("old notes\n")
        git_at(self.repo, "add", ".")
        git_at(self.repo, "commit", "-m", "Initial package")
        if tag is not False:
            git_at(self.repo, "tag", tag or f"v{version}")
        (self.repo / "change.txt").write_text("feature\n")
        git_at(self.repo, "add", ".")
        git_at(self.repo, "commit", "-m", "Add a feature")
        git_at(self.repo, "push", "origin", "main", "--tags")
        return git_at(self.repo, "rev-parse", "HEAD")

    def bump(self, source, **kwargs):
        with working_directory(self.repo):
            return release.bump("main", source, **kwargs)

    def remote_tip(self):
        return git_at(self.remote, "rev-parse", "main")

    def test_r_metadata_changelog_and_tag_move_together(self):
        source = self.seed()
        result = self.bump(source)
        self.assertEqual(result["version"], "0.1.20")
        self.assertEqual(result["commit"], self.remote_tip())
        self.assertEqual(git_at(self.remote, "rev-parse", "v0.1.20^{commit}"), result["commit"])
        self.assertIn("Version: 0.1.20", git_at(self.remote, "show", "main:DESCRIPTION"))
        notes = git_at(self.remote, "show", "main:NEWS.md")
        self.assertIn("# CatMapR 0.1.20", notes)
        self.assertIn("- Add a feature", notes)
        self.assertIn(source, notes)
        self.assertIn("old notes", notes)

    def test_python_changes_only_project_version_and_synchronizes_notes(self):
        source = self.seed("python")
        result = self.bump(source)
        self.assertEqual(result["version"], "0.1.2")
        project = git_at(self.remote, "show", "main:pyproject.toml")
        self.assertIn('version = "0.1.2"', project)
        self.assertIn('[tool.example]\nversion = "9.0.0"', project)
        self.assertEqual(git_at(self.remote, "show", "main:NEWS.md"),
                         git_at(self.remote, "show", "main:docs/release-notes.md"))

    def test_rerun_and_manual_dispatch_do_not_create_extra_versions(self):
        source = self.seed()
        first = self.bump(source)
        second = self.bump(source)
        manual = self.bump(first["commit"])
        self.assertEqual(first["commit"], second["commit"])
        self.assertEqual(first["commit"], manual["commit"])
        self.assertEqual(second["changed"], "false")
        self.assertEqual(manual["changed"], "false")
        self.assertEqual(git_at(self.remote, "tag", "--list").splitlines(), ["v0.1.19", "v0.1.20"])

    def test_old_event_rerun_after_a_new_release_keeps_original_version(self):
        source = self.seed()
        first = self.bump(source)
        git_at(self.repo, "switch", "-C", "main", "origin/main")
        (self.repo / "change.txt").write_text("another feature\n")
        git_at(self.repo, "commit", "-am", "Another feature")
        next_source = git_at(self.repo, "rev-parse", "HEAD")
        git_at(self.repo, "push", "origin", "main")
        second = self.bump(next_source)
        rerun = self.bump(source)
        self.assertEqual(second["version"], "0.1.21")
        self.assertEqual(rerun["commit"], first["commit"])
        self.assertEqual(self.remote_tip(), second["commit"])

    def test_recovers_stale_metadata_above_existing_tags(self):
        source = self.seed(version="0.1.15", tag="v0.1.19")
        self.assertEqual(self.bump(source)["version"], "0.1.20")

    def test_honors_deliberate_larger_version(self):
        source = self.seed(version="1.0.0", tag="v0.1.19")
        self.assertEqual(self.bump(source)["version"], "1.0.0")

    def test_first_push_without_tags_increases_package_version(self):
        source = self.seed(tag=False)
        self.assertEqual(self.bump(source)["version"], "0.1.20")

    def test_dirty_checkout_and_invalid_metadata_do_not_change_remote(self):
        source = self.seed()
        (self.repo / "untracked.txt").write_text("preserve me")
        with self.assertRaisesRegex(ValueError, "clean checkout"):
            self.bump(source)
        self.assertEqual(self.remote_tip(), source)
        (self.repo / "untracked.txt").unlink()
        (self.repo / "DESCRIPTION").write_text("Package: CatMapR\nVersion: invalid\n")
        git_at(self.repo, "commit", "-am", "Invalid version")
        invalid = git_at(self.repo, "rev-parse", "HEAD")
        git_at(self.repo, "push", "origin", "main")
        with self.assertRaisesRegex(ValueError, "three-part"):
            self.bump(invalid)
        self.assertEqual(self.remote_tip(), invalid)
        self.assertEqual(git_at(self.repo, "status", "--porcelain"), "")

    def test_push_rejection_never_leaves_a_remote_tag_without_metadata(self):
        source = self.seed()
        real_git = release.git

        def reject_push(*args, **kwargs):
            if args[0] == "push":
                self.assertIn("--atomic", args)
                return subprocess.CompletedProcess(args, 1, "", "rejected")
            return real_git(*args, **kwargs)

        with patch.object(release, "git", side_effect=reject_push), patch.object(release.time, "sleep"):
            with self.assertRaisesRegex(RuntimeError, "Atomic version push failed"):
                self.bump(source, attempts=2)
        self.assertEqual(self.remote_tip(), source)
        self.assertEqual(git_at(self.remote, "tag", "--list"), "v0.1.19")

    def test_concurrent_writer_is_preserved_and_retried(self):
        source = self.seed()
        racer = self.root / "racer"
        git_at(self.root, "clone", str(self.remote), str(racer))
        git_at(racer, "config", "user.name", "Concurrent Author")
        git_at(racer, "config", "user.email", "test@example.invalid")
        real_git = release.git
        raced = False

        def race_push(*args, **kwargs):
            nonlocal raced
            if args[0] == "push" and not raced:
                raced = True
                (racer / "concurrent.txt").write_text("keep concurrent update\n")
                git_at(racer, "add", ".")
                git_at(racer, "commit", "-m", "Concurrent update")
                git_at(racer, "push", "origin", "main")
                rejected = real_git(*args, **kwargs)
                self.assertNotEqual(rejected.returncode, 0)
                self.assertEqual(git_at(self.remote, "tag", "--list"), "v0.1.19")
                return rejected
            return real_git(*args, **kwargs)

        with patch.object(release, "git", side_effect=race_push), patch.object(release.time, "sleep"):
            result = self.bump(source)
        self.assertTrue(raced)
        self.assertEqual(result["version"], "0.1.20")
        self.assertEqual(git_at(self.remote, "show", "main:concurrent.txt"), "keep concurrent update")

    def test_cli_emits_outputs_and_rerun_is_safe(self):
        source = self.seed("python")
        output = self.root / "outputs"
        env = dict(os.environ, GITHUB_OUTPUT=str(output), PYTHONDONTWRITEBYTECODE="1")
        for _ in range(2):
            subprocess.run(["python", str(SCRIPT), "--branch", "main", "--source", source],
                           cwd=self.repo, env=env, check=True, capture_output=True, text=True)
        lines = output.read_text().splitlines()
        self.assertIn("version=0.1.2", lines)
        self.assertIn("changed=true", lines)
        self.assertIn("changed=false", lines)

    def test_successful_push_with_lost_acknowledgment_is_not_bumped_again(self):
        source = self.seed()
        real_git = release.git

        def lose_ack(*args, **kwargs):
            result = real_git(*args, **kwargs)
            if args[0] == "push":
                self.assertEqual(result.returncode, 0)
                return subprocess.CompletedProcess(args, 1, "", "connection lost after push")
            return result

        with patch.object(release, "git", side_effect=lose_ack):
            result = self.bump(source, attempts=1)
        self.assertEqual(result["version"], "0.1.20")
        self.assertEqual(result["commit"], self.remote_tip())
        self.assertEqual(git_at(self.remote, "tag", "--list").splitlines(), ["v0.1.19", "v0.1.20"])

    def race_same_event(self, distinct_commits):
        source = self.seed()
        racer = self.root / "racer"
        git_at(self.root, "clone", str(self.remote), str(racer))
        real_git = release.git
        raced = False

        def race_push(*args, **kwargs):
            nonlocal raced
            if args[0] == "push" and not raced:
                raced = True
                env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")
                if distinct_commits:
                    # Git stores timestamps at one-second resolution. Force
                    # distinct objects rather than depending on runner speed.
                    env.update(GIT_AUTHOR_DATE="2000-01-01T00:00:00+00:00",
                               GIT_COMMITTER_DATE="2000-01-01T00:00:00+00:00")
                subprocess.run(["python", str(SCRIPT), "--branch", "main", "--source", source],
                               cwd=racer, env=env, check=True, capture_output=True, text=True)
            return real_git(*args, **kwargs)

        with patch.object(release, "git", side_effect=race_push), patch.object(release.time, "sleep"):
            result = self.bump(source)
        self.assertEqual(result["commit"], self.remote_tip())
        self.assertEqual(git_at(self.remote, "tag", "--list").splitlines(), ["v0.1.19", "v0.1.20"])
        return result

    def test_concurrent_rerun_of_same_event_creates_only_one_version(self):
        with patch.dict(os.environ, GIT_AUTHOR_DATE="2001-01-01T00:00:00+00:00",
                        GIT_COMMITTER_DATE="2001-01-01T00:00:00+00:00"):
            result = self.race_same_event(distinct_commits=True)
        self.assertEqual(result["changed"], "false")

    def test_identical_competing_commits_are_a_successful_noop_push(self):
        with patch.dict(os.environ, GIT_AUTHOR_DATE="2000-01-01T00:00:00+00:00",
                        GIT_COMMITTER_DATE="2000-01-01T00:00:00+00:00"):
            result = self.race_same_event(distinct_commits=False)
        self.assertEqual(result["changed"], "true")


if __name__ == "__main__":
    unittest.main()
