No problem! Here's a basic Git learning roadmap with commands and examples, presented clearly in English with icons for major sections.

---

# 🚀 Basic Git Learning Roadmap

Git is a distributed version control system that tracks changes in any set of computer files, usually used for coordinating work among programmers collaboratively developing source code during software development.

## 🌟 1. Understanding the Basics

Before we dive into commands, let's grasp some core Git concepts.

* **Version Control System (VCS)**: A system that records changes to a file or set of files over time so you can recall specific versions later.
* **Repository (Repo)**: A Git repository is essentially your project's folder, where Git tracks all changes. It contains all the files and the entire history of the project.
* **Commit**: A "snapshot" of your repository at a specific point in time. Each commit has a unique ID, a message describing the changes, and information about who made the commit.
* **Branch**: A lightweight movable pointer to a commit. Branches allow you to work on different features or bug fixes simultaneously without affecting the main codebase.
* **Master/Main Branch**: The default development branch.
* **Clone**: Creating a local copy of a remote repository.
* **Push**: Sending your local commits to a remote repository.
* **Pull**: Fetching changes from a remote repository and merging them into your current branch.

## 🛠️ 2. Setting Up Git

First, you need to tell Git who you are. This information will be associated with your commits.

### Command

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Explanation

* `git config`: Used to set Git configuration values.
* `--global`: Applies the setting to all your Git repositories on your system. You can omit this to set it for a specific repository only.
* `user.name`: Your name as it will appear in commit logs.
* `user.email`: Your email as it will appear in commit logs.

### Example

```bash
git config --global user.name "Alice Wonderland"
git config --global user.email "alice@example.com"
```

---

## 🏗️ 3. Creating and Cloning Repositories

You'll either start a new project (create) or join an existing one (clone).

### 3.1. Initializing a New Repository

To start tracking an existing project or a new empty folder.

### Command

```bash
git init
```

### Explanation

* `git init`: Initializes an empty Git repository in the current directory. This creates a hidden `.git` folder that stores all the repository's history and metadata.

### Example

```bash
cd my_new_project
git init
```

### 3.2. Cloning an Existing Repository

To get a copy of a project that's already on a remote server (like GitHub, GitLab, Bitbucket).

### Command

```bash
git clone [repository_url]
```

### Explanation

* `git clone`: Downloads a repository from a specified URL to your local machine.

### Example

```bash
git clone https://github.com/octocat/Spoon-Knife.git
```
This command will create a new directory named `Spoon-Knife` containing a copy of the repository.

---

## 💾 4. Making Changes and Committing

This is the core workflow: modify files, stage them, and commit them.

### 4.1. Checking Status

See what changes are pending.

### Command

```bash
git status
```

### Explanation

* `git status`: Shows the current state of the working directory and the staging area. It tells you which files have been modified, which are staged for the next commit, and which are untracked.

### Example

```bash
git status
# On branch main
# Your branch is up to date with 'origin/main'.
#
# Changes not staged for commit:
#   (use "git add <file>..." to update what will be committed)
#   (use "git restore <file>..." to discard changes in working directory)
#        modified:   index.html
#
# Untracked files:
#   (use "git add <file>..." to include in what will be committed)
#        new_feature.js
```

### 4.2. Staging Changes

Before committing, you need to "stage" the changes you want to include in the next commit. Think of the staging area as a holding zone.

### Command

```bash
git add [file_name]
# Or to stage all changes:
git add .
```

### Explanation

* `git add`: Adds changes from the working directory to the staging area.

### Example

```bash
# After modifying index.html
git add index.html

# After creating new_feature.js and modifying styles.css
git add new_feature.js styles.css

# To stage all modified and new files
git add .
```

### 4.3. Committing Changes

Once changes are staged, you can commit them.

### Command

```bash
git commit -m "Your descriptive commit message"
```

### Explanation

* `git commit`: Records the staged changes to the repository's history.
* `-m "..."`: Provides a short, descriptive message for the commit. A good commit message helps you and others understand what changes were made.

### Example

```bash
git commit -m "Add new header section and update navigation links"
```

### 4.4. Viewing Commit History

To see the history of commits.

### Command

```bash
git log
```

### Explanation

* `git log`: Shows the commit history for the current branch. Each entry includes the commit hash, author, date, and commit message.

### Example

```bash
git log
# commit 1a2b3c4d5e6f... (HEAD -> main, origin/main)
# Author: Alice Wonderland <alice@example.com>
# Date:   Mon Jun 17 19:00:00 2025 +0700
#
#     Add new header section and update navigation links
#
# commit 0f1e2d3c4b5a...
# Author: Bob The Builder <bob@example.com>
# Date:   Sun Jun 16 10:30:00 2025 +0700
#
#     Initial project setup
```

---

## 🌱 5. Working with Branches

Branches are essential for parallel development.

### 5.1. Listing Branches

### Command

```bash
git branch
```

### Explanation

* `git branch`: Lists all local branches. The current branch will be highlighted (e.g., with an asterisk).

### Example

```bash
git branch
#   feature-x
# * main
#   bugfix-123
```

### 5.2. Creating a New Branch

### Command

```bash
git branch [branch_name]
```

### Explanation

* `git branch [branch_name]`: Creates a new branch pointing to the current commit. You remain on the current branch after creating a new one.

### Example

```bash
git branch develop
git branch new-feature
```

### 5.3. Switching Branches

### Command

```bash
git checkout [branch_name]
# Or for newer Git versions (recommended):
git switch [branch_name]
```

