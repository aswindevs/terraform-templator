package main

import (
	"flag"
	"fmt"
	"os"

	"terraform-templator/internal/cli"
	"terraform-templator/internal/server"
)

func main() {
	// CLI flags
	serverMode := flag.Bool("server", false, "Run in server mode")
	port := flag.String("port", "8080", "Port to run server on (server mode only)")
	flag.Parse()

	if *serverMode {
		// Run in server mode
		srv := server.NewServer()
		fmt.Printf("Starting server on port %s...\n", *port)
		if err := srv.Start(*port); err != nil {
			fmt.Printf("Server error: %v\n", err)
			os.Exit(1)
		}
	} else {
		// Run in CLI mode
		if err := cli.Execute(); err != nil {
			fmt.Printf("Error: %v\n", err)
			os.Exit(1)
		}
	}
}
