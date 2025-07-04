## Lesson 5: Docker Networking - Connecting Containers

This lesson will teach you how to create a custom bridge network in Docker and connect two separate containers to it, allowing them to communicate with each other. This is a fundamental concept for building multi-container applications.

### Understanding Docker Networks

By default, Docker creates a `bridge` network for containers. However, when you create your own custom bridge network, Docker provides several benefits:

  * **Automatic DNS Resolution**: Containers on a custom bridge network can resolve each other's names (the container name) to IP addresses, making communication much easier than relying on IP addresses directly.
  * **Isolation**: Custom networks provide better isolation for your applications.
  * **Portability**: You can define your network setup in a `docker-compose.yml` file for easier deployment.

### Step 1: Create a Custom Bridge Network

First, let's create our own bridge network. We'll call it `my-app-network`.

```bash
docker network create my-app-network
```

  * **`docker network create`**: This command is used to create a new Docker network.
  * **`my-app-network`**: This is the name we're giving to our custom bridge network.

You can verify the creation and inspect its details:

```bash
docker network ls
docker network inspect my-app-network
```

### Step 2: Run the First Container and Connect to the Network

Now, let's run our first Ubuntu container and connect it to `my-app-network`. We'll name this container `container1`.

```bash
docker run -it --name container1 --network my-app-network ubuntu bash
```

  * **`--name container1`**: Assigns the name `container1` to this container. This name will be crucial for DNS resolution later.
  * **`--network my-app-network`**: Connects this container to the `my-app-network` we just created.
  * The `-it ubuntu bash` part is the same as in previous lessons, giving you an interactive bash shell inside the Ubuntu container.

Once you run this, you'll be inside `container1`'s bash prompt.

### Step 3: Run the Second Container and Connect to the Same Network

Open a **new terminal window or tab** on your host machine (do not exit `container1` yet).

In this new terminal, run the second Ubuntu container and connect it to the *same* `my-app-network`. We'll name this one `container2`.

```bash
docker run -it --name container2 --network my-app-network ubuntu bash
```

Now you have two separate containers, `container1` and `container2`, both running and connected to `my-app-network`. You should be inside `container2`'s bash prompt in your second terminal.

### Step 4: Ping One Container from Another

Before we ping, we need to ensure the `ping` utility is installed in both containers, as it's not always included in minimal Ubuntu images.

**In both `container1`'s terminal and `container2`'s terminal**, run the following commands:

```bash
apt-get update
apt-get install -y iputils-ping
```

Now, let's ping `container1` from `container2`.

**From `container2`'s terminal** (where you just installed `ping`):

```bash
ping container1
```

You should see successful ping responses, indicating that `container2` can resolve the name `container1` to its IP address and communicate with it.

Similarly, you can go to **`container1`'s terminal** and ping `container2`:

```bash
ping container2
```

You should also see successful ping responses here.

This demonstrates Docker's built-in DNS resolution for custom bridge networks, allowing containers to find and communicate with each other using their assigned names, not just their IP addresses.

### Step 5: Clean Up

When you're done experimenting, it's good practice to stop and remove the containers and the custom network.

**In both container terminals, type `exit` to stop the containers:**

```bash
exit
```

**Back on your host machine's terminal**, stop and remove the containers:

```bash
docker stop container1 container2
docker rm container1 container2
```

Finally, remove the custom network:

```bash
docker network rm my-app-network
```

You can verify that everything has been removed:

```bash
docker ps -a # Should show no running or stopped containers
docker network ls # my-app-network should no longer be listed
```

