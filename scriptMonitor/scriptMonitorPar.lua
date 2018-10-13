FILE_LOG_NAME = getScriptPath().."\\scriptMonitorLog.txt" -- ИМЯ ЛОГ-ФАЙЛА
PARAMS_FILE_NAME = getScriptPath().."\\scriptMonitor.csv" -- ИМЯ ЛОГ-ФАЙЛА

TradesFile = nil -- Файл истории сделок по инструменту
TradesFilePath = getWorkingFolder().."\\Deals\\"

soundFileName = "c:\\windows\\media\\Alarm03.wav"
showTradeCommands = true

ACCOUNT           = ''        -- Идентификатор счета
--ACCOUNT           = 'NL0011100043'        -- пример Идентификатора счета
CLIENT_CODE = ''

--[[
INTERVALS = {
    ["names"] =             {"H1VSA",      "H1",         "H4",            "D",            "W",            "dEMA64",       "dEMA182",      "D Reg",        "D RSI 29"},
    ["visible"] =           {false,         true,          true,           true,           true,           true,           true,           true,           true}, --признак видимости, если невидима, то просто идет расчет и вывод сигналов
    ["width"] =             {0,             12,            12,             12,             12,             12,             12,             12,             12}, --ширина колонки
    ["values"] =            {INTERVAL_H1,   INTERVAL_H1,   INTERVAL_H4,    INTERVAL_D1,    INTERVAL_W1,    INTERVAL_D1,    INTERVAL_D1,    INTERVAL_D1,    INTERVAL_D1},
    ["initAlgorithms"] =    {initVSA,       initstepNRTR,  initstepNRTR,   initstepNRTR,   initstepNRTR,   initEMA,        noSignal,       initReg,        initRSI},   --функции инициализации алгоритма
    ["algorithms"] =        {VSA,           stepNRTR,      stepNRTR,       stepNRTR,       stepNRTR,       allEMA,         noSignal,       Reg,            RSI},                                --функции алгоритма, определены в подключаемых файлах
    ["signalAlgorithms"] =  {signalVSA,     up_downTest,   up_downTest,    up_downTest,    up_downTest,    signalAllEMA,   noSignal,       signalReg,      signalRSI},                                --функции алгоритма, определены в подключаемых файлах
    ["settings"] =          {VSASettings,   NRTRSettings,  NRTRSettings,   NRTRSettings,   NRTRSettings,   allEMASettings, {},             RegSettings,    RSISettings},   --настройки алгоритмов, параметры функции алгоритма
    ["recalculatePeriod"] = {0,             0,             0,              60,             60,             60,             60,             60,             0}   --настройки пересчета алгоритмов в минутах. для интервалов день и более - можно пересчитать данные, чтобы выводит сигналф внутри дня. 0 - не считать
}


INTERVALS = {
    ["names"] =             {"H1VSA",         "M15",          "D",            "W",            "dEMA182",      "dReg",        "Trend",        "dRSI29"},
    ["visible"] =           {false,           true,           true,           true,           true,           true,          true,           true}, --признак видимости, если невидима, то просто идет расчет и вывод сигналов
    ["width"] =             {0,               12,             12,             12,             12,             12,            12,             12}, --ширина колонки
    ["values"] =            {INTERVAL_H1,     INTERVAL_M15,   INTERVAL_D1,    INTERVAL_W1,    INTERVAL_D1,    INTERVAL_D1,   INTERVAL_D1,    INTERVAL_D1},
    ["initAlgorithms"] =    {initVSA,         initRangeBar,   initstepNRTR,   initstepNRTR,   initEMA,        initReg,       nil,            initRSI},   --функции инициализации алгоритма
    ["algorithms"] =        {VSA,             rangeBar,       stepNRTR,       stepNRTR,       EMA,            Reg,           nil,            RSI},                                --функции алгоритма, определены в подключаемых файлах
    ["signalAlgorithms"] =  {signalVSA,       rangeTest,      NRTRTest,       NRTRTest,       up_downTest,    signalReg,     nil,            signalRSI},                                --функции алгоритма, определены в подключаемых файлах
    ["settings"] =          {VSASettings,     rangeSettings,  NRTRSettings,   NRTRSettings,   EMA182Settings, RegSettings,   {},             RSISettings},   --настройки алгоритмов, параметры функции алгоритма
    ["recalculatePeriod"] = {0,               60,             60,             60,             60,             60,            0,              0}   --настройки пересчета алгоритмов в минутах. для интервалов день и более - можно пересчитать данные, чтобы выводит сигналф внутри дня. 0 - не считать
}
]]--

INTERVALS = {
    ["names"] =             {"H1VSA",         "H4",           "D",            "dReg",        "Trend",      "dRSI29"     },
    ["visible"] =           {false,           true,           true,           true,          true,         true         }, --признак видимости, если невидима, то просто идет расчет и вывод сигналов
    ["width"] =             {0,               12,             12,             12,            12,           12           }, --ширина колонки
    ["values"] =            {INTERVAL_H1,     INTERVAL_H4,    INTERVAL_D1,    INTERVAL_D1,   INTERVAL_D1,  INTERVAL_D1  },
    ["initAlgorithms"] =    {initVSA,         initRangeBar,   initRangeBar,   initReg,       nil,          initRSI      },   --функции инициализации алгоритма
    ["algorithms"] =        {VSA,             rangeBar,       rangeBar,       Reg,           nil,          RSI          },                                --функции алгоритма, определены в подключаемых файлах
    ["signalAlgorithms"] =  {signalVSA,       rangeTest,      rangeTest,      signalReg,     nil,          signalRSI    },                                --функции алгоритма, определены в подключаемых файлах
    ["settings"] =          {VSASettings,     rangeSettings,  rangeSettings,  RegSettings,   {},           RSISettings  },   --настройки алгоритмов, параметры функции алгоритма
    ["recalculatePeriod"] = {0,               60,             60,             60,            0,            0            }   --настройки пересчета алгоритмов в минутах. для интервалов день и более - можно пересчитать данные, чтобы выводит сигналф внутри дня. 0 - не считать
}

realtimeAlgorithms = {
    ["initAlgorithms"] =    {initVolume},   --функции инициализации алгоритма
    ["functions"] =         {Volume},
    ["recalculatePeriod"] = {60}
}
