# Kubernetes practice

## Manual deployment of a service

Run:
```
$ kubectl create deployment time-server --image=docker.io/kuredoro/python_time_server:latest
$ kubectl expose deployment time-server --type=LoadBalancer --port=8080
$ minicube service time-server
```

Results:
```
$ kubectl get pods,svc
NAME                               READY   STATUS    RESTARTS   AGE
pod/time-server-694d485d77-k94wg   1/1     Running   0          130m

NAME                  TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/kubernetes    ClusterIP      10.96.0.1        <none>        443/TCP          140m
service/time-server   LoadBalancer   10.102.213.112   <pending>     8080:31794/TCP   126m
```

## Deployment in declarative style

Run:
```
$ kubectl apply -f deployment.yml
$ kubectl apply -f service.yml
```

At this point
```
$ kubectl get services
NAME                  TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
kubernetes            ClusterIP      10.96.0.1      <none>        443/TCP          171m
time-server-service   LoadBalancer   10.99.126.76   <pending>     8080:31093/TCP   4m15s
```

The external IP will never stop pending, since kubectl cannot allocate IPs for the services the load balancer could route to (unlike in AWS or Google Cloud clusters). To solve this issue, we should run in a different terminal window:
```
$ minikube tunnel
```

This will make the service's cluster IP address exposed as-is in the host operating system.

After that, the results are:
```
$ kubectl get pods,svc
NAME                                     READY   STATUS    RESTARTS   AGE
pod/time-server-local-6b5766db87-5xpr4   1/1     Running   0          24m
pod/time-server-local-6b5766db87-kk9gd   1/1     Running   0          24m
pod/time-server-local-6b5766db87-r8xf8   1/1     Running   0          24m

NAME                          TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)          AGE
service/kubernetes            ClusterIP      10.96.0.1      <none>         443/TCP          174m
service/time-server-service   LoadBalancer   10.99.126.76   10.99.126.76   8080:31093/TCP   7m59s
```

## Wrapping my head around k8s

**Ingress** is a k8s object that routes the incomming traffic to the *HTTP(S)* services. To an outside user it would look like any other web server, but depending on the URL paths and *who* the user is, the Ingress will route the traffic to different services, as described in the specification.

**Ingress controller** is a piece of software that implements the Ingress resource. It is responsible for accepting the incomming requests, forwarding them to the correct services and returning the responses back. It is not started automatically on cluster start, it should be enabled manually.

**StatefulSet** is basically a deployment, but with extra features. While deployment makes sure that there are N replicas at all times, the StatefulSet also guarantees that even if a pod dies, it is recreated with the same ID. This is very useful, because now a *state* can be uniquely associated with the pod's ID, and this association can persist between pod destruction and creation. The data persists, always. Even if StatefulSet itself is deleted (or, more correctly, drained and *then* deleted), the volumes are *not* deleted. Logic for being that the data is more important than automatic storage cleaning. Also, because each pod has a unique ID, a total ordering can be established among the pods, and thus they can be updated/deleted in a specified order too.

**DaemonSet** is, also, like a deployment, but it makes sure that there are not N replicas, but that there is a single replica running on each node (or a set of nodes). This one can be used, for example, to run Promtail along all nodes that will send the processed logs to Loki pod somewhere on the cluster.

**Volumes** can be thought of as file systems that are mounted inside unix-like operating systems. They look like an ordinary directory to the applications running inside the OS, but when accessed cause special software to process the request and perform something different than what a usual FS driver would. Kubernetes supports many types of volumes: `emptyDir` for an empty directory, `downwardAPI` for a directory with configuration files written as plain files, `local` for a concrete directory within the node itself and many more. Volumes allow containers to store and share data in a controlled manner (although it's a bad practice for a pod to contain several containers...).

**PersistentVolumes** are volumes but with a very obvious feature that make much more useful (and harder to configure) than plain volumes. These volumes *persist* between pod destructions and creations. The persistent volumes may be AWS EBS, glusterfs deployed somewhere on the cluster, or a local path on a node (although persistent while the node exists). These volumes can be shared among many pods and used as a dumping ground, or they can be used together with StatefulSets and assigned uniquely to each pod (and many more use cases).

## Helm

Run to deploy:
```
$ helm package time-server
$ helm install time-server time-server-0.1.0.tgz
```

And again, for the load balancer to allocate an address, in another terminal window
```
$ minikube tunnel
```

After this `minikube service time-server` will redirect to the deployed service.
```
$ minikube service time-server
|-----------|-------------|-------------|---------------------------|
| NAMESPACE |    NAME     | TARGET PORT |            URL            |
|-----------|-------------|-------------|---------------------------|
| default   | time-server | http/8080   | http://192.168.49.2:32645 |
|-----------|-------------|-------------|---------------------------|
🎉  Opening service default/time-server in default browser...
```

And the kubernetes stats:
```
$ kubectl get pods,svc
NAME                              READY   STATUS    RESTARTS   AGE
pod/time-server-8c5f5777d-khv89   1/1     Running   0          5m25s
pod/time-server-8c5f5777d-kmnkn   1/1     Running   0          5m25s
pod/time-server-8c5f5777d-srl89   1/1     Running   0          5m25s

NAME                  TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)          AGE
service/kubernetes    ClusterIP      10.96.0.1       <none>          443/TCP          24h
service/time-server   LoadBalancer   10.96.144.243   10.96.144.243   8080:32645/TCP   5m25s
```

To uninstall
```
$ helm uninstall time-server
```

## Helm notions

**Library charts** are the other type of charts that don't deploy any applications and no templates. Rather they *define* templates that can be then *instantiated* by application charts for their specific purposes. A template for a config map, a template to manipulate other templates and more can be defined in library charts. This type of charts is created in a usual way via `helm create`, then the `templates/*` are deleted and the `type` field in the `Chart.yaml` is set to `library`. All template files that define templates are prefixed with an underscore (otherwise it is considered to be a Kubernetes template). Finally, to use it, user will define a dependency field in the `Chart.yaml` of an application chart.
