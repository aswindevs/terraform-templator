package usecase

import (
	"terraform-templator/internal/entity"
)

type ChartUseCase struct {
	repo entity.ChartRepository
}

func NewChartUseCase(repo entity.ChartRepository) *ChartUseCase {
	return &ChartUseCase{
		repo: repo,
	}
}

func (c *ChartUseCase) PullChart(registry string) (string, error) {
	chartPath, err := c.repo.PullChart(registry)
	if err != nil {
		return "", err
	}
	return chartPath, nil
}



