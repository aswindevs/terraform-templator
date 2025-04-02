# Terraformesh

A powerful tool for managing and rendering Terraform templates using a chart-based approach, similar to Helm for Kubernetes.

## Features

- **Chart-based Template Management**: Organize Terraform templates in a structured chart format
- **Dynamic Template Rendering**: Render templates based on configuration in `values.yaml`
- **Structured Logging**: Built-in logging with different levels (debug, info, warn, error)
- **Flexible Output**: Support for both console and JSON logging formats
- **Environment-based Configuration**: Configure logging behavior through environment variables


## Chart Structure

A chart is a collection of Terraform templates organized in a specific directory structure:

```
my-chart/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── main.tf
    ├── vpc.tf
    ├── ecs.tf
    └── rds.tf
```

### Chart.yaml

Contains metadata about the chart:

```yaml
name: my-chart
version: 1.0.0
type: terraform
description: My Terraform chart
```

### values.yaml

Contains configuration values for the templates:

```yaml
project:
  name: my-project
  region: us-west-2

vpc:
  cidr: 10.0.0.0/16
  enable_nat: true

ecs:
  cluster_name: my-cluster
  instance_type: t3.medium
```

## Usage

### Basic Usage

```bash
terraformesh render --chart ./charts/my-chart --output ./output
```

### Command Options

- `--chart, -c`: Path to chart directory (required)
- `--output, -o`: Path to output directory (default: "output")
- `--values, -f`: Path to values file (default: "values.yaml")

### Logging Configuration

Control logging behavior through environment variables:

```bash
# Set log level (debug, info, warn, error)
export LOG_LEVEL=debug

# Set log format (console, json)
export LOG_MODE=json

# Run the command
terraformesh render --chart ./charts/my-chart
```

## Development

### Prerequisites

- Go 1.16 or later
- Make (optional, for using Makefile commands)

### Building

```bash
# Build the binary
make build

# Run tests
make test

# Run linter
make lint
```

### Project Structure

```
.
├── cmd/
│   └── cli/          # CLI entry point
├── internal/
│   ├── cli/          # CLI command implementations
│   ├── entity/       # Domain entities
│   ├── logger/       # Logging package
│   ├── repo/         # Repository implementations
│   └── usecase/      # Business logic
├── charts/           # Example charts
├── Makefile
├── go.mod
└── README.md
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 