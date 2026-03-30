package service

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

const (
	defaultGoExecutionTimeout = 8 * time.Second
	maxGoSnippetBytes         = 32 * 1024
	maxGoExecutionOutputBytes = 16 * 1024
)

var (
	// ErrInvalidGoSnippet rejects empty or disallowed runnable snippets.
	// ErrInvalidGoSnippet 用于拒绝空内容或不允许执行的代码片段。
	ErrInvalidGoSnippet = ErrInvalidCodeSnippet
	// ErrInvalidCodeSnippet rejects empty or disallowed runnable snippets across languages.
	// ErrInvalidCodeSnippet 用于跨语言拒绝空内容或不允许执行的代码片段。
	ErrInvalidCodeSnippet = errors.New("invalid code snippet")
	// ErrUnsupportedExecutionLanguage rejects execution requests for unknown languages.
	// ErrUnsupportedExecutionLanguage 用于拒绝未知语言的执行请求。
	ErrUnsupportedExecutionLanguage = errors.New("unsupported execution language")
	// ErrUnavailableExecutionRuntime indicates the target runtime is unavailable on the host.
	// ErrUnavailableExecutionRuntime 表示目标运行时在当前宿主机上不可用。
	ErrUnavailableExecutionRuntime = errors.New("execution runtime unavailable")
)

var forbiddenGoImports = map[string]struct{}{
	"os":       {},
	"os/exec":  {},
	"net":      {},
	"net/http": {},
	"net/url":  {},
	"syscall":  {},
	"unsafe":   {},
}

type GoExecutionResult struct {
	// Stdout keeps the process standard output.
	// Stdout 保存进程标准输出。
	Stdout string `json:"stdout"`
	// Stderr keeps the process standard error.
	// Stderr 保存进程标准错误输出。
	Stderr string `json:"stderr"`
	// ExitCode reports the command exit code, or -1 when it did not finish normally.
	// ExitCode 表示命令退出码；若未正常结束则为 -1。
	ExitCode int `json:"exit_code"`
	// DurationMs keeps the execution time in milliseconds.
	// DurationMs 保存执行耗时（毫秒）。
	DurationMs int64 `json:"duration_ms"`
	// TimedOut indicates whether the execution hit the timeout cap.
	// TimedOut 表示执行是否触发了超时上限。
	TimedOut bool `json:"timed_out"`
}

type snippetRuntime struct {
	language        string
	fileName        string
	commandNames    []string
	commandArgs     func(commandPath string, fileName string) []string
	timeout         time.Duration
	validate        func(source string) (string, error)
	env             func(tempDir string, cacheDir string) []string
	unsupportedHint string
}

var snippetRuntimes = map[string]snippetRuntime{
	"go": {
		language:     "go",
		fileName:     "main.go",
		commandNames: []string{"go"},
		commandArgs: func(_ string, fileName string) []string {
			return []string{"run", fileName}
		},
		timeout:  defaultGoExecutionTimeout,
		validate: validateGoSnippet,
		env: func(tempDir string, cacheDir string) []string {
			return []string{
				"GO111MODULE=off",
				"GOWORK=off",
				"CGO_ENABLED=0",
				"GOCACHE=" + cacheDir,
				"HOME=" + tempDir,
			}
		},
		unsupportedHint: "go toolchain not found",
	},
	"javascript": {
		language:     "javascript",
		fileName:     "main.js",
		commandNames: []string{"node"},
		commandArgs: func(_ string, fileName string) []string {
			return []string{fileName}
		},
		timeout:         5 * time.Second,
		validate:        validateJavaScriptSnippet,
		env:             func(_ string, _ string) []string { return nil },
		unsupportedHint: "node runtime not found",
	},
	"python": {
		language:     "python",
		fileName:     "main.py",
		commandNames: []string{"python3", "py", "python"},
		commandArgs: func(commandPath string, fileName string) []string {
			lowerPath := strings.ToLower(filepath.Base(commandPath))
			if lowerPath == "py" || lowerPath == "py.exe" {
				return []string{"-3", fileName}
			}
			return []string{fileName}
		},
		timeout:         5 * time.Second,
		validate:        validatePythonSnippet,
		env:             func(_ string, _ string) []string { return nil },
		unsupportedHint: "python runtime not found",
	},
}

