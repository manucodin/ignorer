# Makefile for ignorer CLI

BINARY_NAME=ignorer
BINARY_UNIX=$(BINARY_NAME)_unix
BINARY_LINUX=$(BINARY_NAME)_linux
BINARY_DARWIN=$(BINARY_NAME)_darwin
BINARY_WINDOWS=$(BINARY_NAME).exe

# Version logic: try to get from git tags, fallback to dev
GIT_TAG := $(shell git describe --tags --exact-match 2>/dev/null)
GIT_DESCRIBE := $(shell git describe --tags --always --dirty 2>/dev/null)
VERSION ?= $(shell \
	if [ -n "$(GIT_TAG)" ]; then \
		echo "$(GIT_TAG)" | sed 's/^v//'; \
	elif [ -n "$(GIT_DESCRIBE)" ]; then \
		echo "$(GIT_DESCRIBE)" | sed 's/^v//'; \
	else \
		echo "dev"; \
	fi)
LDFLAGS=-ldflags "-X main.version=$(VERSION)"

.PHONY: all build build-all clean test test-coverage run help install uninstall version-info
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

install: build ## Install the binary (tries /usr/local/bin, falls back to ~/.local/bin)
	@echo "Installing $(BINARY_NAME)..."
	@if [ -w /usr/local/bin ] 2>/dev/null; then \
		echo "📦 Installing to /usr/local/bin (system-wide)"; \
		cp bin/$(BINARY_NAME) /usr/local/bin/$(BINARY_NAME); \
		echo "✅ $(BINARY_NAME) installed successfully!"; \
	elif sudo -n true 2>/dev/null; then \
		echo "📦 Installing to /usr/local/bin (with sudo)"; \
		sudo cp bin/$(BINARY_NAME) /usr/local/bin/$(BINARY_NAME); \
		echo "✅ $(BINARY_NAME) installed successfully!"; \
	else \
		echo "🔒 No sudo access, installing locally to ~/.local/bin"; \
		mkdir -p ~/.local/bin; \
		cp bin/$(BINARY_NAME) ~/.local/bin/$(BINARY_NAME); \
		echo "✅ $(BINARY_NAME) installed locally!"; \
		echo "💡 Add to your shell profile (~/.zshrc or ~/.bashrc):"; \
		echo "   export PATH=\"\$$HOME/.local/bin:\$$PATH\""; \
	fi

uninstall: ## Remove the binary from all locations
	@echo "Uninstalling $(BINARY_NAME)..."
	@removed=false; \
	if [ -f /usr/local/bin/$(BINARY_NAME) ]; then \
		echo "🗑️  Removing from /usr/local/bin..."; \
		if [ -w /usr/local/bin ] 2>/dev/null; then \
			rm -f /usr/local/bin/$(BINARY_NAME); \
		else \
			sudo rm -f /usr/local/bin/$(BINARY_NAME); \
		fi; \
		removed=true; \
	fi; \
	if [ -f ~/.local/bin/$(BINARY_NAME) ]; then \
		echo "🗑️  Removing from ~/.local/bin..."; \
		rm -f ~/.local/bin/$(BINARY_NAME); \
		removed=true; \
	fi; \
	if [ -n "$(GOPATH)" ] && [ -f $(GOPATH)/bin/$(BINARY_NAME) ]; then \
		echo "🗑️  Removing from $(GOPATH)/bin..."; \
		rm -f $(GOPATH)/bin/$(BINARY_NAME); \
		removed=true; \
	fi; \
	if [ "$$removed" = "true" ]; then \
		echo "✅ $(BINARY_NAME) uninstalled successfully!"; \
	else \
		echo "ℹ️  $(BINARY_NAME) was not found in any installation location."; \
	fi

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

version-info: ## Show version information
	@echo "🏷️  Version Information:"
	@echo "   Git Tag (exact):      $(GIT_TAG)"
	@echo "   Git Describe:         $(GIT_DESCRIBE)"  
	@echo "   Final Version:        $(VERSION)"
	@echo ""
	@echo "💡 To create a new release:"
	@echo "   git tag v1.0.0"
	@echo "   git push origin v1.0.0"

# Homebrew formula helpers
homebrew-sha256: build-darwin ## Calculate SHA256 for Homebrew formula
	@echo "SHA256 for Homebrew formula:"
	@shasum -a 256 bin/$(BINARY_DARWIN) | cut -d' ' -f1

homebrew-update-formula: ## Update Homebrew formula with latest version (for testing)
	@if [ -z "$(VERSION)" ]; then \
		echo "❌ VERSION is required. Usage: make homebrew-update-formula VERSION=1.0.0"; \
		exit 1; \
	fi
	@echo "📝 Updating Homebrew formula for version $(VERSION)..."
	@TARBALL_URL="https://github.com/ignorer/ignorer/archive/v$(VERSION).tar.gz"; \
	curl -sL "$$TARBALL_URL" -o "ignorer-$(VERSION).tar.gz"; \
	SHA256=$$(shasum -a 256 "ignorer-$(VERSION).tar.gz" | cut -d' ' -f1); \
	sed -i.bak "s|url \".*\"|url \"$$TARBALL_URL\"|g" Formula/ignorer.rb; \
	sed -i.bak "s|sha256 \".*\"|sha256 \"$$SHA256\"|g" Formula/ignorer.rb; \
	rm -f Formula/ignorer.rb.bak "ignorer-$(VERSION).tar.gz"; \
	echo "✅ Updated Homebrew formula for version $(VERSION) with SHA256: $$SHA256"

help: ## Display this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) 