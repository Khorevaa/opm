﻿/////////////////////////////////////////////////////////////////////////
//
// OneScript Package Manager
// Модуль сборки архива пакета
//
/////////////////////////////////////////////////////////////////////////

#Использовать fs
#Использовать logos
#Использовать tempfiles

Перем Лог;
Перем РабочийКаталог;
Перем ВремКаталогСборки;
Перем ОбработчикСобытий;
Перем СобиратьВместеСЗависимостями;
Перем УстановленныйЗависимости;
//////////////////////////////////////////////////////////
// Сборка пакета

Процедура СобиратьВместеСЗависимостями(Знач ПСобиратьВместеСЗависимостями) Экспорт
	СобиратьВместеСЗависимостями = ПСобиратьВместеСЗависимостями;
КонецПроцедуры

Процедура СобратьПакет(Знач КаталогИсходников, Знач ФайлМанифеста, Знач ВыходнойКаталог) Экспорт

	РабочийКаталог = КаталогИсходников;
	ТекущийРабКаталог = ТекущийКаталог();

	Попытка

		Если ВыходнойКаталог = Неопределено Тогда
			ВыходнойКаталог = ТекущийКаталог();
		Иначе
			// получим полное имя, если вдруг передан относительный путь
			ФайлВыхКаталога = Новый Файл(ВыходнойКаталог);
			ВыходнойКаталог = ФайлВыхКаталога.ПолноеИмя;
		КонецЕсли;

		Лог.Информация("Начинаю сборку в каталоге " + РабочийКаталог);
		УстановитьТекущийКаталог(РабочийКаталог);
		УточнитьФайлМанифеста(ФайлМанифеста);
		Манифест = ПрочитатьМанифест(ФайлМанифеста);
		ВызватьСобытиеПередСборкой();
		СобратьПакетВКаталогеСборки(Манифест, ВыходнойКаталог);
		УстановитьТекущийКаталог(ТекущийРабКаталог);
		Лог.Информация("Сборка пакета завершена");

	Исключение
		УстановитьТекущийКаталог(ТекущийРабКаталог);
		ВременныеФайлы.Удалить();
		ВызватьИсключение;

	КонецПопытки;

	ВременныеФайлы.Удалить();

КонецПроцедуры

Процедура УточнитьФайлМанифеста(ФайлМанифеста)

	Если ФайлМанифеста = Неопределено Тогда

		ФайлОбъект = Новый Файл(КонстантыOpm.ИмяФайлаСпецификацииПакета);
		Если ФайлОбъект.Существует() и ФайлОбъект.ЭтоФайл() Тогда
			Лог.Информация("Найден файл манифеста");
			ФайлМанифеста = ФайлОбъект.ПолноеИмя;
		Иначе
			ВызватьИсключение "Не определен манифест пакета";
		КонецЕсли;
	Иначе
		Лог.Информация("Использую файл манифеста " + ФайлМанифеста);
	КонецЕсли;

КонецПроцедуры

Функция ПрочитатьМанифест(Знач ФайлМанифеста)

	ОписаниеПакета = Новый ОписаниеПакета();
	Лог.Информация("Загружаю описание пакета...");
	ВнешнийКонтекст = Новый Структура("Описание", ОписаниеПакета);
	ОбработчикСобытий = ЗагрузитьСценарий(ФайлМанифеста, ВнешнийКонтекст);
	Лог.Информация("Описание пакета прочитано");

	Возврат ОписаниеПакета;

КонецФункции

Процедура СобратьПакетВКаталогеСборки(Знач Манифест, Знач ВыходнойКаталог)

	ВремКаталогСборки = ВременныеФайлы.СоздатьКаталог();

	СвойстваПакета = Манифест.Свойства();

	ИмяФайлаПакета = СтрШаблон("%1-%2.ospx", СвойстваПакета.Имя, СвойстваПакета.Версия);
	ФайлАрхива = Новый Файл(ОбъединитьПути(ВыходнойКаталог, ИмяФайлаПакета));
	Архив = Новый ЗаписьZIPФайла(ФайлАрхива.ПолноеИмя);

	ПодготовитьЗависимостиПакета();
	ДобавитьОписаниеМетаданныхПакета(Архив, Манифест);
	ДобавитьФайлыПакета(Архив, Манифест);

	Архив.Записать();

	ВызватьСобытиеПослеСборки(ФайлАрхива.ПолноеИмя);

	ОчиститьЗависимостиПакета();

	Лог.Информация("Создана сборка %1", ФайлАрхива.ПолноеИмя);

