Простой тестер. Алгоритмы тестирования подключаются через файлы (модули)

dofile (getScriptPath().."\\testNRTR.lua") --stepNRTR алгоритм
dofile (getScriptPath().."\\testTHV_HA.lua") --THV алгоритм
dofile (getScriptPath().."\\testEMA.lua") --EMA алгоритм
dofile (getScriptPath().."\\testSAR.lua") --SAR алгоритм
dofile (getScriptPath().."\\testReg.lua") --Reg алгоритм

Список алгоритмов в таблице

    ALGORITHMS = {
        ["names"] =                 {"NRTR"                 , "2EMA"        , "THV"       , "Sar"         , "Reg"       , "RangeNRTR"          },
        ["initParams"] =            {initStepNRTRParams     , initEMA       , initTHV     , initSAR       , initReg     , initRangeNRTRParams        },
        ["initAlgorithms"] =        {initStepNRTR           , initEMA       , initTHV     , initSAR       , initReg     , initRangeNRTR        },
        ["itetareAlgorithms"] =     {iterateNRTR            , iterateEMA    , iterateTHV  , iterateSAR    , iterateReg  , iterateNRTR     },
        ["calcAlgorithms"] =        {stepNRTR               , allEMA        , THV         , SAR           , Reg         , RangeNRTR            },
        ["tradeAlgorithms"] =       {simpleTrade            , ema2Trade     , simpleTrade , simpleTrade   , simpleTrade , simpleTrade       },
        ["settings"] =              {NRTRSettings           , EMASettings   , THVSettings , SARSettings   , RegSettings , NRTRSettings    },
    }
    
Файл инструментов и алгоритмов для них    
PARAMS_FILE_NAME = getScriptPath().."\\testMonitor.csv" -- ИМЯ ЛОГ-ФАЙЛА

В файле определен список инструментов, открывать лонг и шорт, иднентификатор графика куда выводить метки и данные,
размер баров для тестирования от текущей, интервал тестирования.

<a href="http://funkyimg.com/view/2KKnm" target="_blank"><img src="http://funkyimg.com/i/2KKnm.png" alt="Free Image Hosting at FunkyIMG.com" border="0"></a>

Чтобы выводить данные на график надо задать ChartId.

<a href="http://funkyimg.com/view/2KKni" target="_blank"><img src="http://funkyimg.com/i/2KKni.png" alt="Free Image Hosting at FunkyIMG.com" border="0"></a>

Для вывода линий алгоритма и рассчитанной Эквити надо добавить на график два индикатора algoResults и equityTester.
Они получают данные через библиотеку StaticVar {key,value}, поэтому ее надо не забыть положить в папку установки Квик.

В этих индикаторах надо не забыть указать индентификатор графика, чтобы они получили данные своего инструмента.

<a href="http://funkyimg.com/view/2KKnh" target="_blank"><img src="http://funkyimg.com/i/2KKnh.png" alt="Free Image Hosting at FunkyIMG.com" border="0"></a>

После запуска скрипта откроется окно со списоком инструментов. Можно задать размер и интервал прямо из этого окна.
Для этого надо дважы щелкнуть по колонке с параметром. Для запуска теста надо дважды щелкнуть по колонкам "Инструмент" или "Алгоритм".

<a href="http://funkyimg.com/view/2KKnk" target="_blank"><img src="http://funkyimg.com/i/2KKnk.png" alt="Free Image Hosting at FunkyIMG.com" border="0"></a>

После того как произойдет расчет откроется окно результатов, отсортированное по профиту. Лучшие данные будут выведены на график.
Можно отсортировать данные по колонкам параметров, дважды щелкнув по данным в этой колонке.

<a href="http://funkyimg.com/view/2KKnj" target="_blank"><img src="http://funkyimg.com/i/2KKnj.png" alt="Free Image Hosting at FunkyIMG.com" border="0"></a>

Чтобы вывести на график данные из конкретной строки надо дважды щелкнуть по "Инструмент" или "Алгоритм".
Тем самым можно выводить на график данные одного алгоритма но с разными параметрами. Выводятся метки и данные линий, эквити (если добавлены индикаторы). Если окно результатов закрытили, то его можно повторно открыть дважды щелкнув по проценту выполнения из основного окна. Также можно открыть окно результатов еще в процессе расчета, для оценки данных.

<a href="http://funkyimg.com/view/2KKng" target="_blank"><img src="http://funkyimg.com/i/2KKng.png" alt="Free Image Hosting at FunkyIMG.com" border="0"></a>
<a href="http://funkyimg.com/view/2KKnf" target="_blank"><img src="http://funkyimg.com/i/2KKnf.png" alt="Free Image Hosting at FunkyIMG.com" border="0"></a>

Установка тестера: проcто добавить скрипт testet в Квике. Не забыть добавить библиотеку обмена StaticVar в папку Квика. Индикаторы в папку Luaindicators.

В функции simpleTrade заданы времена совершения сделок для срочного рынка. Я для себя определил начало торгов в 10:12, окончания в 18:42. Т.е. первая сделка будет совершана только после 10:12, а после 18:42 позиция будет закрыта. Данные параметры, конечно, можно менять.

    if time >= 1012 then 
        dealTime = true 
    end    
    if time >= 1842 then 
        dealTime = false 
    end
