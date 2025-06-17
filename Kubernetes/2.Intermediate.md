---
## Roadmap to Learning Intermediate Kubernetes

This roadmap builds upon the foundational knowledge of basic Kubernetes, guiding you through more sophisticated concepts essential for managing production-ready containerized applications.

### Intermediate Level: Mastering Kubernetes for Robust Applications

At this level, you'll dive deeper into managing application state, configuration, and advanced deployment strategies.

* ⚙️ **Configuration Management:**
    * **Understanding ConfigMaps: Externalizing configuration data for your applications.**
        * **Example:** Instead of baking configuration files directly into your Docker images, you can manage them separately as **ConfigMaps**. This allows you to change configurations without rebuilding and redeploying your application images.
        * **Example (`app-config.yaml` and using it in a Pod):**
            ```yaml
            # app-config.yaml
            apiVersion: v1
            kind: ConfigMap
            metadata:
              name: app-settings
            data:
              APP_MODE: "production"
              DB_HOST: "my-database-service"
              log_level: "INFO"
              # You can also store entire files here:
              nginx.conf: |
                server {
                  listen 80;
                  location / {
                    root /usr/share/nginx/html;
                  }
                }
            ```
            ```yaml
            # Pod using ConfigMap
            apiVersion: v1
            kind: Pod
            metadata:
              name: my-app-pod
            spec:
              containers:
              - name: my-app-container
                image: my-custom-app:1.0
                env:
                - name: APP_MODE
                  valueFrom:
                    configMapKeyRef:
                      name: app-settings
                      key: APP_MODE
                volumeMounts:
                - name: config-volume
                  mountPath: /etc/nginx/conf.d/default.conf # Mount as a file
                  subPath: nginx.conf # Specify which key to mount as a file
              volumes:
              - name: config-volume
                configMap:
                  name: app-settings
            ```
            To create: `kubectl apply -f app-config.yaml` then `kubectl apply -f my-app-pod.yaml`
    * **Understanding Secrets: Managing sensitive information securely.**
        * **Example:** Similar to ConfigMaps, **Secrets** are used for sensitive data like API keys, passwords, and OAuth tokens. Kubernetes encrypts Secrets at rest within `etcd` (the cluster's key-value store).
        * **Example (`db-secret.yaml` and using it in a Pod):**
            ```yaml
            # db-secret.yaml (Note: values are base64 encoded)
            apiVersion: v1
            kind: Secret
            metadata:
              name: db-credentials
            type: Opaque
            data:
              username: YWRtaW4= # echo -n 'admin' | base64
              password: c3VwZXJzZWNyZXRwYXNzd29yZA== # echo -n 'supersecretpassword' | base64
            ```
            ```yaml
            # Pod using Secret
            apiVersion: v1
            kind: Pod
            metadata:
              name: db-client-pod
            spec:
              containers:
              - name: db-client-container
                image: mysql-client:latest
                env:
                - name: DB_USERNAME
                  valueFrom:
                    secretKeyRef:
                      name: db-credentials
                      key: username
                - name: DB_PASSWORD
                  valueFrom:
                    secretKeyRef:
                      name: db-credentials
                      key: password
            ```
            To create: `kubectl apply -f db-secret.yaml` then `kubectl apply -f db-client-pod.yaml`

* 💾 **Persistent Storage:**
    * **Understanding PersistentVolumes (PV) and PersistentVolumeClaims (PVC): Providing durable storage for stateful applications.**
        * **Example:** While **Volumes** provide temporary storage, **PersistentVolumes** represent actual storage resources (e.g., a disk on a cloud provider, an NFS share) in the cluster. **PersistentVolumeClaims** are requests made by Pods for a certain amount and type of storage from a PV.
        * **Example (NFS PersistentVolume - `nfs-pv.yaml`):**
            ```yaml
            # nfs-pv.yaml
            apiVersion: v1
            kind: PersistentVolume
            metadata:
              name: nfs-pv
            spec:
              capacity:
                storage: 5Gi
              volumeMode: Filesystem
              accessModes:
                - ReadWriteMany # Can be mounted by multiple nodes/pods
              persistentVolumeReclaimPolicy: Retain # Keep data after PVC is deleted
              storageClassName: manual
              nfs:
                path: /data/k8s-volumes # Path on your NFS server
                server: 192.168.1.100 # IP of your NFS server
            ```
        * **Example (PersistentVolumeClaim - `my-pvc.yaml`):**
            ```yaml
            # my-pvc.yaml
            apiVersion: v1
            kind: PersistentVolumeClaim
            metadata:
              name: my-app-pvc
            spec:
              accessModes:
                - ReadWriteMany
              storageClassName: manual # Must match the PV's storageClassName
              resources:
                requests:
                  storage: 2Gi # Requesting 2GB of storage
            ```
        * **Example (Pod using PVC - `pod-with-pvc.yaml`):**
            ```yaml
            # pod-with-pvc.yaml
            apiVersion: v1
            kind: Pod
            metadata:
              name: my-app-with-data
            spec:
              containers:
              - name: my-data-container
                image: busybox
                command: ["/bin/sh", "-c", "echo 'My persistent data' > /mnt/data/my_file.txt && sleep 3600"]
                volumeMounts:
                - name: persistent-storage
                  mountPath: /mnt/data
              volumes:
              - name: persistent-storage
                persistentVolumeClaim:
                  claimName: my-app-pvc # Link to the PVC
            ```
            To create: `kubectl apply -f nfs-pv.yaml`, `kubectl apply -f my-pvc.yaml`, then `kubectl apply -f pod-with-pvc.yaml`
    * **Understanding StorageClasses for Dynamic Provisioning (Cloud Environments).**
        * **Example:** In cloud environments (AWS EKS, Azure AKS, GCP GKE), **StorageClasses** allow **dynamic provisioning** of storage. Instead of manually creating PVs, you define a StorageClass, and when a PVC requests storage using that class, the cloud provider automatically creates the underlying disk.
            ```yaml
            # storageclass.yaml (Example for AWS EBS)
            apiVersion: storage.k8s.io/v1
            kind: StorageClass
            metadata:
              name: gp2-standard
            provisioner: kubernetes.io/aws-ebs
            parameters:
              type: gp2 # General Purpose SSD
            reclaimPolicy: Delete # Delete the volume when PVC is deleted
            volumeBindingMode: Immediate
            ```
            Your PVC would then reference `storageClassName: gp2-standard`.

* 🔄 **Managing Stateful Applications - StatefulSets:**
    * **Understanding StatefulSets: Deploying stateful applications that require stable unique network identities and stable persistent storage.**
        * **Example:** Databases (MySQL, PostgreSQL), message queues (Kafka, RabbitMQ), and distributed key-value stores (ZooKeeper, etcd) are prime candidates for **StatefulSets**. They ensure ordered deployment, scaling, and deletion of Pods, and provide unique, persistent hostnames and storage for each replica.
        * **Example (Simple Headless Service and StatefulSet for Nginx, illustrating concepts):**
            ```yaml
            # nginx-headless-service.yaml (for stable network identities)
            apiVersion: v1
            kind: Service
            metadata:
              name: nginx-headless
              labels:
                app: nginx
            spec:
              ports:
              - port: 80
                name: web
              clusterIP: None # Makes this a headless service
              selector:
                app: nginx
            ```
            ```yaml
            # nginx-statefulset.yaml
            apiVersion: apps/v1
            kind: StatefulSet
            metadata:
              name: web
            spec:
              serviceName: "nginx-headless" # Links to the headless service
              replicas: 2
              selector:
                matchLabels:
                  app: nginx
              template:
                metadata:
                  labels:
                    app: nginx
                spec:
                  containers:
                  - name: nginx
                    image: nginx:latest
                    ports:
                    - containerPort: 80
                      name: web
                    volumeMounts:
                    - name: www
                      mountPath: /usr/share/nginx/html
              volumeClaimTemplates: # Automatically creates PVCs for each replica
              - metadata:
                  name: www
                spec:
                  accessModes: [ "ReadWriteOnce" ]
                  storageClassName: standard # Replace with your StorageClass
                  resources:
                    requests:
                      storage: 1Gi
            ```
            To create: `kubectl apply -f nginx-headless-service.yaml`, then `kubectl apply -f nginx-statefulset.yaml`
            Observe Pod names: `web-0`, `web-1`.

* 🛡️ **Security Primitives (Basic):**
    * **Understanding RBAC (Role-Based Access Control): Controlling who can do what in your cluster.**
        * **Example:** RBAC allows you to define roles (sets of permissions) and bind them to users or service accounts. This ensures that a developer can, for instance, only `get` and `list` Pods in their namespace, while an administrator has broader permissions.
        * **Example (Role to allow reading Pods - `pod-reader-role.yaml`):**
            ```yaml
            # pod-reader-role.yaml
            apiVersion: rbac.authorization.k8s.io/v1
            kind: Role
            metadata:
              namespace: default
              name: pod-reader
            rules:
            - apiGroups: [""] # "" indicates the core API group
              resources: ["pods"]
              verbs: ["get", "watch", "list"]
            ```
        * **Example (RoleBinding to assign `pod-reader` role to a user/ServiceAccount - `pod-reader-rolebinding.yaml`):**
            ```yaml
            # pod-reader-rolebinding.yaml
            apiVersion: rbac.authorization.k8s.io/v1
            kind: RoleBinding
            metadata:
              name: read-pods-binding
              namespace: default
            subjects:
            - kind: User # Could also be ServiceAccount or Group
              name: jane # Name of the user (e.g., from an identity provider)
              apiGroup: rbac.authorization.k8s.io
            roleRef:
              kind: Role
              name: pod-reader
              apiGroup: rbac.authorization.k8s.io
            ```
            To create: `kubectl apply -f pod-reader-role.yaml`, `kubectl apply -f pod-reader-rolebinding.yaml`
    * **ServiceAccounts: Providing identity for processes running in Pods.**
        * **Example:** Pods interact with the Kubernetes API using a **ServiceAccount**. By default, Pods use the `default` ServiceAccount in their namespace, but you can create specific ServiceAccounts with tailored RBAC permissions for your applications.
            ```yaml
            # custom-serviceaccount.yaml
            apiVersion: v1
            kind: ServiceAccount
            metadata:
              name: my-app-serviceaccount
              namespace: default
            ```
            ```yaml
            # Pod using custom ServiceAccount
            apiVersion: v1
            kind: Pod
            metadata:
              name: pod-with-custom-sa
            spec:
              serviceAccountName: my-app-serviceaccount # Assign the custom ServiceAccount
              containers:
              - name: my-container
                image: my-app:latest
            ```
            Then, you'd create a `Role` and `RoleBinding` to grant specific permissions to `my-app-serviceaccount`.

* 🔄 **Advanced Deployments & Updates:**
    * **Understanding Rolling Updates and Rollbacks.**
        * **Example:** When you update a **Deployment** (e.g., change the image version), Kubernetes performs a **rolling update** by default. It gradually replaces old Pods with new ones, ensuring zero downtime. If something goes wrong, you can easily **rollback** to a previous version.
        * **Example (Updating Nginx image version):**
            ```bash
            kubectl set image deployment/nginx-deployment nginx=nginx:1.21.0 # Update the image
            kubectl rollout status deployment/nginx-deployment # Monitor the rollout
            kubectl rollout history deployment/nginx-deployment # Check revision history
            kubectl rollout undo deployment/nginx-deployment # Rollback to previous revision
            ```
    * **Introduction to Liveness and Readiness Probes: Ensuring application health.**
        * **Liveness Probe:** Tells Kubernetes when to restart a container. If the probe fails, Kubernetes restarts the container.
        * **Readiness Probe:** Tells Kubernetes when a container is ready to serve traffic. Pods will not receive traffic from Services until their readiness probes pass.
        * **Example (Pod with Liveness and Readiness Probes):**
            ```yaml
            apiVersion: v1
            kind: Pod
            metadata:
              name: my-web-app-probes
            spec:
              containers:
              - name: my-web-app
                image: my-custom-web-app:1.0
                ports:
                - containerPort: 8080
                livenessProbe:
                  httpGet:
                    path: /healthz
                    port: 8080
                  initialDelaySeconds: 5
                  periodSeconds: 5
                readinessProbe:
                  httpGet:
                    path: /ready
                    port: 8080
                  initialDelaySeconds: 10
                  periodSeconds: 5
                  failureThreshold: 3
            ```

* 🔗 **Network Policies (Basic):**
    * **Understanding Network Policies: Controlling network traffic between Pods and namespaces.**
        * **Example:** By default, Pods can communicate freely within a cluster. **Network Policies** allow you to define firewall rules at the Pod level, specifying which Pods can communicate with which other Pods or external endpoints.
        * **Example (Deny all ingress to a Pod unless explicitly allowed):**
            ```yaml
            apiVersion: networking.k8s.io/v1
            kind: NetworkPolicy
            metadata:
              name: default-deny-ingress
              namespace: my-app-ns
            spec:
              podSelector: {} # Applies to all pods in this namespace
              policyTypes:
                - Ingress
            ```
        * **Example (Allow ingress only from Pods with specific labels):**
            ```yaml
            apiVersion: networking.k8s.io/v1
            kind: NetworkPolicy
            metadata:
              name: allow-app-frontend
              namespace: my-app-ns
            spec:
              podSelector:
                matchLabels:
                  app: backend
              policyTypes:
                - Ingress
              ingress:
                - from:
                    - podSelector:
                        matchLabels:
                          app: frontend # Only allow traffic from frontend pods
                  ports:
                    - protocol: TCP
                      port: 8080
            ```

---

### General Tips for Intermediate Learning:

* 📖 **Deep Dive into YAML:** Kubernetes is configured primarily through YAML. Become highly proficient in writing and understanding complex YAML structures.
* 🌐 **Understand the Control Plane:** Get a basic understanding of what components make up the Kubernetes control plane (kube-apiserver, etcd, kube-scheduler, kube-controller-manager, cloud-controller-manager) and what their roles are.
* 🛠️ **Practice Troubleshooting:** Learn to use `kubectl describe`, `kubectl logs`, `kubectl exec`, and `kubectl events` effectively to diagnose issues.
* 🧪 **Experiment with Different Services and Deployments:** Try deploying a simple multi-tier application (e.g., a frontend, a backend API, and a database) using Deployments, Services, and PersistentVolumeClaims.
* 📊 **Explore Monitoring & Logging Basics:** Understand the importance of monitoring (e.g., Prometheus) and centralized logging (e.g., ELK stack or Grafana Loki) for applications in Kubernetes.

By mastering these intermediate concepts, you'll be well-equipped to deploy and manage a wide range of stateful and stateless applications on Kubernetes in a more robust and secure manner. What's the most challenging aspect you anticipate in managing stateful applications in Kubernetes?