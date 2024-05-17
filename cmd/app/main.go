package main

import (
	"misc/Internal/logic"
)

type context struct {
	Version string
}

//var Context context {}(Version: "2.0.0.1")

func main() {
	root := logic.NewRoot()
	root.Init()
}
