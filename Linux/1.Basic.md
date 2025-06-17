Here's a basic Linux learning roadmap, complete with commands and examples, presented clearly in English with helpful icons.

---

# 🚀 Basic Linux Learning Roadmap

Linux is a powerful open-source operating system that forms the backbone of servers, supercomputers, and even Android phones. Understanding its command line is essential for many tech roles.

## 🌟 1. Understanding the Basics

Before typing commands, let's grasp some fundamental concepts.

* **Kernel**: The core of the Linux operating system, managing system resources.
* **Shell**: A command-line interpreter that allows you to interact with the kernel. Bash (Bourne Again SHell) is the most common.
* **File System Hierarchy**: Linux organizes files in a tree-like structure, starting from the root directory (`/`).
* **Permissions**: Linux uses a robust system to control who can read, write, or execute files and directories.
* **Terminal/Console**: The application you use to type commands and see their output.

---

## 📂 2. Navigating the File System

One of the first things you'll do in Linux is move around directories.

### 2.1. Present Working Directory (`pwd`)

Know where you are.

### Command

```bash
pwd
```

### Explanation

* `pwd`: Stands for "print working directory." It tells you the absolute path of your current location in the file system.

### Example

```bash
pwd
# Output: /home/yourusername
```

### 2.2. Change Directory (`cd`)

Move to a different location.

### Command

```bash
cd [directory_path]
```

### Explanation

* `cd`: Stands for "change directory." It allows you to move between directories.
    * `cd ~` or `cd`: Go to your home directory.
    * `cd ..`: Go up one level (parent directory).
    * `cd /`: Go to the root directory.
    * `cd -`: Go back to the previous directory you were in.

### Example

```bash
cd /var/log         # Move to the /var/log directory
pwd                 # Output: /var/log
cd ..               # Move up to /var
pwd                 # Output: /var
cd ~                # Move to your home directory
pwd                 # Output: /home/yourusername
```

### 2.3. List Directory Contents (`ls`)

See what's inside a directory.

### Command

```bash
ls [options] [directory]
```

### Explanation

* `ls`: Lists the contents (files and directories) of a directory.
    * `ls -l`: Long listing format (shows permissions, owner, size, date).
    * `ls -a`: Lists all files, including hidden ones (those starting with a dot `.`).
    * `ls -lh`: Long listing with human-readable file sizes (e.g., 1K, 234M).
    * `ls -R`: Lists contents of subdirectories recursively.

### Example

```bash
ls                  # List contents of current directory
ls -l /home/user    # List contents of /home/user in long format
ls -la              # List all files (including hidden) in long format
```

---

## 📝 3. Working with Files and Directories

Creating, deleting, copying, and moving.

### 3.1. Create Empty File (`touch`)

### Command

```bash
touch [file_name]
```

### Explanation

* `touch`: Creates a new empty file or updates the timestamp of an existing file.

### Example

```bash
touch my_notes.txt
```

### 3.2. Create Directory (`mkdir`)

### Command

```bash
mkdir [directory_name]
```

### Explanation

* `mkdir`: Stands for "make directory." Creates a new directory.
    * `mkdir -p`: Creates parent directories if they don't exist.

### Example

```bash
mkdir my_documents
mkdir -p projects/web/css # Creates projects, then web, then css
```

### 3.3. Copy Files/Directories (`cp`)

### Command

```bash
cp [source_path] [destination_path]
```

### Explanation

