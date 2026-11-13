# Automatic package versions

Every push to the repository's **default branch**, including documentation-only
changes, runs the `Package version` GitHub Actions workflow. Pull requests test
the automation without changing versions or tags.

1. Test the version allocator against disposable local Git remotes.
2. Read the current package version and all numeric `vMAJOR.MINOR.PATCH` tags.
3. Allocate the next patch version above the highest tag. An intentionally
   larger version already set in package metadata is honored, so a manual major
   or minor increase remains possible.
4. Update package metadata and prepend `NEWS.md` with recent commit subjects.
5. Create a bot commit and matching annotated tag, then push both **atomically**.
6. Check the exact version commit and build its documentation after checks pass.

Rerunning the same source event reuses its original version and tag. Manually
running the workflow on a bot version commit also reuses that version. Each bot
commit records `Package-Source` and `Package-Version` trailers for this purpose.
The normal `GITHUB_TOKEN` prevents recursive push runs; rerun detection provides
an additional guard. Concurrent writers retry from the latest default branch
without force-pushing or discarding anyone else's commits.

The workflow uses only the repository's built-in `GITHUB_TOKEN`, with
`contents: write` scoped to the version job. If branch rules later prohibit bot
writes, the workflow fails without pushing a partial metadata/tag update.
No extra credentials are required. GitHub release uploads and registry
publication are separate from creating a version tag.

## Making changes

Commit and push changes normally. You do not need to edit the package version
for a patch update. After the workflow succeeds, run `git pull --ff-only` in a
clean checkout to receive its bot commit before starting more work. A source
push does not immediately change the local package version: the increment is
committed by GitHub Actions after that push.

For a deliberate major or minor release, edit the package metadata to a version
higher than all existing numeric release tags, then push it with the changes.
Never manually create the matching tag first; the workflow creates it on the
commit containing the changelog and final metadata.

## Verification and recovery

The README and website status badge follows the `Package version` workflow,
which includes versioning, all platform checks, and documentation deployment.
`R-CMD-check.yaml` is called as a reusable workflow; its standalone badge can
retain an older failed run even after the full package pipeline passes.

The workflow summary identifies the allocated version, tag, and commit. The tag
must resolve to that commit and its package metadata must contain the same
version. If a run fails, fix the reported issue or rerun it. Successful version
allocation is idempotent even when a later package check fails; rerunning does
not allocate another patch just to repeat the check.

Locally test the allocator (standard-library Python only):

```sh
PYTHONDONTWRITEBYTECODE=1 python -m unittest discover -s .github/tests -v
```

The allocator itself must only be run in a clean, disposable checkout: it
switches to a detached copy of the remote default branch, commits metadata, and
pushes. It validates the full input version before changing files and refuses
dirty checkouts or source commits outside the default branch.

## CatMapR details

- Package version: `DESCRIPTION`, `Version:` field.
- Changelog: `NEWS.md`.
- Checks: R CMD check on Linux, macOS, and Windows through the reusable
  `R-CMD-check.yaml` workflow.
- Documentation: reusable `pkgdown.yaml`, using the checked version commit.

This replaces the former tag-only workflow, which incremented tags without
updating DESCRIPTION and allowed the two version numbers to drift apart.
