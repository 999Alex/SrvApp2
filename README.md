# Сервер приложений (1С 7.7, 8.3)

## cmd\app: серверная часть:
  templates\* - веб-шаблоны панели управления;
  main.go - исходный файл проекта;
  SrvApp.exe - исполняемый файл;
  default.ini - файл настроек, необходимо скопировать в SrvApp.ini.

## internal\*: исходные файлы проекта.

## append: дополнительные файлы:
  import.cmd - файл для импорта необходимых библиотек перед компиляцией;
  ТерминалСлужебный.ert - обработка 1С, обеспечивающая связь с сервером приложений через внешнюю компоненту;
  2 Компонента\* - исходные файлы внешней компоненты 1С и сама компонента;
  2 Компонента\TlnExt5.dll - внешняя компонента 1С для связи с сервером приложений через отображаемые файлы.

## Настройки сервера приложений считываются при запуске из файла SrvApp.ini:
### Секция [Network]:
    PortTCP=2000 - порт TCP;
    PortHTTP=2080 - порт HTTP.
### Секции [App_0]..[App_9] - настройки используемых приложений:
    OpenCmd - путь запуска приложения;
    OpenMode - режим запуска приложения при старте сервера приложений (0 - не запускать, 1 - запускать);
    OpenTimeout - таймаут запуска приложения в секундах;
    Login - имя пользователя для общих сессий приложения;
    Password - пароль для общих сессий приложения;
    WorkTimeout - таймаут выполнения команд приложением;
    CloseCmd - команда, передаваемая приложению при закрытии;
### Секции [User_0]..[User_9] - настройки пользователей приложений:
    AppIndex - индекс приложения из секции настроек приложений (0-9);
    Login - имя пользователя в приложении;
    Password - пароль пользователя в приложении.
### Запуск сервера 
При запуске сервер приложений запускает приложения с режимом запуска=1, открывает на прослушивание указанные порты, ожидает подключение клиентов. В отладочных целях для подключения возможно использование стандартного клиента телнет. После подключения клиент TCP может установить таймаут ожидания и индекс пользователя в секции настроек [User_N]. При получении команды, обращающейся к приложению (ee, ebi) сервер проверяет состояние приложения этой сессии, если приложение не запущено - стартует процесс. Дополнительно к строке запуска из файла настроек в параметры запуска добавляется идентификатор отображаемого файла. Приложение получает команды и отправляет данные через этот файл. Для 1С предприятия разработана внешняя компонента, обеспечивающая работу с сервером приложений через отображаемые файлы (TlnExt5.dll). 

### Доступные команды:
-  nop - не выполняет никаких операций, сбрасывает сетевой таймаут;
-  help - выводит список команд;
-  stop - завершает работу сервера приложений;
-  quit - завершает сесиию;
-  set - выводит значения всех переменных сессии;
-  set [Переменная] [Значение] - устанавливает значение переменных сессии;
-  get [Переменная] - возвращает значение переменной сессии;
-  ee [Выражение 1С] - вычисляет выражение 1С через EvalExpr в текущей сессии;
-  eb [Выражение 1С] - выполняет пакет команд 1С через ExecBatch в текущей сессии;
-  eei [Индекс] [Выражение 1С] - вычисляет выражение 1С через EvalExpr в сессии по указанному индексу (секция App_N);
-  ebi [Индекс] [Выражение 1С] - выполняет пакет команд 1С через ExecBatch в сессии  по указанному индексу (секция App_N);
-  locki [Индекс] - блокирует сессию по указанному индексу;
-  ulocki [Индекс] - разблокирует сессию по указанному индексу;

### Формат ответа:
При успешном выполнении команды возвращается код 2хх. Если команда не возвращает ответа, то код находится в диапазоне 200-249, иначе 250-299. При возврате ответа его концом считается строка, состоящая из одиночной точки.
Для вспомогательных команд (nop, help) выделен диапазон кодов ответа 1хх.

#### Коды ответов:
		100: NOP.
		101: Команда выполнена успешно.
		150: Команда выполнена успешно, передача ответа.
		200: Команда выполнена успешно.
		250: Команда выполнена успешно, передача ответа.
		300: Ошибка связи с приложением.
		301: Не удалось подключиться к общей сессии.
		400: Ошибка клиента.
		401: Неизвестная команда.
		402: Недостаточно аргументов.
		500: Внутренняя ошибка сервера.
		501: Сервер не принимает подключения.
		502: Сервер находится на обслуживании.

### Примеры команд:
#### Обращение к приложению - вывод текущей даты 1С. Код ответа 250, далее идет тело ответа, завершается строкой из точки.
    ee ТекущаяДата()
    250
    17.05.2024
    .
