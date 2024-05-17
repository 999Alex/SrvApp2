package winapi

import (
	"syscall"
	"unsafe"

	"github.com/gonutz/w32"
)

const (
	PAGE_EXECUTE_READ      = 0x20
	PAGE_EXECUTE_READWRITE = 0x40
	PAGE_EXECUTE_WRITECOPY = 0x80
	PAGE_READONLY          = 0x04
	PAGE_READWRITE         = 0x04
	PAGE_WRITECOPY         = 0x08
)

type SecurityAttributes struct {
}

type PSecurityAttributes *SecurityAttributes

func GetCurrentThreadId() w32.HWND {
	dll := syscall.NewLazyDLL("kernel32.dll")
	proc := dll.NewProc("GetCurrentThreadId")

	r1, _, err1 := proc.Call()
	if err1 == nil {
	}
	return w32.HWND(r1)
}

func WaitForInputIdle(hProcess w32.HANDLE, dwMilliseconds uint) uintptr {
	dll := syscall.NewLazyDLL("user32.dll")
	proc := dll.NewProc("WaitForInputIdle")

	r1, _, err1 := proc.Call(
		uintptr(hProcess),
		uintptr(dwMilliseconds),
	)
	if err1 == nil {
	}
	return r1

}

func SetParent(hWndChild, hWndNewParent w32.HWND) {
	dll := syscall.NewLazyDLL("user32.dll")
	proc := dll.NewProc("SetParent")

	_, _, err1 := proc.Call(
		uintptr(hWndChild),
		uintptr(hWndChild),
	)
	if err1 == nil {
	}
	//return r1

}

func CreateFileMapping(
	hFile w32.HANDLE,
	lpFileMapingAttributes PSecurityAttributes,
	flProtect uint,
	dwMaximumSizeHigh uint,
	dwMaximumSizeLow uint,
	lpName string,
) (w32.HANDLE, error) {
	dll := syscall.NewLazyDLL("kernel32.dll")
	proc := dll.NewProc("CreateFileMappingW")

	r1, _, err := proc.Call(
		uintptr(hFile),
		uintptr(unsafe.Pointer(lpFileMapingAttributes)),
		uintptr(flProtect),
		uintptr(dwMaximumSizeHigh),
		uintptr(dwMaximumSizeLow),
		uintptr(unsafe.Pointer(syscall.StringToUTF16Ptr(lpName))),
	)
	//if err == nil {
	//fmt.Println("!!! cfm: ", err)
	//}
	return w32.HANDLE(r1), err
}
