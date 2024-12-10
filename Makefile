# Makefile for gRPC Go Project

KIND=kind
CLUSTER_NAME=kind

# Variables
PROTO_DIR=pkg/greet
GO_OUT_DIR=pkg/generated
SERVER_NAME=grpc-server
CLIENT_NAME=grpc-client

# Protobuf compiler settings
PROTOC=protoc
PROTOC_GEN_GO=protoc-gen-go
PROTOC_GEN_GO_GRPC=protoc-gen-go-grpc

# Docker settings
DOCKER_REGISTRY?=local
VERSION?=0.1.0

# Find all .proto files
PROTO_FILES=$(wildcard $(PROTO_DIR)/*.proto)

# Default target
.PHONY: all
all: generate build

# Generate Go code from .proto files
.PHONY: generate
generate:
	@echo "Generating Go code from protobuf..."
	@mkdir -p $(GO_OUT_DIR)
	@$(PROTOC) \
		--go_out=$(GO_OUT_DIR) \
		--go_opt=paths=import \
		--go-grpc_out=$(GO_OUT_DIR) \
		--go-grpc_opt=paths=import \
		$(PROTO_FILES)

# Build server and client binaries
.PHONY: build
build: generate
	@echo "Building server and client..."
	@go build -o bin/$(SERVER_NAME) cmd/server/main.go
	@go build -o bin/$(CLIENT_NAME) cmd/client/main.go

# Build Docker images
.PHONY: docker-build
docker-build: generate
	@echo "Building Docker images..."
	@docker build -t $(DOCKER_REGISTRY)/$(SERVER_NAME):$(VERSION) -f Dockerfile.server .
	@docker build -t $(DOCKER_REGISTRY)/$(CLIENT_NAME):$(VERSION) -f Dockerfile.client .

# Push Docker images to registry
.PHONY: docker-push
docker-push:
	@echo "Pushing Docker images..."
	@docker push $(DOCKER_REGISTRY)/$(SERVER_NAME):$(VERSION)
	@docker push $(DOCKER_REGISTRY)/$(CLIENT_NAME):$(VERSION)

# Push Docker images to kind cluster
.PHONY: kind-push
kind-push:
	@echo "Pushing Docker images to kind cluster $(CLUSTER_NAME)..."
	$(KIND) load docker-image -n $(CLUSTER_NAME) $(DOCKER_REGISTRY)/$(SERVER_NAME):$(VERSION)
	$(KIND) load docker-image -n $(CLUSTER_NAME) $(DOCKER_REGISTRY)/$(CLIENT_NAME):$(VERSION)

# Run server locally
.PHONY: run-server
run-server: generate
	@go run cmd/server/main.go

# Run client locally
.PHONY: run-client
run-client: generate
	@go run cmd/client/main.go

# Clean generated files and binaries
.PHONY: clean
clean:
	@echo "Cleaning up..."
	@rm -rf $(GO_OUT_DIR)
	@rm -rf bin
	@docker rmi $(DOCKER_REGISTRY)/$(SERVER_NAME):$(VERSION) 2>/dev/null || true
	@docker rmi $(DOCKER_REGISTRY)/$(CLIENT_NAME):$(VERSION) 2>/dev/null || true

# Install protobuf tools
.PHONY: protobuf-tools
protobuf-tools:
	@echo "Installing protobuf tools..."
	@go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	@go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Help target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  generate     - Generate Go code from .proto files"
	@echo "  build        - Build server and client binaries"
	@echo "  docker-build - Build Docker images"
	@echo "  docker-push  - Push Docker images to registry"
	@echo "  run-server   - Run server locally"
	@echo "  run-client   - Run client locally"
	@echo "  clean        - Remove generated files and images"
	@echo "  protobuf-tools - Install protobuf generation tools"
	@echo "  help         - Show this help message"
