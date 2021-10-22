package main

import (
	"archive/zip"
	"bufio"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

func extractContents(missionPath string, tempPath string) {
	zipReader, _ := zip.OpenReader(missionPath)
	defer zipReader.Close()

	os.MkdirAll(tempPath, os.ModePerm)
	os.MkdirAll(tempPath+"/l10n", os.ModePerm)
	os.MkdirAll(tempPath+"/l10n/DEFAULT", os.ModePerm)

	for _, eachItem := range zipReader.File {
		eachPath := filepath.Join(tempPath, eachItem.Name)

		copyFile, _ := os.OpenFile(eachPath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, os.ModePerm)
		eachFile, _ := eachItem.Open()

		io.Copy(copyFile, eachFile)

		copyFile.Close()
		eachFile.Close()
	}
}

func packageContents(packagePath string, tempPath string) {
	packageFile, _ := os.Create(packagePath)
	defer packageFile.Close()

	zipWriter := zip.NewWriter(packageFile)
	defer zipWriter.Close()

	addContent(zipWriter, tempPath, "")
}

func addContent(zipWriter *zip.Writer, basePath string, nextPath string) {
	srcList, _ := ioutil.ReadDir(basePath)

	for _, eachFile := range srcList {
		eachName := eachFile.Name()
		if !eachFile.IsDir() {
			srcData, _ := ioutil.ReadFile(basePath + eachName)
			newFile, _ := zipWriter.Create(nextPath + eachName)
			_, err := newFile.Write(srcData)
			if err != nil {
				fmt.Println(err)
			}
		} else {
			depthPath := eachName + "/"
			addContent(zipWriter, basePath+depthPath, nextPath+depthPath)
		}
	}
}

func processContents(missionPath string, sourcePath string, tempPath string) {
	dataPath := tempPath + "mission"
	os.Remove(dataPath)

	zipReader, _ := zip.OpenReader(missionPath)
	defer zipReader.Close()

	oldData, _ := zipReader.Open("mission")
	newData, _ := os.Create(dataPath)
	srcData, _ := os.Open(sourcePath)
	defer srcData.Close()

	oldScan := bufio.NewScanner(oldData)
	srcScan := bufio.NewScanner(srcData)

	getMissionLines := func(fileName string) (int, int) {
		reader, _ := zip.OpenReader(fileName)
		defer reader.Close()

		file, _ := reader.Open("mission")
		scanner := bufio.NewScanner(file)

		r1, r2, cnt, sw := 0, 0, 0, false
		for scanner.Scan() {
			txt := scanner.Text()
			if !sw {
				if strings.Contains(txt, `["name"] = "blue",`) {
					cnt++
					sw = true
					r1 = cnt + 1
				} else {
					cnt++
				}
			} else {
				if strings.Contains(txt, `-- end of ["country"]`) {
					r2 = cnt - 1
					break
				} else {
					cnt++
				}
			}
		}
		return r1, r2
	}

	getWaypointLines := func(fileName string) (int, int) {
		file, _ := os.Open(fileName)
		defer file.Close()

		scanner := bufio.NewScanner(file)

		r1, r2, cnt, sw := 0, 0, 0, false
		for scanner.Scan() {
			txt := scanner.Text()
			if !sw {
				if strings.Contains(txt, `missionWaypoint =`) {
					r1 = cnt
					sw = true
					cnt++
				} else {
					cnt++
				}
			} else {
				if strings.Contains(txt, `-- end of missionWaypoint`) {
					r2 = cnt
					break
				} else {
					cnt++
				}
			}
		}
		return r1, r2
	}

	x1, x2 := getMissionLines(missionPath)
	y1, y2 := getWaypointLines(sourcePath)

	i, j := 0, 0

	for oldScan.Scan() {
		oldTxt := oldScan.Text()
		if i == x1+1 {
			for srcScan.Scan() {
				newTxt := srcScan.Text()
				if j > y1 && j < y2 {
					newData.WriteString("\t\t\t" + newTxt + "\n")
				}
				j++
			}
		} else if i < x1 || i > x2 {
			newData.WriteString(oldTxt + "\n")
		}
		i++
	}
}

func main() {
	DCS := "/mnt/c/Users/blklo/Saved Games/DCS.openbeta/Missions/"
	MIZ := "fmb_training_caucasus.miz"
	PKG := "waypointedMission.miz"
	SRC := "missionWaypoint.lua"
	TMP := "./wpm/temp/"

	optionDevMode := false

	os.Remove(DCS + PKG)
	os.RemoveAll(TMP)

	extractContents(DCS+MIZ, TMP)
	processContents(DCS+MIZ, DCS+SRC, TMP)
	packageContents(DCS+PKG, TMP)

	if !optionDevMode {
		fmt.Println("MISSION RE-PACKAGED:", PKG)
		os.Remove(DCS + SRC)
		os.RemoveAll(TMP)
	}
}
