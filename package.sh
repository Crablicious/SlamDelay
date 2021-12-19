#!/usr/bin/env bash

# Create a release tag first and push it. Then make a release and run
# ./package.sh to create the zip-release.
# git tag v0.0.5
# git push --tags

version=`git tag | tail -n 1`

zip_cmd="zip SlamDelay-${version}-bcc.zip"

for f in `git ls-files | grep SlamDelay/`
do
    zip_cmd="${zip_cmd} ${f}"
done

eval $zip_cmd
