package Session

import (
	"fmt"
	"misc/Internal/logic/winapi"
	"misc/Internal/strutils"
	"strconv"
	"syscall"
	"time"
)

type AppMan struct {
	CommandLine string
	CloseCmd    string
	Handle      syscall.Handle
	FM          *FileMap
	TimeoutWork uint
	Token       string
}

func NewManApp(t string) *AppMan {
	return &AppMan{
		Token: t,
	}
}

func (am *AppMan) Start() error {
	// Создание отображаемого файла
	//lToken := fmt.Sprintf("%d", 1)
	lFileID := fmt.Sprintf("ManagerApp" + am.Token)

	lFM := NewFileMap()
	err := lFM.Open(lFileID)
	if err != nil {
		return err
	}

	if lFM.Handle == 0 { // Ошибка создания отображаемого файла
		return fmt.Errorf("Ошибка создания отображаемого файла")
	}

	am.FM = lFM

	lFM.Write("INIT", "", "")
	PI := winapi.StartApplication(am.CommandLine + " /ID" + am.Token)
	_, err = lFM.WaitFor("ANSWER", 5)

	if err != nil {
		return err
	}

	//fmt.Println("OK")
	am.Handle = PI.Process
	lFM.Write("READY", "", "")
	//	for {
	//		fmt.Println(string(lFM.Buff[0:11]))
	//		time.Sleep(1000 * time.Millisecond)
	//	}

	return nil
}

func (am *AppMan) Close() error {
	/*
		if Assigned(OnAppClose) then OnAppClose(lSession);
		if fActive then begin
		  doLog(lSession, ' отправка команды на закрытие', 0);
		  SetParent(nil);

		  l_CloseCode:=AppInfo.CloseCmd;
		  Send(l_CloseCode+#9);
		  lTO:=TSession(Session).ManApp.AppInfo.CloseTimeOut;
		end;
		//lTO:=30;
		// Ожидание
		lDT:=Now+lTO/24/60/60;
		repeat
		  sleep(100);
		  if CheckApp=0 then begin
			doLog(lSession, ' приложение закрылось', 0);
			exit;
		  end;
		  if Assigned(OnProcessMessages) then OnProcessMessages;
		until Now>lDT;
	*/
	// Закрытие приложения принудительно
	//doLog(lSession, ' принудительное завершение', 0);

	//if am.Handle != 0 {
	if am.CheckApp() {
		am.Send(strutils.EncodeWindows1251(am.CloseCmd))
		lTime := time.Now()
		lTO := time.Second * 30
		for {
			time.Sleep(time.Millisecond * 100)
			if !am.CheckApp() {
				return nil
			}
			if time.Since(lTime) >= lTO {
				break
			}
		}

		syscall.TerminateProcess(am.Handle, 4)
	}
	return nil
}

func (am *AppMan) CheckApp() bool {
	// Проверим, запущено ли приложение

	if am.Handle != syscall.Handle(0) {
		var lCode uint32
		syscall.GetExitCodeProcess(am.Handle, &lCode)

		if lCode == winapi.STILL_ACTIVE {
			return true
		}
	}
	return false
}

func (am *AppMan) Send(ACmd string) ([]byte, uint) {
	lRes := []byte{}

	if !am.CheckApp() {
		//if am.Handle == 0 {
		err := am.Start()
		if err != nil {
			return lRes, 500
		}
	}
	_, err := am.FM.WaitFor("READY", am.TimeoutWork)
	if err != nil {
		return lRes, 500
	}

	am.FM.Write("QUERY", "", ACmd)
	lPack, err := am.FM.WaitFor("ANSWER", am.TimeoutWork)
	if err != nil {
		return lRes, 500
	}
	fmt.Println("len ", lPack.Len)
	lRes = am.FM.Data[:lPack.Len]
	//fmt.Println(">", string(am.FM.Data[:lPack.Len]))
	am.FM.Write("READY", "", "")

	lReply, _ := strconv.ParseInt(lPack.Reply, 10, 16)
	return lRes, uint(lReply)
}
