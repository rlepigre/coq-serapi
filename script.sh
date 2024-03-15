#!/bin/bash
set -euo pipefail

BASE="8.19.0+0.19.1"
TAG="8.19.0+0.19.1+bedrock"
REMOTE="rlepigre"
PUSH="true"
FETCH="true"

if [[ "$FETCH" == "true" ]]; then
  git fetch --all
else
  echo "Not fetching any remotes."
fi

REMOTE_URL="$(git remote get-url $REMOTE)"
REMOTE_PATH="${REMOTE_URL#"git@github.com:"}"
REMOTE_PATH="${REMOTE_PATH%".git"}"
if [[ "$REMOTE_URL" != "git@github.com:$REMOTE_PATH.git" ]]; then
  echo "The extracted remote path ($REMOTE_PATH) does not look right."
  exit 1
fi

# Reset to the version tag, to allow re-running the script.
mv script.sh script.sh.backup
git reset --hard "$BASE"
mv script.sh.backup script.sh

# PR 18327: Adapt to coq/coq#18327 (projection opacity).
git cherry-pick 06093b0182389195835797070aae44e9909ff9ce

# Recording the script.
git add script.sh
git commit \
  -m "Cherry-picking script used to create this branch." \
  --author "Rodolphe Lepigre <rodolphe@bedrocksystems.com>"

# Tagging and pushing.
if [[ "$PUSH" != "true" ]]; then
  echo "Skipping the tagging."
  exit 0;
fi

# Tagging and pushing.
git tag -f "$TAG"
git push --force-with-lease --set-upstream "$REMOTE"
git push -f --tags

echo "Sleeping for 10 seconds..."
sleep 10

wget "https://github.com/$REMOTE_PATH/archive/refs/tags/$TAG.tar.gz"

echo "md5=$(md5sum "$TAG.tar.gz" | cut -d' ' -f1)"
echo "sha256=$(sha256sum "$TAG.tar.gz" | cut -d' ' -f1)"
echo "sha512=$(sha512sum "$TAG.tar.gz" | cut -d' ' -f1)"
rm "$TAG.tar.gz"
