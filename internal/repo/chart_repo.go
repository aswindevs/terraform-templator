package repo

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path"

	"terraform-templator/internal/logger"

	ocispec "github.com/opencontainers/image-spec/specs-go/v1"
	"oras.land/oras-go/v2/content"
	"oras.land/oras-go/v2/registry/remote"
)

type chartRepo struct{}

func NewChartRepo() *chartRepo {
	return &chartRepo{}
}

func (r *chartRepo) PullChart(registry string) (string, error) {
	ctx := context.Background()

	// Create repository with full reference
	repo, err := remote.NewRepository(registry)
	if err != nil {
		return "", err
	}

	logger.Info("Pulling Chart", logger.String("registry", registry))

	// Get manifest
	manifestDescriptor, rc, err := repo.FetchReference(ctx, registry)
	if err != nil {
		return "", err
	}
	defer rc.Close()

	// Read and parse manifest
	pulledContent, err := content.ReadAll(rc, manifestDescriptor)
	if err != nil {
		return "", err
	}

	var pulledManifest ocispec.Manifest
	if err := json.Unmarshal(pulledContent, &pulledManifest); err != nil {
		return "", err
	}

	// Create output directory with proper permissions
	chartDir := "charts"
	if err := os.MkdirAll(chartDir, 0755); err != nil {
		return "", err
	}

	// Process each layer
	var chartName string
	var filePath string
	for _, layer := range pulledManifest.Layers {
		if name := pulledManifest.Annotations["org.opencontainers.image.title"]; name != "" {
			chartName = name
		}
		filename := fmt.Sprintf("%s.tgz", chartName)
		filePath = path.Join(chartDir, filename)
		logger.Info("Downloading chart", logger.String("name", chartName))
		chartBlob, err := content.FetchAll(ctx, repo, layer)
		if err != nil {
			return "", err
		}

		if err := os.WriteFile(filePath, chartBlob, 0644); err != nil {
			return "", err
		}
	}

	// Extract and cleanup
	cmd := exec.Command("tar", "-xzf", filePath, "-C", chartDir)
	if err := cmd.Run(); err != nil {
		return "", err
	}

	if err := os.Remove(filePath); err != nil {
		logger.Info("Failed to remove temporary file",
			logger.String("file", filePath),
			logger.String("error", err.Error()))
	}

	chartPath := path.Join(chartDir, chartName)
	return chartPath, nil
}
