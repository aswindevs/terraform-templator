.PHONY: build run test clean cli-build cli-run

# Build variables
BINARY_NAME=terraform-templator
BUILD_DIR=build

# Go commands
GOCMD=go
GOBUILD=$(GOCMD) build
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOCLEAN=$(GOCMD) clean

# Build the application
build:
	mkdir -p $(BUILD_DIR)
	$(GOBUILD) -o $(BUILD_DIR)/$(BINARY_NAME) ./cmd/main.go

# Build the CLI
cli-build:
	mkdir -p $(BUILD_DIR)
	$(GOBUILD) -o $(BUILD_DIR)/$(BINARY_NAME)-cli ./cmd/cli/main.go

# Run the application
run:
	$(GOCMD) run ./cmd/main.go

# Run the CLI
cli-run:
	$(GOCMD) run ./cmd/cli/main.go

# Run tests
test:
	$(GOTEST) -v ./...

# Clean build files
clean:
	$(GOCLEAN)
	rm -rf $(BUILD_DIR)

# Install dependencies
deps:
	$(GOGET) github.com/gin-gonic/gin
	$(GOGET) github.com/spf13/cobra
	$(GOGET) github.com/Masterminds/sprig/v3
	$(GOGET) gopkg.in/yaml.v2

# Run with development mode
dev:
	gin.SetMode(gin.DebugMode)
	$(GOCMD) run ./cmd/main.go

# Run with custom port
run-port:
	$(GOCMD) run ./cmd/main.go --addr=:$(port)

# CLI examples
cli-examples:
	@echo "Render templates:"
	@echo "  terraform-templator-cli render -f values.yaml -t templates -o output"
	@echo "\nShow help:"
	@echo "  terraform-templator-cli --help"
	@echo "  terraform-templator-cli render --help" 