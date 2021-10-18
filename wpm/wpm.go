package main

import (
	"archive/zip"
	"fmt"
)

func main() {
	md := "/mnt/c/Users/blklo/Saved Games/DCS.openbeta/Missions/"

	r, _ := zip.OpenReader(md + "test.miz")
	defer r.Close()

	for _, f := range r.File {
		fmt.Println(f.Name)
	}
}
