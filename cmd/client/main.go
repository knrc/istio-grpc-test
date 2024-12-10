package main

import (
	"context"
	"log"
	"os"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	"github.com/knrc/grpctest/pkg/generated/greet/pb"
)

func main() {
	// Create a new client connection
	server := "172.17.0.2"
	if len(os.Args) > 1 {
		server = os.Args[1]
	}

	log.Printf("Sending request to %s", server)

	for {
		callClient(server)
	}
}

func callClient(server string) {
	conn, err := grpc.NewClient(server+":50050",
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
	}
	defer conn.Close()

	// Create the gRPC service client
	client := pb.NewGreetServiceClient(conn)

	for {
		err := callService(client)
		if err != nil {
			break
		}
	}
}

func callService(client pb.GreetServiceClient) error {
	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	// Make the gRPC call
	r, err := client.SayHello(ctx, &pb.HelloRequest{Name: "World"})
	if err != nil {
		log.Printf("Could not greet: %v", err)
		return err
	}

	log.Printf("Greeting: %s", r.GetGreeting())
	return nil
}
