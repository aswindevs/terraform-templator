package cli

import (
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
		// Initialize dependencies
		templateRepo := repo.NewTemplateRepo()
		templateUseCase := usecase.NewTemplateUseCase(templateRepo)

		// Render chart
		return templateUseCase.RenderChart(chartPath, outputDir, valuesFile)
	},
}

func init() {
	rootCmd.AddCommand(renderCmd)

	renderCmd.Flags().StringVarP(&chartPath, "chart", "c", "", "Path to chart directory")
	renderCmd.Flags().StringVarP(&outputDir, "output", "o", "output", "Path to output directory")
	renderCmd.Flags().StringVarP(&valuesFile, "values", "f", "values.yaml", "Path to values file")

	renderCmd.MarkFlagRequired("chart")
}
