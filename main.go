package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"sort"
)

func removeElem(src *[]byte, i int) {
	*src = append((*src)[:i], (*src)[i+1:]...)
}

func removeCommentLegacie(src *[]byte) {
	ini := false
	act := false
	for i := 0; i < len(*src); i++ {
		if !act && string((*src)[i]) == "-" {
			if !ini {
				ini = true
			} else {
				ini = false
				act = true
				removeElem(src, i-1)
				i--
			}
		}
		if act {
			if (*src)[i] == 10 {
				act = false
			} else {
				removeElem(src, i)
				i--
			}
		}
	}
}

func removeComment(src *[]byte) {
	act := false
	for i := 0; i < len(*src)-1; i++ {
		str := string((*src)[i]) + string((*src)[i+1])
		if str == "--" && !act {
			act = true
		}
		if act && (*src)[i] != 10 {
			removeElem(src, i)
			i--
		} else if act && (*src)[i] == 10 {
			act = false
		}
	}
}

func removeLineFeed(src *[]byte) {
	for i := 0; i < len(*src); i++ {
		if (*src)[i] == 10 {
			(*src)[i] = 32
		}
	}
}

func removeSideSpace(src *[]byte) {
	arr := []string{
		"+",
		"-",
		"*",
		"/",
		"~",
		"=",
		",",
		".",
		"{",
		"}",
		"(",
		")",
		"^",
		"<",
		">",
		";",
		"[",
		"]",
	}

	find := func(str string) bool {
		for _, v := range arr {
			if v == str {
				return true
			}
		}
		return false
	}

	quotesor := false
	for i := 0; i < len(*src); i++ {
		quotesor = isQuotes(string((*src)[i]), &quotesor)
		if !quotesor && find(string((*src)[i])) {
			if (*src)[i-1] == 32 {
				removeElem(src, i-1)
				i = i - 2
			}
			if (*src)[i+1] == 32 {
				removeElem(src, i+1)
				i--
			}
		}
	}
}

func removeWhiteSpace(src *[]byte) {
	quotesor := false
	for i := 0; i < len(*src); i++ {
		quotesor = isQuotes(string((*src)[i]), &quotesor)
		if !quotesor && (*src)[i] == 32 {
			if i != 0 && (*src)[i-1] == 32 {
				removeElem(src, i-1)
				i--
			} else if i == 0 {
				removeElem(src, i)
				i--
			}
		}
	}
}

func isQuotes(str string, quotesor *bool) bool {
	for _, v := range []string{`'`, `"`} {
		if str == `'` && *quotesor {
			return *quotesor
		}
		if v == str {
			if !*quotesor {
				return true
			} else {
				return false
			}
		}
	}
	return *quotesor
}

func getSource() []string {
	arr := []string{}
	filepath.Walk("./src/", func(path string, info os.FileInfo, _ error) error {
		if filepath.Ext(path) == ".lua" {
			arr = append(arr, info.Name())
		}
		return nil
	})

	sort.Strings(arr)

	for _, v := range arr {
		fmt.Println("Found: " + v)
	}

	return arr
}

func main() {
	missionScript, _ := os.Create("missionScript.lua")
	defer missionScript.Close()

	missionSource := getSource()

	optionDevmode := true

	var script []byte
	for i := 0; i < len(missionSource); i++ {
		src, _ := ioutil.ReadFile("./src/" + missionSource[i])
		if !optionDevmode && len(src) > 0 {
			removeComment(&src)
			removeLineFeed(&src)
			removeSideSpace(&src)
			removeWhiteSpace(&src)
		}
		for _, elem := range src {
			script = append(script, elem)
		}
		if i != len(missionSource)-1 && optionDevmode {
			script = append(script, 10)
			script = append(script, 10)
		}
		if i != len(missionSource)-1 && !optionDevmode {
			script = append(script, 32)
		}
	}

	if !optionDevmode {
		fmt.Println("TOTAL LENGTH: ", len(script))
		fmt.Println("** MERGING & SERIALIZING COMPLETE **")
	} else {
		fmt.Println("** MERGING COMPLETE **")
	}

	ioutil.WriteFile("missionScript.lua", script, 0)
}
