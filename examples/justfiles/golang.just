# Go-specific recipes

# Run Go linters
go-lint:
  golangci-lint run ./...

# Run Go tests with coverage
go-test:
  go test -v -cover -race ./...

# Run Go tests with detailed coverage
go-test-coverage:
  go test -v -coverprofile=coverage.out ./...
  go tool cover -html=coverage.out -o coverage.html
  @echo "Coverage report: coverage.html"

# Format Go code
go-fmt:
  gofmt -s -w .
  goimports -w .

# Tidy Go modules
go-tidy:
  go mod tidy
  go mod verify

# Run all Go checks
go-check: go-lint go-test
