locals {
  tags = {
    {{- range $key, $value := .tags }}
    {{ $key }} = "{{ $value }}"
    {{- end }}
  }
} 