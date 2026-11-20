#!/usr/bin/env bash
# Writes a small Go project for /refine to ask about. Nothing compiles or runs it.
set -euo pipefail

mkdir -p internal/store

cat > go.mod <<'GO'
module example.com/todo

go 1.24
GO

cat > main.go <<'GO'
package main

import (
	"fmt"
	"io"
	"os"
	"strings"
	"time"

	"example.com/todo/internal/store"
)

func main() {
	os.Exit(run(os.Args[1:], os.Stdout))
}

func run(args []string, out io.Writer) int {
	if len(args) == 0 {
		fmt.Fprintln(out, "usage: todo add <text> | todo list")
		return 2
	}

	items, err := store.Load()
	if err != nil {
		fmt.Fprintln(out, err)
		return 1
	}

	switch args[0] {
	case "add":
		items = append(items, store.Item{
			Text:  strings.Join(args[1:], " "),
			Added: time.Now().Format(time.DateOnly),
		})
		if err := store.Save(items); err != nil {
			fmt.Fprintln(out, err)
			return 1
		}
		return 0
	case "list":
		for i, item := range items {
			fmt.Fprintln(out, format(i+1, item))
		}
		return 0
	}

	fmt.Fprintf(out, "unknown command: %s\n", args[0])
	return 2
}

func format(n int, item store.Item) string {
	return fmt.Sprintf("%d. %s (added %s)", n, item.Text, item.Added)
}
GO

cat > main_test.go <<'GO'
package main

import (
	"testing"

	"example.com/todo/internal/store"
)

func TestFormatNumbersItems(t *testing.T) {
	got := format(1, store.Item{Text: "milk", Added: "2026-01-02"})
	if want := "1. milk (added 2026-01-02)"; got != want {
		t.Errorf("format() = %q, want %q", got, want)
	}
}
GO

cat > internal/store/store.go <<'GO'
package store

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
)

type Item struct {
	Text  string `json:"text"`
	Added string `json:"added"`
}

func path() string {
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".todo.json")
}

func Load() ([]Item, error) {
	data, err := os.ReadFile(path())
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var items []Item
	return items, json.Unmarshal(data, &items)
}

func Save(items []Item) error {
	data, err := json.Marshal(items)
	if err != nil {
		return err
	}
	return os.WriteFile(path(), data, 0o600)
}
GO

cat > README.md <<'MD'
# todo

A tiny command-line todo list. `todo add <text>` adds an item, `todo list` prints them.
MD
