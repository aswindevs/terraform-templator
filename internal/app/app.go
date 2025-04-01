package app

import (
	"terraform-templator/internal/controller/http"
	"terraform-templator/internal/repo"
	"terraform-templator/internal/usecase"

	"github.com/gin-gonic/gin"
)

type App struct {
	httpServer *gin.Engine
}

func NewApp() *App {
	gin.SetMode(gin.ReleaseMode)
	httpServer := gin.Default()

	// Initialize dependencies
	templateRepo := repo.NewTemplateRepo()
	templateUseCase := usecase.NewTemplateUseCase(templateRepo)
	templateHandler := http.NewTemplateHandler(templateUseCase)

	// Setup routes
	httpServer.POST("/render", templateHandler.Render)

	return &App{
		httpServer: httpServer,
	}
}

func (a *App) Run(addr string) error {
	return a.httpServer.Run(addr)
}
