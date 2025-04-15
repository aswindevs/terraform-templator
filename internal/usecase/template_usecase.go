package usecase

import (
	"os"
	"terraform-templator/internal/entity"
	"terraform-templator/internal/logger"
)

type TemplateUseCase struct {
	templateRepo entity.TemplateRepository
	chartRepo    entity.ChartRepository
}

func NewTemplateUseCase(templateRepo entity.TemplateRepository, chartRepo entity.ChartRepository) *TemplateUseCase {
	return &TemplateUseCase{
		templateRepo: templateRepo,
		chartRepo:    chartRepo,
	}
}

func (u *TemplateUseCase) RenderChart(valuesFile, chartPath, outputDir string, useLocalChart bool) error {
	logger.Debug("Starting chart rendering",
		logger.String("chart_path", chartPath),
		logger.String("values_file", valuesFile),
		logger.String("output_dir", outputDir))

	// Load values from file
	values, err := u.templateRepo.LoadValues(valuesFile)
	if err != nil {
		logger.Error("Failed to load values file",
			logger.String("file", valuesFile),
			logger.ErrorField("error", err))
		return err
	}

	if useLocalChart != true {
		chart, err := u.chartRepo.PullChart(chartPath)
		if err != nil {
			logger.Error("Failed to pull chart",
				logger.String("path", chartPath),
				logger.ErrorField("error", err))
		}
		chartPath = chart
	}

	// Load the chart
	chart, err := u.templateRepo.LoadChart(chartPath)
	if err != nil {
		logger.Error("Failed to load chart",
			logger.String("path", chartPath),
			logger.ErrorField("error", err))
		return err
	}

	// Validate the chart
	if err := u.templateRepo.ValidateChart(chart); err != nil {
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
		if err := u.templateRepo.RenderTemplate(tmpl, values, outputDir); err != nil {
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
