package main

import (
	"context"
	"log"
	"net"
	"strconv"
	"sync/atomic"

	"google.golang.org/grpc"

	"github.com/google/uuid"
	"github.com/knrc/grpctest/pkg/generated/greet/pb"
)

type server struct {
	pb.UnimplementedGreetServiceServer

	count atomic.Uint64
	uuid  string
}

func (s *server) SayHello(ctx context.Context, req *pb.HelloRequest) (*pb.HelloResponse, error) {
	log.Printf("Received request from %s", req.Name)
	greeting := strconv.FormatUint(s.count.Add(1), 10) + ": Hello, " + req.Name + " from server " + s.uuid + "!"
	defer log.Printf("Returning greeting '%v'\n", greeting)
	return &pb.HelloResponse{
		Greeting: greeting,
	}, nil
}

func main() {
	uuid := uuid.New()
	lis, err := net.Listen("tcp", ":50050")
	if err != nil {
		log.Fatalf("Failed to listen: %v", err)
	}

	s := grpc.NewServer()
	pb.RegisterGreetServiceServer(s, &server{uuid: uuid.String()})

	log.Println("Server " + uuid.String() + " listening on :50050")
	if err := s.Serve(lis); err != nil {
		log.Fatalf("Failed to serve: %v", err)
	}
}
