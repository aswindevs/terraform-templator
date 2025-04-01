package entity

type Template struct {
	Values      map[string]interface{}
	TemplateDir string
	OutputDir   string
	Content     string
}

type TemplateRepository interface {
	Render(template *Template) error
	RenderChart(chartPath, outputDir, valuesFile string) error
}
