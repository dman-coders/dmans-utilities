#!/usr/bin/env bash

# From https://lostechies.com/johnteague/2014/04/04/using-git-subtrees-to-split-a-repository/

# Take an existing Drupal submodule and split it into its own repository.
# This migrates an all-in-one git blob Drupal project
# into something that can be better handled via makefiles.
#
# And makes things built in one site possible to be re-used properly in
# other sites, if the developer had not been doing that before!
#
# It extracts the history of the target directory (only) and makes a new project
# folder for it (nearby)
# It then pushes that project into the remote git repo.
# Then it returns to the main project, removes the folder, then REPLACES
# it by including the new remote project in its place.
#
# Run this from the docroot of a clean site checkout.
# Give it the PROJECT_NAME and PROJECT_PATH and new GIT_URI of the submodule to hit.
# You will need to create a central, remote git repo manually first!
# ..probably in the project on gitorious.

# Example values:
PROJECT_NAME=promotions
PROJECT_PATH=sites/all/modules/sparks/promotions
GIT_URI=git@git.sparksinteractive.co.nz:national-party-mp-sites/promotions.git
PROJECT_BRANCH=7.x-1.x


if (( $# != 3 ))
then
  echo "* Requires 3 parameters:";
  echo "  $0 {project_name} {project_path} {git_uri}";
  echo "eg  $0 ${PROJECT_NAME} ${PROJECT_PATH} ${GIT_URI}";
  echo "* This expects to be run in the Drupal siteroot.";
  echo "* The remote git URI must be created beforehand"
  exit 1
fi

PROJECT_NAME=$1;
PROJECT_PATH=$2;
GIT_URI=$3;

echo "Assuming I am in docroot and on a clean git of the branch you want to make this change in."
DOCROOT=`pwd`
MAIN_BRANCH=`git rev-parse --abbrev-ref HEAD`
git status
git pull
git tag "BEFORE_SUBTREE_SPLIT_$PROJECT_NAME"

echo "The subtree split may take a while (~1 min) due to large project backstory."

# This extracts the subproject into a stand-alone branch containing only it.
git subtree split --prefix=$PROJECT_PATH -b $PROJECT_NAME

echo "Prepare a place to copy the new twig into. Building the new folder and repo."
cd ..
mkdir $PROJECT_NAME
cd $PROJECT_NAME
git init
git remote add origin $GIT_URI
git checkout -b $PROJECT_BRANCH
# Now have a local place to build the subproject.
# This transfers the contents of our fake temp branch from the master project 
# into this new repo as our preferred branch (eg 7.x-1.x).
git pull $DOCROOT $PROJECT_NAME:$PROJECT_BRANCH
git push origin $PROJECT_BRANCH

echo "Now replace the subfolder i the master project with an included subtree"
cd $DOCROOT
git remote add $PROJECT_NAME $GIT_URI
git rm -r $PROJECT_PATH
git commit -m "Remove $PROJECT_NAME feature for splitting into sub-project" $PROJECT_PATH
git subtree add --prefix=$PROJECT_PATH $PROJECT_NAME $PROJECT_BRANCH
git tag "AFTER_SUBTREE_SPLIT_$PROJECT_NAME"


# It seems to be best to remove the reference to the sub-project remote
# immediately or else the subproject gets pulled into your proj
# the next time you attempt a git pull *awful* !?
# After hours of tracing, I can blame it on git rebase.
# http://stackoverflow.com/questions/27414132/git-subtree-split-merge-works-poorly/30204551#30204551
# So stop that.
git config branch.master.rebase false


# git status

echo "This process has now already made the git commits to your project. CHECK this now before pushing."
echo "You can revert to BEFORE_SUBTREE_SPLIT_$NAME to back out now if there is a problem."
echo "Running"
echo "    git diff  BEFORE_SUBTREE_SPLIT_$NAME AFTER_SUBTREE_SPLIT_$NAME"
echo "should show NO changes at all."
echo "You can ignore these local tags, probably no need to push them."
