#!/bin/bash
#
# gh_classroom_get_submissions_dates.sh
#
# Description:
# This script retrieves and analyzes the commit history of all student submodules 
# within a specified GitHub Classroom grading repository. The goal is to determine 
# whether students submitted their assignment on time, submitted late, or did not 
# submit at all (excluding commits by the github-classroom[bot] or hrsdr14sum).

# Function to convert a date string into a UTC timestamp
convert_to_utc_timestamp() {
  date -u -d "$1" +%s
}

# Function to calculate days late and points off
calculate_late_days_and_points() {
  local secslate=$1

  if (( secslate > 0 )); then
    # Calculate days late
    days_late=$((1 + (secslate - (secslate % (60 * 60 * 24))) / (60 * 60 * 24)))
  else
    days_late=0
  fi

  # Calculate points off: 2^dayslate - 1
  points_off=$((2**days_late - 1))
  if (( points_off > 100)); then
    points_off=100
  fi

  echo "$days_late $points_off"
}

# Prompt for the target assignment name
read -p "Please enter the name of the target GitHub Classroom assignment: " assignment_name

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

# Prompt for the assignment due date (just the date)
read -p "Please enter the assignment due date (format: YYYY-MM-DD): " due_date

# Automatically set the time to 23:59:59 (11:59:59 PM) on the given date
due_date_full="$due_date 23:59:59"

# Convert the full due date to a UTC timestamp
due_date_ts=$(convert_to_utc_timestamp "$due_date_full")
if [[ -z "$due_date_ts" ]]; then
  echo "Error: Invalid due date format. Please use YYYY-MM-DD."
  exit 1
fi

# Adjust the due date by adding 3 hours (3 * 3600 seconds)
adjusted_due_date_ts=$((due_date_ts + 3 * 3600 + 1))

# Convert the adjusted timestamp back to a human-readable date in UTC
adjusted_due_date_full=$(date -u -d @$adjusted_due_date_ts +"%Y-%m-%d %H:%M:%S UTC")

# Output the adjusted due date and timestamp for verification
echo "Adjusted assignment due date (UTC): $adjusted_due_date_full"

# Use an absolute path for the output file
output_file="$(pwd)/${assignment_name}-submissions_dates.txt"
current_runtime=$(date)

# Ensure the output file can be created and written to
touch "$output_file" 2>/dev/null

if [[ $? -ne 0 ]]; then
  echo "Error: Failed to create or write to the file '$output_file'. Please check permissions."
  exit 1
fi

# Append the header to the file (no overwriting)
{
  echo "Submission Dates Report for Assignment: $assignment_name"
  echo "Assignment due date: $adjusted_due_date_full, due_date_ts (UTC): $adjusted_due_date_ts"
  echo "----------------------------------------"
  echo ""
  echo "gh_classroom_get_submissions_dates.sh runtime: $current_runtime"
} >> "$output_file"

# Counters for summary
student_count=0
on_time_count=0
late_count=0
no_valid_commit_count=0

# Array to store formatted late points
formatted_late_points=()

# Loop over all submodules (student repositories)
for submodule in */; do
  repo_name=$(basename "$submodule")

  # Skip any repositories that do not contain the assignment name
  if [[ "$repo_name" != *"$assignment_name"* ]]; then
    continue
  fi

  student_count=$((student_count + 1))

  echo "Processing repository: $repo_name"

  # Change into each student's submodule directory
  cd "$submodule" || continue
  
  # Get all commit dates and authors excluding commits by github-classroom[bot]
  commit_infos=$(git log --pretty=format:"%ci %an" | grep -v "github-classroom\[bot\]" | grep -v "hrsdr14sum")

  if [[ -z "$commit_infos" ]]; then
    echo "$repo_name NO SUBMISSION: No valid commit excluding github-classroom[bot] or hrsdr14sum" >> "$output_file"
    formatted_late_points+=("$repo_name 100")
    no_valid_commit_count=$((no_valid_commit_count + 1))
    cd ..
    continue
  fi

  # Track the latest commit timestamp and submission status
  submitted_on_time=false
  submitted_late=false
  latest_commit_ts=0
  latest_commit_info=""

  while IFS= read -r commit_info; do
    commit_date=$(echo "$commit_info" | awk '{print $1 " " $2}')
    commit_author=$(echo "$commit_info" | awk '{$1=$2=$3=""; print $0}' | xargs)

    # Convert the commit timestamp to UTC
    commit_ts=$(date -u -d "$commit_date" +%s)
    commit_date=$(echo "Git (local): $commit_date, commit_ts (UTC): $commit_ts")

    # Track the latest commit timestamp for accurate submission information
    if [[ "$commit_ts" -gt "$latest_commit_ts" ]]; then
      latest_commit_ts=$commit_ts
      latest_commit_info="$commit_date"
    fi

    # Check if any commit is after the due date
    if [[ "$commit_ts" -gt "$adjusted_due_date_ts" ]]; then
      submitted_on_time=false
      submitted_late=true
    elif [[ "$commit_ts" -le "$adjusted_due_date_ts" && "$submitted_late" = false ]]; then
      submitted_on_time=true
    fi
  done <<< "$commit_infos"

  # Calculate seconds late
  secslate=$((latest_commit_ts - adjusted_due_date_ts))

  # Calculate days late and points off
  read -r days_late points_off <<< "$(calculate_late_days_and_points "$secslate")"

  # Output the result for the latest commit
  if [[ "$submitted_late" = true ]]; then
    echo "$repo_name LATE $latest_commit_info" >> "$output_file"
  else
    echo "$repo_name ON TIME $latest_commit_info" >> "$output_file"
  fi

  # Record the late points
  formatted_late_points+=("$repo_name $points_off")

  # Update summary counts
  if [[ "$submitted_on_time" = true ]]; then
    on_time_count=$((on_time_count + 1))
  elif [[ "$submitted_late" = true ]]; then
    late_count=$((late_count + 1))
  fi

  cd ..
done

# Generate the summary
{
  echo "----------------------------------------"
  echo "Summary:"
  echo "$student_count students were processed."
  echo "$on_time_count students submitted on time."
  echo "$late_count students submitted late."
  echo "$no_valid_commit_count students had no valid submission."
  echo ""
  echo "Formatted Late Points:"
  for entry in "${formatted_late_points[@]}"; do
    echo "$entry"
  done
  echo ""
} >> "$output_file"

echo "Submission report generated in $output_file."
