package service

import (
	"errors"
	"os/exec"
	"strings"
	"testing"
	"time"
)

func TestExecuteGoSnippetSuccess(t *testing.T) {
	// Execute a small runnable Go program and capture stdout.
	// 执行一段可运行的 Go 程序，并捕获标准输出。
	result, err := executeGoSnippetWithTimeout(`package main

import "fmt"

func main() {
	fmt.Println("hello from learning")
}
`, 15*time.Second)
	if err != nil {
		t.Fatalf("execute go snippet: %v", err)
	}
	if strings.Contains(strings.ToLower(result.Stderr), "out of memory") {
		t.Skip("go runtime is out of memory in the current environment")
	}
	if result.ExitCode != 0 {
		t.Fatalf("expected exit code 0, got %d with stderr %q", result.ExitCode, result.Stderr)
	}
	if !strings.Contains(result.Stdout, "hello from learning") {
		t.Fatalf("unexpected stdout: %q", result.Stdout)
	}
}

func TestExecuteGoSnippetRejectsForbiddenImport(t *testing.T) {
	// Reject snippets that import forbidden packages before execution.
	// 在执行前拒绝导入禁用包的代码片段。
	_, err := ExecuteGoSnippet(`package main

import "os/exec"

func main() {}
`)
	if !errors.Is(err, ErrInvalidGoSnippet) {
		t.Fatalf("expected invalid go snippet error, got %v", err)
	}
	if !errors.Is(err, ErrInvalidCodeSnippet) {
		t.Fatalf("expected invalid code snippet error, got %v", err)
	}
}

func TestExecuteGoSnippetTimesOut(t *testing.T) {
	// Stop runaway programs once the timeout budget is exhausted.
	// 在超时预算耗尽后终止失控程序。
	result, err := executeGoSnippetWithTimeout(`package main

func main() {
	for {
	}
}
`, 150*time.Millisecond)
	if err != nil {
		t.Fatalf("execute timed out snippet: %v", err)
	}
	if !result.TimedOut {
		t.Fatalf("expected timed out result, got %+v", result)
	}
	if result.ExitCode != -1 {
		t.Fatalf("expected timeout exit code -1, got %d", result.ExitCode)
	}
}

func TestExecuteCodeSnippetRejectsUnsupportedLanguage(t *testing.T) {
	// Reject execution requests for languages the backend does not recognize.
	// 拒绝后端无法识别语言的执行请求。
	_, err := ExecuteCodeSnippet("ruby", "puts 'hi'")
	if !errors.Is(err, ErrUnsupportedExecutionLanguage) {
		t.Fatalf("expected unsupported language error, got %v", err)
	}
}

func TestValidateJavaScriptSnippetRejectsForbiddenModule(t *testing.T) {
	// Reject JavaScript snippets that try to access forbidden runtime modules.
	// 拒绝尝试访问禁用运行时模块的 JavaScript 片段。
	_, err := validateJavaScriptSnippet("const fs = require('fs'); console.log('x')")
	if !errors.Is(err, ErrInvalidCodeSnippet) {
		t.Fatalf("expected invalid code snippet error, got %v", err)
	}
}

func TestValidatePythonSnippetRejectsForbiddenModule(t *testing.T) {
	// Reject Python snippets that try to access forbidden runtime modules.
	// 拒绝尝试访问禁用运行时模块的 Python 片段。
	_, err := validatePythonSnippet("import os\nprint('x')")
	if !errors.Is(err, ErrInvalidCodeSnippet) {
		t.Fatalf("expected invalid code snippet error, got %v", err)
	}
}

func TestExecuteJavaScriptSnippetSuccessWhenRuntimeExists(t *testing.T) {
	// Execute a small JavaScript snippet when Node.js is available in the environment.
	// 当环境中存在 Node.js 时，执行一段简单 JavaScript 片段。
	if _, err := exec.LookPath("node"); err != nil {
		t.Skip("node runtime is not available")
	}
	result, err := ExecuteCodeSnippet("javascript", "console.log('hello from js')")
	if err != nil {
		t.Fatalf("execute javascript snippet: %v", err)
	}
	if result.ExitCode != 0 {
		t.Fatalf("expected exit code 0, got %d with stderr %q", result.ExitCode, result.Stderr)
	}
	if !strings.Contains(result.Stdout, "hello from js") {
		t.Fatalf("unexpected stdout: %q", result.Stdout)
	}
}

func TestExecutePythonSnippetSuccessWhenRuntimeExists(t *testing.T) {
	// Execute a small Python snippet when Python is available in the environment.
	// 当环境中存在 Python 时，执行一段简单 Python 片段。
	if _, err := resolveRuntimeCommand([]string{"python3", "python"}); err != nil {
		t.Skip("python runtime is not available")
	}
	result, err := ExecuteCodeSnippet("python", "print('hello from python')")
	if err != nil {
		t.Fatalf("execute python snippet: %v", err)
	}
	if result.ExitCode == 9009 && strings.TrimSpace(result.Stderr) == "" {
		t.Skip("python launcher is unavailable in the current environment")
	}
	if result.ExitCode != 0 {
		t.Fatalf("expected exit code 0, got %d with stderr %q", result.ExitCode, result.Stderr)
	}
	if !strings.Contains(result.Stdout, "hello from python") {
		t.Fatalf("unexpected stdout: %q", result.Stdout)
	}
}