КонецПроцедуры

Процедура ПодготовитьЗависимостиПакета()

	Если НЕ СобиратьВместеСЗависимостями Тогда
		Возврат;
	КонецЕсли;
	
	КаталогУстановкиЗависимостей = ОбъединитьПути(РабочийКаталог, КонстантыOpm.ЛокальныйКаталогУстановкиПакетов);
	ФС.ОбеспечитьКаталог(КаталогУстановкиЗависимостей);

	УстановленныйЗависимости = Новый Соответствие();

	МассивФайлов = НайтиФайлы(КаталогУстановкиЗависимостей, ПолучитьМаскуВсеФайлы(), Ложь);

	Для каждого Файл Из МассивФайлов Цикл
		УстановленныйЗависимости.Вставить(Файл.ПолноеИмя);
	КонецЦикла;

	ФайлМанифеста = ОбъединитьПути(РабочийКаталог, КонстантыOpm.ИмяФайлаСпецификацииПакета);
	ОписаниеПакета = ПрочитатьМанифест(ФайлМанифеста);
	
	УстановкаПакета = Новый МенеджерУстановкиПакетов(РежимУстановкиПакетов.Локально, КаталогУстановкиЗависимостей);
	УстановкаПакета.РазрешитьЗависимостиПакета(ОписаниеПакета);
	
КонецПроцедуры

Процедура ПроверитьУстановленнуюЗависимость(КаталогПакета)
	
	Каталог

КонецПроцедуры

Процедура ОчиститьЗависимостиПакета()
	
	Если НЕ СобиратьВместеСЗависимостями Тогда
		Возврат;
	КонецЕсли;
	
	КаталогУстановкиЗависимостей = ОбъединитьПути(РабочийКаталог, КонстантыOpm.ЛокальныйКаталогУстановкиПакетов);

	ФайлыЗависимостей = НайтиФайлы(КаталогУстановкиЗависимостей, ПолучитьМаскуВсеФайлы(), Ложь);

	Для каждого Файл Из ФайлыЗависимостей Цикл
		
		Если ИгнорируемыеФайлы.Получить(Файл.ПолноеИмя) = Неопределено Тогда
			УдалитьФайлы(Файл.ПолноеИмя);
		КонецЕсли;

	КонецЦикла;

КонецПроцедуры

Процедура ДобавитьОписаниеМетаданныхПакета(Знач Архив, Знач Манифест)

	ПутьМанифеста = ОбъединитьПути(ВремКаталогСборки, "opm-metadata.xml");
	Запись = Новый ЗаписьXML;
	Запись.ОткрытьФайл(ПутьМанифеста);

	Сериализатор = Новый СериализацияМетаданныхПакета();
	Сериализатор.ЗаписатьМетаданныеВXML(Запись, Манифест);

	Запись.Закрыть();

	Архив.Добавить(ПутьМанифеста);
	Лог.Информация("Записаны метаданные пакета");

КонецПроцедуры

Процедура ДобавитьОписаниеБиблиотеки(Знач Архив, Знач Манифест)

	Модули = Манифест.ВсеМодулиПакета();
	Если Модули.Количество() = 0 Тогда
		Возврат;
	КонецЕсли;

	Лог.Информация("Формирую определения модулей пакета (lib.config)");

	ПутьКонфигурацииПакета = ОбъединитьПути(ВремКаталогСборки, "lib.config");
	Запись = Новый ЗаписьXML;
	Запись.ОткрытьФайл(ПутьКонфигурацииПакета);
	Запись.ЗаписатьОбъявлениеXML();
	Запись.ЗаписатьНачалоЭлемента("package-def");
	Запись.ЗаписатьСоответствиеПространстваИмен("", "http://oscript.io/schemas/lib-config/1.0");

	Для Каждого ОписаниеМодуля Из Модули Цикл
		Если ОписаниеМодуля.Тип = Манифест.ТипыМодулей.Класс Тогда
			Запись.ЗаписатьНачалоЭлемента("class");
		Иначе
			Запись.ЗаписатьНачалоЭлемента("module");
		КонецЕсли;

		ФайлМодуля = Новый Файл(ОписаниеМодуля.Файл);
		Если Не ФайлМодуля.Существует() Тогда
			Лог.Предупреждение("Файл модуля " + ОписаниеМодуля.Файл + " не обнаружен.");
		КонецЕсли;

		Запись.ЗаписатьАтрибут("name", ОписаниеМодуля.Идентификатор);
		Запись.ЗаписатьАтрибут("file", ОписаниеМодуля.Файл);
		Запись.ЗаписатьКонецЭлемента();

	КонецЦикла;

	Запись.ЗаписатьКонецЭлемента();
	Запись.Закрыть();

	Архив.Добавить(ПутьКонфигурацииПакета);
	Лог.Информация("Записаны определения модулей пакета");

