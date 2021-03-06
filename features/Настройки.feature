# language: ru

Функциональность: Настройки продукта

Как разработчик
Я хочу иметь возможность настраивать параметры продукта из внешнего файла
Чтобы управлять поведением продукта, например, если есть прокси

Контекст: файл настроек
    Допустим Я создаю временный каталог и сохраняю его в контекст
    И Я устанавливаю временный каталог как рабочий каталог

    И Я установил рабочий каталог как текущий каталог

    # И Я показываю рабочий каталог

Сценарий: Получение настроек
    Допустим Я копирую файл "opm.cfg" из каталога "tests/fixtures" проекта в рабочий каталог
    Когда я читаю настройки из файла "opm.cfg"
    Тогда значение настройки "СоздаватьShСкриптЗапуска" равно "false"
    И значение настройки "ИспользоватьПрокси" равно "false"
    И значение настройки "ИспользоватьСистемныйПрокси" равно "false"
    И значение настройки "НастройкиПрокси.Сервер" равно ""
    И значение настройки "НастройкиПрокси.Порт" равно 0
    И значение настройки "НастройкиПрокси.Пользователь" равно ""
    И значение настройки "НастройкиПрокси.Пароль" равно ""
    И значение настройки "НастройкиПрокси.ИспользоватьАутентификациюОС" равно "false"

Сценарий: Получение значения по умолчанию, если настройка не задана в файле настроек 
    Допустим Я копирую файл "opm-incomplete.cfg" из каталога "tests/fixtures" проекта в рабочий каталог
    Когда я читаю настройки из файла "opm-incomplete.cfg"
    Тогда значение настройки "СоздаватьShСкриптЗапуска" равно "false"
    И значение настройки "ИспользоватьПрокси" равно "Истина"
    И значение настройки "ИспользоватьСистемныйПрокси" равно "Истина"
    И значение настройки "НастройкиПрокси.Сервер" равно ""
    И значение настройки "НастройкиПрокси.Порт" равно 0
    И значение настройки "НастройкиПрокси.Пользователь" равно ""
    И значение настройки "НастройкиПрокси.Пароль" равно ""
    И значение настройки "НастройкиПрокси.ИспользоватьАутентификациюОС" равно "false"

Сценарий: Получение значений по умолчанию, если файл настроек отсутствует
    Дано Файл "opm.cfg" не существует
    Когда я читаю настройки из файла "opm.cfg"
    Тогда значение настройки "СоздаватьShСкриптЗапуска" равно "false"
    И значение настройки "ИспользоватьПрокси" равно "false"
    И значение настройки "ИспользоватьСистемныйПрокси" равно "false"
    И значение настройки "НастройкиПрокси.Сервер" равно ""
    И значение настройки "НастройкиПрокси.Порт" равно ""
    И значение настройки "НастройкиПрокси.Пользователь" равно ""
    И значение настройки "НастройкиПрокси.Пароль" равно ""
    И значение настройки "НастройкиПрокси.ИспользоватьАутентификациюОС" равно "false"
