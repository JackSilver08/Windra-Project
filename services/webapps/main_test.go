package main

import "testing"

func TestSlug(t *testing.T) {
    if got := slug("  You Tube  "); got != "you-tube" {
        t.Fatalf("slug = %q", got)
    }
}

func TestValidateURL(t *testing.T) {
    if err := validateURL("https://example.com"); err != nil { t.Fatal(err) }
    if err := validateURL("file:///etc/passwd"); err == nil { t.Fatal("expected invalid scheme") }
}
