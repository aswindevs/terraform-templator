package http

import (
	"net/http"

	"terraform-templator/internal/usecase"

	"github.com/gin-gonic/gin"
)

type TemplateHandler struct {
	useCase *usecase.TemplateUseCase
}

func NewTemplateHandler(useCase *usecase.TemplateUseCase) *TemplateHandler {
	return &TemplateHandler{
		useCase: useCase,
	}
}

type renderRequest struct {
	Values      map[string]interface{} `json:"values" binding:"required"`
	TemplateDir string                 `json:"templateDir" binding:"required"`
	OutputDir   string                 `json:"outputDir" binding:"required"`
}

func (h *TemplateHandler) Render(c *gin.Context) {
	var req renderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.useCase.RenderTemplate(req.Values, req.TemplateDir, req.OutputDir); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success"})
}