КонецПроцедуры

Процедура ДобавитьФайлыПакета(Знач Архив, Знач Манифест)

	ВключаемыеФайлы = Манифест.ВключаемыеФайлы();

	Если СобиратьВместеСЗависимостями Тогда
	
		Если ВключаемыеФайлы.Найти(КонстантыOpm.ЛокальныйКаталогУстановкиПакетов) = Неопределено Тогда			
			ВключаемыеФайлы.Добавить(КонстантыOpm.ЛокальныйКаталогУстановкиПакетов);
		КонецЕсли;
	
	КонецЕсли;

	Если ВключаемыеФайлы.Количество() = 0 Тогда
		Лог.Информация("Не определены включаемые файлы");
		Возврат;
	КонецЕсли;

	ПутьАрхиваЦелевойСистемы = ОбъединитьПути(ВремКаталогСборки, "content.zip");
	АрхивЦелевойСистемы = Новый ЗаписьZIPФайла(ПутьАрхиваЦелевойСистемы);

	ДобавитьОписаниеБиблиотеки(АрхивЦелевойСистемы, Манифест);

	Для Каждого ВключаемыйФайл Из ВключаемыеФайлы Цикл
		Лог.Информация("Добавляем файл: " + ВключаемыйФайл);
		ПолныйПуть = Новый Файл(ВключаемыйФайл).ПолноеИмя;
		АрхивЦелевойСистемы.Добавить(ПолныйПуть, РежимСохраненияПутейZIP.СохранятьОтносительныеПути, РежимОбработкиПодкаталоговZIP.ОбрабатыватьРекурсивно);
	КонецЦикла;

	ВызватьСобытиеПриСборке(АрхивЦелевойСистемы);

	АрхивЦелевойСистемы.Записать();

	Архив.Добавить(ПутьАрхиваЦелевойСистемы, РежимСохраненияПутейZIP.НеСохранятьПути, РежимОбработкиПодкаталоговZIP.ОбрабатыватьРекурсивно);

КонецПроцедуры

Процедура ВызватьСобытиеПередСборкой()
	Рефлектор = Новый Рефлектор;
	Если Рефлектор.МетодСуществует(ОбработчикСобытий, "ПередСборкой") Тогда
		Лог.Отладка("Вызываю событие ПередСборкой");
		ОбработчикСобытий.ПередСборкой(РабочийКаталог);
	КонецЕсли;
КонецПроцедуры

Процедура ВызватьСобытиеПриСборке(АрхивПакета)
	Рефлектор = Новый Рефлектор;
	Если Рефлектор.МетодСуществует(ОбработчикСобытий, "ПриСборке") Тогда
		Лог.Отладка("Вызываю событие ПриСборке");
		ОбработчикСобытий.ПриСборке(РабочийКаталог, АрхивПакета);
	КонецЕсли;
КонецПроцедуры

Процедура ВызватьСобытиеПослеСборки(ПутьКФайлуПакета)
	Рефлектор = Новый Рефлектор;
	Если Рефлектор.МетодСуществует(ОбработчикСобытий, "ПослеСборки") Тогда
		Лог.Отладка("Вызываю событие ПослеСборки");
		ОбработчикСобытий.ПослеСборки(РабочийКаталог, ПутьКФайлуПакета);
	КонецЕсли;
КонецПроцедуры

////////////////////////////////////////////////////////
// Подготовка пустого каталога под новый пакет

