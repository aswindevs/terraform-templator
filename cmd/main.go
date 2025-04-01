package main

import (
	"flag"
	"log"

	"terraform-templator/internal/app"
)

func main() {
	addr := flag.String("addr", ":8080", "Server address")
	flag.Parse()

	application := app.NewApp()
	log.Printf("Starting server on %s", *addr)
	if err := application.Run(*addr); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
