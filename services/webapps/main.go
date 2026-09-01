package main

import (
    "encoding/json"
    "errors"
    "flag"
    "fmt"
    "net/url"
    "os"
    "path/filepath"
    "regexp"
    "sort"
    "strings"
)

type WebApp struct {
    ID      string `json:"id"`
    Name    string `json:"name"`
    URL     string `json:"url"`
    Icon    string `json:"icon,omitempty"`
    Browser string `json:"browser"`
}

var idSanitizer = regexp.MustCompile(`[^a-z0-9-]+`)

func main() {
    if len(os.Args) < 2 {
        usage()
        os.Exit(2)
    }

    var err error
    switch os.Args[1] {
    case "install":
        err = installCmd(os.Args[2:])
    case "remove":
        err = removeCmd(os.Args[2:])
    case "list":
        err = listCmd()
    default:
        usage()
        os.Exit(2)
    }
    if err != nil {
        fmt.Fprintln(os.Stderr, "windra-webapp:", err)
        os.Exit(1)
    }
}

func usage() {
    fmt.Println(`Windra Web App Manager

Usage:
  windra-webapp install --name NAME --url URL [--icon PATH] [--browser chromium]
  windra-webapp remove  --name NAME
  windra-webapp list`)
}

func installCmd(args []string) error {
    fs := flag.NewFlagSet("install", flag.ContinueOnError)
    name := fs.String("name", "", "Tên ứng dụng")
    rawURL := fs.String("url", "", "URL http/https")
    icon := fs.String("icon", "", "Đường dẫn icon")
    browser := fs.String("browser", "chromium", "Browser executable")
    if err := fs.Parse(args); err != nil { return err }
    if strings.TrimSpace(*name) == "" { return errors.New("thiếu --name") }
    if err := validateURL(*rawURL); err != nil { return err }
    if strings.ContainsAny(*browser, "\r\n") { return errors.New("browser không hợp lệ") }

    app := WebApp{
        ID: slug(*name), Name: strings.TrimSpace(*name), URL: *rawURL,
        Icon: strings.TrimSpace(*icon), Browser: strings.TrimSpace(*browser),
    }
    if app.ID == "" { return errors.New("không tạo được app id") }

    appDir, metaDir, err := dirs()
    if err != nil { return err }
    if err := os.MkdirAll(appDir, 0o755); err != nil { return err }
    if err := os.MkdirAll(metaDir, 0o755); err != nil { return err }

    desktop := desktopEntry(app)
    desktopPath := filepath.Join(appDir, "windra-webapp-"+app.ID+".desktop")
    if err := os.WriteFile(desktopPath, []byte(desktop), 0o644); err != nil { return err }

    data, _ := json.MarshalIndent(app, "", "  ")
    if err := os.WriteFile(filepath.Join(metaDir, app.ID+".json"), data, 0o644); err != nil { return err }

    fmt.Printf("Đã cài Web App %q\n%s\n", app.Name, desktopPath)
    return nil
}

func removeCmd(args []string) error {
    fs := flag.NewFlagSet("remove", flag.ContinueOnError)
    name := fs.String("name", "", "Tên hoặc ID ứng dụng")
    if err := fs.Parse(args); err != nil { return err }
    id := slug(*name)
    if id == "" { return errors.New("thiếu --name") }
    appDir, metaDir, err := dirs()
    if err != nil { return err }

    removed := false
    for _, path := range []string{
        filepath.Join(appDir, "windra-webapp-"+id+".desktop"),
        filepath.Join(metaDir, id+".json"),
    } {
        if err := os.Remove(path); err == nil { removed = true } else if !os.IsNotExist(err) { return err }
    }
    if !removed { return fmt.Errorf("không tìm thấy Web App %q", id) }
    fmt.Printf("Đã gỡ Web App %q\n", id)
    return nil
}

func listCmd() error {
    _, metaDir, err := dirs()
    if err != nil { return err }
    entries, err := os.ReadDir(metaDir)
    if os.IsNotExist(err) { fmt.Println("Chưa có Web App nào."); return nil }
    if err != nil { return err }

    apps := make([]WebApp, 0, len(entries))
    for _, e := range entries {
        if e.IsDir() || filepath.Ext(e.Name()) != ".json" { continue }
        data, err := os.ReadFile(filepath.Join(metaDir, e.Name()))
        if err != nil { continue }
        var app WebApp
        if json.Unmarshal(data, &app) == nil { apps = append(apps, app) }
    }
    sort.Slice(apps, func(i, j int) bool { return strings.ToLower(apps[i].Name) < strings.ToLower(apps[j].Name) })
    if len(apps) == 0 { fmt.Println("Chưa có Web App nào."); return nil }
    for _, app := range apps { fmt.Printf("%-24s %s\n", app.Name, app.URL) }
    return nil
}

func validateURL(raw string) error {
    if strings.ContainsAny(raw, "\r\n") { return errors.New("URL không hợp lệ") }
    u, err := url.Parse(raw)
    if err != nil || u.Host == "" || (u.Scheme != "http" && u.Scheme != "https") {
        return errors.New("--url phải là URL http/https hợp lệ")
    }
    return nil
}

func slug(s string) string {
    s = strings.ToLower(strings.TrimSpace(s))
    s = strings.ReplaceAll(s, "_", "-")
    s = strings.ReplaceAll(s, " ", "-")
    s = idSanitizer.ReplaceAllString(s, "-")
    return strings.Trim(s, "-")
}

func dirs() (string, string, error) {
    home, err := os.UserHomeDir()
    if err != nil { return "", "", err }
    dataHome := os.Getenv("XDG_DATA_HOME")
    if dataHome == "" { dataHome = filepath.Join(home, ".local", "share") }
    return filepath.Join(dataHome, "applications"), filepath.Join(dataHome, "windra", "webapps"), nil
}

func desktopEntry(app WebApp) string {
    icon := app.Icon
    if icon == "" { icon = "web-browser" }
    return fmt.Sprintf(`[Desktop Entry]
Type=Application
Version=1.0
Name=%s
Comment=Windra Web App
Exec=%s --app=%s
Icon=%s
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
X-Windra-WebApp=true
X-Windra-WebApp-Id=%s
`, desktopValue(app.Name), desktopValue(app.Browser), desktopValue(app.URL), desktopValue(icon), desktopValue(app.ID))
}

func desktopValue(s string) string {
    // Desktop Entry values are line-oriented; reject line injection and escape backslashes.
    s = strings.ReplaceAll(s, "\\", "\\\\")
    s = strings.ReplaceAll(s, "\n", "")
    s = strings.ReplaceAll(s, "\r", "")
    return s
}
