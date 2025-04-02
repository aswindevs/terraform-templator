package repo

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"terraform-templator/internal/entity"
	"terraform-templator/internal/logger"

	"github.com/Masterminds/sprig/v3"
	"go.uber.org/zap"
	"gopkg.in/yaml.v3"
)

type templateRepo struct{}

func NewTemplateRepo() *templateRepo {
	return &templateRepo{}
}

func (r *templateRepo) RenderChart(chartPath, outputDir, valuesFile string) error {
	// Load the chart
	chart, err := r.LoadChart(chartPath)
	if err != nil {
		return err
	}

	// Validate the chart
	if err := r.ValidateChart(chart); err != nil {
		return err
	}

	// Create output directory
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		return err
	}

	// Render each template
	for _, tmpl := range chart.Templates {
		if err := r.RenderTemplate(tmpl, chart.Values, outputDir); err != nil {
			return err
		}
	}

	return nil
}

func (r *templateRepo) LoadChart(chartPath string) (*entity.Chart, error) {
	logger.Debug("Loading chart", zap.String("path", chartPath))

	// Read Chart.yaml
	chartData, err := os.ReadFile(filepath.Join(chartPath, "Chart.yaml"))
	if err != nil {
		return nil, fmt.Errorf("failed to read Chart.yaml: %w", err)
	}

	var chart entity.Chart
	if err := yaml.Unmarshal(chartData, &chart); err != nil {
		return nil, fmt.Errorf("failed to parse Chart.yaml: %w", err)
	}

	// Load templates
	templatesDir := filepath.Join(chartPath, "templates")
	if err := os.MkdirAll(templatesDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create templates directory: %w", err)
	}

	files, err := os.ReadDir(templatesDir)
	if err != nil {
		return nil, fmt.Errorf("failed to read templates directory: %w", err)
	}

	for _, file := range files {
		if !file.IsDir() && strings.HasSuffix(file.Name(), ".tf") {
			content, err := os.ReadFile(filepath.Join(templatesDir, file.Name()))
			if err != nil {
				return nil, fmt.Errorf("failed to read template %s: %w", file.Name(), err)
			}
			chart.Templates = append(chart.Templates, entity.ChartTemplate{
				Name:    file.Name(),
				Content: string(content),
			})
			logger.Debug("Loaded template", zap.String("name", file.Name()))
		}
	}

	logger.Info("Chart loaded successfully",
		zap.String("name", chart.Name),
		zap.String("version", chart.Version),
		zap.Int("template_count", len(chart.Templates)))
	return &chart, nil
}

func (r *templateRepo) ValidateChart(chart *entity.Chart) error {
	if chart == nil {
		return fmt.Errorf("chart is nil")
	}
	if chart.Name == "" {
		return fmt.Errorf("chart name is required")
	}
	if chart.Version == "" {
		return fmt.Errorf("chart version is required")
	}
	if len(chart.Templates) == 0 {
		return fmt.Errorf("no templates found in chart")
	}
	logger.Debug("Chart validation successful")
	return nil
}

func (r *templateRepo) RenderTemplate(tmpl entity.ChartTemplate, values map[string]interface{}, outputDir string) error {
	// Get template name without .tf extension
	templateKey := strings.TrimSuffix(tmpl.Name, ".tf")
	outputPath := filepath.Join(outputDir, tmpl.Name)

	logger.Debug("Processing template",
		zap.String("name", tmpl.Name),
		zap.String("key", templateKey))

	// Check if template is enabled in values
	if _, exists := values[templateKey]; !exists {
		// Delete the file if it exists
		if err := os.Remove(outputPath); err != nil && !os.IsNotExist(err) {
			logger.Error("Failed to remove unconfigured file",
				zap.String("file", outputPath),
				zap.Error(err))
			return fmt.Errorf("failed to remove unconfigured file %s: %w", outputPath, err)
		}
		logger.Info("Removed unconfigured template", zap.String("name", tmpl.Name))
		return nil
	}

	template, err := template.New(tmpl.Name).
		Funcs(sprig.TxtFuncMap()).
		Parse(tmpl.Content)
	if err != nil {
		logger.Error("Failed to parse template",
			zap.String("name", tmpl.Name),
			zap.Error(err))
		return fmt.Errorf("failed to parse template %s: %w", tmpl.Name, err)
	}

	if err := os.MkdirAll(filepath.Dir(outputPath), 0755); err != nil {
		logger.Error("Failed to create output directory",
			zap.String("path", filepath.Dir(outputPath)),
			zap.Error(err))
		return fmt.Errorf("failed to create output directory: %w", err)
	}

	f, err := os.Create(outputPath)
	if err != nil {
		logger.Error("Failed to create output file",
			zap.String("path", outputPath),
			zap.Error(err))
		return fmt.Errorf("failed to create output file %s: %w", outputPath, err)
	}
	defer f.Close()

	if err := template.Execute(f, values); err != nil {
		logger.Error("Failed to render template",
			zap.String("name", tmpl.Name),
			zap.Error(err))
		return fmt.Errorf("failed to render template %s: %w", tmpl.Name, err)
	}

	logger.Info("Rendered template successfully", zap.String("name", tmpl.Name))
	return nil
}
