# Сервер приложений (1С 7.7, 8.3)

## cmd\app: серверная часть:
  templates\* - веб-шаблоны панели управления;
  main.go - исходный файл проекта;
  SrvApp.exe - исполняемый файл;
  default.ini - файл настроек, необходимо скопировать в SrvApp.ini.

## internal\*: исходные файлы проекта.

## append: дополнительные файлы:
  import.cmd - файл для импорта необходимых библиотек перед компиляцией;
  ТерминалСлужебный.ert - обработка 1С, обеспечивающая связь с сервером приложений;
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
### При запуске сервер приложений запускает приложения с режимом запуска=1, открывает на прослушивание указанные порты, ожидает подключение клиентов. В отладочных целях для подключения возможно использование стандартного клиента телнет. После подключения клиент TCP может установить таймаут ожидания и индекс пользователя в секции настроек [User_N]. Доступные команды:
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
