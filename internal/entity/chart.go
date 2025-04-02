package entity

// Chart represents a Terraform template chart
type Chart struct {
	Name        string `yaml:"name"`
	Version     string `yaml:"version"`
	Description string `yaml:"description,omitempty"`
	Type        string `yaml:"type,omitempty"`
	Metadata    ChartMetadata
	Values      map[string]interface{}
	Templates   []ChartTemplate
	ValuesFiles []string
}

// ChartMetadata contains metadata about the chart
type ChartMetadata struct {
	Name        string       `yaml:"name"`
	Version     string       `yaml:"version"`
	Description string       `yaml:"description"`
	Type        string       `yaml:"type"` // e.g., "aws", "gcp", "azure"
	Author      string       `yaml:"author,omitempty"`
	Home        string       `yaml:"home,omitempty"`
	Keywords    []string     `yaml:"keywords,omitempty"`
	Maintainers []Maintainer `yaml:"maintainers,omitempty"`
}

// Maintainer represents a chart maintainer
type Maintainer struct {
	Name  string `yaml:"name"`
	Email string `yaml:"email,omitempty"`
	URL   string `yaml:"url,omitempty"`
}

// ChartTemplate represents a template file in the chart
type ChartTemplate struct {
	Name    string
	Path    string
	Content string
}

// ChartRepository defines the interface for chart operations
type ChartRepository interface {
	LoadChart(path string, valuesFile string) (*Chart, error)
	ValidateChart(chart *Chart) error
}
