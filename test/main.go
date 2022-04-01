package main

import (
	"fmt"
	"net/http"
	"os"
)

func ok(w http.ResponseWriter, req *http.Request) {
	w.Header().Set("X-Powered-By", "1")
	w.Header().Set("X-Rack-Cache", "1")
	w.Header().Set("X-Runtime", "1")
	// Forward request host so that it can be evaluated as part of tests
	w.Header().Set("X-Test-Host", req.Host)
	fmt.Println("GET /")
	fmt.Fprintf(w, "ok\n")
}

func health(w http.ResponseWriter, req *http.Request) {
	fmt.Fprintf(w, "ok\n")
}

func main() {
	http.HandleFunc("/", ok)
	http.HandleFunc("/health", health)
	port := os.Getenv("LISTEN_PORT")
	if port == "" {
		port = "8081"
	}
	fmt.Printf("Running test server on port %s\n", port)
	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		panic(err)
	}
}
