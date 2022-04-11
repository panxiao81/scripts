package main

import (
	"embed"
	"encoding/json"
	"html/template"
	"log"
	"net/http"
	"net/url"
)

//go:embed templates
var indexHTML embed.FS

type tools struct {
	UA     string
	Method string
	Arg    url.Values
}

func enableCors(w *http.ResponseWriter) {
	(*w).Header().Set("Access-Control-Allow-Origin", "*")
}

func hello(w http.ResponseWriter, r *http.Request) {
	// Embed index file
	tmpl, err := template.ParseFS(indexHTML, "templates/index.html")
	if err != nil {
		log.Fatal(err)
		w.WriteHeader(http.StatusInternalServerError)
	}
	tmpl.Execute(w, "")
}

func getFormData(r *http.Request) (*tools, error) {
	err := r.ParseForm()
	if err != nil {
		return nil, err
	}
	tmplData := new(tools)
	tmplData.Arg = make(url.Values)
	tmplData.UA = r.UserAgent()
	tmplData.Method = r.Method
	tmplData.Arg = r.Form
	return tmplData, nil
}

func testPostJson(w http.ResponseWriter, r *http.Request) {
	data, err := getFormData(r)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		log.Print(err)
	}
	out, err := json.Marshal(data)
	if err != nil {
		log.Fatal(err)
	}
	enableCors(&w)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(out)
}

func testPost(w http.ResponseWriter, req *http.Request) {
	tmplData, err := getFormData(req)
	if err != nil {
		log.Fatal(err)
		w.WriteHeader(http.StatusInternalServerError)
	}
	// Template
	tmpl, err := template.ParseFS(indexHTML, "templates/tool.html")
	if err != nil {
		log.Fatal(err)
		w.WriteHeader(http.StatusInternalServerError)
	}
	tmpl.Execute(w, tmplData)
}

func main() {

	http.HandleFunc("/post", testPost)
	http.HandleFunc("/post/json", testPostJson)
	http.HandleFunc("/", hello)

	log.Println("Start the server on :8080")
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		log.Fatal(err)
	}
}
