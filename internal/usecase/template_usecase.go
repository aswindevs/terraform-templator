package usecase

import (
	"os"
	"terraform-templator/internal/entity"
	"terraform-templator/internal/logger"

	"gopkg.in/yaml.v3"
)

type TemplateUseCase struct {
	repo entity.TemplateRepository
}

func NewTemplateUseCase(repo entity.TemplateRepository) *TemplateUseCase {
	return &TemplateUseCase{
		repo: repo,
	}
}

func (u *TemplateUseCase) RenderChart(valuesFile, chartPath, outputDir string) error {
	logger.Debug("Starting chart rendering",
		logger.String("chart_path", chartPath),
		logger.String("values_file", valuesFile),
		logger.String("output_dir", outputDir))

	// Load values from file
	values, err := loadValues(valuesFile)
	if err != nil {
		logger.Error("Failed to load values file",
			logger.String("file", valuesFile),
			logger.ErrorField("error", err))
		return err
	}

	// Load the chart
	chart, err := u.repo.LoadChart(chartPath)
	if err != nil {
		logger.Error("Failed to load chart",
			logger.String("path", chartPath),
			logger.ErrorField("error", err))
		return err
	}

	// Validate the chart
	if err := u.repo.ValidateChart(chart); err != nil {
		logger.Error("Chart validation failed",
			logger.String("name", chart.Name),
			logger.ErrorField("error", err))
		return err
	}

	// Create output directory
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		logger.Error("Failed to create output directory",
			logger.String("path", outputDir),
			logger.ErrorField("error", err))
		return err
	}

	// Render each template
	for _, tmpl := range chart.Templates {
		if err := u.repo.RenderTemplate(tmpl, values, outputDir); err != nil {
			logger.Error("Failed to render template",
				logger.String("name", tmpl.Name),
				logger.ErrorField("error", err))
			return err
		}
	}

	logger.Info("Chart rendering completed successfully",
		logger.String("chart", chart.Name),
		logger.String("version", chart.Version))
	return nil
}

func loadValues(valuesFile string) (map[string]interface{}, error) {
	logger.Debug("Loading values file", logger.String("file", valuesFile))

	data, err := os.ReadFile(valuesFile)
	if err != nil {
		return nil, err
	}

	var values map[string]interface{}
	if err := yaml.Unmarshal(data, &values); err != nil {
		return nil, err
	}

	logger.Debug("Values file loaded successfully",
		logger.Int("key_count", len(values)))
	return values, nil
}