### Explanation

* `git checkout`: Switches to the specified branch. This updates your working directory to reflect the files of that branch.
* `git switch`: A newer, more intuitive command for switching branches.

### Example

```bash
git checkout develop
# or
git switch develop
# Switched to branch 'develop'
```

### 5.4. Creating and Switching to a New Branch (Shortcut)

### Command

```bash
git checkout -b [new_branch_name]
# Or with git switch (recommended):
git switch -c [new_branch_name]
```

### Explanation

* Combines creating a new branch and immediately switching to it.

### Example

```bash
git checkout -b feature/user-profile
# or
git switch -c feature/user-profile
# Switched to a new branch 'feature/user-profile'
```

### 5.5. Merging Branches

After developing on a feature branch, you'll want to integrate those changes back into a main branch.

### Command

```bash
git merge [branch_to_merge_from]
```

### Explanation

* `git merge`: Integrates changes from the specified branch into your current branch.

### Example

Assume you are on the `main` branch and want to merge changes from `feature/user-profile`:

```bash
git switch main
git merge feature/user-profile
# If no conflicts, Git performs a fast-forward merge or a 3-way merge.
# If conflicts occur, Git will tell you which files need manual resolution.
```

### 5.6. Deleting a Branch

Once a branch is merged and no longer needed, you can delete it.

### Command

```bash
git branch -d [branch_name]
# Use -D (force delete) if the branch has unmerged changes.
```

### Explanation

* `git branch -d`: Deletes the specified branch, but only if it has been fully merged into its upstream branch.
* `git branch -D`: Force deletes the branch, regardless of its merge status. Use with caution!

### Example

```bash
git branch -d feature/user-profile
# Deleted branch feature/user-profile (was 1a2b3c4).
```

---

## ☁️ 6. Working with Remote Repositories

Collaborating means interacting with remote versions of your repository.

### 6.1. Pushing Changes

To send your local commits to the remote repository.

### Command

```bash
git push origin [branch_name]
# The first time you push a new branch, you might need to set its upstream:
git push -u origin [branch_name]
```

### Explanation

* `git push`: Uploads local changes to a remote repository.
* `origin`: The default name Git gives to the remote repository from which you cloned.
* `[branch_name]`: The branch you want to push.
* `-u` or `--set-upstream`: Sets the upstream tracking reference, so future `git push` and `git pull` commands on that branch can be run without specifying `origin` and `branch_name`.

### Example

```bash
git push origin main
git push -u origin feature/new-login
```

### 6.2. Pulling Changes

To fetch changes from the remote repository and merge them into your current local branch.

### Command

```bash
git pull origin [branch_name]
# Often, if you set up upstream tracking, you can just:
git pull
```

### Explanation

* `git pull`: A shortcut for `git fetch` (downloads changes) followed by `git merge` (integrates them).

### Example

```bash
git pull origin main
# or (if upstream is set)
git pull
```

### 6.3. Fetching Changes (Without Merging)

To download changes from a remote repository without integrating them into your current branch. Useful for reviewing changes before merging.

### Command

```bash
git fetch origin
```

### Explanation

* `git fetch`: Downloads branches and their respective commits from the remote repository, but it does not merge them into your current branch. The changes are downloaded into a separate "remote-tracking" branch (e.g., `origin/main`).

### Example

```bash
git fetch origin
# Now you can compare your local 'main' with 'origin/main'
git log origin/main
```

---

## 🔄 7. Undoing Things (Basic)

Everyone makes mistakes! Git allows you to revert them.

### 7.1. Unstaging Changes

To remove a file from the staging area *before* committing.

### Command

```bash
git restore --staged [file_name]
# Or for older Git versions:
git reset HEAD [file_name]
```

### Explanation

* `git restore --staged`: Moves changes from the staging area back to the working directory. The actual changes to the file are kept.

### Example

```bash
# After you ran 'git add index.html' but changed your mind
git restore --staged index.html
```

### 7.2. Discarding Local Changes

To discard changes in your working directory and revert a file to its last committed state. **This is destructive!**

### Command

```bash
git restore [file_name]
# Or for older Git versions:
git checkout -- [file_name]
```

### Explanation

* `git restore`: Discards uncommitted changes in the working directory for a specific file.

### Example

```bash
# You made changes to styles.css and want to discard them
git restore styles.css
```

### 7.3. Undoing a Commit (Soft Reset)

To uncommit changes but keep them in your staging area.

### Command

```bash
git reset --soft HEAD~1
```

### Explanation

* `git reset --soft HEAD~1`: Moves the `HEAD` pointer back one commit, but keeps the changes from the undone commit in your staging area, ready to be re-committed (perhaps with a different message or combined with other changes). `HEAD~1` refers to the commit just before the current HEAD.

### Example

```bash
git reset --soft HEAD~1
# Now the changes from the last commit are unstaged,
# and you can 'git status' to see them.
```

---

## 🚀 What's Next?

This roadmap covers the essentials to get you comfortable with Git. To deepen your knowledge, consider exploring:

* **Handling Merge Conflicts**: Strategies for resolving conflicts when merging branches.
* **Git Rebase**: An alternative to merging for integrating changes.
* **Git Stash**: Temporarily saving uncommitted changes.
* **Git Tags**: Marking specific points in history (e.g., releases).
* **Git Ignore**: Specifying files or directories that Git should not track.
* **Remote Tracking Branches**: Understanding `origin/main` etc.

Do you want to delve deeper into any specific Git topic, or are you ready to try out these commands?