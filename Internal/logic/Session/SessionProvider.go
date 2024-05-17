package Session

import (
	"fmt"
	"misc/Internal/logic/config"
	"strconv"
	"strings"
	"time"

	"net"
)

type SessionProvider struct {
	Config *config.Config        // Ссылка на конфигурацию
	Items  map[*Session]*Session // Массив сессий
	OnAdd  func(Session *Session)
	OnDel  func(Session *Session)

	LastID uint
	Log    string
}

type Session struct {
	Parent      *SessionProvider // Ссылка на родительский объект
	Id          uint             // Идентификатор сессии
	Token       string           // Идентификатор сессии HTTP
	Name        string           // Имя сессии - вид, ИП адрес
	SharedId    int              // Идентификатор общей сессии - индекс базы
	SessionLock *Session         // Сессия, захватившая дпнную сессию - для общих сессий
	Log         string

	Conn   net.Conn // Сетевое подключение
	Vars   Vars     // Переменные сессии
	AppMan AppMan   // Менеджер приложения

	CodePage    uint      // Кодовая страница: 0-866, 1-1251, иначе UTF8
	TimeNet     time.Time // Время последней сетевой активности
	TimeApp     time.Time // Время последней активности приложения
	TimeCreate  time.Time // Время создания сессии
	TimeoutWork uint      // Таймаут
}

func NewSessions(config *config.Config) *SessionProvider {
	//	lLog:=""
	return &SessionProvider{
		Config: config,
		Items:  map[*Session]*Session{},
		//		Log:    &lLog,
	}
}

func (sm *SessionProvider) AddLog(msg string) {
	ltime := time.Now().Format("15:04:05")
	sm.Log = sm.Log + ltime + "> " + msg + "\n"
	fmt.Println(ltime + "> " + msg)
}

func (sm *SessionProvider) Run() {
	// Создание общих сессий
	for i, lApp := range sm.Config.Applications {
		if lApp.PoolMin == 0 {
			continue
		}
		lSession := sm.Add("Общая")
		lSession.SharedId = i
		lSession.TimeoutWork = 0

		AppCmd := lApp.OpenCmd
		AppCmd = strings.Replace(AppCmd, "<User>", lApp.Login, 1)
		AppCmd = strings.Replace(AppCmd, "<Pass>", lApp.Password, 1)

		lSession.AppMan.CommandLine = AppCmd
		lSession.AppMan.CloseCmd = lApp.CloseCmd
		lSession.AppMan.TimeoutWork = lApp.WorkTimeout
		if lApp.OpenMode == 1 {
			lSession.AppMan.Send("ee 0")
		}
	}

	// запуск проверки таймаутов
	go CheckTimeouts(sm)
}

func (sm *SessionProvider) Add(AName string) *Session {
	var lSession Session

	lSession.Id = sm.LastID
	sm.LastID++
	lSession.Name = AName
	lVar := *NewVars()
	lVar.OnChange = func(AName string, AValue string) {
		switch AName {
		case "userindex":
			{
				lIndex, _ := strconv.ParseInt(AValue, 10, 16)
				lUser := sm.Config.Users[lIndex]
				AppCmd := sm.Config.Applications[lUser.AppIndex].OpenCmd
				AppCmd = strings.Replace(AppCmd, "<User>", lUser.Login, 1)
				AppCmd = strings.Replace(AppCmd, "<Pass>", lUser.Password, 1)
				lSession.TimeoutWork = sm.Config.Applications[lUser.AppIndex].WorkTimeout
				lSession.AppMan.CommandLine = AppCmd
				lSession.AppMan.CloseCmd = sm.Config.Applications[lUser.AppIndex].CloseCmd
				lSession.AppMan.TimeoutWork = sm.Config.Applications[lUser.AppIndex].WorkTimeout
			}
		case "codepage":
			{
				lIndex, _ := strconv.ParseInt(AValue, 10, 16)
				lSession.CodePage = uint(lIndex)
			}
		case "timeout":
			{
				lIndex, _ := strconv.ParseUint(AValue, 10, 16)
				lSession.TimeoutWork = uint(lIndex)
			}
		}
	}

	lSession.Parent = sm
	lSession.Vars = lVar
	lSession.AppMan = *NewManApp(fmt.Sprintf("%d", lSession.Id))
	lSession.TimeNet = time.Now()
	lSession.TimeApp = time.Now()
	lSession.TimeCreate = time.Now()
	lSession.SharedId = -1

	sm.Items[&lSession] = &lSession
	if sm.OnAdd != nil {
		sm.OnAdd(&lSession)
	}
	return &lSession
}

func (sm *SessionProvider) Delete(Session *Session) {
	delete(sm.Items, Session)
	if sm.OnDel != nil {
		sm.OnDel(Session)
	}
}

func CheckTimeouts(sm *SessionProvider) {
	for {
		for _, s := range sm.Items {
			if s.TimeoutWork == 0 {
				continue
			}

			lTO := time.Second * time.Duration(s.TimeoutWork)
			if time.Since(s.TimeNet) > lTO {
				s.Close()
				//s.Quit()
			}
			//if time.Since(s.TimeApp) > lTO {
			//	s.Quit()
			//}
		}
		time.Sleep(time.Second)
	}
}

func (s *Session) AddLog(msg string) {
	ltime := time.Now().Format("15:04:05")
	s.Log = s.Log + ltime + "> " + msg + "\n"
	fmt.Println(ltime + "> " + msg)
}

func (s *Session) Quit() error {
	//s.Parent.Delete(s)
	//s.AppMan.Close()
	if s.Conn != nil {
		s.Conn.Close()
	}
	if s.Token != "" {
		s.Close()
	}
	return nil
}

func (s *Session) Close() error {

	// Разблокировка общих сессий
	for _, lSession := range s.Parent.Items {
		if lSession.SharedId >= 0 {
			if lSession.SessionLock == s {
				lSession.SessionLock = nil
			}
		}
	}

	s.Parent.Delete(s)
	s.AppMan.Close()
	if s.Conn != nil {
		s.Conn.Close()
	}
	if s.Token != "" {
	}

	return nil
}