Процедура ПодготовитьКаталогПроекта(Знач ВыходнойКаталог) Экспорт

	Если ВыходнойКаталог = Неопределено Тогда
		ВыходнойКаталог = ТекущийКаталог();
	КонецЕсли;

	ВыходнойКаталог = Новый Файл(ВыходнойКаталог);

	ИмяПакета = ВыходнойКаталог.Имя;
	ПутьВыходногоКаталога = ВыходнойКаталог.ПолноеИмя;

	Если Не ВыходнойКаталог.Существует() Тогда
		Лог.Информация("Создаю каталог " + ИмяПакета);
		СоздатьКаталог(ПутьВыходногоКаталога);
	Иначе
		Содержимое = НайтиФайлы(ПутьВыходногоКаталога, ПолучитьМаскуВсеФайлы());
		Если Содержимое.Количество() Тогда
			ВызватьИсключение "Каталог проекта " + ПутьВыходногоКаталога + " уже содержит файлы!";
		КонецЕсли;
	КонецЕсли;

	СоздатьПодкаталог(ПутьВыходногоКаталога, "src");
	СоздатьПодкаталог(ПутьВыходногоКаталога, "tests");
	СоздатьПодкаталог(ПутьВыходногоКаталога, "docs");
	СоздатьПодкаталог(ПутьВыходногоКаталога, "tasks");
	СоздатьПодкаталог(ПутьВыходногоКаталога, "features");

	ПодготовитьФайлКомандыТестирования(ВыходнойКаталог);

	ЗаписатьЗаготовкуМанифестаБиблиотеки(ПутьВыходногоКаталога, ИмяПакета);

	Лог.Информация("Готово");

КонецПроцедуры

Процедура СоздатьПодкаталог(Знач База, Знач Имя)
	Лог.Информация("Создаю каталог " + Имя);
	СоздатьКаталог(ОбъединитьПути(База, Имя));
КонецПроцедуры

