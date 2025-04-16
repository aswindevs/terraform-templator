package logger

import (
	"fmt"
	"os"
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var log *zap.Logger

// Field represents a key-value pair for structured logging
type Field struct {
	Key   string
	Value interface{}
}

func init() {
	// Set default log level from environment or default to info
	logLevel := os.Getenv("LOG_LEVEL")
	if logLevel == "" {
		logLevel = "info"
	}
	logMode := os.Getenv("LOG_MODE")
	if logMode == "" {
		logMode = "console"
	}

	config := zap.NewProductionConfig()
	config.DisableCaller = true
	config.EncoderConfig.EncodeLevel = zapcore.CapitalColorLevelEncoder
	config.EncoderConfig.TimeKey = "timestamp"
	config.EncoderConfig.EncodeTime = func(t time.Time, enc zapcore.PrimitiveArrayEncoder) {
		enc.AppendString(t.Format("02-01-2006 15:04:05"))
	}

	if logMode != "json" {
		config.EncoderConfig.EncodeName = func(name string, enc zapcore.PrimitiveArrayEncoder) {
			enc.AppendString(name + " | ")
		}
		config.EncoderConfig.ConsoleSeparator = " | "
	}

	// Set log level from environment variable
	switch logLevel {
	case "debug":
		config.Level = zap.NewAtomicLevelAt(zapcore.DebugLevel)
	case "warn":
		config.Level = zap.NewAtomicLevelAt(zapcore.WarnLevel)
	case "error":
		config.Level = zap.NewAtomicLevelAt(zapcore.ErrorLevel)
	default:
		config.Level = zap.NewAtomicLevelAt(zapcore.InfoLevel)
	}

	if logMode == "json" {
		config.Encoding = "json"
	} else {
		config.Encoding = "console"
	}

	var err error
	log, err = config.Build()
	if err != nil {
		panic(err)
	}
}

// convertFields converts our Field type to zap.Field
func convertFields(fields []Field) []zap.Field {
	zapFields := make([]zap.Field, len(fields))
	for i, f := range fields {
		zapFields[i] = zap.Any(f.Key, f.Value)
	}
	return zapFields
}

// String creates a string field
func String(key string, value string) Field {
	return Field{Key: key, Value: value}
}

// Int creates an integer field
func Int(key string, value int) Field {
	return Field{Key: key, Value: value}
}

// Error creates an error field
func ErrorField(key string, value error) Field {
	return Field{Key: key, Value: value}
}

// Debug logs a debug message with structured fields
func Debug(msg string, fields ...Field) {
	log.Debug(msg, convertFields(fields)...)
}

// Info logs an info message with structured fields
func Info(msg string, fields ...Field) {
	log.Info(msg, convertFields(fields)...)
}

// Warn logs a warning message with structured fields
func Warn(msg string, fields ...Field) {
	log.Warn(msg, convertFields(fields)...)
}

// Error logs an error message with structured fields and returns an error
func Error(msg string, fields ...Field) error {
	log.Error(msg, convertFields(fields)...)
	return fmt.Errorf(msg)
}

// Fatal logs a fatal message and exits
func Fatal(msg string, fields ...Field) {
	log.Fatal(msg, convertFields(fields)...)
	os.Exit(1)
}

// With creates a child logger with the given fields
func With(fields ...Field) *zap.Logger {
	return log.With(convertFields(fields)...)
}
