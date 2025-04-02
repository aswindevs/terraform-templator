package cli

import (
	"fmt"
	"terraform-templator/internal/logger"
	"terraform-templator/internal/repo"
	"terraform-templator/internal/usecase"

	"github.com/spf13/cobra"
	"go.uber.org/zap"
)

var (
	chartPath  string
	outputDir  string
	valuesFile string
)

var renderCmd = &cobra.Command{
	Use:   "render",
	Short: "Render Terraform templates from a chart",
	Long: `Render Terraform templates from a chart using values from values.yaml.
Example:
  terraform-templator render --chart ./charts/aws-vpc --output ./output`,
	RunE: func(cmd *cobra.Command, args []string) error {
		logger.Debug("Starting render command",
			zap.String("chart_path", chartPath),
			zap.String("output_dir", outputDir),
			zap.String("values_file", valuesFile))

		// Initialize dependencies
		templateRepo := repo.NewTemplateRepo()
		templateUseCase := usecase.NewTemplateUseCase(templateRepo)

		// Validate inputs
		if chartPath == "" {
			err := fmt.Errorf("chart path is required")
			logger.Error("Invalid input", zap.Error(err))
			return err
		}
		if valuesFile == "" {
			valuesFile = "values.yaml"
			logger.Info("Using default values file", zap.String("file", valuesFile))
		}

		// Render chart
		if err := templateUseCase.RenderChart(valuesFile, chartPath, outputDir); err != nil {
			logger.Error("Chart rendering failed", zap.Error(err))
			return fmt.Errorf("failed to render chart: %w", err)
		}

		logger.Info("Chart rendering completed successfully",
			zap.String("output_dir", outputDir))
		return nil
	},
}

func init() {
	rootCmd.AddCommand(renderCmd)

	renderCmd.Flags().StringVarP(&chartPath, "chart", "c", "", "Path to chart directory")
	renderCmd.Flags().StringVarP(&outputDir, "output", "o", "output", "Path to output directory")
	renderCmd.Flags().StringVarP(&valuesFile, "values", "f", "values.yaml", "Path to values file")

	renderCmd.MarkFlagRequired("chart")
}
