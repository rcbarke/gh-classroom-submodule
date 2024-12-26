#!/bin/bash
#
# gh_classroom_checkout_main.sh
#
# Description:
# This script reverts all student submodules to their main branches within a given 
# assignment. Useful if one or more repositories have been swapped to the feedback
# branch. 

# Check if the assignment name was provided as an argument
if [[ -z "$1" ]]; then
  echo "Error: No assignment name provided."
  echo "Usage: ./gh_classroom_checkout_main.sh <assignment_name>"
  exit 1
fi

# Set the assignment name from the first argument
assignment_name="$1"

submissions_folder="${assignment_name}-submissions"

if [[ ! -d "$submissions_folder" ]]; then
  echo "Error: The submissions folder '$submissions_folder' does not exist."
  exit 1
fi

# Initialize submodules on the local machine
echo "Initializing new submodules in .gitmodules to the local .git configuration..."
./gh_classroom_submodule_init.sh

# Change to the grading repository directory
cd "$submissions_folder" || { echo "Error: Could not enter folder $submissions_folder"; exit 1; }

# Loop over all submodules (student repositories)
for submodule in */; do
  repo_name=$(basename "$submodule")

  # Skip any repositories that do not contain the assignment name
  if [[ "$repo_name" != *"$assignment_name"* ]]; then
    continue
  fi

  # Enter the student's repository directory
  echo "Processing $submodule"
  cd "$submodule" || { echo "Error: Could not enter folder $submodule"; continue; }

  # Make sure the repo has the 'main' branch and check it out
  if git rev-parse --verify main >/dev/null 2>&1; then
    git checkout main
    echo "Checked out 'main' for $submodule"
  else
    echo "'main' branch not found in $submodule"
  fi

  # Go back to the parent directory to process the next submodule
  cd ..
done

echo "All repositories checked out 'main' branch."