var executionLanguageAliases = map[string]string{
	"go":         "go",
	"golang":     "go",
	"js":         "javascript",
	"javascript": "javascript",
	"node":       "javascript",
	"py":         "python",
	"python":     "python",
}

func ExecuteGoSnippet(source string) (GoExecutionResult, error) {
	// Execute one runnable Go snippet with size, import, and timeout guards.
	// 在大小、导入和超时限制下执行一段可运行 Go 代码。
	return executeGoSnippetWithTimeout(source, defaultGoExecutionTimeout)
}

func ExecuteCodeSnippet(language string, source string) (GoExecutionResult, error) {
	// Execute one code snippet for the requested language through the shared runtime registry.
	// 通过共享运行时注册表执行指定语言的代码片段。
	runtime, err := resolveSnippetRuntime(language)
	if err != nil {
		return GoExecutionResult{}, err
	}
	return executeSnippetWithRuntime(runtime, source)
}

func executeGoSnippetWithTimeout(source string, timeout time.Duration) (GoExecutionResult, error) {
	source, err := validateGoSnippet(source)
	if err != nil {
		return GoExecutionResult{}, err
	}

	runtime := snippetRuntimes["go"]
	runtime.timeout = timeout
	return executeSnippetFile(runtime, source)
}

func executeSnippetWithRuntime(runtime snippetRuntime, source string) (GoExecutionResult, error) {
	// Execute one validated snippet using the supplied runtime descriptor.
	// 使用给定运行时描述执行一段已校验代码片段。
	source, err := runtime.validate(source)
	if err != nil {
		return GoExecutionResult{}, err
	}
	return executeSnippetFile(runtime, source)
}

func executeSnippetFile(runtime snippetRuntime, source string) (GoExecutionResult, error) {
	// Materialize one snippet into a temp file and run it with the requested interpreter.
	// 将代码片段写入临时文件，并使用目标解释器执行。
	commandPath, err := resolveRuntimeCommand(runtime.commandNames)
	if err != nil {
		return GoExecutionResult{}, fmt.Errorf("%w: %s", ErrUnavailableExecutionRuntime, runtime.unsupportedHint)
	}

	tempDir, err := os.MkdirTemp("", "learning-go-run-*")
	if err != nil {
		return GoExecutionResult{}, err
	}
	defer os.RemoveAll(tempDir)

	filePath := filepath.Join(tempDir, runtime.fileName)
	if err := os.WriteFile(filePath, []byte(source), 0o600); err != nil {
		return GoExecutionResult{}, err
	}

	cacheDir, err := goExecutionCacheDir()
	if err != nil {
		return GoExecutionResult{}, err
	}

	ctx, cancel := context.WithTimeout(context.Background(), runtime.timeout)
	defer cancel()

	cmd := exec.CommandContext(
		ctx,
		commandPath,
		runtime.commandArgs(commandPath, runtime.fileName)...,
	)
	cmd.Dir = tempDir
	cmd.Env = append(filteredGoExecutionEnv(os.Environ()), runtime.env(tempDir, cacheDir)...)

	stdoutBuffer := newLimitedExecutionBuffer(maxGoExecutionOutputBytes)
	stderrBuffer := newLimitedExecutionBuffer(maxGoExecutionOutputBytes)
	cmd.Stdout = stdoutBuffer
	cmd.Stderr = stderrBuffer

	startedAt := time.Now()
	runErr := cmd.Run()
	durationMs := time.Since(startedAt).Milliseconds()

	result := GoExecutionResult{
		Stdout:     stdoutBuffer.String(),
		Stderr:     stderrBuffer.String(),
		ExitCode:   0,
		DurationMs: durationMs,
		TimedOut:   false,
	}

	if errors.Is(ctx.Err(), context.DeadlineExceeded) {
		result.TimedOut = true
		result.ExitCode = -1
		if strings.TrimSpace(result.Stderr) == "" {
			result.Stderr = "execution timed out"
		}
		return result, nil
	}
	if runErr == nil {
		return result, nil
	}

	var exitErr *exec.ExitError
	if errors.As(runErr, &exitErr) {
		result.ExitCode = exitErr.ExitCode()
		if strings.TrimSpace(result.Stderr) == "" {
			result.Stderr = strings.TrimSpace(string(exitErr.Stderr))
		}
		return result, nil
	}

	return GoExecutionResult{}, runErr
}

