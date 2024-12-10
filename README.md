# Example gRPC client running within Istio

This project contains a simple example to show how a gRPC client can access an external gRPC service, with outlier detection configured to eject instances of the service when there are 5 consecutive errors.

The gRPC service is emulated by two pods running within the *test-server* namespace, each having its own Service definition to define its virtual IP address.

The service is accessed by the grpc-client using a non-existent DNS name, grpc-server.internal, which is intercepted by the envoy proxy to implement round robin access between the two backend virtual IP addresses.

# Building

Run 
```
make docker-build
make docker-push
```
to build and push the images to a docker registry, or
```
make docker-build
make kind-push
```
to build and push to a local kind cluster

# Deploying

Run
```
istio/deploy
```
to deploy the servers and client into an existing Service Mesh

# Testing

In separate terminals run commands to view the server and client logs
```
while : ; do kubectl logs -n test-server -f deployment/grpc-server-1 ; sleep 1 ; done
```
```
while : ; do kubectl logs -n test-server -f deployment/grpc-server-2 ; sleep 1 ; done
```
```
kubectl logs -n test-client deploy/grpc-client -f
```

then run the
```
istio/scale_test
```
script to scale down and up each gRPC server in turn, pressing `return` key to move on to the next step.  The ejection period is currently a multiple of 30 seconds, depending on how often an endpoint has been ejected, so you may need to wait for the scaled up endpoint to rejoin the cluster within envoy.