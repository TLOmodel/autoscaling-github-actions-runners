#!/bin/bash

# Make script more robust
set -Eeuxo pipefail
# `*` glob character matches hidden files too.
shopt -s dotglob nullglob

# We have a somewhat recent checkout of the repository in `/git/repository`, with all the
# LFS objects already fetched.  Before starting the job we move it to the runner workspace,
# so that we don't need to clone it and fetch the LFS objects every time.
mv -v /git/repository/* "${GITHUB_WORKSPACE}"/.
