package usecase

import (
	"os"
	"terraform-templator/internal/entity"
	"terraform-templator/internal/logger"

	"go.uber.org/zap"
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
		zap.String("chart_path", chartPath),
		zap.String("values_file", valuesFile),
		zap.String("output_dir", outputDir))

	// Load values from file
	values, err := loadValues(valuesFile)
	if err != nil {
		logger.Error("Failed to load values file",
			zap.String("file", valuesFile),
			zap.Error(err))
		return err
	}

	// Load the chart
	chart, err := u.repo.LoadChart(chartPath)
	if err != nil {
		logger.Error("Failed to load chart",
			zap.String("path", chartPath),
			zap.Error(err))
		return err
	}

	// Validate the chart
	if err := u.repo.ValidateChart(chart); err != nil {
		logger.Error("Chart validation failed",
			zap.String("name", chart.Name),
			zap.Error(err))
		return err
	}

	// Create output directory
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		logger.Error("Failed to create output directory",
			zap.String("path", outputDir),
			zap.Error(err))
		return err
	}

	// Render each template
	for _, tmpl := range chart.Templates {
		if err := u.repo.RenderTemplate(tmpl, values, outputDir); err != nil {
			logger.Error("Failed to render template",
				zap.String("name", tmpl.Name),
				zap.Error(err))
			return err
		}
	}

	logger.Info("Chart rendering completed successfully",
		zap.String("chart", chart.Name),
		zap.String("version", chart.Version))
	return nil
}

func loadValues(valuesFile string) (map[string]interface{}, error) {
	logger.Debug("Loading values file", zap.String("file", valuesFile))

	data, err := os.ReadFile(valuesFile)
	if err != nil {
		return nil, err
	}

	var values map[string]interface{}
	if err := yaml.Unmarshal(data, &values); err != nil {
		return nil, err
	}

	logger.Debug("Values file loaded successfully",
		zap.Int("key_count", len(values)))
	return values, nil
}
