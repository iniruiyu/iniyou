package config

import (
	"bufio"
	"errors"
	"os"
	"path/filepath"
	"strings"
)

const localEnvFileName = ".env.local"

type localEnvLine struct {
	// Raw keeps untouched comments and blank lines when we rewrite the file.
	// Raw 保留未改动的注释与空行，便于重写时尽量保持原样。
	Raw string
	// Key stores the parsed environment variable name for assignment lines.
	// Key 保存赋值行解析后的环境变量名称。
	Key string
	// Value stores the parsed environment variable value for assignment lines.
	// Value 保存赋值行解析后的环境变量值。
	Value string
	// IsAssignment marks lines that contain one parsed KEY=VALUE record.
	// IsAssignment 标记该行是否包含一条已解析的 KEY=VALUE 记录。
	IsAssignment bool
}

func LocalOverridePath() string {
	// Resolve the shared local override file relative to the backend working directory.
	// 相对 backend 工作目录解析共享本地覆盖配置文件路径。
	path, err := filepath.Abs(localEnvFileName)
	if err != nil {
		return localEnvFileName
	}
	return path
}

func ReadLocalOverrideValue(key string) (string, string, error) {
	// Read one environment override from the shared local override file.
	// 从共享本地覆盖配置文件中读取单个环境变量。
	path := LocalOverridePath()
	lines, err := loadLocalEnvLines(path)
	if err != nil {
		return "", path, err
	}
	for _, line := range lines {
		if line.IsAssignment && line.Key == key {
			return line.Value, path, nil
		}
	}
	return "", path, nil
}

func WriteLocalOverrideValue(key string, value string) (string, error) {
	// Write one environment override into the shared local override file.
	// 将单个环境变量写入共享本地覆盖配置文件。
	key = strings.TrimSpace(key)
	if key == "" {
		return "", errors.New("config key required")
	}
	path := LocalOverridePath()
	lines, err := loadLocalEnvLines(path)
	if err != nil {
		return path, err
	}

	updated := false
	for index := range lines {
		if !lines[index].IsAssignment || lines[index].Key != key {
			continue
		}
		lines[index].Value = value
		lines[index].Raw = key + "=" + value
		updated = true
	}
	if !updated {
		lines = append(lines, localEnvLine{
			Raw:          key + "=" + value,
			Key:          key,
			Value:        value,
			IsAssignment: true,
		})
	}
	if err := saveLocalEnvLines(path, lines); err != nil {
		return path, err
	}
	return path, nil
}

func readLocalOverrideValue(key string) (string, bool) {
	// Read one override value for config loading without surfacing filesystem errors.
	// 在配置加载阶段读取单个覆盖值，并吞掉文件系统错误。
	value, _, err := ReadLocalOverrideValue(key)
	if err != nil {
		return "", false
	}
	if strings.TrimSpace(value) == "" {
		return "", false
	}
	return value, true
}

func loadLocalEnvLines(path string) ([]localEnvLine, error) {
	// Parse the local override file into editable line records.
	// 将本地覆盖文件解析为可编辑的行记录。
	content, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return []localEnvLine{}, nil
		}
		return nil, err
	}
	lines := make([]localEnvLine, 0)
	scanner := bufio.NewScanner(strings.NewReader(string(content)))
	for scanner.Scan() {
		raw := scanner.Text()
		trimmed := strings.TrimSpace(raw)
		if trimmed == "" || strings.HasPrefix(trimmed, "#") {
			lines = append(lines, localEnvLine{Raw: raw})
			continue
		}
		key, value, found := strings.Cut(raw, "=")
		if !found {
			lines = append(lines, localEnvLine{Raw: raw})
			continue
		}
		lines = append(lines, localEnvLine{
			Raw:          raw,
			Key:          strings.TrimSpace(key),
			Value:        strings.TrimSpace(value),
			IsAssignment: true,
		})
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}
	return lines, nil
}

func saveLocalEnvLines(path string, lines []localEnvLine) error {
	// Persist the editable line records back to the local override file.
	// 将可编辑的行记录重新写回本地覆盖文件。
	builder := strings.Builder{}
	for index, line := range lines {
		builder.WriteString(line.Raw)
		if index < len(lines)-1 {
			builder.WriteString("\n")
		}
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	return os.WriteFile(path, []byte(builder.String()), 0o644)
}
