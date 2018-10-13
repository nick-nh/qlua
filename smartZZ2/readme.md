Индикатор Зиг-Заг, построенный по классическому алгоритму.

Индикатор также позволяет видеть уровни вершин, выводит точки середины волны, также есть некий алгоритм предсказания движения
(вывод целевых зон). Также есть вывод метки с статистикой по последним 5-и волнам, точкам формации XABCD.

<a href="http://funkyimg.com/view/2KKiR" target="_blank"><img src="http://funkyimg.com/i/2KKiR.png" alt="Free Image Hosting at FunkyIMG.com" border="0"></a>

<a href="http://funkyimg.com/view/2M4yp" target="_blank"><img src="http://funkyimg.com/p/2M4yp.png" alt="Free Image Hosting at FunkyIMG.com" border="0"></a>

Основные настройки

	showCalculatedLevels = 0, -- показывать уровни от прошлого движения
	showextraCalculatedLevels = 0, -- показывать расширения уровней от прошлого движения
	regimeOfCalculatedLevels = 2, -- 1- последнее движение, 2 - последний максимальный диапазон
	deepZZForCalculatedLevels = 10, -- глубина поиска последнего максимального диапазона по вершинам. До 20.
	showZZLevels = 0, -- показывать уровни от вершин
	numberOfZZLevels = 10, -- сколько показывать уровней от вершин до 20
	numberOfHistoryZZLevels = 0, -- сколько показывать уровней от вершин для истоических данных
	showCoG = 1, -- показывать центр движения для вил Эндрюса
	numberOfShownCOG = 3, --  глубина показа COG
	showTargetZone = 1, -- показывать целевую зону
	numberOfMovesForTargetZone = 5, --  глубина поиска движений для предсказания
	spreadOfTargetZone = 10, -- диапазон целевой зоны (%)
	showLabel = 1, -- показывать метку паттерна
	showFiboExt = 1, -- показывать расширение фибо волны
	LabelShift = 100, -- сдвиг метки от вершины

Чтобы выводилась метка по паттернам надо задать идентификтор графика.

Целевая зона строится по двум прицпам. Если удалось определить паттерн движения по этим соотношениям
(алгоритм взял из индикатора MT5).

<a href="http://funkyimg.com/view/2KKk1" target="_blank"><img src="http://funkyimg.com/i/2KKk1.png" alt="Free Image Hosting at FunkyIMG.com" border="0"></a>      


Если паттерн не определен, то целевая зона определяется через усреднение (numberOfMovesForTargetZone = 5) прошлых движений.




