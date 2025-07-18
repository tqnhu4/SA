## Lesson 4: Basic Docker Volumes

This lesson will guide you through creating and using Docker volumes to persist data generated by and used by Docker containers. Volumes are the preferred mechanism for persisting data generated by Docker containers because they are managed by Docker and are more performant than bind mounts.

### Why Use Volumes?

By default, when a container is removed, all data written inside the container's writable layer is also removed. This is problematic for applications that need to store data (like databases, log files, or user-uploaded content). Docker volumes provide a way to store this data outside the container's filesystem, ensuring it persists even if the container is stopped, removed, or replaced.

### Step 1: Create a Docker Volume

First, let's create a named volume. Named volumes are easier to manage and refer to.

```bash
docker volume create my-data-volume
```

  * **`docker volume create`**: This command is used to create a new Docker volume.
  * **`my-data-volume`**: This is the name we're giving to our new volume. You can choose any descriptive name.

You can verify that the volume has been created by listing all volumes:

```bash
docker volume ls
```

You should see `my-data-volume` in the list.

### Step 2: Run a Container and Mount the Volume

Now, let's run an Ubuntu container and mount `my-data-volume` into it. We'll use the `-v` flag for this.

```bash
docker run -it -v my-data-volume:/appdata ubuntu bash
```

Let's break down the new part:

  * **`-v my-data-volume:/appdata`**: This is the volume mounting instruction.
      * `my-data-volume`: This is the name of the volume we created in Step 1.
      * `/appdata`: This is the path *inside the container* where the volume will be mounted. You can choose any path you like, but it's good practice to pick a meaningful one.

Once you run this command, you'll be inside the Ubuntu container's bash prompt, similar to Lesson 2.

### Step 3: Create a File Inside the Mounted Volume

Now, let's create a file inside the `/appdata` directory within the container. Since `/appdata` is mounted to `my-data-volume`, this file will be stored on the volume, not just within the container's ephemeral filesystem.

From inside the container's prompt (`root@<container-id>:/#`):

```bash
echo "Hello from my persistent data!" > /appdata/persistent_file.txt
```

You can verify the file exists:

```bash
ls /appdata
cat /appdata/persistent_file.txt
```

You should see `persistent_file.txt` listed and its content displayed.

### Step 4: Exit the Container and Verify Data Persistence

Now, exit the container:

```bash
exit
```

The container will stop. To prove that the data persists, we'll run a *new* container (or the same one, but the point is the data is independent of the container instance) and mount the *same* volume.

Run the container again, mounting `my-data-volume` to `/appdata`:

```bash
docker run -it -v my-data-volume:/appdata ubuntu bash
```

Once inside the new container's prompt, navigate to the `/appdata` directory and check for your file:

```bash
ls /appdata
cat /appdata/persistent_file.txt
```

You should see `persistent_file.txt` and its content ("Hello from my persistent data\!"). This demonstrates that even though the first container was stopped and exited, the data stored on `my-data-volume` remained intact and was accessible to the new container.

### Step 5 (Optional): Clean Up the Volume

If you no longer need the volume, you can remove it. **Be careful:** this will delete all data stored on the volume.

First, make sure no containers are actively using the volume. You might need to stop and remove any containers that were mounting it.

```bash
# Exit the current container if you're still in it
exit

# List all containers (including stopped ones)
docker ps -a

# If you see any containers using my-data-volume, stop and remove them
# docker stop <container_id_or_name>
# docker rm <container_id_or_name>

# Finally, remove the volume
docker volume rm my-data-volume
```

This completes your basic introduction to Docker volumes and how they enable data persistence for your containers.