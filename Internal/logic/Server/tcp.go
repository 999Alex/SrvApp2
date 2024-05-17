package Server

import (
	"bufio"
	"log"
	"misc/Internal/logic/Session"
	"net"
	"time"
)

type ServerTCP struct {
	listenAddr string
	listener   net.Listener

	quitch chan struct{}

	OnLog     func(Session *Session.Session, msg string)
	OnConnect func(Session *Session.Session)
	OnCmd     func(Session *Session.Session, data string)
	OnClose   func(Session *Session.Session)

	Sessions *Session.SessionProvider
}

func NewServerTCP(listenAddr string, ASessions *Session.SessionProvider) *ServerTCP {
	return &ServerTCP{
		listenAddr: listenAddr,
		Sessions:   ASessions,
		quitch:     make(chan struct{}),
	}
}

func (s *ServerTCP) Start() error {
	ln, err := net.Listen("tcp", s.listenAddr)
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
	return nil
}

func (s *ServerTCP) acceptLoop() {
	for {
		conn, err := s.listener.Accept()
		if err != nil {
			// fmt.Println ("accept error: ", err)
			log.Fatal(err)
			continue
		}
		lSession := s.Sessions.Add("tcp: " + conn.RemoteAddr().String())
		lSession.Conn = conn
		lSession.Vars.Set("userindex", "0")

		if s.OnConnect != nil {
			s.OnConnect(lSession)
		}

		go s.readLoop(lSession)
		time.Sleep(time.Millisecond * 10)
	}
}

func (s *ServerTCP) readLoop(ASession *Session.Session) {
	conn := ASession.Conn
	defer conn.Close()

	lData := bufio.NewScanner(conn)
	for lData.Scan() {
		lCmd := lData.Text()

		if s.OnCmd != nil {
			s.OnCmd(ASession, lCmd)
		}
	}
	if s.OnClose != nil {
		s.OnClose(ASession)
	}
}
