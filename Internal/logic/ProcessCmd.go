package logic

import (
	"misc/Internal/logic/Session"
	"misc/Internal/strutils"
	"strconv"
	"strings"
	"time"
)

//type Logic struct {
//}

// func (l *Logic) ProcessCmd(session *Session.Session, DataStr string) ([]byte, uint) {
func ProcessCmd(session *Session.Session, DataStr string) ([]byte, uint) {
	val := ""
	//code := 200
	str := strings.Split(DataStr, " ") // разбор строки на части
	lDataStr := strutils.EncodeWindows1251(DataStr)

	if len(str) <= 0 {
		//conn.Write(InvalidCommand)
		return []byte(val), 200
	}
	cmd := strings.ToLower(str[0])

	//fmt.Println(cmd)
	switch cmd {
	default:
		{
			return Session.Reply[401], 401
		}
	case "stop":
		{
			root.Active = false
			return []byte("Stopping"), 200
		}
	case "nop":
		{
			return []byte("NOP"), 200
		}
	case "quit":
		{
			session.Quit()
			return []byte(val), 200
		}
	case "help":
		{
			lRes := "quit\n\rhelp\n\rset\n\rget\n\ree\n\reb\n\r"
			return []byte(lRes), 150
		}
	case "set":
		{
			switch len(str) {
			case 1:
				{
					val, code := session.Vars.List()
					return []byte(val), code
				}
			case 3:
				{
					val, code := session.Vars.Set(str[1], str[2])
					return []byte(val), code
				}
			default:
				{
					return Session.Reply[402], 402
				}

			}
		}
	case "get":
		{
			switch len(str) {
			case 2:
				{
					val, _ = session.Vars.Get(str[1])
					return []byte(val), 200
				}
			default:
				{
					return Session.Reply[402], 402
				}
			}
		}
	case "ee", "eb":
		{
			if len(str) < 2 {
				return Session.Reply[402], 402
			}
			session.TimeApp = time.Now()
			val, reply := session.AppMan.Send(lDataStr)
			session.TimeApp = time.Now()
			return val, reply
		}

	case "eei", "ebi":
		{
			if len(str) < 3 {
				return Session.Reply[402], 402
			}
			session.TimeApp = time.Now()
			li, _ := strconv.ParseUint(str[1], 10, 16)

			ls1 := append([]string{str[0][0:2]}, str[2:]...)
			cmd := strutils.EncodeWindows1251(strings.Join(ls1, " "))
			for _, lSession := range session.Parent.Items {
				if lSession.SharedId == int(li) {
					val, reply := lSession.AppMan.Send(cmd)
					lSession.TimeApp = time.Now()
					return val, reply
				}
			}
			return Session.Reply[301], 301
		}
	case "locki":
		{
			if len(str) < 2 {
				return Session.Reply[402], 402
			}

			session.TimeApp = time.Now()
			li, _ := strconv.ParseUint(str[1], 10, 16)

			for _, lSession := range session.Parent.Items {
				if lSession.SharedId == int(li) {
					if lSession.SessionLock == nil {
						lSession.SessionLock = session
						return []byte{}, 200
					}
				}
			}

			return Session.Reply[301], 301
		}
	case "unlocki":
		{
			if len(str) < 2 {
				return Session.Reply[402], 402
			}

			session.TimeApp = time.Now()
			li, _ := strconv.ParseUint(str[1], 10, 16)

			for _, lSession := range session.Parent.Items {
				if lSession.SharedId == int(li) {
					if lSession.SessionLock == session {
						lSession.SessionLock = nil
						return []byte{}, 200
					}
				}
			}

			return Session.Reply[301], 301
		}
	}
}
