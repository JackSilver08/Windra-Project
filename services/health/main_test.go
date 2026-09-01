package main

import "testing"

func TestCollect(t *testing.T) {
    h, err := collect()
    if err != nil { t.Fatal(err) }
    if h.MemoryTotalMB == 0 { t.Fatal("expected RAM") }
    if h.RootTotalGB <= 0 { t.Fatal("expected root storage") }
}
