package service

import "testing"

func TestIsAccountActive(t *testing.T) {
	// Legacy empty values should still be accepted, while disabled states are blocked.
	// 历史空值仍应视为可用，而禁用类状态必须被拦截。
	tests := []struct {
		name   string
		status string
		want   bool
	}{
		{name: "empty", status: "", want: true},
		{name: "active", status: "active", want: true},
		{name: "active-with-spaces", status: "  ACTIVE  ", want: true},
		{name: "disabled", status: "disabled", want: false},
		{name: "suspended", status: "suspended", want: false},
	}

	for _, tc := range tests {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			if got := IsAccountActive(tc.status); got != tc.want {
				t.Fatalf("IsAccountActive(%q) = %v, want %v", tc.status, got, tc.want)
			}
		})
	}
}
