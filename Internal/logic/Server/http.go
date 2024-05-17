package Server

import (
	"encoding/json"
	"fmt"
	"html/template"
	"io"
	"log"
	"misc/Internal/logic/Session"
	"misc/Internal/strutils"
	"net/http"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
)

//var Port string
//var OnConnect func(w http.ResponseWriter, r *http.Request)

type ServerHTTP struct {
	listenAddr string
	//listener   net.Listener

	quitch   chan struct{}
	OnLog    func(Session *Session.Session, msg string)
	OnHandle func(w http.ResponseWriter, r *http.Request)
	OnCmd    func(Session *Session.Session, data string) ([]byte, []byte)
	//OnClose   func(Session *Session.Session)

	Sessions *Session.SessionProvider
}

type Answer struct {
	Id     string `json:"id"`
	Code   string `json:"Код"`
	Answer string `json:"Ответ"`
}

type Pair struct {
	Key   uint
	Value *Session.Session
}

type PairList []Pair

type sesLog struct {
	Log []string
}

func NewServerHTTP(listenAddr string, ASessions *Session.SessionProvider) *ServerHTTP {
	lServerHTTP := ServerHTTP{
		listenAddr: listenAddr,
		Sessions:   ASessions,
		quitch:     make(chan struct{}),
	}
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// Загрузка шаблонов
		t, err := template.ParseFiles("templates/cntrl/main.html", "templates/cntrl/mainlog.html", "templates/cntrl/sessionlist.html", "templates/cntrl/sessionlog.html")
		if err != nil {
			fmt.Fprintf(w, err.Error())
			return
		}

		// Подготовка структур
		mainLog := strings.Split(ASessions.Log, "\n") // разбор строки на части
		var sessionlist []struct {
			Id         uint
			Name       string
			UserName   string
			TimeNet    string
			TimeApp    string
			TimeCreate string
			LogI       int
		}

		// отсортируем сессии по идентификатору
		pl := make(PairList, 0, len(ASessions.Items))
		for k := range ASessions.Items {
			pl = append(pl, Pair{k.Id, k})
		}
		sort.Slice(pl, func(i, j int) bool { return pl[i].Key < pl[j].Key })

		SesLogs := make([]sesLog, len(ASessions.Items), len(ASessions.Items))
		for i, v := range pl {
			lSes := v.Value
			sLog := strings.Split(lSes.Log, "\n") // разбор строки на части
			for _, v := range sLog {
				SesLogs[i].Log = append(SesLogs[i].Log, v)
			}

			var lName string
			if lSes.SessionLock != nil {
				lName = lSes.Name + " < " + fmt.Sprintf("%d", lSes.SessionLock.Id)
			} else {
				lName = lSes.Name
			}

			lUserI, _ := lSes.Vars.Get("userindex")
			li, _ := strconv.ParseInt(lUserI, 10, 8)
			lUserName := ASessions.Config.Users[li].Login

			sessionlist = append(sessionlist, struct {
				Id         uint
				Name       string
				UserName   string
				TimeNet    string
				TimeApp    string
				TimeCreate string
				LogI       int
			}{lSes.Id, lName, lUserName,
				time.Time{}.Add(time.Since(lSes.TimeNet)).Format("15:04:05"), time.Time{}.Add(time.Since(lSes.TimeApp)).Format("15:04:05"), lSes.TimeCreate.Format("02-01-2006 15:04:05"),
				i,
			})
		}

		// Обработка команд
		lCmd := r.FormValue("cmd")
		switch lCmd {
		case "mainlog":
			{
				t.ExecuteTemplate(w, "mainlog", mainLog)
				return
			}
		case "sessionlist":
			{
				t.ExecuteTemplate(w, "sessionlist", sessionlist)
				return
			}
		case "sessionlog":
			{
				var obj struct {
					Sessions []struct {
						Id         uint
						Name       string
						UserName   string
						TimeNet    string
						TimeApp    string
						TimeCreate string
						LogI       int
					}
					Logs []sesLog
				}
				obj.Sessions = sessionlist
				obj.Logs = SesLogs

				t.ExecuteTemplate(w, "sessionlog", obj)
				return
			}
		case "session_close":
			{
				lid, _ := strconv.ParseUint(r.FormValue("id"), 10, 16)
				for lSes := range ASessions.Items {
					if lSes.Id == uint(lid) {
						lSes.Quit()
						break
					}
				}
				return
			}
		case "session_nop":
			{
				lid, _ := strconv.ParseUint(r.FormValue("id"), 10, 16)
				for lSes := range ASessions.Items {
					if lSes.Id == uint(lid) {
						lSes.TimeNet = time.Now()
						break
					}
				}
				return
			}
		case "":
			{
				t.ExecuteTemplate(w, "main", nil)
			}
		}
	})

	http.HandleFunc("/api", func(w http.ResponseWriter, r *http.Request) {
		lToken := r.FormValue("id")

		if lServerHTTP.OnLog != nil {
			lServerHTTP.OnLog(nil, "Сервер HTTP: "+lToken)
		}

		lBody, err := io.ReadAll(r.Body)
		if err != nil {
			log.Fatalf("Oops! Failed reading body of the request.\n %s", err)
			http.Error(w, err.Error(), 500)
		}

		//lPack := HTTPPack{}
		//err := json.Unmarshal(lBody, &lPack)
		//if err != nil { //Ошибка запроса - невозможно разобрать JSON
		//	return
		//}

		var lSession *Session.Session
		lSession = nil

		if lToken == "" { // Если токен пустой - создаем сессию
			lSession = ASessions.Add("http: " + r.RemoteAddr)
			lSession.Token = uuid.New().String()
			lSession.Vars.Set("userindex", "0")
			lSession.Vars.Set("codepage", "1")

			//if s.OnConnect != nil {
			//	s.OnConnect(lSession)
			//}
		} else {
			// ищем сессию в существующих по токену
			for _, lSes := range ASessions.Items {
				if lSes.Token == "" { // это не HTTP сессия
					continue
				}
				if lSes.Token == lToken { // нашли сессию
					lSession = lSes
				}
			}

		}
		if lSession == nil {
			return
		}
		lTimeout, _ := strconv.ParseUint(r.FormValue("timeout"), 10, 64)
		lSession.TimeoutWork = uint(lTimeout)
		if lServerHTTP.OnCmd != nil {
			res, code := lServerHTTP.OnCmd(lSession, string(lBody))
			//fmt.Println(res, code)
			var lres string
			//switch lSession.CodePage {
			//case 0:
			//	lres = strutils.EncodeCodePage866(string(res))
			//case 1:
			//	lres = strutils.EncodeWindows1251(string(res))
			//default:
			//	lres = string(res)
			//}

			lres = strutils.DecodeWindows1251(res)

			lAnswer := Answer{
				Id:     lSession.Token,
				Code:   string(code),
				Answer: string(lres),
			}

			data, err := json.Marshal(lAnswer)

			if err != nil {
				return
			}
			w.Header().Set("Content-Type", "application/text; charset=UTF-8'")
			fmt.Fprintln(w, string(data))
		}

		//if lServerHTTP.OnHandle != nil {
		//	lServerHTTP.OnHandle(w, r)
		//}

		//data, err := json.Marshal(r.Body)
		//if err != nil { //Ошибка запроса - невозможно разобрать JSON
		//	return
		//}

		//output, err := exec.Command("go", "run", "notepad.exe").Output()
		//if err == nil {
		//	w.Write(output) // write the output with ResponseWriter
		//}
	})

	return &lServerHTTP

}

func (s *ServerHTTP) Start() error {
	if s.OnLog != nil {
		s.OnLog(nil, "Cервер HTTP запущен.")
	}
	http.ListenAndServe(s.listenAddr, nil)

	/*	ln, err := net.Listen("http", s.listenAddr)
		if err != nil {
			if s.OnLog != nil {
				s.OnLog(nil, "Ошибка запуска сервера TCP: "+err.Error())
			}
			return err
		}
		defer ln.Close()
		s.OnLog(nil, "Cервер TCP запущен.")

		s.listener = ln
		go s.acceptLoop()
		<-s.quitch
	*/
	return nil
}

/*func Init() {

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		//Sessions.Append("http")
		fmt.Println("connect")
		fmt.Fprintf(w, "Hello World!")

		output, err := exec.Command("go", "run", "notepad.exe").Output()
		if err == nil {
			w.Write(output) // write the output with ResponseWriter
		}
		if OnConnect != nil {
			OnConnect(w, r)
		}

	})
	http.ListenAndServe(Port, nil)
}*/
