package main

import (
	"errors"
	"net/http"
	"os"
	"testing"
	"time"
)

func getTestURL() (string, error) {
	url := os.Getenv("TEST_URL")
	if url == "" {
		return "", errors.New("No TEST_URL set")
	}
	return url, nil
}

func getHTTPClient() *http.Client {
	return &http.Client{
		Timeout: time.Second * 2,
	}
}

func TestProxy(t *testing.T) {
	url, err := getTestURL()
	if err != nil {
		t.Fatal(err)
	}

	req, err := http.NewRequest("GET", url, nil)

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
}
