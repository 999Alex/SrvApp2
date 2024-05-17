package logic

import (
	"fmt"
	"misc/Internal/logic/Server"
	"misc/Internal/logic/Session"
	"misc/Internal/logic/config"
	"misc/Internal/strutils"
	"os"
	"time"
)

var root *Root
var Sessions *Session.SessionProvider
var Config config.Config

type Root struct {
	Config   *config.Config
	Sessions *Session.SessionProvider
	Active   bool
}

func NewRoot() *Root {
	return &Root{}
}

func (r *Root) Init() {
	root = r
	r.Active = true
	Config = config.Init()
	Sessions = Session.NewSessions(&Config)
	Sessions.OnAdd = func(Session *Session.Session) {
		//gui.SessionsLogs.Add(Session)
	}
	Sessions.OnDel = func(Session *Session.Session) {
		//gui.SessionsList.Refresh(Session.Parent)
	}

	//gui.Init(Sessions)

	Sessions.Run()
	//gui.SessionsList.Refresh(Sessions)

	// запуск серверов IP
	StartServers()

	// запуск окна
	//gui.Run()
	for r.Active {
		data := make([]byte, 8)
		n, err := os.Stdin.Read(data)
		if err == nil && n > 0 {
			//process(data)
			fmt.Println("Остановка сервера")
		}
		break
		//time.Sleep(100)
	}

	// закрытие сессий
	for _, lSes := range Sessions.Items {
		lSes.Close()
	}
}

func StartServers() {
	// Настройка сервера TCP
	if Config.Network.PortTCP != 0 {
		portTCP := fmt.Sprint(Config.Network.PortTCP)

		//gui.AddLog("Сервер TCP порт " + portTCP)
		Sessions.AddLog("Сервер TCP порт " + portTCP)

		server_tcp := Server.NewServerTCP(":"+portTCP, Sessions)
		server_tcp.OnLog = func(Session *Session.Session, msg string) {
			Sessions.AddLog(msg)
			//gui.AddLog(msg)
		}

		server_tcp.OnConnect = func(Session *Session.Session) {
			conn := Session.Conn

			tClient := "tcp: " + conn.RemoteAddr().String()
			Session.Name = tClient
			Session.Parent.AddLog("Подключение " + tClient)
			//gui.AddLog("Подключение " + tClient)
			//gui.SessionsList.Refresh(Sessions)

			ProcessCmd(Session, "set userindex 0")
			ProcessCmd(Session, "set codepage 0")
			conn.Write([]byte("SrvApp v1.0\r\n"))
		}

		server_tcp.OnCmd = func(Session *Session.Session, data string) {
			conn := Session.Conn
			lCmd := ""
			if Session.CodePage == 0 {
				lCmd = strutils.DecodeCodePage866(data)
			} else {
				lCmd = strutils.DecodeWindows1251([]byte(data))
			}
			val, code := ProcessCmd(Session, lCmd)
			scode := fmt.Sprint(code)
			Session.TimeNet = time.Now()
			if string(val) == "NOP" {
				conn.Write([]byte(scode))
				conn.Write([]byte("\r\n"))
			} else {
				//gui.SessionsLogs.Log(Session, "{"+lCmd+"}")
				//gui.SessionsLogs.Log(Session, "["+scode+"] "+strutils.DecodeWindows1251(val))
				Session.AddLog("{" + lCmd + "}")
				Session.AddLog("[" + scode + "] " + strutils.DecodeWindows1251(val))
				if byte(scode[1]) > 52 {
					conn.Write([]byte(scode + "\r\n"))
					conn.Write(val)
					conn.Write([]byte("\r\n.\r\n"))
				} else {
					lAnswer := ""
					switch Session.CodePage {
					case 0:
						lAnswer = strutils.EncodeCodePage866(string(val))
					case 1:
						lAnswer = strutils.EncodeWindows1251(string(val))
					default:
						lAnswer = string(val)
					}
					conn.Write([]byte(scode))
					conn.Write([]byte(" "))
					conn.Write([]byte(lAnswer))
					//conn.Write(val)
					conn.Write([]byte("\r\n"))
				}
			}
		}
		server_tcp.OnClose = func(Session *Session.Session) {
			conn := Session.Conn

			tClient := "tcp: " + conn.RemoteAddr().String()
			//gui.AddLog("Отключение " + tClient)
			Session.Parent.AddLog("Отключение " + tClient)

			Session.Close()

			//gui.SessionsList.Refresh(Sessions)
			//gui.SessionsLogs.Del(Session)
		}

		go server_tcp.Start()
	}
	// Настройка сервера HTTP
	if Config.Network.PortHTTP != 0 {
		portHTTP := fmt.Sprint(Config.Network.PortHTTP)
		//gui.AddLog("Сервер HTTP порт " + portHTTP)
		Sessions.AddLog("Сервер HTTP порт " + portHTTP)

		server_http := Server.NewServerHTTP(":"+portHTTP, Sessions)
		server_http.OnLog = func(Session *Session.Session, msg string) {
			//gui.AddLog(msg)
			Sessions.AddLog(msg)
		}
		server_http.OnCmd = func(Session *Session.Session, data string) ([]byte, []byte) {
			//gui.SessionsList.Refresh(Sessions)
			val, code := ProcessCmd(Session, data)
			scode := fmt.Sprint(code)
			Session.TimeNet = time.Now()

			//fmt.Println(val, scode)
			return []byte(val), []byte(scode)
		}

		go server_http.Start()

	}

	/*
		portHTTP := fmt.Sprint(r.Config.Network.Port + 80)
		Server.Port = ":" + portHTTP
		gui.AddLog("Сервер HTTP порт " + portHTTP)
		go Server.Init() // запуск сервера HTTP

		Server.OnConnect = func(w http.ResponseWriter, r *http.Request) {
			tClient := "http: " + r.Host + " " + r.Method
			gui.AddLog("Подключение " + tClient)
			AppCmd := r.Config.Applications[0].OpenCmd
			lUser := r.Co Config.Users[0]
			AppCmd = strings.Replace(AppCmd, "<User>", lUser.Login, 1)
			AppCmd = strings.Replace(AppCmd, "<Pass>", lUser.Password, 1)
			winapi.StartApplication(AppCmd)
		}
	*/
}
