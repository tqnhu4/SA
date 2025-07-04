
-----

## Lesson 2: Creating a Container from an Official Image

In this lesson, you'll learn how to launch an interactive container based on an official Ubuntu image, install a new package (`curl`), and then use it to test network connectivity.

### Step 1: Run an Interactive Ubuntu Container

Open your terminal or command prompt and type the following command, then press Enter:

```bash
docker run -it ubuntu bash
```

Let's break down what this command does:

  * **`docker run`**: This is the fundamental command used to create and start a new container.
  * **`-it`**: This is a very common combination of two flags:
      * **`-i` (or `--interactive`)**: Keeps the standard input (STDIN) open, allowing you to type commands into the container.
      * **`-t` (or `--tty`)**: Allocates a pseudo-TTY (a "terminal"), which provides a proper command-line interface inside the container, making it feel like you're directly logged into a Linux machine.
  * **`ubuntu`**: This specifies the **Docker image** we want to use. Since we didn't specify a version tag (like `ubuntu:22.04`), Docker will default to pulling the `ubuntu:latest` image from Docker Hub (Docker's public registry).
  * **`bash`**: This is the command that will be executed *inside* the container as soon as it starts. It launches a Bash shell, giving you an interactive prompt within the Ubuntu environment.

Once the command runs, you'll notice your terminal prompt changes. It will typically look something like `root@<container-id>:/#`, indicating you are now inside the running Ubuntu container.

### Step 2: Install `curl` inside the Container

Now that you're inside the Ubuntu container's bash prompt, we'll install `curl`, a command-line tool for transferring data with URLs.

First, it's good practice to update the package lists:

```bash
apt-get update
```

This command downloads the package information from all configured sources. After it completes, you can install `curl`:

```bash
apt-get install -y curl
```

  * **`apt-get install`**: This command is used to install new software packages.
  * **`-y`**: This flag automatically answers "yes" to any prompts that might appear during the installation process, allowing it to proceed non-interactively.

You'll see output as `curl` and its dependencies are downloaded and installed.

### Step 3: Test `curl` by Accessing Google.com

With `curl` installed, let's test its functionality and confirm the container has outbound internet connectivity.

Still within the container's prompt, run:

```bash
curl google.com
```

You should see a large amount of HTML content scroll through your terminal. This is the source code of Google's homepage, confirming that `curl` works and your container can reach external websites.

### Step 4: Exit the Container

When you're finished experimenting inside the container, you can exit back to your host machine's terminal by simply typing:

```bash
exit
```

**Important Note**: When you `exit` a container launched in this manner, the container will stop, and any changes you made *inside* it (like installing `curl`) will **not be persisted** if you start a *new* `ubuntu` container later. Each `docker run` command creates a fresh instance of the image. To save changes, you'd typically commit the container to a new image, which is a more advanced topic.