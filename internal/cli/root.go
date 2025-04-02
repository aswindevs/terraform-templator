package cli

import (
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "terraformesh",
	Short: "A tool for rendering Terraform templates",
	Long: `Terraformesh is a CLI tool that helps you render Terraform templates
using values from a YAML file, similar to how Helm works.`,
}

func Execute() error {
	return rootCmd.Execute()
}
