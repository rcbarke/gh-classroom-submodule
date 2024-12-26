#!/bin/bash
#
# gh_classroom_submodule_add.sh
#
# Ryan Barker
# 
# Description: Auxiliary script for gh_classroom_clone_student-repos.sh. Sets up 
# cloned gh classroom submission folder for grading and links grading repo 
# to all student repos as git submodules.
#
# Script flow:
# 1. Begins with ./auxiliary/gh_classroom_clone_student-repos.sh script to clone down a new assignment from GitHub Classroom.
# 2. Prompts user to confirm the name of the gh classroom assignment to target.
# 3. Executes git submodule add command on all student repos to add them into the grading repository's .gitmodules configuration for the target assignment.
#    - Ensures the grading repository tracks the `main` branch of all student repositories for the target assignment.
#    - This is a rather frustrating reality of the git submodule function. By default, 
#    it tracks to the latest commit in the student's repo, not their main branch.
# 4. If submodule add command returned any errors, display them and exit 2.
#    - Skips repo if it already exists in the index; allowing this script to be executed multiple times without harm.
# 5. Once all submodules have been added, update the local machine's .git/config and .git/modules folder to apply the new configuration. 
#    - git submodule update --init --recursive to set up the submodule file tree locally
#    - git submodule update --remote --merge will ensure each submodule tracks the main branch from the remote repository. Network errors can occur here, so a retry loop is included.
# 6. Only if all submodules added successfully (exit 3 if anything below fails):
#    - Copy all files and subdirectories within ./scripts into the target classroom submissions folder.
#    - Add all files within the target classroom submissions folder to the git repo.
#    - Commit to the git repo with the message "Added student repos as submodules".
#    - Push the git repo.

# Pre-Conditions and Assumptions:
# 1. Asks user to verify if they have loaded all grading scripts for this assignment within the ./scripts directory.
#    This will be leveraged to setup the cloned repos for grading after they are added as submodules. 
# 2. Asks user to provide the name of the assignment cloned by gh_classroom_clone_student-repos.sh script and assumes it is accurate.
# 3. Required software dependencies are handled by gh_classroom_clone_student-repos.sh script.

# Clone the student repos for the specified assignment:
repo_path="https://github.com/your-repo-url" # replace with absolute path
echo "Initiating gh classroom clone of a new assignment..."
./auxiliary/gh_classroom_clone_student-repos.sh

# Verify that grading scripts are loaded in the ./scripts directory
if [[ ! -d "./scripts" || -z "$(ls -A ./scripts)" ]]; then
  echo "Error: No grading scripts or compile files found in the ./scripts directory. Please ensure all files and subdirectories are loaded."
  exit 1
else
  read -p "Have you loaded the latest grading scripts and compile files within the ./scripts directory? (y/n): " latest_scripts

  if [[ "$latest_scripts" != "y" ]]; then
    echo "Error: Please load the latest grading scripts and compile files within the ./scripts directory before proceeding."
    exit 1
  fi
fi

# Prompt for the target assignment name
read -p "Please enter the name of the target GitHub Classroom assignment: " assignment_name

submissions_folder="${assignment_name}-submissions"

if [[ ! -d "$submissions_folder" ]]; then
  echo "Error: The submissions folder '$submissions_folder' does not exist."
  exit 1
fi

# Ensure we are at the top level of the working tree
cd "$(git rev-parse --show-toplevel)" || { echo "Error: Failed to move to the top level of the repository."; exit 1; }
echo "Initiating submodule add on '$submissions_folder'..."

# Loop through each student repository in the submissions folder and add it as a submodule into .gitmodules file
for repo in "$submissions_folder"/*/; do
  repo_name=$(basename "$repo")
  echo "Adding $repo_name to .gitmodules..."

  # Try to add the submodule
  output=$(git submodule add "$repo_path/$repo_name.git" "$submissions_folder/$repo_name" 2>&1)

  # Check if the submodule already exists in the index
  if echo "$output" | grep -q "already exists in the index"; then
    echo "Skipping $repo_name - already exists in the index."
  elif echo "$output" | grep -q "Adding existing repo"; then
    echo "$repo_name added successfully."
    
    # Configure the submodule to track the main branch
    git config -f .gitmodules submodule."$submissions_folder/$repo_name".branch main
  else
    echo "Error: Failed to add $repo_name into .gitmodules. Debug output:"
    echo "$output"
    exit 2
  fi
done

# Initialize submodules on the local machine
echo "Initializing new submodules in .gitmodules to the local .git configuration..."
./gh_classroom_submodule_init.sh

# Retry mechanism for submodule updates
max_retries=5
retry_count=0
retry_delay=5

# Synchronize with the main branch of each student's remote repository
update_submodules() {
  echo "Updating submodules to track the latest main branch..."
  git submodule update --remote --merge
}

# Network error retry loop
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

# Copy all files and subdirectories from ./scripts into the target classroom submissions folder
echo "Copying grading scripts to the submissions folder..."
cp -r ./scripts/* "$submissions_folder/" || { echo "Error: Failed to copy grading scripts to the submissions folder."; exit 3; }

# Add all files within the target classroom submissions folder to the git repository
echo "Staging all submodules to git..."
git add "$submissions_folder" || { echo "Error: Failed to add files to git."; exit 3; }

# Check if there are any changes to commit
if git diff-index --quiet HEAD --; then
  echo "No changes to commit. All student repos are up to date."
else
  # Commit the changes
  echo "Committing the updates..."
  git commit -m "Added new assignment ${assignment_name}"
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

