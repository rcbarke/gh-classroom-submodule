#!/bin/bash
#
# gh_classroom_submodule_init.sh
#
# Ryan Barker
# 
# Description: Initializes the git submodules contained in this software package.
#
# Git Submodules 101:
# 1. Git submodules provide a method for creating add-in software packages to main git repositories.
# - This is essentially parent/child relationships between repositories.
# - The shell scripts within this repository leverage submodules to create connections into each student's repository for every assignment. This enables efficient grading across all student repositories, so we do not have to grade individually repo-by-repo.
# 2. To create submodule relationships, one must build a .gitmodules file containing the desired submodule repository paths, urls, and default branches.
# 3. .gitmodules then must be loaded into the local machine's .git folder. This adds the configuration to .git/config and a .git/modules containing .git repos for each submodule. This is accomplished via the command within this script.
# 4. There is non-intuitive behavior present in the integration between remote repositories and submodules.
# - When a local repository containing configured submodules is pushed to a remote git repository (Ex: GitHub), the .gitmodules file is pushed, however, the contents of .git are not versioned and do not push.
# 5. This means that when a GitHub repository containing submodules is cloned down to a new machine, submodules must be initialized on that specific machine before they can be used. Unfortunately, this does NOT happen by default during a git clone due to edge cases where one would intentionally want to leave submodules uninitialized.
#
# Pre-Conditions and Assumptions:
# 1. None, this script is intended to be run immediately after git clone before leveraging any other commands in this repository. 
# 2. This script only needs to be run once, but without it, other scripts in this repo referencing submodules will not function correctly.
#
# This command has also been integrated within the gh clossroom submodule add and update scripts as a defensive programming practice, to ensure configurations are applied locally as they are pulled down.

# Initialize submodules on the local machine
git submodule update --init --recursive

echo "All repository submodules have been successfully initialized."
