package main

import (
	"errors"
	"io"
	"net/http"
	"net/url"
	"os"
	"path"
	"strings"
	"testing"
	"time"
)

func getTestURL() (string, error) {
	u := os.Getenv("TEST_URL")

	if u == "" {
		return "", errors.New("No TEST_URL set")
	}
	return u, nil
}

func getHTTPClient() *http.Client {
	return &http.Client{
		Timeout: time.Second * 2,
	}
}

func TestHealth(t *testing.T) {
	u, err := getTestURL()
	if err != nil {
		t.Fatal(err)
	}

	parsed, err := url.Parse(u)
	if err != nil {
		t.Fatal(err)
	}

	req, err := http.NewRequest("GET", parsed.JoinPath("/health").String(), nil)

	if err != nil {
		t.Fatal(err)
	}

	client := getHTTPClient()
	res, err := client.Do(req)

	if err != nil {
		t.Fatal(err)
	}

	if res.StatusCode != http.StatusOK {
		t.Fatalf("Expected HTTP %d but got %d", http.StatusOK, res.StatusCode)
	}
}

func TestStatic(t *testing.T) {
	u, err := getTestURL()
	if err != nil {
		t.Fatal(err)
	}

	parsed, err := url.Parse(u)
	if err != nil {
		t.Fatal(err)
	}
	parsed.Path = path.Join(parsed.Path, "/static/a.txt")
	u = parsed.String()

	req, err := http.NewRequest("GET", u, nil)

	if err != nil {
		t.Fatal(err)
	}

	client := getHTTPClient()
	res, err := client.Do(req)

	if err != nil {
		t.Fatal(err)
	}

	if res.StatusCode != http.StatusOK {
		t.Fatal(u)
		t.Fatalf("Expected HTTP %d but got %d", http.StatusOK, res.StatusCode)
	}

	b, err := io.ReadAll(res.Body)
	if err != nil {
		t.Fatal(err)
	}

	if strings.TrimSpace(string(b)) != "hello" {
		t.Fatalf("Expected to get 'hello' back as content of %s", u)
	}
}

func TestProxy(t *testing.T) {
	u, err := getTestURL()
	if err != nil {
		t.Fatal(err)
	}

	parsed, err := url.Parse(u)
	if err != nil {
		t.Fatal(err)
	}

	req, err := http.NewRequest("GET", u, nil)

	if err != nil {
		t.Fatal(err)
	}

	client := getHTTPClient()
	res, err := client.Do(req)

	if err != nil {
		t.Fatal(err)
	}

	if res.StatusCode != http.StatusOK {
		t.Fatalf("Expected HTTP %d but got %d", http.StatusOK, res.StatusCode)
	}

	nukedHeaders := []string{
		"X-Powered-By",
		"X-Rack-Cache",
		"X-Runtime",
		"Server",
	}

	for _, k := range nukedHeaders {
		h := res.Header.Get(k)
		if h != "" {
			t.Fatalf("Expected %s header to be removed", k)
		}
	}

	expectedHeaders := []string{
		"X-Request-ID",
		"X-Frame-Options",
		"X-XSS-Protection",
		"X-Content-Type-Options",
	}

	for _, k := range expectedHeaders {
		h := res.Header.Get(k)
		if h == "" {
			t.Fatalf("Expected %s header to be set", k)
		}
	}

	expectedHost := strings.Split(parsed.Host, ":")[0]
	hostHeader := res.Header.Get("X-Test-Host")
	if hostHeader != expectedHost {
		t.Fatalf("Expected Host header to be %s, got %s", expectedHost, hostHeader)
	}
}
