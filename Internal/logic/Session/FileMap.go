package Session

import (
	"fmt"
	"reflect"
	"strings"
	"sync"
	"syscall"
	"time"
	"unsafe"
)

type FileMap struct {
	Handle     syscall.Handle
	handleLock sync.Mutex
	Buff       []byte
	Data       []byte
	OnTiker    func()
}

type Pack struct {
	Ticker uint   // счетчик регистрации активности приложения
	Cmd    string //11
	Reply  string //4
	Len    uint   //4
	Data   *[]byte
}

func NewFileMap() *FileMap {
	return &FileMap{}
}

func (fm *FileMap) Open(FileID string) error {
	size := 65000
	offset := 0

	// создаем отображаемый файл
	h, err := syscall.CreateFileMapping(syscall.InvalidHandle, nil, syscall.PAGE_READWRITE, 0, uint32(size), syscall.StringToUTF16Ptr(FileID))
	if err != nil {
		return err
	}

	// отображаем файл
	addr, err := syscall.MapViewOfFile(h, syscall.FILE_MAP_WRITE, uint32(offset>>32), uint32(offset), uintptr(size))
	if err != nil {
		return err
	}

	// сохраним handle файла
	fm.handleLock.Lock()
	fm.Handle = h
	fm.handleLock.Unlock()

	// Создаем слайс и привязываем его к отображаемой памяти
	sl := reflect.SliceHeader{Data: addr, Len: size, Cap: size}
	fm.Buff = *(*[]byte)(unsafe.Pointer(&sl))

	sd := reflect.SliceHeader{Data: addr + 23, Len: size, Cap: size}
	fm.Data = *(*[]byte)(unsafe.Pointer(&sd))

	return err

	/*
		lHandle, err := winapi.CreateFileMapping(w32.INVALID_HANDLE_VALUE, nil, winapi.PAGE_READWRITE, 0, 65535, FileID)
		if !errors.Is(err, windows.ERROR_SUCCESS) {
			return err
		}

		lAddr, err := syscall.MapViewOfFile(syscall.Handle(lHandle), syscall.FILE_MAP_WRITE, 0, 0, 0)
		//fm.Addr = unsafe.Pointer(lAddr)
		fm.Addr = (*[]byte)(unsafe.Pointer(lAddr))
		lv := *fm.Addr
		fmt.Println(lv[0])

		tAddr := []byte("123")
		tv := *tAddr

		return nil
	*/
}

func (fm *FileMap) Write(ACmd string, AReply string, AData string) error {
	// запишем длину данных
	lLen := int32(len(AData))
	sl := unsafe.Slice(&lLen, 4)
	lenBuff := *(*[]byte)(unsafe.Pointer(&sl))
	copy(fm.Buff[19:], lenBuff) //Len

	// запишем данные
	copy(fm.Buff[23:], []byte(AData)) //Cmd

	// запишем команду последней, когда пакет готов
	lCmd := make([]byte, 11)
	copy(lCmd, ACmd[:])
	copy(fm.Buff[4:], lCmd) //Cmd

	return nil
}

func (fm *FileMap) Read() (Pack, error) {
	var lPack Pack

	lPack.Ticker = uint(fm.Buff[0]) +
		uint(fm.Buff[1])*256 +
		uint(fm.Buff[2])*256*256 +
		uint(fm.Buff[3])*256*256*256 // счетчик событий активности приложения

	lPack.Cmd = strings.SplitN(string(fm.Buff[4:15]), "\x00", 2)[0] // команда, заканчивается 0 символом

	lPack.Reply = string(fm.Buff[16:19]) // код ответа, 3 символа
	lPack.Len = uint(fm.Buff[19]) +
		uint(fm.Buff[20])*256 +
		uint(fm.Buff[21])*256*256 +
		uint(fm.Buff[22])*256*256*256 // длина данных в буфере
	lPack.Data = &fm.Data // связываем данные с буфером

	return lPack, nil
}

func (fm *FileMap) CheckFor(ACmd string) (Pack, error) {
	var lPack Pack

	//	if fm.Buff==[]byte(ACmd){

	//	}

	return lPack, nil
}

func (fm *FileMap) Listen() error {
	lPack, err := fm.Read()
	if err != nil {
		return err
	}
	lTicker := lPack.Ticker

	for {
		lPack, err := fm.Read()
		if err != nil { // ошибка чтения из файла
			return err
		}

		if lPack.Ticker != lTicker { // обновился счетчик активности приложения
			lTicker = lPack.Ticker
			if fm.OnTiker != nil {
				fm.OnTiker()
			}
		}
		time.Sleep(time.Millisecond)
	}
}

func (fm *FileMap) WaitFor(ACmd string, ATimeOutMS uint) (Pack, error) {
	lPack, err := fm.Read()
	if err != nil {
		return lPack, err
	}
	lTicker := lPack.Ticker

	lTimeOut := time.Now().Add(time.Duration(ATimeOutMS) * time.Second)
	for {
		lPack, err := fm.Read()
		if err != nil { // ошибка чтения из файла
			return lPack, err
		}

		if lPack.Cmd == ACmd { // пришла ожидаемая команда
			return lPack, nil
		}

		if lPack.Ticker != lTicker { // обновился счетчик активности приложения
			lTimeOut = time.Now().Add(time.Duration(ATimeOutMS) * time.Second)
			if fm.OnTiker != nil {
				fm.OnTiker()
			}
		}
		if lTimeOut.Before(time.Now()) { // превышен таймаут ожидания
			return lPack, fmt.Errorf("timeout")
		}

		//fmt.Println(lPack.Cmd)
		time.Sleep(time.Millisecond)
	}
	//return nil
}
