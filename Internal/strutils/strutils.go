package strutils

import "golang.org/x/text/encoding/charmap"

func DecodeWindows1251(enc []byte) string {
	dec := charmap.Windows1251.NewDecoder()

	out, _ := dec.Bytes(enc)
	return string(out)
}

func EncodeWindows1251(inp string) string {
	enc := charmap.Windows1251.NewEncoder()
	out, _ := enc.String(inp)
	return out
}

func DecodeCodePage866(inp string) string {
	dec := charmap.CodePage866.NewDecoder()
	out, _ := dec.String(inp)
	return out
}

func EncodeCodePage866(inp string) string {
	enc := charmap.CodePage866.NewEncoder()
	out, _ := enc.String(inp)
	return out
}
