# gh-classroom-submodule extension
## Ryan Barker and Dr. Harlan Russell
This is a private grading repository for the ECE-2230 course located here:

https://github.com/clemson-ece-2230

The grading scripts located here are NOT visible to students.

GitHub Classroom's CLI is a useful starting point for grading at scale, though it has several limitations:

https://docs.github.com/en/education/manage-coursework-with-github-classroom/teach-with-github-classroom/using-github-classroom-with-github-cli

This extension package leverages GitHub submodules to address these challenges, enabling efficient bulk grading operations at scale.

For those seeking to leverage these scripts within their classroom environments, the repository path within each script must be set to point to the GitHub organization linked to your GitHub Classroom instance. Sample data will NOT be available within this repo due to HIPPA compliance. 

### How to correctly clone this repository:
1. Perform your clone method of choice, e.g.
<code>gh repo clone rcbarke/clemson-ece-2230-grading</code>
2. **ALWAYS** immediately execute <code>./gh_classroom_submodule_init.sh</code> on a fresh clone to initialize git submodules in the parent grading repo on your local machine.
    - This is particularly important if you are working on an existing assignment already existing in the remote repo (ex: mp1-submissions).
    - See "Git Submodules 101" below for a detailed explanation of git submodules.
    - Without this step, commands that wish to access the student git repos, such as retrieving the student git repo commit histories, will not function on your machine.
3. Leverage the scripts documented below as needed. 

### Notable GitHub Classroom CLI limitations:
1. GitHub Classroom CLI does not allow you to create a private grading repo without exposing grading scripts to students.
2. GitHub Classroom supports cloning student repositories but does not allow for automatically adding them as submodules in your grading repo. Most operations provided operate student-by-student, with no ability to quickly iterate.

### Git submodules 101:
1. Git submodules provide a method for creating add-in software packages to main git repositories.
    - This is essentially parent/child relationships between repositories.
    - The shell scripts within this repository leverage submodules to create connections into each student's repository for every assignment. This enables efficient grading across all student repositories, so we do not have to grade individually repo-by-repo.
2. To create submodule relationships, one must build a .gitmodules file containing the desired submodule repository paths, urls, and default branches.
3. .gitmodules then must be loaded into the local machine's .git folder. This adds the configuration to .git/config and a .git/modules containing .git repos for each submodule. This is accomplished via the command within this script.
4. There is non-intuitive behavior present in the integration between remote repositories and submodules.
    - When a local repository containing configured submodules is pushed to a remote git repository (Ex: GitHub), the .gitmodules file is pushed, however, the contents of .git are not versioned and do not push.
5. This means that when a GitHub repository containing submodules is cloned down to a new machine, submodules must be initialized on that specific machine before they can be used. Unfortunately, this does NOT happen by default during a git clone due to edge cases where one would intentionally want to leave submodules uninitialized.

### We provide the following solution scripts to address these limitations:
1.  **Initializing existing Student Repository Submodules:**
    Execute the following script to initialize all existing student repository submodules upon a success git clone of this repository:
    <code>./gh_classroom_submodule_init.sh</code>
   
    This script has also been baked into other the other below scripts as a defensive programming measure, however, best practice is to always run it first.

2.  **Adding Student Repositories as Submodules:**
    Execute this script to add new assignments to the grading repository. It will clone down every student repository, and then configure each repo as a submodule:
    <code>./gh_classroom_submodule_add.sh</code>
   
    Key features:
    - Confirms necessary prerequisites, including running <code>./auxiliary/gh_classroom_clone_student-repos.sh</code> prior to this script.
    - Adds student repositories as submodules based on their main branch.
    - Copies grading scripts into the main submission folder.
    - Commits and pushes the changes to the remote grading repository.

3.  **Updating Submodules:**
    To refresh student repositories in your grading repo to pull all main branch changes for a given assignment, run the update script:
    <code>./gh_classroom_submodule_update.sh</code>

    This lightweight script updates all of the student repositories for any new commits to main. It will check out the student's main branch if another branch is stored locally.
    
    <code>./gh_classroom_submodule_add.sh</code> can also be run to perform the same function without harm to your .git repo, however, this update script is more efficient.

4.  **Submission Date Analysis and Grading:**
    For analyzing student submission dates and determining whether they submitted on time, use the following script:
    <code>./gh_classroom_get_submissions_dates.sh</code>

    This script processes each student's repository, excludes GitHub Classroom bot commits, and generates a detailed report indicating whether the submission was on time, late, or not submitted. It also calculates late points and prints them. 
    
    The report generated in this script will be found in the assignment repo, suffixed with "-submission_dates.txt".
    
    This script can be executed multiple times, and each run is logged and appended to the end of the file.

    Summary statistics include the number of students who submitted on time, late, or had no valid submission.

### Auxiliary scripts:
1.  **Cloning Student Repositories:**
    Execute the following script to clone student repositories for the desired assignment into your local grading repository:
    <code>./auxiliary/gh_classroom_clone_student-repos.sh</code>
   
    This script ensures that you are logged in with `gh` and verifies the necessary software dependencies (`gh`, `git`) before proceeding.
    
    Warning: Executing this script independent of the larger <code>gh_classroom_submodule_add.sh</code> script will not properly initialize the cloned student repositories as submodules!

For further instructions, consult the in-line comments within each script.

1.  **Checking out 'main' branch:**
    Execute the following script to checkout the 'main' branch for the desired assignment into your local grading repository for all students:
    <code>./auxiliary/gh_classroom_checkout.sh $assignment_name</code>
   
    Example usage:
    <code>./auxiliary/gh_classroom_checkout.sh mp1</code>
   
For further instructions, consult the in-line comments within each script.
