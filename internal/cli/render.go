package cli

import (
	"terraform-templator/internal/logger"
	"terraform-templator/internal/repo"
	"terraform-templator/internal/usecase"

	"github.com/spf13/cobra"
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
			logger.String("chart_path", chartPath),
			logger.String("output_dir", outputDir),
			logger.String("values_file", valuesFile))

		// Initialize dependencies
		templateRepo := repo.NewTemplateRepo()
		templateUseCase := usecase.NewTemplateUseCase(templateRepo)

		// Validate inputs
		if chartPath == "" {
			return logger.Error("Invalid input - chart path is required")
		}
		if valuesFile == "" {
			valuesFile = "values.yaml"
			logger.Info("Using default values file", logger.String("file", valuesFile))
		}

		// Render chart
		if err := templateUseCase.RenderChart(valuesFile, chartPath, outputDir); err != nil {
			return logger.Error("Chart rendering failed", logger.ErrorField("error", err))

		}

		logger.Info("Chart rendering completed successfully",
			logger.String("output_dir", outputDir))
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
