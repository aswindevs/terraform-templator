package server

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
	"os"
	"path/filepath"

	"terraform-templator/internal/repo"
)

type Server struct {
	templateRepo *repo.TemplateRepo
}

func NewServer() *Server {
	return &Server{
		templateRepo: repo.NewTemplateRepo(),
	}
}

type RenderRequest struct {
	ChartPath  string                 `json:"chart_path"`
	OutputDir  string                 `json:"output_dir"`
	ValuesFile string                 `json:"values_file"`
	Values     map[string]interface{} `json:"values,omitempty"`
}

type RenderResponse struct {
	Status string            `json:"status"`
	Files  map[string]string `json:"files"`
	Error  string            `json:"error,omitempty"`
}

func (s *Server) Start(port string) error {
	http.HandleFunc("/render", s.handleRender)
	return http.ListenAndServe(":"+port, nil)
}

func (s *Server) handleRender(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req RenderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Create a temporary directory for rendering
	tempDir, err := ioutil.TempDir("", "terraform-render-*")
	if err != nil {
		sendError(w, "Failed to create temporary directory", http.StatusInternalServerError)
		return
	}
	defer os.RemoveAll(tempDir)

	// Render the chart
	if err := s.templateRepo.RenderChart(req.ChartPath, tempDir, req.ValuesFile); err != nil {
		sendError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Read all rendered files
	files := make(map[string]string)
	err = filepath.Walk(tempDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			content, err := ioutil.ReadFile(path)
			if err != nil {
				return err
			}
			relPath, err := filepath.Rel(tempDir, path)
			if err != nil {
				return err
			}
			files[relPath] = string(content)
		}
		return nil
	})

	if err != nil {
		sendError(w, "Failed to read rendered files", http.StatusInternalServerError)
		return
	}

	// Send response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(RenderResponse{
		Status: "success",
		Files:  files,
	})
}

func sendError(w http.ResponseWriter, message string, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(RenderResponse{
		Status: "error",
		Error:  message,
	})
}
