package repo

import (
	"fmt"
	"os"
	"path/filepath"
	"text/template"

	"terraform-templator/internal/entity"

	"github.com/Masterminds/sprig/v3"
	"gopkg.in/yaml.v3"
)

type templateRepo struct {
	chartRepo *chartRepo
}

func NewTemplateRepo() *templateRepo {
	return &templateRepo{
		chartRepo: NewChartRepo(),
	}
}

func (r *templateRepo) RenderChart(chartPath, outputDir, valuesFile string) error {
	// Load the chart
	chart, err := r.chartRepo.LoadChart(chartPath, valuesFile)
	if err != nil {
		return err
	}

	// Validate the chart
	if err := r.chartRepo.ValidateChart(chart); err != nil {
		return err
	}

	// Create output directory
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		return err
	}

	// Render each template
	for _, tmpl := range chart.Templates {
		if err := r.renderTemplate(tmpl, chart.Values, outputDir); err != nil {
			return err
		}
	}

	return nil
}

func (r *templateRepo) renderTemplate(tmpl entity.ChartTemplate, values map[string]interface{}, outputDir string) error {
	// Convert values to YAML bytes
	yamlBytes, err := yaml.Marshal(values)
	if err != nil {
		return fmt.Errorf("failed to marshal values: %w", err)
	}

	// Unmarshal into a structured type
	var unmarshalledValues map[string]interface{}
	if err := yaml.Unmarshal(yamlBytes, &unmarshalledValues); err != nil {
		return fmt.Errorf("failed to unmarshal values: %w", err)
	}
	outputPath := filepath.Join(outputDir, tmpl.Path)

	// Check if module is enabled
	if _, ok := unmarshalledValues[tmpl.Name]; ok {
		fmt.Println(tmpl.Name)
		template, err := template.New(tmpl.Name).
			Funcs(sprig.TxtFuncMap()).
			Parse(tmpl.Content)
		if err != nil {
			return err
		}

		// Create output file
		f, err := os.Create(outputPath)
		if err != nil {
			return err
		}
		defer f.Close()

		// Execute template
		return template.Execute(f, values)
	} else {
		fmt.Println("Module is disabled", tmpl.Name)
		os.Remove(outputPath)
	}

	return nil
}
