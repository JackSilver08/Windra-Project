package main

import (
    "bufio"
    "encoding/json"
    "flag"
    "fmt"
    "os"
    "strconv"
    "strings"
    "syscall"
)

type Health struct {
    MemoryTotalMB     uint64  `json:"memory_total_mb"`
    MemoryAvailableMB uint64  `json:"memory_available_mb"`
    MemoryUsedPercent float64 `json:"memory_used_percent"`
    RootTotalGB       float64 `json:"root_total_gb"`
    RootFreeGB        float64 `json:"root_free_gb"`
}

func main() {
    asJSON := flag.Bool("json", false, "Xuất JSON")
    flag.Parse()

    h, err := collect()
    if err != nil {
        fmt.Fprintln(os.Stderr, "windra-health:", err)
        os.Exit(1)
    }

    if *asJSON {
        enc := json.NewEncoder(os.Stdout)
        enc.SetIndent("", "  ")
        _ = enc.Encode(h)
        return
    }
    fmt.Printf("RAM: %.1f%% dùng (%d MB khả dụng / %d MB)\n", h.MemoryUsedPercent, h.MemoryAvailableMB, h.MemoryTotalMB)
    fmt.Printf("Ổ /: %.1f GB trống / %.1f GB\n", h.RootFreeGB, h.RootTotalGB)
}

func collect() (Health, error) {
    total, available, err := memInfo()
    if err != nil { return Health{}, err }

    var fs syscall.Statfs_t
    if err := syscall.Statfs("/", &fs); err != nil { return Health{}, err }
    totalBytes := uint64(fs.Blocks) * uint64(fs.Bsize)
    freeBytes := uint64(fs.Bavail) * uint64(fs.Bsize)

    used := float64(0)
    if total > 0 { used = float64(total-available) / float64(total) * 100 }

    return Health{
        MemoryTotalMB: total / 1024,
        MemoryAvailableMB: available / 1024,
        MemoryUsedPercent: used,
        RootTotalGB: float64(totalBytes) / (1024 * 1024 * 1024),
        RootFreeGB: float64(freeBytes) / (1024 * 1024 * 1024),
    }, nil
}

func memInfo() (totalKB, availableKB uint64, err error) {
    f, err := os.Open("/proc/meminfo")
    if err != nil { return 0, 0, err }
    defer f.Close()

    scanner := bufio.NewScanner(f)
    values := map[string]uint64{}
    for scanner.Scan() {
        fields := strings.Fields(scanner.Text())
        if len(fields) < 2 { continue }
        key := strings.TrimSuffix(fields[0], ":")
        if key != "MemTotal" && key != "MemAvailable" { continue }
        v, parseErr := strconv.ParseUint(fields[1], 10, 64)
        if parseErr == nil { values[key] = v }
    }
    if err := scanner.Err(); err != nil { return 0, 0, err }
    return values["MemTotal"], values["MemAvailable"], nil
}