func validateGoSnippet(source string) (string, error) {
	// Accept only bounded runnable snippets and reject risky imports early.
	// 仅接受受限的可运行代码片段，并提前拒绝高风险导入。
	trimmed := strings.TrimSpace(source)
	if trimmed == "" {
		return "", fmt.Errorf("%w: empty source", ErrInvalidCodeSnippet)
	}
	if len(trimmed) > maxGoSnippetBytes {
		return "", fmt.Errorf("%w: source too large", ErrInvalidCodeSnippet)
	}
	if strings.Contains(trimmed, "//go:") {
		return "", fmt.Errorf("%w: compiler directives are not allowed", ErrInvalidCodeSnippet)
	}

	fileSet := token.NewFileSet()
	parsedFile, err := parser.ParseFile(fileSet, "main.go", trimmed, parser.ImportsOnly)
	if err != nil {
		return "", fmt.Errorf("%w: %s", ErrInvalidCodeSnippet, err)
	}
	if parsedFile.Name == nil || parsedFile.Name.Name != "main" {
		return "", fmt.Errorf("%w: package must be main", ErrInvalidCodeSnippet)
	}
	for _, importSpec := range parsedFile.Imports {
		importPath := strings.Trim(importSpec.Path.Value, `"`)
		if _, forbidden := forbiddenGoImports[importPath]; forbidden {
			return "", fmt.Errorf("%w: import %q is not allowed", ErrInvalidCodeSnippet, importPath)
		}
	}

	parsedProgram, err := parser.ParseFile(fileSet, "main.go", trimmed, 0)
	if err != nil {
		return "", fmt.Errorf("%w: %s", ErrInvalidCodeSnippet, err)
	}
	if !hasMainFunction(parsedProgram) {
		return "", fmt.Errorf("%w: missing func main()", ErrInvalidCodeSnippet)
	}
	return trimmed, nil
}

func validateJavaScriptSnippet(source string) (string, error) {
	// Accept only bounded JavaScript snippets and reject risky runtime modules.
	// 仅接受受限 JavaScript 代码片段，并拒绝高风险运行时模块。
	trimmed := strings.TrimSpace(source)
	if trimmed == "" {
		return "", fmt.Errorf("%w: empty source", ErrInvalidCodeSnippet)
	}
	if len(trimmed) > maxGoSnippetBytes {
		return "", fmt.Errorf("%w: source too large", ErrInvalidCodeSnippet)
	}
	for _, forbiddenPattern := range []string{
		"require('child_process')",
		"require(\"child_process\")",
		"require('fs')",
		"require(\"fs\")",
		"require('net')",
		"require(\"net\")",
		"require('http')",
		"require(\"http\")",
		"import child_process",
		"from 'child_process'",
		"from \"child_process\"",
		"process.exit(",
	} {
		if strings.Contains(trimmed, forbiddenPattern) {
			return "", fmt.Errorf("%w: forbidden javascript runtime capability", ErrInvalidCodeSnippet)
		}
	}
	return trimmed, nil
}

func validatePythonSnippet(source string) (string, error) {
	// Accept only bounded Python snippets and reject risky modules and file/network primitives.
	// 仅接受受限 Python 代码片段，并拒绝高风险模块及文件/网络原语。
	trimmed := strings.TrimSpace(source)
	if trimmed == "" {
		return "", fmt.Errorf("%w: empty source", ErrInvalidCodeSnippet)
	}
	if len(trimmed) > maxGoSnippetBytes {
		return "", fmt.Errorf("%w: source too large", ErrInvalidCodeSnippet)
	}
	for _, forbiddenPattern := range []string{
		"import os",
		"from os",
		"import sys",
		"from sys",
		"import subprocess",
		"from subprocess",
		"import socket",
		"from socket",
		"import http",
		"from http",
		"import urllib",
		"from urllib",
		"open(",
		"__import__(",
	} {
		if strings.Contains(trimmed, forbiddenPattern) {
			return "", fmt.Errorf("%w: forbidden python runtime capability", ErrInvalidCodeSnippet)
		}
	}
	return trimmed, nil
}

