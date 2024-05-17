package Server

import "misc/Internal/logic/Session"

type Server interface {
	OnConnect(Session *Session.Session)
	OnCmd(Session *Session.Session, data string)
	OnClose(Session *Session.Session)
}
