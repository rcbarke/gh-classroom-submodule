#!/bin/bash
#
# gh_classroom_clone_student-repos.sh
#
# Ryan Barker
# 
# Description: Useful for pulling GitHub classroom assignments into this repository for grading.
#
# Pre-Conditions and Assumptions:
# 1. Assumes git and gh are both installed:
#    sudo apt-get install git gh
# 2. Assumes gh classroom extension is installed:
#    gh extension install github/gh-classroom
# 3. Validates gh is connected to GitHub and prompts the user to initiate a gh auth login command and exits with an error if not.

# Check authentication status
auth_status=$(gh auth status 2>&1)

# Check if the output contains the phrase "Logged in to github.com account"
if echo "$auth_status" | grep -q "Logged in to github.com account"; then
  echo "Authenticated successfully. Pulling student repositories..."

  # Collect student repos
  if gh classroom clone student-repos; then
    echo "Student repositories cloned successfully."
  else
    echo "Error: Failed to clone student repositories. Please check the error messages above."
    exit 1
  fi
else
  echo "Error: Not logged in to GitHub. Please authenticate first via gh auth login."
  exit 1
fi

