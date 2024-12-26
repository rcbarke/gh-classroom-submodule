#!/bin/bash
#
# gh_classroom_submodule_update.sh
#
# Ryan Barker
# 
# Description: This script synchronizes all GitHub Classroom submodules with the latest changes on their `main` branch. It allows for the latest commit to be pulled in one command for all students.
#
# Script flow:
# 1. Prompts user for the name of the GitHub Classroom assignment to target.
# 2. Pulls the latest changes for all submodules (student repositories) to synchronize with their `main` branch for the given assignment.
# 3. Commits and pushes any updates to the remote grading repository.
#
# Pre-Conditions and Assumptions:
# 1. Asks user to provide the assignment name to check for student updates.
# 2. Required software dependencies are assumed to be handled by the environment where the script is run.

# Prompt for the target assignment name
read -p "Please enter the name of the target GitHub Classroom assignment: " assignment_name

submissions_folder="${assignment_name}-submissions"

if [[ ! -d "$submissions_folder" ]]; then
  echo "Error: The submissions folder '$submissions_folder' does not exist."
  exit 1
fi

# Ensure we are at the top level of the working tree
cd "$(git rev-parse --show-toplevel)" || { echo "Error: Failed to move to the top level of the repository."; exit 1; }

# Initialize submodules on the local machine
echo "Checkout 'main' branch of each submodule..."
auxiliary/gh_classroom_checkout_main.sh ${assignment_name}

# Retry mechanism for submodule updates
max_retries=5
retry_count=0
retry_delay=5

# Function to update submodules and retry on failure
update_submodules() {
  echo "Updating submodules to track the latest main branch..."
  git submodule update --remote --merge
}

# Attempt to update submodules with retries
until update_submodules; do
  ((retry_count++))
  if [[ $retry_count -ge $max_retries ]]; then
    echo "Error: Failed to update submodules after $max_retries attempts."
    exit 4
  fi
  echo "Network issue detected. Retrying in $retry_delay seconds... (Attempt $retry_count/$max_retries)"
  sleep $retry_delay
done

echo "Submodules updated to the latest main branch successfully."

# Add all files within the target classroom submissions folder to the git repository
echo "Adding any updated files to git..."
git add "$submissions_folder" || { echo "Error: Failed to add updated files to git."; exit 3; }

# Check if there are any changes to commit
if git diff-index --quiet HEAD --; then
  echo "No changes to commit. All student repos are up to date."
else
  # Commit the changes
  echo "Committing the updates..."
  git commit -m "Synchronized all student repos with their main branches"
  commit_status=$?

  # Check the commit status
  if [[ $commit_status -eq 0 || $commit_status -eq 1 ]]; then
    echo "Changes committed successfully."
  else
    echo "Error: Failed to commit changes."
    exit 3
  fi

  # Push the changes to the remote repository
  read -p "Do you want to push the changes to the remote repository? (y/n): " push_confirmation
  if [[ "$push_confirmation" == "y" ]]; then
    echo "Pushing changes to the remote repository..."
    git push || { echo "Error: Failed to push changes."; exit 3; }
    echo "Changes pushed successfully."
  else
    echo "Changes not pushed. You can push manually later if needed."
  fi
fi