func hasMainFunction(file *ast.File) bool {
	// Detect whether the program declares a top-level func main().
	// 检测程序是否声明顶层 func main()。
	for _, declaration := range file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Recv != nil {
			continue
		}
		if function.Name != nil && function.Name.Name == "main" {
			return true
		}
	}
	return false
}

func filteredGoExecutionEnv(values []string) []string {
	// Keep the base environment while dropping inherited Go workspace overrides.
	// 保留基础环境，同时剔除继承的 Go 工作区覆盖项。
	filtered := make([]string, 0, len(values))
	for _, entry := range values {
		switch {
		case strings.HasPrefix(entry, "GO111MODULE="):
			continue
		case strings.HasPrefix(entry, "GOWORK="):
			continue
		case strings.HasPrefix(entry, "GOCACHE="):
			continue
		case strings.HasPrefix(entry, "GOMODCACHE="):
			continue
		case strings.HasPrefix(entry, "GOPATH="):
			continue
		case strings.HasPrefix(entry, "CGO_ENABLED="):
			continue
		default:
			filtered = append(filtered, entry)
		}
	}
	return filtered
}

func resolveSnippetRuntime(language string) (snippetRuntime, error) {
	// Resolve one frontend language token into a concrete backend runtime descriptor.
	// 将前端语言标记解析为具体后端运行时描述。
	normalized := strings.ToLower(strings.TrimSpace(language))
	normalized = executionLanguageAliases[normalized]
	runtime, ok := snippetRuntimes[normalized]
	if !ok {
		return snippetRuntime{}, fmt.Errorf("%w: %s", ErrUnsupportedExecutionLanguage, language)
	}
	return runtime, nil
}

func resolveRuntimeCommand(commandNames []string) (string, error) {
	// Return the first available interpreter command from the candidate list.
	// 从候选列表中返回第一个可用解释器命令。
	for _, commandName := range commandNames {
		commandPath, err := exec.LookPath(commandName)
		if err == nil && strings.TrimSpace(commandPath) != "" {
			return commandPath, nil
		}
	}
	return "", ErrUnavailableExecutionRuntime
}

func goExecutionCacheDir() (string, error) {
	// Reuse one local Go cache directory so repeated learning runs avoid cold compilation.
	// 复用本地 Go 缓存目录，避免学习页重复执行时每次都冷启动编译。
	cacheRoot, err := os.UserCacheDir()
	if err != nil || strings.TrimSpace(cacheRoot) == "" {
		cacheRoot = os.TempDir()
	}
	cacheDir := filepath.Join(cacheRoot, "iniyou", "learning-go-cache")
	if err := os.MkdirAll(cacheDir, 0o755); err != nil {
		return "", err
	}
	return cacheDir, nil
}

type limitedExecutionBuffer struct {
	buffer    bytes.Buffer
	limit     int
	truncated bool
}

func newLimitedExecutionBuffer(limit int) *limitedExecutionBuffer {
	return &limitedExecutionBuffer{limit: limit}
}

func (buffer *limitedExecutionBuffer) Write(value []byte) (int, error) {
	// Preserve at most `limit` bytes while still satisfying the command writer contract.
	// 仅保留最多 `limit` 字节，同时满足命令写入器约定。
	if len(value) == 0 {
		return 0, nil
	}
	if buffer.limit <= 0 {
		buffer.truncated = true
		return len(value), nil
	}
	remaining := buffer.limit - buffer.buffer.Len()
	if remaining > 0 {
		if len(value) <= remaining {
			_, _ = buffer.buffer.Write(value)
		} else {
			_, _ = buffer.buffer.Write(value[:remaining])
			buffer.truncated = true
		}
	} else {
		buffer.truncated = true
	}
	return len(value), nil
}

func (buffer *limitedExecutionBuffer) String() string {
	// Return the captured text and append a truncation marker when needed.
	// 返回已捕获文本，并在发生截断时追加提示。
	text := buffer.buffer.String()
	if buffer.truncated {
		return text + "\n... output truncated ..."
	}
	return text
}
