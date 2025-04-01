package usecase

import (
	"terraform-templator/internal/entity"
)

type TemplateUseCase struct {
	repo entity.TemplateRepository
}

func NewTemplateUseCase(repo entity.TemplateRepository) *TemplateUseCase {
	return &TemplateUseCase{
		repo: repo,
	}
}


func (u *TemplateUseCase) RenderChart(chartPath, outputDir, valuesFile string) error {
	return u.repo.RenderChart(chartPath, outputDir, valuesFile)
}