Процедура ЗаписатьЗаготовкуСкриптаУстановки(ЗаписьТекста)

	Лог.Информация("Создаю процедур установки/удаления");

	ЗаписьТекста.ЗаписатьСтроку("///////////////////////////////////////////////////////////////////");
	ЗаписьТекста.ЗаписатьСтроку("// Процедуры установки пакета с клиентской машины        ");
	ЗаписьТекста.ЗаписатьСтроку("///////////////////////////////////////////////////////////////////
	|
	|");

	ЗаписьТекста.ЗаписатьСтроку("// Вызывается пакетным менеджером перед установкой пакета на клиентскую машину.");
	ЗаписьТекста.ЗаписатьСтроку("// ");
	ЗаписьТекста.ЗаписатьСтроку("// Параметры:");
	ЗаписьТекста.ЗаписатьСтроку("//   КаталогУстановкиПакета - строка. Путь в который пакетный менеджер устанавливает текущий пакет.");
	ЗаписьТекста.ЗаписатьСтроку("//   ЧтениеZipФайла - ЧтениеZipФайла. Архив пакета.");
	ЗаписьТекста.ЗаписатьСтроку("// ");
	ЗаписьТекста.ЗаписатьСтроку("Процедура ПередУстановкой(Знач КаталогУстановкиПакета, Знач ЧтениеZipФайла) Экспорт");
	ЗаписьТекста.ЗаписатьСтроку("	// TODO: Реализуйте спец. логику перед установкой, если требуется");
	ЗаписьТекста.ЗаписатьСтроку("КонецПроцедуры");
	ЗаписьТекста.ЗаписатьСтроку(Символы.ПС);

	ЗаписьТекста.ЗаписатьСтроку("// Вызывается пакетным менеджером после распаковки пакета на клиентскую машину.");
	ЗаписьТекста.ЗаписатьСтроку("// ");
	ЗаписьТекста.ЗаписатьСтроку("// Параметры:");
	ЗаписьТекста.ЗаписатьСтроку("//   КаталогУстановкиПакета - строка. Путь в который пакетный менеджер устанавливает текущий пакет.");
	ЗаписьТекста.ЗаписатьСтроку("//   СтандартнаяОбработка - Булево. Возможность отменить стандартную обработку.");
	ЗаписьТекста.ЗаписатьСтроку("// ");
	ЗаписьТекста.ЗаписатьСтроку("Процедура ПриУстановке(Знач КаталогУстановкиПакета, СтандартнаяОбработка) Экспорт");
	ЗаписьТекста.ЗаписатьСтроку("	// TODO: Реализуйте спец. логику установки, если требуется");
	ЗаписьТекста.ЗаписатьСтроку("КонецПроцедуры");
	ЗаписьТекста.ЗаписатьСтроку(Символы.ПС);

КонецПроцедуры

Процедура ЗаписатьЗаготовкуСкриптаСборки(Знач ЗаписьТекста)

	Лог.Информация("Создаю заготовку процедур сборки");

	ЗаписьТекста.ЗаписатьСтроку("///////////////////////////////////////////////////////////////////");
	ЗаписьТекста.ЗаписатьСтроку("// Процедуры сборки пакета                                          ");
	ЗаписьТекста.ЗаписатьСтроку("///////////////////////////////////////////////////////////////////
	|
	|");

	ЗаписьТекста.ЗаписатьСтроку("// Вызывается пакетным менеджером перед началом сборки пакета.");
	ЗаписьТекста.ЗаписатьСтроку("// ");
	ЗаписьТекста.ЗаписатьСтроку("// Параметры:");
	ЗаписьТекста.ЗаписатьСтроку("//   РабочийКаталог - Строка - Текущий рабочий каталог с исходниками пакета.");
	ЗаписьТекста.ЗаписатьСтроку("// ");
	ЗаписьТекста.ЗаписатьСтроку("Процедура ПередСборкой(Знач РабочийКаталог) Экспорт");
	ЗаписьТекста.ЗаписатьСтроку("	// TODO: Реализуйте спец. логику сборки, если требуется");
	ЗаписьТекста.ЗаписатьСтроку("КонецПроцедуры");
	ЗаписьТекста.ЗаписатьСтроку(Символы.ПС);

	ЗаписьТекста.ЗаписатьСтроку("// Вызывается пакетным менеджером после помещения файлов в пакет.");
	ЗаписьТекста.ЗаписатьСтроку("// ");
	ЗаписьТекста.ЗаписатьСтроку("// Параметры:");
	ЗаписьТекста.ЗаписатьСтроку("//   РабочийКаталог - Строка - Текущий рабочий каталог с исходниками пакета.");
	ЗаписьТекста.ЗаписатьСтроку("//   АрхивПакета - ЗаписьZIPФайла - ZIP-архив с содержимым пакета (включаемые файлы).");
	ЗаписьТекста.ЗаписатьСтроку("// ");
	ЗаписьТекста.ЗаписатьСтроку("Процедура ПриСборке(Знач РабочийКаталог, Знач АрхивПакета) Экспорт");
	ЗаписьТекста.ЗаписатьСтроку("	// TODO: Реализуйте спец. логику сборки, если требуется");
	ЗаписьТекста.ЗаписатьСтроку("	// АрхивПакета.Добавить(ПолныйПутьНужногоФайла,
	|	//	РежимСохраненияПутейZIP.СохранятьОтносительныеПути,
	|	//	РежимОбработкиПодкаталоговZIP.ОбрабатыватьРекурсивно);");
	ЗаписьТекста.ЗаписатьСтроку("КонецПроцедуры");
	ЗаписьТекста.ЗаписатьСтроку(Символы.ПС);

	ЗаписьТекста.ЗаписатьСтроку("// Вызывается пакетным менеджером после сборки пакета.");
	ЗаписьТекста.ЗаписатьСтроку("// ");
	ЗаписьТекста.ЗаписатьСтроку("// Параметры:");
	ЗаписьТекста.ЗаписатьСтроку("//   РабочийКаталог - Строка - Текущий рабочий каталог с исходниками пакета.");
	ЗаписьТекста.ЗаписатьСтроку("//   ПутьКФайлуПакета - Строка - Полный путь к собранному файлу пакета.");
	ЗаписьТекста.ЗаписатьСтроку("// ");
	ЗаписьТекста.ЗаписатьСтроку("Процедура ПослеСборки(Знач РабочийКаталог, Знач ПутьКФайлуПакета) Экспорт");
	ЗаписьТекста.ЗаписатьСтроку("	// TODO: Реализуйте спец. логику сборки, если требуется");
	ЗаписьТекста.ЗаписатьСтроку("КонецПроцедуры");
	ЗаписьТекста.ЗаписатьСтроку(Символы.ПС);

КонецПроцедуры

Процедура ЗаписатьЗаготовкуМанифестаБиблиотеки(Знач Каталог, Знач ИмяПакета)

	Лог.Информация("Создаю заготовку описания пакета");

	ЗаписьТекста = Новый ЗаписьТекста(ОбъединитьПути(Каталог, КонстантыOpm.ИмяФайлаСпецификацииПакета));

	ЗаписьТекста.ЗаписатьСтроку("////////////////////////////////////////////////////////////");
	ЗаписьТекста.ЗаписатьСтроку("// Описание пакета для сборки и установки");
	ЗаписьТекста.ЗаписатьСтроку("// Полную документацию см. на hub.oscript.io/packaging");
	ЗаписьТекста.ЗаписатьСтроку("//");
	ЗаписьТекста.ЗаписатьСтроку("");

	Консоль = Новый Консоль;
	ДобавлятьПроцедурыПереопределения = Неопределено;
	Лог.Информация("Добавить в описание пакета процедуры переопределения сборки и установки?");
	Пока Истина Цикл
		Лог.Информация("(y/n)");
		Значение = Консоль.ПрочитатьСтроку();
		Если ВРег(Значение) = "Y" Тогда
			ДобавлятьПроцедурыПереопределения = Истина;
			Прервать;
		ИначеЕсли ВРег(Значение) = "N" Тогда
			ДобавлятьПроцедурыПереопределения = Ложь;
			Прервать;
		КонецЕсли;
	КонецЦикла;

	Если ДобавлятьПроцедурыПереопределения Тогда
		ЗаписатьЗаготовкуСкриптаУстановки(ЗаписьТекста);
		ЗаписатьЗаготовкуСкриптаСборки(ЗаписьТекста);
	КонецЕсли;

	ЗаписьТекста.ЗаписатьСтроку("
	|Описание.Имя(""" + ИмяПакета + """)
	|        .Версия(""1.0.0"")
	|        .Автор("""")
	|        .АдресАвтора(""author@somemail.com"")
	|        .Описание(""Это очень хороший и нужный пакет программ"")
	|        .ВерсияСреды(""1.0.21"")
	|        .ВключитьФайл(""src"")
	|        .ВключитьФайл(""doc"")
	|        .ВключитьФайл(""tasks"")
	|        //.ВключитьФайл(""tests"")
	|        //.ВключитьФайл(""features"")
	|			");

	Если ДобавлятьПроцедурыПереопределения Тогда
		ЗаписьТекста.ЗаписатьСтроку(
		"        .ВключитьФайл(""" + КонстантыOpm.ИмяФайлаСпецификацииПакета + """)");
	КонецЕсли;

	ЗаписьТекста.ЗаписатьСтроку(
	"        //.ЗависитОт(""package1"", "">=2.0"")
	|        //.ЗависитОт(""package2"", "">=1.1"", ""<2.0"")
	|        //.ОпределяетКласс(""УправлениеВселенной"", ""src/universe-mngr.os"")
	|        //.ОпределяетМодуль(""ПолезныеФункции"", ""src/tools.os"")
	|        ;");

	ЗаписьТекста.Закрыть();

КонецПроцедуры

Процедура ПодготовитьФайлКомандыТестирования(Знач ВыходнойКаталог)
	ИсходныйПутьЗапускателяТестов = ОбъединитьПути(КаталогПроекта(), "tasks", "test.os");
	КонечныйПутьЗапускателяТестов = ОбъединитьПути(ВыходнойКаталог.ПолноеИмя, "tasks", "test.os");
	КопироватьФайл(ИсходныйПутьЗапускателяТестов, КонечныйПутьЗапускателяТестов);
КонецПроцедуры

Функция КаталогПроекта()
	Рез = ОбъединитьПути(ТекущийСценарий().Каталог, "..", "..", "..");
	Лог.Информация("Рез %1", Рез);
	Возврат ФС.ПолныйПуть(Рез);
КонецФункции

Лог = Логирование.ПолучитьЛог(КонстантыOpm.ИмяЛога);
// Лог.УстановитьУровень(УровниЛога.Отладка);
СобиратьВместеСЗависимостями = Ложь;
