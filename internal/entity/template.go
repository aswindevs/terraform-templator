package entity

type Template struct {
	Values      map[string]interface{}
	TemplateDir string
	OutputDir   string
	Content     string
}

type TemplateRepository interface {
	LoadChart(chartPath string) (*Chart, error)
	ValidateChart(chart *Chart) error
	RenderTemplate(tmpl ChartTemplate, values map[string]interface{}, outputDir string) error
}
