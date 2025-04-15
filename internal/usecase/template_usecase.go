package usecase

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path"
	"terraform-templator/internal/entity"
	"terraform-templator/internal/logger"

	ocispec "github.com/opencontainers/image-spec/specs-go/v1"
	"gopkg.in/yaml.v3"
	"oras.land/oras-go/v2/content"
	"oras.land/oras-go/v2/registry/remote"
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

func PullHelmChart(registry string) (string, error) {
	ctx := context.Background()
	
	// Create repository with full reference
	repo, err := remote.NewRepository(registry)
	if err != nil {
		return "", fmt.Errorf("failed to create repository: %w", err)
	}
	
	logger.Info("Pulling Chart", logger.String("registry", registry))
	
	// Get manifest
	manifestDescriptor, rc, err := repo.FetchReference(ctx, registry)
	if err != nil {
		return "", fmt.Errorf("failed to fetch manifest: %w", err)
	}
	defer rc.Close()
	
	// Read and parse manifest
	pulledContent, err := content.ReadAll(rc, manifestDescriptor)
	if err != nil {
		return "", fmt.Errorf("failed to read manifest: %w", err)
	}
	
	var pulledManifest ocispec.Manifest
	if err := json.Unmarshal(pulledContent, &pulledManifest); err != nil {
		return "", fmt.Errorf("failed to parse manifest: %w", err)
	}
	
	// Create output directory with proper permissions
	chartDir := "charts"
	if err := os.MkdirAll(chartDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create output directory: %w", err)
	}

	// Process each layer
	chartName := "terraformesh-chart"
	for _, layer := range pulledManifest.Layers {
		if name := pulledManifest.Annotations["org.opencontainers.image.title"]; name != "" {
			chartName = name
		}

		filename := fmt.Sprintf("%s.tgz", chartName)
		filePath := path.Join(chartDir, filename)

		logger.Info("Downloading chart", logger.String("name", chartName))
		chartBlob, err := content.FetchAll(ctx, repo, layer)
		if err != nil {
			return "", fmt.Errorf("failed to fetch chart: %w", err)
		}

		if err := os.WriteFile(filePath, chartBlob, 0644); err != nil {
			return "", fmt.Errorf("failed to write chart: %w", err)
		}

		// Extract and cleanup
		cmd := exec.Command("tar", "-xzf", filePath, "-C", chartDir)
		if err := cmd.Run(); err != nil {
			return "", fmt.Errorf("failed to extract chart: %w", err)
		}

		if err := os.Remove(filePath); err != nil {
			logger.Info("Failed to remove temporary file",
				logger.String("file", filePath),
				logger.String("error", err.Error()))
		}
	}
	chartPath := path.Join(chartDir, chartName)
	return chartPath, nil
}
