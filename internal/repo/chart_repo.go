package repo

import (
	"os"
	"path/filepath"
	"strings"

	"terraform-templator/internal/entity"
	"terraform-templator/internal/logger"

	"gopkg.in/yaml.v2"
)

type chartRepo struct{}

func NewChartRepo() *chartRepo {
	return &chartRepo{}
}

func (r *chartRepo) LoadChart(chartPath, valuesFile string) (*entity.Chart, error) {
	// Read Chart.yaml
	chartYAML, err := os.ReadFile(filepath.Join(chartPath, "Chart.yaml"))
	if err != nil {
		return nil, err
	}

	var chart entity.Chart
	if err := yaml.Unmarshal(chartYAML, &chart.Metadata); err != nil {
		return nil, err
	}

	// Read values.yaml
	valuesYAML, err := os.ReadFile(valuesFile)
	if err != nil {
		return nil, err
	}

	if err := yaml.Unmarshal(valuesYAML, &chart.Values); err != nil {
		return nil, err
	}

	// Load templates
	templatesDir := filepath.Join(chartPath, "templates")
	files, err := os.ReadDir(templatesDir)
	if err != nil {
		return nil, err
	}

	for _, file := range files {
		content, err := os.ReadFile(filepath.Join(templatesDir, file.Name()))
		if err != nil {
			return nil, err
		}
		chart.Templates = append(chart.Templates, entity.ChartTemplate{
			Name:    strings.TrimSuffix(file.Name(), ".tf"),
			Content: string(content),
			Path:    file.Name(),
		})
	}

	return &chart, nil
}

func (r *chartRepo) ValidateChart(chart *entity.Chart) error {
	// Validate required fields
	if chart.Metadata.Name == "" {
		return logger.Error("Chart validation failed", logger.String("error", "chart name is required"))
	}
	if chart.Metadata.Version == "" {
		return logger.Error("Chart validation failed", logger.String("error", "chart version is required"))
	}
	if chart.Metadata.Type == "" {
		return logger.Error("Chart validation failed", logger.String("error", "chart type is required"))
	}

	// Validate templates
	if len(chart.Templates) == 0 {
		return logger.Error("Chart validation failed", logger.String("error", "chart must contain at least one template"))
	}

	// Validate values
	if len(chart.Values) == 0 {
		return logger.Error("Chart validation failed", logger.String("error", "chart must contain values"))
	}

	return nil
}
