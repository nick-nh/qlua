Сохранение данных баров в файл.

Данный скрипт позволяет организовать хранение данных баров, а также данных рассчитанных алгоритмов.

Для корректной работы необходимо обеспечить доступность библиотек:

local log   = require("log") [библиотеки логирования](https://github.com/nick-nh/qlua/tree/master/logging)

local maLib = require("maLib") [библиотеки maLib](https://github.com/nick-nh/qlua/tree/master/maLib.lua)

Список инструментов хранится в файле sec_list.txt

Данный файл организован по структуре как таблица Lua.

Пример:

    return {

        [1] = {
            sec_code        = "SRZ1",
            class_code      = "SPBFUT",
            interval        = 1,
            algo            = {
                [1] = {
                    method          = "EMA",
                    period          = 14,
                    data_type       = "Close"
                },
                [2] = {
                    method          = "MACD",
                    ma_method       = "EMA",
                    short_period    = 12,
                    long_period     = 26,
                    signal_method   = "SMA",
                    signal_period   = 9,
                    percent         = "ON",
                    data_type       = "Close"
                }
            }
        },
        [2] = {
            sec_code        = "SRZ1",
            class_code      = "SPBFUT",
            interval        = 3,
            algo            = {
                [1] = {
                    method          = "MACD",
                    ma_method       = "EMA",
                    short_period    = 12,
                    long_period     = 26,
                    signal_method   = "SMA",
                    signal_period   = 9,
                    percent         = "ON",
                    data_type       = "Close"
                }
            }
        },
        [3] = {
            sec_code        = "RIZ1",
            class_code      = "SPBFUT",
            interval        = 3,
            algo            = {
                [1] = {
                    method          = "MACD",
                    ma_method       = "EMA",
                    short_period    = 12,
                    long_period     = 26,
                    signal_method   = "SMA",
                    signal_period   = 9,
                    percent         = "ON",
                    data_type       = "Close"
                }
            }
        }

    }

Файл содержит основную таблицу(список):

return {
}

Далее в нее добавляются записи по индексам с разделением запятыми:

return {

    [1] = {

            sec_code        = "SRZ1",
            class_code      = "SPBFUT",
            interval        = 1,
    },
    [2] = {

            sec_code        = "SRZ1",
            class_code      = "SPBFUT",
            interval        = 3,
    }
}

Если требуется организовать выгрузку значений алгоритма, то необходимо добавить записи в вложенный список algo:

    [1] = {
            sec_code        = "SRZ1",
            class_code      = "SPBFUT",
            interval        = 1,
            algo            = {
                [1] = {
                    method          = "EMA",
                    period          = 14,
                    data_type       = "Close"
                },
                [2] = {
                    method          = "MACD",
                    ma_method       = "EMA",
                    short_period    = 12,
                    long_period     = 26,
                    signal_method   = "SMA",
                    signal_period   = 9,
                    percent         = "ON",
                    data_type       = "Close"
                }
            }
    }

Запись о расчете алгоритма содержит поля необходимые для вызова метода из библиотеки maLib.

Для примера, расчет EMA требует:

    method          = "EMA",
    period          = 14,
    data_type       = "Close"

А для расчета MACD:

    method          = "MACD",
    ma_method       = "EMA",
    short_period    = 12,
    long_period     = 26,
    signal_method   = "SMA",
    signal_period   = 9,
    percent         = "ON",
    data_type       = "Close"

Список параметров видно из метода maLib. Для примера MACD:

    --Moving Average Convergence/Divergence ("MACD")
    local function F_MACD(settings, ds)

        settings            = (settings or {})

        local ma_method     = (settings.ma_method or "EMA")
        local short_period  = (settings.short_period or 12)
        local long_period   = (settings.long_period or 26)
        local signal_method = (settings.signal_method or "SMA")
        local signal_period = (settings.signal_period or 9)
        local percent       = (settings.percent or 'on')
        local data_type     = (settings.data_type or "Close")
        local round         = (settings.round or "OFF")
        local scale         = (settings.scale or 0)


При старте скрипт формирует файлы для хранения данных. Наименование файла формируется из кода, класса инструмента и тайм-фрейма. Также, если задан расчет алгоритмов, добавляются их имена. Для примера

    SR_SPBFUT_M3.csv
    SR_SPBFUT_M3_MACD1.csv
    SR_SPBFUT_M1_EMA1_MACD2.csv

Имя кода фьючерсного контракта содержит только символы инструмента. Т.о. при переходе на новый контракт запись будет осуществляться в тот же файл (склейка данных).

Скрипт позволяет сохранять данные как онлайн, так и только историю. Если выбран режим сохранения данных онлайн, то сначала записываются все данные истории, что прошли с момента предыдущего запуска (при старте происходит поиск времени последнего уже записанного бара), а далее скрипт переходит в режим ожидания. При получения нового бара осуществляется запись в файл. Т.о. можно организовать непрерывную запись данных.

Переключение режима производится через параметр:

    --Сохранять только историю.
    -- 0 - выключено. В этом режиме скрипт в фоне контролирует получение новых баров и сохраняет их в файл.
    ONLY_HISTORY                  = 1

Изменять параметры можно через файл barsSaver_params.ini или, если такового нет, прямо в коде скрипта.

Файлы сохраняются в текстовый файл с расширением csv с разделителем ";". Такой файл можно открыть в Excel, подключить к базе данных.

Числовые значения можно приводить к формату принятому в lua, когда разделитель дробной части - это точка, так и через запятую, как это принято в Excel.

Переключение режима производится через параметр:

    --Разделитель дробной числа:
    -- 0 - разделитель точка
    -- 1 - разделитель запятая
    EXCEL_NUM                     = 0