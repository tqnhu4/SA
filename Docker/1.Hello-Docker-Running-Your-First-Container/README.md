
-----

## Lesson 1: Hello Docker - Running Your First Container

This lesson is all about verifying your Docker installation by running the classic "hello-world" container. It's a quick and simple way to confirm everything is set up correctly.

### Step 1: Open Your Terminal or Command Prompt

You'll need to use your command-line interface to interact with Docker.

### Step 2: Execute the `hello-world` command

Type the following command into your terminal and hit Enter:

```bash
docker run hello-world
```

### What Happens When You Run This Command?

When you run `docker run hello-world`, here's a quick breakdown of the process:

  * **Docker Client Connects**: Your Docker client, which is what you're using in your terminal, connects to the **Docker daemon**. This daemon is the background service that manages all Docker objects, like images, containers, volumes, and networks.
  * **Image Check**: The Docker daemon first checks if the `hello-world` **image** is already available on your local machine.
  * **Image Pull (if needed)**: If the image isn't found locally, Docker will automatically **pull** it from Docker Hub, which is Docker's public registry. You'll often see messages indicating that it's "Unable to find image 'hello-world:latest' locally" followed by "Pulling from library/hello-world."
  * **Container Creation and Execution**: Once the image is available, Docker **creates a new container** from that image and then **runs** the small program embedded within the `hello-world` image.
  * **Output and Exit**: The program inside the container simply prints a welcoming message to your terminal, typically confirming that your Docker installation is working correctly. After printing the message, the program finishes, and the container stops.
