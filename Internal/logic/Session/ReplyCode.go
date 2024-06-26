package Session

var Reply map[uint][]byte

func init() {
	Reply = map[uint][]byte{
		100: []byte("NOP"),
		101: []byte("Команда выполнена успешно."),
		150: []byte("Команда выполнена успешно, передача ответа."),
		200: []byte("Команда выполнена успешно."),
		250: []byte("Команда выполнена успешно, передача ответа."),
		300: []byte("Ошибка связи с приложением."),
		301: []byte("Не удалось подключиться к общей сессии."),
		400: []byte("Ошибка клиента."),
		401: []byte("Неизвестная команда."),
		402: []byte("Недостаточно аргументов."),
		500: []byte("Внутренняя ошибка сервера."),
		501: []byte("Сервер не принимает подключения."),
		502: []byte("Сервер находится на обслуживании."),
	}
}
