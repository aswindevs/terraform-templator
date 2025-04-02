package repo

import (
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"terraform-templator/internal/entity"
	"terraform-templator/internal/logger"

	"github.com/Masterminds/sprig/v3"
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
	logger.Debug("Loading chart", logger.String("path", chartPath))

	// Read Chart.yaml
	chartData, err := os.ReadFile(filepath.Join(chartPath, "Chart.yaml"))
	if err != nil {
		return nil, logger.Error("Failed to read Chart.yaml", logger.ErrorField("error", err))
	}

	var chart entity.Chart
	if err := yaml.Unmarshal(chartData, &chart); err != nil {
		return nil, logger.Error("Failed to parse Chart.yaml", logger.ErrorField("error", err))
	}

	// Load templates
	templatesDir := filepath.Join(chartPath, "templates")
	if err := os.MkdirAll(templatesDir, 0755); err != nil {
		return nil, logger.Error("Failed to create templates directory", logger.ErrorField("error", err))
	}

	files, err := os.ReadDir(templatesDir)
	if err != nil {
		return nil, logger.Error("Failed to read templates directory", logger.ErrorField("error", err))
	}

	for _, file := range files {
		if !file.IsDir() && strings.HasSuffix(file.Name(), ".tf") {
			content, err := os.ReadFile(filepath.Join(templatesDir, file.Name()))
			if err != nil {
				return nil, logger.Error("Failed to read template", logger.String("name", file.Name()), logger.ErrorField("error", err))
			}
			chart.Templates = append(chart.Templates, entity.ChartTemplate{
				Name:    file.Name(),
				Content: string(content),
			})
			logger.Debug("Loaded template", logger.String("name", file.Name()))
		}
	}

	logger.Info("Chart loaded successfully",
		logger.String("name", chart.Name),
		logger.String("version", chart.Version),
		logger.Int("template_count", len(chart.Templates)))
	return &chart, nil
}

func (r *templateRepo) ValidateChart(chart *entity.Chart) error {
	if chart == nil {
		return logger.Error("Chart is nil")
	}
	if chart.Name == "" {
		return logger.Error("Chart name is required")
	}
	if chart.Version == "" {
		return logger.Error("Chart version is required")
	}
	if len(chart.Templates) == 0 {
		return logger.Error("No templates found in chart")
	}
	logger.Debug("Chart validation successful")
	return nil
}

func (r *templateRepo) RenderTemplate(tmpl entity.ChartTemplate, values map[string]interface{}, outputDir string) error {
	// Get template name without .tf extension
	templateKey := strings.TrimSuffix(tmpl.Name, ".tf")
	outputPath := filepath.Join(outputDir, tmpl.Name)

	logger.Debug("Processing template",
		logger.String("name", tmpl.Name),
		logger.String("key", templateKey))

	// Check if template is enabled in values
	if _, exists := values[templateKey]; !exists {
		// Delete the file if it exists
		if err := os.Remove(outputPath); err != nil && !os.IsNotExist(err) {
			logger.Error("Failed to remove unconfigured file",
				logger.String("file", outputPath),
				logger.ErrorField("error", err))
			return logger.Error("Failed to remove unconfigured file", logger.String("name", tmpl.Name), logger.ErrorField("error", err))
		}
		logger.Info("Removed unconfigured template", logger.String("name", tmpl.Name))
		return nil
	}

	template, err := template.New(tmpl.Name).
		Funcs(sprig.TxtFuncMap()).
		Parse(tmpl.Content)
	if err != nil {
		logger.Error("Failed to parse template",
			logger.String("name", tmpl.Name),
			logger.ErrorField("error", err))
		return logger.Error("Failed to parse template", logger.String("name", tmpl.Name), logger.ErrorField("error", err))
	}

	if err := os.MkdirAll(filepath.Dir(outputPath), 0755); err != nil {
		logger.Error("Failed to create output directory",
			logger.String("path", filepath.Dir(outputPath)),
			logger.ErrorField("error", err))
		return logger.Error("Failed to create output directory", logger.String("path", filepath.Dir(outputPath)), logger.ErrorField("error", err))
	}

	f, err := os.Create(outputPath)
	if err != nil {
		logger.Error("Failed to create output file",
			logger.String("path", outputPath),
			logger.ErrorField("error", err))
		return logger.Error("Failed to create output file", logger.String("path", outputPath), logger.ErrorField("error", err))
	}
	defer f.Close()

	if err := template.Execute(f, values); err != nil {
		logger.Error("Failed to render template",
			logger.String("name", tmpl.Name),
			logger.ErrorField("error", err))
		return logger.Error("Failed to render template", logger.String("name", tmpl.Name), logger.ErrorField("error", err))
	}

	logger.Info("Rendered template successfully", logger.String("name", tmpl.Name))
	return nil
}
