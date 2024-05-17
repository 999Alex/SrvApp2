package winapi

import (
	"syscall"

	"github.com/gonutz/w32"
	"github.com/hnakamur/w32syscall"
)

const (
	STATUS_PENDING uint32 = 0x0000103
	STILL_ACTIVE   uint32 = STATUS_PENDING
)

type Window struct {
	Handle w32.HWND
	Text   string
}

var CurThrId w32.HWND = GetCurrentThreadId() //  w32.HWND(r1)
var CurProcId w32.HWND = GetCurrentProcessId()

func GetCurrentProcessId() w32.HWND {
	return w32.HWND(w32.GetCurrentProcessId())
}

func GetWindows(cur_id w32.HWND) []Window {
	res := []Window{}
	err := w32syscall.EnumWindows(
		func(hwnd syscall.Handle, lparam uintptr) bool {
			h := w32.HWND(hwnd)
			id := w32syscall.GetWindowThreadProcessId(hwnd)
			lid := w32.HWND(id)

			if lid != cur_id {
				return true
			}
			if !w32.IsWindowVisible(h) {
				return true
			}

			var lWin Window
			lWin.Handle = h
			lWin.Text = w32.GetWindowText(h)
			res = append(res, lWin)
			return true
		},
		0)
	if err != nil {
		//log.Fatalln(err)
		return []Window{}
	}
	return res
}

func StartApplication(Application string) syscall.ProcessInformation {
	var sI syscall.StartupInfo
	var pI syscall.ProcessInformation
	syscall.CreateProcess(
		nil,
		syscall.StringToUTF16Ptr(Application),
		nil,
		nil,
		true,
		0,
		nil,
		nil,
		&sI,
		&pI)
	return pI

	//w32.MoveWindow(h, 0, 0, 1200, 600, true)

}

//lLog.SetText(lLog.Text + fmt.Sprintf("%d", lid) + ": " + text + "\n")
//if strings.Contains(text, "Calculator") {
//w32.MoveWindow(h, 0, 0, 1200, 600, true)
//}

/*
	w32syscall.EnumChildWindows(hwnd,
		func(hwndc syscall.Handle, lparam uintptr) bool {
			hc := w32.HWND(hwndc)
			textc := w32.GetWindowText(hc)
			res = res + " - " + textc + "\n"
			return true
			}, 0)
*/

//output, err := exec.Command("go", "run", "notepad.exe").Output()
//output, err := exec.Command("notepad.exe", "").Output()
//if err == nil {
//	fmt.Println(output) // write the output with ResponseWriter
//}
