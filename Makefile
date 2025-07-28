# Makefile for ignorer CLI

BINARY_NAME=ignorer
BINARY_UNIX=$(BINARY_NAME)_unix
BINARY_LINUX=$(BINARY_NAME)_linux
BINARY_DARWIN=$(BINARY_NAME)_darwin
BINARY_WINDOWS=$(BINARY_NAME).exe

VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
LDFLAGS=-ldflags "-X main.version=$(VERSION)"

.PHONY: all build build-all clean test test-coverage run help install uninstall
.DEFAULT_GOAL := help

all: test build ## Run tests and build binary

build: ## Build the binary for current platform
	@echo "Building $(BINARY_NAME)..."
	go build $(LDFLAGS) -o bin/$(BINARY_NAME) cmd/ignorer/main.go

build-all: build-linux build-darwin build-windows ## Build binaries for all platforms

build-linux: ## Build binary for Linux
	@echo "Building for Linux..."
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o bin/$(BINARY_LINUX) cmd/ignorer/main.go

build-darwin: ## Build binary for macOS
	@echo "Building for macOS..."
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build $(LDFLAGS) -o bin/$(BINARY_DARWIN) cmd/ignorer/main.go

build-windows: ## Build binary for Windows
	@echo "Building for Windows..."
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build $(LDFLAGS) -o bin/$(BINARY_WINDOWS) cmd/ignorer/main.go

test: ## Run all tests
	@echo "Running tests..."
	go test -v ./...

test-coverage: ## Run tests with coverage
	@echo "Running tests with coverage..."
	go test -race -coverprofile=coverage.out -covermode=atomic ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated at coverage.html"

run: build ## Build and run the binary
	./bin/$(BINARY_NAME)

install: build ## Install the binary to GOPATH/bin
	@echo "Installing $(BINARY_NAME)..."
	cp bin/$(BINARY_NAME) $(GOPATH)/bin/$(BINARY_NAME)

uninstall: ## Remove the binary from GOPATH/bin
	@echo "Uninstalling $(BINARY_NAME)..."
	rm -f $(GOPATH)/bin/$(BINARY_NAME)

clean: ## Clean build artifacts
	@echo "Cleaning..."
	go clean
	rm -rf bin/
	rm -f coverage.out coverage.html

deps: ## Download dependencies
	@echo "Downloading dependencies..."
	go mod download
	go mod tidy

fmt: ## Format Go code
	@echo "Formatting code..."
	go fmt ./...

lint: ## Run linter
	@echo "Running linter..."
	golangci-lint run

dev-setup: deps ## Setup development environment
	@echo "Setting up development environment..."
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

release-prep: clean test-coverage build-all ## Prepare for release
	@echo "Release preparation complete"
	@echo "Binaries available in ./bin/"
	@ls -la ./bin/

# Homebrew formula helpers
homebrew-sha256: build-darwin ## Calculate SHA256 for Homebrew formula
	@echo "SHA256 for Homebrew formula:"
	@shasum -a 256 bin/$(BINARY_DARWIN) | cut -d' ' -f1

help: ## Display this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) 