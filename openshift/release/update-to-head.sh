#!/usr/bin/env bash

# Synchs the release-next branch to master and then triggers CI
# Usage: update-to-head.sh

set -ex
REPO_ORG=$(basename $(dirname $(git rev-parse --show-toplevel)))
REPO_NAME=$(basename $(git rev-parse --show-toplevel))

# Reset release-next to upstream/master.
git fetch upstream master
git checkout upstream/master -B release-next

# Update downstream's master and take all needed files from there.
git fetch downstream master # get downstream/master
git checkout downstream/master openshift # extract openshift directory from downstream/master
git mv -f openshift/OWNERS_ALIASES openshift/OWNERS . # (re)place OWNERS* files in the current workspace
git rm -rf openshift/release # remove files unnecessary for release
git add openshift/Dockerfile.tests openshift/Makefile OWNERS_ALIASES OWNERS # add the openshift directory and the OWNERS* to the release-next branch
git commit -m ":open_file_folder: Update openshift specific files." # commit

git push -f downstream release-next # replace downstream/release-next

# Update downstream's master branch
git checkout -B master downstream/master # switch to downstream/master
git reset --hard downstream/master
git rebase upstream/master # rebase downstream/master to master so the openshift directory stay no top of the commits
git push -f downstream master # replace downstream/master with the updated (rebased) one

# Trigger CI
git checkout release-next -B release-next-ci
date > ci
git add ci
git commit -m ":robot: Triggering CI on branch 'release-next' after synching to upstream/master"
git push -f downstream release-next-ci

# Create a PR to trigger the CI
#if hash hub 2>/dev/null; then
#   hub pull-request --no-edit -l "kind/sync-fork-to-upstream" -b ${REPO_ORG}/${REPO_NAME}:release-next -h ${REPO_ORG}/${REPO_NAME}:release-next-ci
#else
#   echo "hub (https://github.com/github/hub) is not installed, so you'll need to create a PR manually."
#fi