* `cp`: Stands for "copy." Copies files or directories.
    * `cp -r`: Recursively copies directories and their contents.
    * `cp -v`: Verbose output (shows what's being copied).

### Example

```bash
cp my_notes.txt my_documents/
cp -r projects/web/ /var/www/html/ # Copy entire web directory
```

### 3.4. Move/Rename Files/Directories (`mv`)

### Command

```bash
mv [source_path] [destination_path]
```

### Explanation

* `mv`: Stands for "move." Moves files or directories from one location to another. It's also used for renaming.

### Example

```bash
mv my_notes.txt my_documents/meeting_notes.txt # Move and rename
mv old_report.pdf archived_reports/           # Move to another directory
```

### 3.5. Remove Files (`rm`)

### Command

```bash
rm [file_name]
```

### Explanation

* `rm`: Stands for "remove." Deletes files.
    * `rm -i`: Interactive mode (prompts before deleting).
    * `rm -f`: Force delete (no prompts, use with extreme caution!).

### Example

```bash
rm temp_file.log
rm -i unwanted_image.jpg # Asks for confirmation
```

### 3.6. Remove Empty Directory (`rmdir`)

### Command

```bash
rmdir [directory_name]
```

### Explanation

* `rmdir`: Removes an **empty** directory. If the directory contains files or other directories, it will fail. For non-empty directories, use `rm -r`.

### Example

```bash
rmdir empty_folder
```

### 3.7. Remove Non-Empty Directory (`rm -r`)

### Command

```bash
rm -r [directory_name]
# Or with force:
rm -rf [directory_name]
```

### Explanation

* `rm -r`: Recursively deletes a directory and its contents.
* `rm -rf`: **Forcefully** and recursively deletes a directory and its contents. **Use with extreme caution, as there is no undo!**

### Example

```bash
rm -r old_project_files
rm -rf /tmp/test_dir # Dangerous! Be sure of what you are deleting.
```

---

## 👁️ 4. Viewing File Contents

Reading files without opening a text editor.

### 4.1. Display Entire File (`cat`)

### Command

```bash
cat [file_name]
```

### Explanation

* `cat`: Stands for "concatenate." Displays the entire content of a file to the standard output. Also used to combine files.

### Example

```bash
cat /etc/os-release
cat logfile.txt
```

### 4.2. View Paged Output (`less`, `more`)

For viewing large files that don't fit on the screen.

### Command

```bash
less [file_name]
more [file_name]
```

### Explanation

* `less`: Allows you to view file content page by page. You can scroll forward (Spacebar), backward (b), and search (/). Press `q` to quit. Generally preferred over `more`.
* `more`: Similar to `less`, but typically only allows forward scrolling.

### Example

```bash
less /var/log/syslog
more long_document.txt
```

### 4.3. View Beginning/End of File (`head`, `tail`)

### Command

```bash
head [options] [file_name]
tail [options] [file_name]
```

### Explanation

* `head`: Displays the first 10 lines of a file by default. Use `-n [number]` to specify a different number of lines.
* `tail`: Displays the last 10 lines of a file by default. Use `-n [number]` to specify a different number of lines.
    * `tail -f`: "Follows" the file, displaying new lines as they are added (useful for log files).

### Example

```bash
head -n 5 access.log     # Show first 5 lines
tail error.log           # Show last 10 lines
tail -f server.log       # Monitor server log in real-time
```

---

## 🔍 5. Searching for Files and Content

Finding what you need.

### 5.1. Find Files (`find`)

### Command

```bash
find [path] [expression]
```

### Explanation

* `find`: Searches for files and directories within a specified location based on criteria.

### Example

```bash
find . -name "*.txt"         # Find all .txt files in current dir and subdirs
find /home -type d -name "projects" # Find directories named "projects" in /home
find /var/log -size +10M     # Find files larger than 10MB in /var/log
```

### 5.2. Search Content in Files (`grep`)

### Command

```bash
grep [options] "search_string" [file_name]
```

### Explanation

* `grep`: Stands for "global regular expression print." Searches for patterns (text) within files.

### Example

```bash
grep "error" /var/log/syslog        # Find "error" in syslog
grep -i "warning" access.log        # Case-insensitive search for "warning"
grep -r "function_name" .           # Search recursively in current directory
grep -n "failed" auth.log           # Show line numbers
```

---

## 🔀 6. Redirection and Pipes

Connecting commands to each other.

### 6.1. Output Redirection (`>`, `>>`)

Send command output to a file.

### Command

```bash
command > file       # Overwrite file
command >> file      # Append to file
```

### Explanation

* `>`: Redirects the standard output of a command to a file, **overwriting** the file if it exists.
* `>>`: Redirects the standard output of a command to a file, **appending** to the file if it exists.

### Example

```bash
ls -l > file_list.txt        # Save directory listing to a file
echo "Hello, world!" >> greeting.txt # Add a line to greeting.txt
```

### 6.2. Input Redirection (`<`)

Feed a file's content as input to a command.

### Command

```bash
command < file
```

### Explanation

* `<`: Redirects the content of a file to be the standard input for a command.

### Example

```bash
wc -l < my_document.txt # Count lines in my_document.txt (wc counts words, lines, chars)
```

### 6.3. Pipes (`|`)

Chain commands together, sending the output of one as the input of another.

### Command

```bash
command1 | command2
```

### Explanation

* `|`: The "pipe" operator takes the standard output of `command1` and feeds it as the standard input to `command2`.

### Example

```bash
ls -l | less                  # View long directory listing page by page
grep "fail" /var/log/syslog | wc -l # Count how many lines contain "fail"
ps aux | grep "apache"        # Find running Apache processes
```

---

## 💪 7. Permissions (Basic)

Control who can access what.

### 7.1. View Permissions (`ls -l`)

As seen earlier, `ls -l` shows permissions.

### Example Output

```
-rw-r--r-- 1 yourusername yourusername 1234 Jun 17 19:00 my_file.txt
drwxr-xr-x 2 yourusername yourusername 4096 Jun 17 19:05 my_directory/
```

* **First character**: `-` for file, `d` for directory.
* **Next 9 characters**: Permissions for `owner` (3), `group` (3), `others` (3).
    * `r`: read
    * `w`: write
    * `x`: execute

### 7.2. Change Permissions (`chmod`)

### Command

```bash
chmod [permissions] [file/directory]
```

### Explanation

* `chmod`: Changes file or directory permissions. Permissions can be set using symbolic (`u+x`, `go-w`) or octal (numeric) modes. Octal is more common for system administration.
    * **Octal values**:
        * `r` = 4 (read)
        * `w` = 2 (write)
        * `x` = 1 (execute)
    * Combine values for each set (owner, group, others).
        * `7` = rwx (4+2+1)
        * `6` = rw- (4+2)
        * `5` = r-x (4+1)
        * `4` = r-- (4)

### Example

```bash
chmod 755 script.sh # Owner can read/write/execute, group/others can read/execute
chmod 644 document.txt # Owner can read/write, group/others can only read
chmod u+x myscript.sh # Add execute permission for the owner
chmod go-w important_file.conf # Remove write permission for group and others
```

### 7.3. Change Ownership (`chown`, `chgrp`)

### Command

```bash
chown [new_owner]:[new_group] [file/directory]
chgrp [new_group] [file/directory]
```

### Explanation

* `chown`: Changes the owner and/or group of a file or directory. Often requires `sudo` (root privileges).
* `chgrp`: Changes only the group ownership of a file or directory.

### Example

```bash
sudo chown root:root /var/www/html/index.html # Change owner and group to root
sudo chown youruser:youruser my_app/ # Change owner and group to youruser
sudo chgrp www-data /var/www/html/ # Change group to www-data
```

---

## ⚙️ 8. User Management (Basic)

For systems with multiple users.

### Command

```bash
whoami           # Show current username
id               # Show user and group IDs
sudo [command]   # Execute command with root privileges
passwd           # Change your own password
```

### Example

```bash
whoami
# Output: yourusername
id
# Output: uid=1000(yourusername) gid=1000(yourusername) groups=1000(yourusername),4(adm),27(sudo)
sudo apt update # Update package lists (requires your password)
passwd # Prompts to change your password
```

---

## 🚀 What's Next?

This roadmap provides a strong foundation in basic Linux command-line usage. To advance your skills, consider exploring:

* **Package Management**: Using `apt`, `yum`, `dnf` to install/manage software.
* **Process Management**: `ps`, `top`, `htop`, `kill` to manage running programs.
* **Networking Commands**: `ip`, `ping`, `ssh`, `netstat` (legacy) for network configuration and troubleshooting.
* **Text Editors**: `Vim` or `Nano` for editing files directly in the terminal.
* **Shell Scripting**: Automating tasks using Bash scripts.
* **User and Group Management (Advanced)**: `useradd`, `userdel`, `groupadd`, `groupdel`.

Feel free to ask if you'd like to dive deeper into any of these areas, or if you have specific tasks you'd like to accomplish!