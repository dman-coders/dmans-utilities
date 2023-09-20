#!/usr/bin/env bash

# Usage:
# 	./git-extract.sh git@repo_site.com:/my_repo.git origin/folder/customlib/ customlib
#
# This will take the named folder from within a git repo, bringing history,
# and set up a newly inited repo for it, stand-alone.
#
# Used for converting a monolith project - like a Drupal that has a lot of custom modules
# Into one that can be managed with composer ot submodules by spawning that branch into a
# project of its own/
#
# http://stackoverflow.com/questions/359424/detach-subdirectory-into-separate-git-repository


repo=$1
folder=$2
newproject=$3

git clone --no-hardlinks $repo $newproject

#The --no-hardlinks switch makes git use real file copies instead of hardlinking when cloning a local repository. The garbage collection and pruning actions will only work on blobs (file contents), not links.
#Then just filter-branch and reset to exclude the other files, so they can be pruned:

cd $newproject
git filter-branch --subdirectory-filter $folder -- --all

# Then delete the backup reflogs so the space can be truly reclaimed (although now the operation is destructive)

git reset --hard
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --aggressive --prune=now

# Also sort out its remote refs 
# well, remove the existing one anyway to avoid confusion.
git remote rm origin

#git remote add origin git@git.sparksinteractive.co.nz:kidshealth/$newproject.git

git config --add branch.6.x-1.x.remote origin
git config --add branch.6.x-1.x.merge refs/heads/6.x-1.x

#commit to make the history work
git commit -m "removed all data but the folder that was extracted"



echo 'Done. Remember to add a new remote origin, and commit and push the changes (especially including push --tags) to the destination branch.'