--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

	Зиг-Заг
]]

_G.unpack = rawget(table, "unpack") or _G.unpack

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\zz_algo.txt", "w")

local math_max              = math.max
local math_min              = math.min
local math_abs              = math.abs
local os_time               = os.time
-- local os_date               = os.date
local string_format         = string.format
local string_upper          = string.upper
local string_match          = string.match
local table_insert          = table.insert
local table_sort            = table.sort
local math_floor            = math.floor
local math_ceil             = math.ceil
local math_tointeger        = math.tointeger
local math_sqrt             = math.sqrt
local math_pow              = function(x, y) return x^y end

local message               = _G['message']
local RGB                   = _G['RGB']
local TYPE_LINE             = _G['TYPE_LINE']
local TYPE_POINT            = _G['TYPE_POINT']
local TYPE_DASH             = _G['TYPE_DASH']
local TYPE_TRIANGLE_UP      = _G['TYPE_TRIANGLE_UP']
local TYPE_TRIANGLE_DOWN    = _G['TYPE_TRIANGLE_DOWN']
local isDark                = _G.isDarkTheme()
local line_color            = isDark and RGB(240, 240, 240) or RGB(0, 0, 0)
local C                     = _G['C']
local H                     = _G['H']
local L                     = _G['L']
local T                     = _G['T']
local V                     = _G['V']
local Size                  = _G['Size']
local SetValue              = _G['SetValue']
local SetRangeValue         = _G['SetRangeValue']
local getDataSourceInfo     = _G['getDataSourceInfo']
local getSecurityInfo       = _G['getSecurityInfo']
local CandleExist           = _G['CandleExist']
local SetLabelParams        = _G['SetLabelParams']
local AddLabel              = _G['AddLabel']
local DelAllLabels          = _G['DelAllLabels']

_G.Settings= {
    Name 		    = "*zz_algo",
    --Для установки значения, необходимо поставить * перед выбранным вариантом.
    --[[Вид расчета отклонения от вершины
    Extr  - от прошлой вершины. Если цена прошла от вершины размер отступа, то это смена тренда.
    Range - в % от прошлой волны. В этом режиме параметр offset_type должен быть равен %. Если цена прошла указанный процент от прошлой волны, то это смена тренда.
    ATR   - для смены тренда цена должна пройти ATR*offset_value
    ]]
    ['Вариант расчета']                                 = 'Extr; *Range; ATR', -- Тип расчета ZZ: Extr; Range; ATR
    --Для установки значения, необходимо поставить * перед выбранным вариантом.
    --[[Тип отсупа от вершины для определения нового тренда
    %     - в процентах
    Steps - в шагах цены
    ]]
    ['Тип отступа']                                     = '*%; Steps',
    ['Размер отступа']                                  = 30, -- Размер отступа от вершины для начала нового тренда. Выражен в зависимости от выбранного вида расчета и типа отступа.
    ['Окно поиска вершины (бар)']                       = 24, --Глубина поиска новой вершины. Если за указанное число баров появился новый экстремум, то он берется в анализ
	['Рассчитывать уровни диапазона']                   = 0, -- показывать уровни от прошлого движения
	['Показывать метки смены направления']              = 1, -- Показывать метки смены направления
	['Показывать расширения уровней']                   = 0, -- показывать расширения уровней от прошлого движения
	['Вариант расчета уровней']                         = 2, -- 1- последнее движение, 2 - последний максимальный диапазон
	['Глубина поиска последнего диапазона по вершинам'] = 10, -- глубина поиска последнего максимального диапазона по вершинам. До 20.
	['Показывать уровни от вершин']                     = 0, -- показывать уровни от вершин
	['Число уровней от вершин']                         = 10, -- сколько показывать уровней от вершин до 20
	['Число исторических уровней от вершин']            = 0, -- сколько показывать уровней от вершин для исторических данных
	['Показывать центр волны']                          = 1, -- показывать центр движения для вил Эндрюса
	['Число центров волны']                             = 3, --  глубина показа COG
	['Показывать целевую зону']                         = 1, -- показывать целевую зону
	['Показывать вилы Эндрюса']                         = 1, -- показывать вилы Эндрюса
	['Сдвиг вершин для вил Эндрюса']                    = 1, -- сдвиг вершин вилы Эндрюса
	['Показывать регрессионный канал']                  = 0, -- показывать регрессию
	['Ширина регрессионного канала']                    = 1, -- ширина канала регрессии (стандартное отклонение)
	['Число волн для целевой зоны по среднему']         = 5, --  глубина поиска движений для предсказания
	['Ширина целевой зоны по среднему %']               = 10, -- диапазон целевой зоны (%)
	['Показывать метку паттерна']                       = 1, -- показывать метку паттерна
	['Показывать расширение фибоначчи']                 = 1, -- показывать расширение фибо волны
	['Отступ метки от вершины']                         = 100, -- сдвиг метки от вершины
	['Идентификатор графика']                           = ''
}

local lines = {
    --1
    {
        Name  = 'ZIGZAG',
        Color = line_color,
        Type  = TYPE_LINE,
        Width = 1
    },
    --2
    {
        Name = "CentreOfGravity",
        Color = RGB(0, 128, 255),
        Type = TYPE_POINT,
        Width = 3
    },
    --3
    {
        Name = "[-2/8]",
        Type =TYPE_LINE,
        Width = 2,
        Color = RGB(255,0, 255)
    },
    --4
    {
        Name = "[-1/8]",
        Type =TYPE_LINE,
        Width = 2,
        Color = RGB(255,191, 191)
    },
    --5
    {
        Name = "[0/8] Окончательное сопротивление",
        Type =TYPE_LINE,
        Width = 2,
        Color = RGB(0,128, 255)
    },
    --6
    {
        Name = "[1/8] Слабый, место для остановки и разворота",
        Type =TYPE_LINE,
        Width = 2,
        Color = RGB(218,188, 18)
    },
    --7
    {
        Name = "[2/8] Вращение, разворот",
        Type =TYPE_LINE,
        Width = 2,
        Color = RGB(255,0, 128)
    },
    --8
    {
        Name = "[3/8] Дно торгового диапазона",
        Type =TYPE_LINE,
        Width = 2,
        Color = RGB(120,220, 235)
    },
    --9
    {
        Name = "[4/8] Главный уровень поддержки/сопротивления",
        Type =TYPE_LINE,
        Width = 2,
        Color = RGB(128,128, 128)--green
    },
    --10
    {
        Name = "[5/8] Верх торгового диапазона",
        Type =TYPE_LINE,
        Width = 2,
        Color = RGB(120,220, 235)
    },
    --11
    {
        Name = "[6/8] Вращение, разворот",
        Type =TYPE_LINE,
        Width = 2,
        Color = RGB(255,0, 128)
    },
    --12
    {
        Name = "[7/8] Слабый, место для остановки и разворота",
        Type =TYPE_LINE,
        Width = 2,
        Color = RGB(218,188, 18)
    },
    --13
    {
        Name = "[8/8] Окончательное сопротивление",
        Type =TYPE_LINE,
        Width = 2,
        Color = RGB(0,128, 255)
    },
    --14
    {
        Name = "[+1/8]",
        Type =TYPE_LINE,
        Width = 2,
        Color = RGB(255,191, 191)
    },
    --15
    {
        Name = "[+2/8]",
        Type =TYPE_LINE,
        Width = 2,
        Color = RGB(255,0, 255)
    },
    --16
    {
        Name = "Target",
        Type =TYPE_LINE,
        Width = 3,
        Color = RGB(89,213, 107)
    },
    --17
    {
        Name = "Target",
        Type =TYPE_LINE,
        Width = 3,
        Color = RGB(89,213, 107)
    },
    --18
    {
        Name = "TargetFibo1",
        Type =TYPE_DASH,
        Width = 1,
        Color = RGB(0,0, 0)
    },
    --19
    {
        Name = "TargetFibo2",
        Type =TYPE_DASH,
        Width = 1,
        Color = RGB(0,0, 0)
    },
    --20
    {
        Name = "TargetFibo3",
        Type =TYPE_DASH,
        Width = 1,
        Color = RGB(0,0, 0)
    },
    --21
    {
        Name = "TargetFibo4",
        Type =TYPE_DASH,
        Width = 1,
        Color = RGB(0,0, 0)
    },
    --22
    {
        Name = "targetE",
        Type =TYPE_LINE,
        Width = 3,
        Color = RGB(89,213, 107)
    },
    --23
    {
        Name = "evolutionE",
        Type =TYPE_LINE,
        Width = 3,
        Color = RGB(0,135,135)
    },
    --24
    {
        Name = "mutationE",
        Type =TYPE_LINE,
        Width = 3,
        Color = RGB(89,107, 213)
    },
    --25
    {
        Name = "zPoint",
        Color = RGB(255, 10, 10),
        Type = TYPE_POINT,
        Width = 3
    },
    --26
    {
        Name = "REG",
        Type = TYPE_DASH,
        Width = 1,
        Color = RGB(64,0, 128)
    },
    --27
    {
        Name = "REG up",
        Type = TYPE_DASH,
        Width = 1,
        Color = RGB(64,0, 128)
    },
    --28
    {
        Name = "REG dw",
        Type = TYPE_DASH,
        Width = 1,
        Color = RGB(64,0, 128)
    },
    --29
    {
        Name = "Andrews up",
        Type = TYPE_DASH,
        Width = 1,
        Color = RGB(0,0, 0)
    },
    --30
    {
        Name = "Andrews mid",
        Type = TYPE_DASH,
        Width = 1,
        Color = RGB(0,0, 0)
    },
    --31
    {
        Name = "Andrews dw",
        Type = TYPE_DASH,
        Width = 1,
        Color = RGB(0,0, 0)
    },
    --32
    {
        Name = "change dir up",
        Type = TYPE_TRIANGLE_UP,
        Width = 2,
        Color = RGB(89,213, 107)
    },
    --33
    {
        Name = "change dir dw",
        Type = TYPE_TRIANGLE_DOWN,
        Width = 2,
        Color = RGB(255, 128, 0)
    }
}


local function add_lines()
	_G.Settings.line = {}
    for i=1,#lines do
        _G.Settings.line[i] = lines[i]
    end
end

add_lines()

local PlotLines     = function(index) return index end
local error_log     = {}
local AddedLabels   = {}
local chart_id      = ''

_G._tostring = tostring

local format_value = function(x)
  if type(x) == "number" and (math_floor(x) == x) then
    return _VERSION == "Lua 5.1" and string_format("%0.16g", x) or _G._tostring(math_tointeger(x) or x)
  end
  return _G._tostring(x)
end

local table_to_string
table_to_string = function(value, show_number_keys)
    local str = ''
    if show_number_keys == nil then show_number_keys = true end

    if (type(value) ~= 'table') then
        if (type(value) == 'string') then
            str = string_format("%q", value)
        else
            str = format_value(value)
        end
    else
        local auxTable = {}
        local max_index = #value
        for key in pairs(value) do
            if value[key] ~= nil then
                if type(key) ~= "table" and type(key) ~= "function" then
                    if (tonumber(key) ~= key) then
                        table_insert(auxTable, key)
                    else
                        table_insert(auxTable, string.rep('0', max_index-format_value(key):len())..format_value(key))
                    end
                end
            end
        end
        table_sort(auxTable)

        str = str..'{'
        local separator = ""
        local entry
        for _, fieldName in ipairs(auxTable) do
            local prefix = fieldName..' = '
            if ((tonumber(fieldName)) and (tonumber(fieldName) > 0)) then
                fieldName = tonumber(fieldName)
                prefix    = (show_number_keys and "["..format_value(tonumber(fieldName)).."] = " or '')
            end
            entry = value[fieldName]
            -- Check the value type
            if type(entry) == "table" and getmetatable(entry) == nil then
                entry = table_to_string(entry)
            elseif type(entry) == "boolean" then
                entry = _G._tostring(entry)
            elseif type(entry) == "number" then
                entry = format_value(entry)
            else
                entry = "\""..format_value(entry).."\""
            end
            entry = prefix..entry
            str = str..separator..entry
            separator = ", "
        end
        str = str..'}'
    end
    return str
end

_G.tostring = function(x)
    if type(x) == "table" and getmetatable(x) == nil then
      return table_to_string(x)
    else
      return format_value(x)
    end
end

local function log_tostring(...)
    local n = select('#', ...)
    if n == 1 then
    return tostring(select(1, ...))
    end
    local t = {}
    for i = 1, n do
    t[#t + 1] = tostring((select(i, ...)))
    end
    return table.concat(t, " ")
end

local function myLog(...)
	if logFile==nil then return end
    logFile:write(tostring(os.date("%c",os_time())).." "..log_tostring(...).."\n");
    logFile:flush();
end

local function rounding(num, round, scale)
    scale = scale or 0
    if not round or string_upper(round)== "OFF" then return num end
    if num and tonumber(scale) then
        local mult = 10^scale
        if num >= 0 then return math_floor(num * mult + 0.5) / mult
        else return math_ceil(num * mult - 0.5) / mult end
    else return num end
end

---@param n number
local function money_value(n)
    n = tostring(n)
    local left,num,right = string_match(n,'^([^%d]*%d)(%d*)(.-)$')
    if not left or not num or not right then return n end
	return left..(num:reverse():gsub('(%d%d%d)','%1 '):reverse())..right
end
-- Алгоритм: проверка размера волн и корректировка по следующим от- |
-- ношениям "Идеальных пропорций" ("Золотое сечение" версия 1):     |
-- (в терминах XABCD точки равны: A = X, B = A, C = B, D = B, E = D)|
--   №    (D-E)/(D-C)   "ЗС версия1" №  (E-D)/(C-D)   "ЗС версия1"  |
--   M1    2             1.618       W1  0.3334        0.3819       |
--   M2    0.5           0.5         W2  0.6667        0.618        |
--   M3    1.5           1.2720      W3  1.5           1.2720       |
--   M4    0.6667	     0.618       W4  0.5           0.5          |
--   M5    1.3334        1.2720      W5  2             1.618        |
--   M6    0.75          0.618       W6  0.25          0.25         |
--   M7    3             3.0000      W7  0.5           0.5          |
--   M8    0.3334        0.3819      W8  2             1.618        |
--   M9    2             1.618       W9  0.3334        0.3819       |
--   M10   0.5           0.5         W10 3             3.0000       |
--   M11   0.25          0.25        W11 0.75          0.618        |
--   M12   2             1.618       W12 1.3334        1.2720       |
--   M13   0.5           0.5         W13 0.6667        0.618        |
--   M14   1.5           1.2720      W14 1.5           1.2720       |
--   M15   0.6667        0.618       W15 0.5           0.5          |
--   M16   0.3334        0.3819      W16 2             1.618        |


local pattern_names =
{
 ERROR     = 2,
 NOPATTERN = 3,
 W15       = 8,
 W16       = 12,
 M8        = 64,
 M4        = 80,
 M3        = 112,
 W9        = 512,
 W13       = 640,
 W14       = 896,
 M13       = 4096,
 M12       = 5120,
 M7        = 7168,
 W4        = 32768,
 W5        = 40960,
 W10       = 57344,
 M11       = 262144,
 M10       = 327680,
 M5        = 393216,
 M6        = 458752,
 M16       = 2097152,
 M15       = 2621440,
 M14       = 3145728,
 M9        = 3670016,
 W1        = 16777216,
 W2        = 20971520,
 W3        = 25165824,
 W8        = 29360128,
 W6        = 134217728,
 W7        = 167772160,
 W11       = 201326592,
 W12       = 234881024,
 M1        = 536870912,
 M2        = 805306368
}

-- Скорректировать точку E по паттерну и точкам
---@param pattern number
---@param pC number
---@param pD number
---@param pE number
---@return number
local function AnalizePointE(pattern, _, _, pC, pD, pE)

	 --- 1. Если паттерн определен то можно анализировать/корректировать значение E
	if ((pattern ~= pattern_names.NOPATTERN) and (pattern ~= pattern_names.ERROR))
	  then
	   if (pattern == pattern_names.M1)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.618)
			then
			 pE = pD - 1.618 * (pD-pC)
			end
		 end
	   if (pattern == pattern_names.M2)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.5)
			then
			 pE = pD - 0.5 * (pD-pC)
			end
		 end
	   if (pattern == pattern_names.M3)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.2720)
			then
			 pE = pD - 1.2720 * (pD-pC)
			end
		 end
	   if (pattern == pattern_names.M4)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.618)
			then
			 pE = pD - 0.618 * (pD-pC)
			end
		 end
	   if (pattern == pattern_names.M5)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.2720)
			then
			 pE = pD - 1.2720 * (pD-pC)
			end
		 end
	   if (pattern == pattern_names.M6)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.618)
			then
			 pE = pD - 0.618 * (pD-pC)
			end
		 end
	   if (pattern == pattern_names.M7)
		 then
		  if (((pD-pE)/(pD-pC)) < 3.0000)
			then
			 pE = pD - 3.0000 * (pD-pC)
			end
		 end
	   if (pattern == pattern_names.M8)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.3819)
			then
			 pE = pD - 0.3819 * (pD-pC)
			end
		 end
	   if (pattern == pattern_names.M9)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.618)
			then
			 pE = pD - 1.618 * (pD-pC)
			end
		 end
	   if (pattern == pattern_names.M10)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.5)
			then
			 pE = pD - 0.5 * (pD-pC)
			end
		 end
	   if (pattern == pattern_names.M11)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.25)
			then
			 pE = pD - 0.25 * (pD-pC)
			end
		 end
	   if (pattern == pattern_names.M12)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.618)
			then
			 pE = pD - 1.618 * (pD-pC)
			end
		 end
	   if (pattern == pattern_names.M13)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.5)
			then
			 pE = pD - 0.5 * (pD-pC)
			end
		 end
	   if (pattern == pattern_names.M14)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.2720)
			then
			 pE = pD - 1.2720 * (pD-pC)
			end
		 end
	   if (pattern == pattern_names.M15)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.618)
			then
			 pE = pD - 0.618 * (pD-pC)
			end
		 end
	   if (pattern == pattern_names.M16)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.3819)
			then
			 pE = pD - 0.3819 * (pD-pC)
			end
		 end
	   if (pattern == pattern_names.W1)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.3819)
			then
			 pE = 0.3819 * (pC-pD)+pD
			end
		 end
	   if (pattern == pattern_names.W2)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.618)
			then
			 pE = 0.618 * (pC-pD)+pD
			end
		 end
	   if (pattern == pattern_names.W3)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.2720)
			then
			 pE = 1.2720 * (pC-pD)+pD
			end
		 end
	   if (pattern == pattern_names.W4)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.5)
			then
			 pE = 0.5 * (pC-pD)+pD
			end
		 end
	   if (pattern == pattern_names.W5)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.618)
			then
			 pE = 1.618 * (pC-pD)+pD
			end
		 end
	   if (pattern == pattern_names.W6)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.25)
			then
			 pE = 0.25 * (pC-pD)+pD
			end
		 end
	   if (pattern == pattern_names.W7)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.5)
			then
			 pE = 0.5 * (pC-pD)+pD
			end
		 end
	   if (pattern == pattern_names.W8)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.618)
			then
			 pE = 1.618 * (pC-pD)+pD
			end
		 end
	   if (pattern == pattern_names.W9)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.3819)
			then
			 pE = 0.3819 * (pC-pD)+pD
			end
		 end
	   if (pattern == pattern_names.W10)
		 then
		  if (((pE-pD)/(pC-pD)) < 3.0000)
			then
			 pE = 3.0000 * (pC-pD)+pD
			end
		 end
	   if (pattern == pattern_names.W11)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.618)
			then
			 pE = 0.618 * (pC-pD)+pD
			end
		 end
	   if (pattern == pattern_names.W12)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.2720)
			then
			 pE = 1.2720 * (pC-pD)+pD
			end
		 end
	   if (pattern == pattern_names.W13)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.618)
			then
			 pE = 0.618 * (pC-pD)+pD
			end
		 end
	  if (pattern == pattern_names.W14)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.2720)
			then
			 pE = 1.2720 * (pC-pD)+pD
			end
		 end
	   if (pattern == pattern_names.W15)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.5)
			then
			 pE = 0.5 * (pC-pD)+pD
			end
		 end
	   if (pattern == pattern_names.W16)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.618)
			then
			 pE = 1.618 * (pC-pD)+pD
			end
		 end
	  end

	return pE

end

-- Получить паттерн по 5-и точкам
---@param pA number
---@param pB number
---@param pC number
---@param pD number
---@param pE number
---@return number
---@return number
---@return string
local function getPattern(pA, pB, pC, pD, pE)

    local pattern, patternName

    if (pB>pA and pA>pD and pD>pC and pC>pE)	then
		pattern     = pattern_names.M1;
        patternName = 'M1'
		return pattern, patternName
	end
	--- M2
	if (pB>pA and pA>pD and pD>pE and pE>pC) then
		pattern     = pattern_names.M2;
        patternName = 'M2'
		return pattern, patternName
	end
	--- M3
	if (pB>pD and pD>pA and pA>pC and pC>pE) then
		pattern     = pattern_names.M3;
        patternName = 'M3'
		return pattern, patternName
	end
	--- M4
	if (pB>pD and pD>pA and pA>pE and pE>pC) then
		pattern     = pattern_names.M4;
        patternName = 'M4'
		return pattern, patternName
	end
	--- M5
	if (pD>pB and pB>pA and pA>pC and pC>pE) then
		pattern     = pattern_names.M5;
        patternName = 'M5'
		return pattern, patternName
	end
	--- M6
	if (pD>pB and pB>pA and pA>pE and pE>pC) then
		pattern     = pattern_names.M6;
        patternName = 'M6'
		return pattern, patternName
	end
	--- M7
	if (pB>pD and pD>pC and pC>pA and pA>pE) then
		pattern     = pattern_names.M7;
        patternName = 'M7'
		return pattern, patternName
	end
	--- M8
	if (pB>pD and pD>pE and pE>pA and pA>pC) then
		pattern     = pattern_names.M8;
        patternName = 'M8'
		return pattern, patternName
	end
	--- M9
	if (pD>pB and pB>pC and pC>pA and pA>pE) then
		pattern     = pattern_names.M9;
        patternName = 'M9'
		return pattern, patternName
	end
	--- M10
	if (pD>pB and pB>pE and pE>pA and pA>pC) then
		pattern     = pattern_names.M10;
        patternName = 'M10'
		return pattern, patternName
	end
	--- M11
	if (pD>pE and pE>pB and pB>pA and pA>pC) then
		pattern     = pattern_names.M11;
        patternName = 'M11'
		return pattern, patternName
	end
	--- M12
	if (pB>pD and pD>pC and pC>pE and pE>pA) then
		pattern     = pattern_names.M12;
        patternName = 'M12'
		return pattern, patternName
	end
	--- M13
	if (pB>pD and pD>pE and pE>pC and pC>pA) then
		pattern     = pattern_names.M13;
        patternName = 'M13'
		return pattern, patternName
	end
	--- M14
	if (pD>pB and pB>pC and pC>pE and pE>pA) then
		pattern     = pattern_names.M14;
        patternName = 'M14'
		return pattern, patternName
	end
	--- M15
	if (pD>pB and pB>pE and pE>pC and pC>pA) then
		pattern     = pattern_names.M15;
        patternName = 'M15'
		return pattern, patternName
	end
	--- M16
	if (pD>pE and pE>pB and pB>pC and pC>pA) then
		pattern     = pattern_names.M16;
        patternName = 'M16'
		return pattern, patternName
	end
	--- W1
	if (pA>pC and pC>pB and pB>pE and pE>pD) then
		pattern     = pattern_names.W1;
        patternName = 'M17'
		return pattern, patternName
	end
	--- W2
	if (pA>pC and pC>pE and pE>pB and pB>pD) then
		pattern     = pattern_names.W2;
        patternName = 'W2'
		return pattern, patternName
	end
	--- W3
	if (pA>pE and pE>pC and pC>pB and pB>pD) then
		pattern     = pattern_names.W3;
        patternName = 'W3'
		return pattern, patternName
	end
	--- W4
	if (pA>pC and pC>pE and pE>pD and pD>pB) then
		pattern     = pattern_names.W4;
        patternName = 'W4'
		return pattern, patternName
	end
	--- W5
	if (pA>pE and pE>pC and pC>pD and pD>pB) then
		pattern     = pattern_names.W5;
        patternName = 'W5'
		return pattern, patternName
	end
	--- W6
	if (pC>pA and pA>pB and pB>pE and pE>pD) then
		pattern     = pattern_names.W6;
        patternName = 'W6'
		return pattern, patternName
	end
	--- W7
	if (pC>pA and pA>pE and pE>pB and pB>pD) then
		pattern     = pattern_names.W7;
        patternName = 'W7'
		return pattern, patternName
	end
	--- W8
	if (pE>pA and pA>pC and pC>pB and pB>pD) then
		pattern     = pattern_names.W8;
        patternName = 'W8'
		return pattern, patternName
	end
	--- W9
	if (pC>pA and pA>pE and pE>pD and pD>pB) then
		pattern     = pattern_names.W9;
        patternName = 'W9'
		return pattern, patternName
	end
	--- W10
	if (pE>pA and pA>pC and pC>pD and pD>pB) then
		pattern     = pattern_names.W10;
        patternName = 'W10'
		return pattern, patternName
	end
	--- W11
	if (pC>pE and pE>pA and pA>pB and pB>pD) then
		pattern     = pattern_names.W11;
        patternName = 'W11'
		return pattern, patternName
	end
	--- W12
	if (pE>pC and pC>pA and pA>pB and pB>pD) then
		pattern     = pattern_names.W12;
        patternName = 'W12'
		return pattern, patternName
	end
	--- W13
	if (pC>pE and pE>pA and pA>pD and pD>pB) then
		pattern     = pattern_names.W13;
        patternName = 'W13'
		return pattern, patternName
	end
	--- W14
	if (pE>pC and pC>pA and pA>pD and pD>pB) then
		pattern     = pattern_names.W14;
        patternName = 'W14'
		return pattern, patternName
	end
	--- W15
	if (pC>pE and pE>pD and pD>pA and pA>pB) then
		pattern     = pattern_names.W15;
        patternName = 'W15'
		return pattern, patternName
	end
	--- W16
	if (pE>pC and pC>pD and pD>pA and pA>pB) then
		pattern     = pattern_names.W16;
        patternName = 'W16'
		return pattern, patternName
	end

	--- NOPATTERN
    pattern     = pattern_names.NOPATTERN;
    patternName = 'NOPATTERN'

    return pattern, patternName

end

-- Получить цели движения по паттерну и точкам
---@param pattern number
---@param pA number
---@param pB number
---@param pC number
---@param pD number
---@param pE number
---@return number
---@return number
local function CalcPredictPoints(pattern, pA, pB, pC, pD, pE)

    local evE, mutE

    if (pattern == pattern_names.ERROR)
	  then
	--+------------------------------------------------------------+
	--| ПАТТЕРН: ERROR                                             |
	--| Точка "эволюции"=> НЕТ = 0                                 |
	--| Точка "мутации" => НЕТ = 0                                 |
	--+------------------------------------------------------------+
	  return;
   end


	----- ПРОВЕРКА НАЛИЧИЯ ТЕКУЩЕГО ПАТТЕРНА
	if (pattern == pattern_names.NOPATTERN)
	  then
	   return;                                         -- НЕТ ПАТТЕРНА - ВЫХОД
	end

	--+---------------------------------------------------------------+
	--| РАСЧЕТ ТОЧЕК ПРОГНОЗА                                         |
	--+---------------------------------------------------------------+

	   if pattern == pattern_names.M1 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M1 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> нет= 0                                  |
	   --| Точка "мутации" => W1 = 0.3819 * (pD-pE)+pE               |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = 0.3819 * (pD-pE)+pE

	   end
	   if pattern == pattern_names.M2 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M2 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M1 = D - 1.618 * (pD-pC)                |
	   --| Точка "мутации" => W4 = 0.5 * (pD-pE)+pE                  |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = pD - 1.618 * (pD-pC)

		 -----
		 mutE = 0.5 * (pD-pE)+pE

	   end
	   if pattern == pattern_names.M3 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M3 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> нет= 0                                  |
	   --| Точка "мутации" => W1 = 0.3819 * (pD-pE)+pE               |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = 0.3819 * (pD-pE)+pE

	   end
	   if pattern == pattern_names.M4 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M4 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M3 = D - 1.272 * (pD-pC)                |
	   --| Точка "мутации" => W4 = 0.5 * (pD-pE)+pE                  |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = pD - 1.272 * (pD-pC)

		 -----
		 mutE = 0.5 * (pD-pE)+pE

	   end
	   if pattern == pattern_names.M5 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M5 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> нет = 0                                 |
	   --| Точка "мутации" => W6  = 0.25 * (pD-pE)+pE                |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = 0.25 * (pD-pE)+pE

	   end
	   if pattern == pattern_names.M6 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M6 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M5 = D - 1.272 * (pD-pC)                |
	   --| Точка "мутации" => W9 = 0.3819 * (pD-pE)+pE               |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = pD - 1.272 * (pD-pC)

		 -----
		 mutE = 0.3819 * (pD-pE)+pE

	   end
	   if pattern == pattern_names.M7 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M7 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> нет = 0                                 |
	   --| Точка "мутации" => W1  = 0.3819 * (pD-pE)+pE              |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = 0.3819 * (pD-pE)+pE

	   end
	   if pattern == pattern_names.M8 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M8 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M4 = D - 0.618 * (pD-pC)                |
	   --| Точка "мутации" => W4 = 0.5 * (pD-pE)+pE                  |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = pD - 0.618 * (pD-pC)

		 -----
		 mutE = 0.5 * (pD-pE)+pE

	   end
	   if pattern == pattern_names.M9 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M9 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> нет = 0                                 |
	   --| Точка "мутации" => W6  = 0.25 * (pD-pE)+pE                |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = 0.25 * (pD-pE)+pE

	   end
	   if pattern == pattern_names.M10 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M10 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M6 = D - 0.618 * (pD-pC)                |
	   --| Точка "мутации" => W9 = 0.3819 * (pD-pE)+pE               |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = pD - 0.618 * (pD-pC)

		 -----
		 mutE = 0.3819 * (pD-pE)+pE

	   end
	   if pattern == pattern_names.M11 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M11 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M10 = D - 0.5 * (pD-pC)                 |
	   --| Точка "мутации" => W15 = 0.5 * (pD-pE)+pE                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = pD - 0.5 * (pD-pC)

		 -----
		 mutE = 0.5 * (pD-pE)+pE

	   end
	   if pattern == pattern_names.M12 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M12 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M7 = D - 3.0000 * (pD-pC)               |
	   --| Точка "мутации" => W1 = 0.3819 * (pD-pE)+pE               |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = pD - 3.0000 * (pD-pC)

		 -----
		 mutE = 0.3819 * (pD-pE)+pE

	   end
	   if pattern == pattern_names.M13 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M13 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M12 = D - 1.618 * (pD-pC)               |
	   --| Точка "мутации" => W4  = 0.5 * (pD-pE)+pE                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = pD - 1.618 * (pD-pC)

		 -----
		 mutE = 0.5 * (pD-pE)+pE

	   end
	   if pattern == pattern_names.M14 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M14 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M9 = D - 1.618 * (pD-pC)                |
	   --| Точка "мутации" => W6 = 0.25 * (pD-pE)+pE                 |
	   --+------------------------------------------------------------+
		 evE = pD - 1.618 * (pD-pC)

		 -----
		 mutE = 0.25 * (pD-pE)+pE

	   end
	   if pattern == pattern_names.M15 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M15 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M14 = D - 1.272 * (pD-pC)               |
	   --| Точка "мутации" => W9  = 0.3819 * (pD-pE)+pE              |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = pC-(pC-pA)/1.618

		 -----
		 mutE = pE+(pB-pE)/1.618

	   end
	   if pattern == pattern_names.M16 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M16 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M15 = D - 0.618 * (pD-pC)               |
	   --| Точка "мутации" => W15 = 0.5 * (pD-pE)+pE                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = pD - 0.618 * (pD-pC)

		 -----
		 mutE = 0.5 * (pD-pE)+pE

	   end
	   if pattern == pattern_names.W1 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W1 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W2  = 0.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M2  = E - 0.5 * (pE-pD)                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = 0.618 * (pC-pD)+pD

		 -----
		 mutE = pE-0.5 * (pE-pD)

	   end
	   if pattern == pattern_names.W2 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W2 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W3  = 1.272 * (pC-pD)+pD               |
	   --| Точка "мутации" => M8  = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = 1.272 * (pC-pD)+pD

		 -----
		 mutE = pE-0.3819 * (pE-pD)

	   end
	   if pattern == pattern_names.W3 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W3 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W8  = 1.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M11 = E - 0.25 * (pE-pD)                |
	   --+------------------------------------------------------------+
		 evE = 1.618 * (pC-pD)+pD

		 -----
		 mutE = pE-0.25 * (pE-pD)

	   end
	   if pattern == pattern_names.W4 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W4 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W5  = 1.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M13 = E - 0.5 * (pE-pD)                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = 1.618 * (pC-pD)+pD

		 -----
		 mutE = pE-0.5 * (pE-pD)

	   end
	   if pattern == pattern_names.W5 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W5 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W10 = 3.0000 * (pC-pD)+pD              |
	   --| Точка "мутации" => M16 = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 evE = 3.0000 * (pC-pD)+pD

		 -----
		 mutE = pE-0.3819 * (pE-pD)

	   end
	   if pattern == pattern_names.W6 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W6 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W7 = 0.5 * (pC-pD)+pD                  |
	   --| Точка "мутации" => M2 = E - 0.5 * (pE-pD)                  |
	   --+------------------------------------------------------------+
		 evE = 0.5 * (pC-pD)+pD

		 -----
		 mutE = pE-0.5 * (pE-pD)

	   end
	   if pattern == pattern_names.W7 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W7 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W11 = 0.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M8  = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 evE = 0.618 * (pC-pD)+pD

		 -----
		 mutE = pE-0.3819 * (pE-pD)

	   end
	   if pattern == pattern_names.W8 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W8 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> НЕТ = 0                                 |
	   --| Точка "мутации" => M11 = E - 0.25 * (pE-pD)                |
	   --+------------------------------------------------------------+
		 evE = nil
		 -----
		 mutE = pE-0.25 * (pE-pD)

	   end
	   if pattern == pattern_names.W9 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W9 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W13 = 0.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M13 = E - 0.5 * (pE-pD)                 |
	   --+------------------------------------------------------------+
		 evE = 0.618 * (pC-pD)+pD

		 -----
		 mutE = pE-0.5 * (pE-pD)

	   end
	   if pattern == pattern_names.W10 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W10 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> НЕТ = 0                                 |
	   --| Точка "мутации" => M16 = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 evE = nil
		 -----
		 mutE = pE-0.3819 * (pE-pD)

	   end
	   if pattern == pattern_names.W11 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W11 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W12 = 1.272 * (pC-pD)+pD               |
	   --| Точка "мутации" => M8  = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 evE = 1.272 * (pC-pD)+pD

		 -----
		 mutE = pE-0.3819 * (pE-pD)

	   end
	   if pattern == pattern_names.W12 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W12 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> НЕТ = 0                                 |
	   --| Точка "мутации" => M11 = E - 0.25 * (pE-pD)                |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = pE-0.25 * (pE-pD)

	   end
	   if pattern == pattern_names.W13 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W13 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W14 = 1.272 * (pC-pD)+pD               |
	   --| Точка "мутации" => M13 = E - 0.5 * (pE-pD)                 |
	   --+------------------------------------------------------------+

	   ----- level_0:
	   evE = 1.272 * (pC-pD)+pD

	   -----
	   mutE = pE-0.5 * (pE-pD)

	   end
	   if pattern == pattern_names.W14 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W14 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> НЕТ = 0                                 |
	   --| Точка "мутации" => M16 = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = pE-0.3819 * (pE-pD)

	   end
	   if pattern == pattern_names.W15 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W15 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W16 = 1.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M13 = E - 0.5 * (pE-pD)                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = 1.618 * (pC-pD)+pD

		 -----
		 mutE = pE-0.5 * (pE-pD)

	   end
	   if pattern == pattern_names.W16 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W16 +                                             |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> НЕТ = 0                                 |
	   --| Точка "мутации" => M16 = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = pE-0.3819 * (pE-pD)

	   end

       return evE, mutE

end

local function get_pattern(zz_data)
    if not zz_data or #zz_data < 5 then
        return
    end
    local pA = zz_data[#zz_data - 4].val
    local pB = zz_data[#zz_data - 3].val
    local pC = zz_data[#zz_data - 2].val
    local pD = zz_data[#zz_data - 1].val
    local pE = zz_data[#zz_data].val
    -- myLog('get_pattern', pA, pB, pC, pD, pE, last_extr)
    local pattern = getPattern(pA, pB, pC, pD, pE)
    local targetE = AnalizePointE(pattern, pA, pB, pC, pD, pE)
    if targetE == pD then targetE = nil end
    local evE, mutE
    if targetE then
        evE, mutE = CalcPredictPoints(pattern, pA, pB, pC, pD, targetE)
    end
    return targetE, evE, mutE
end

--- Получть значения расширения фиббоначи по трем точкам
---@param trend number
---@param pA number
---@param pB number
---@param pC number
---@param fibo_ext table|nil - таблица процентов. Если не задано, то берутся классические значения.
---@return table
local function getFiboExtention(trend, pA, pB, pC, fibo_ext)

    local fibo_range = math_max(math_abs((pB - pA)), math_abs((pB - pC)))

    fibo_ext = fibo_ext or {[100.0] = 0, [161.8] = 0, [261.8] = 0, [423.6] = 0}

    for k in pairs(fibo_ext) do
        fibo_ext[k] = pC + trend*fibo_range*k/100
    end

    return fibo_ext

end

local function getCandleProp(index)
	if CandleExist(index) then
		local datetimeL = T(index)
		return (((datetimeL.year + datetimeL.month/100)*100) + datetimeL.day/100)*100, ((datetimeL.hour + datetimeL.min/100)*100)*100
	end
end

-- Regression
-- Linear:      degree = 1
-- Parabolic:   degree = 2
-- Cubic:       degree = 3
local function F_REG(settings, data_set)

    settings            = (settings or {})
    local period        = settings.period or 10
    local degree        = settings.degree or 1
    local kstd          = settings.kstd or 1

    local sql_buffer
    local sqh_buffer
    local fx_buffer
	local sx
    local input
    local calc_buffer
    local nn = degree + 1
    local ai = {{1,2,3,4}, {1,2,3,4}, {1,2,3,4}, {1,2,3,4}}
	local b  = {}
	local x  = {}

    return function(index, recacl)


		if fx_buffer == nil or index == 1 then

            calc_buffer = {}
            fx_buffer   = {}
			sql_buffer  = {}
			sqh_buffer  = {}
            input       = {}
			--- sx
			sx={}
			-- sx[1] = period + 1
            local sum
			for mi = 0, nn*2-2 do
                sum=0
                for n = 1, period do
					sum = sum + math_pow(n,mi)
				end
			    sx[mi+1]=sum
			end

			return nil
		end

		if not recacl and calc_buffer[index] ~= nil then
			return fx_buffer, sqh_buffer, sql_buffer
		end

        if not data_set[index] or index < period then
			return nil
		end

        input = {}

        --- syx
        local sum
		for mi=1, nn do
			sum = 0
			for n = 1, period do
				if data_set[index+n-period] then
                    input[#input + 1] = data_set[index+n-period]
                    if mi == 1 then
					   sum = sum + input[#input]
					else
					   sum = sum + input[#input]*math_pow(n, mi-1)
					end
				end
			end
			b[mi] = sum
		end

		--- Matrix
		for jj=1, nn do
			for ii=1, nn do
				ai[ii][jj] = sx[ii+jj-1]
			end
		end

		--- Gauss
		for kk=1, nn-1 do
			local ll = 0
			local mm = 0
			for ii = kk, nn do
				if math_abs(ai[ii][kk])>mm then
					mm = math_abs(ai[ii][kk])
					ll = ii
				end
			end

			if ll==0 then
				return nil
			end
			if ll~=kk then
				for jj=1, nn do
					ai[ll][jj], ai[kk][jj] = ai[kk][jj], ai[ll][jj]
				end
				b[ll], b[kk] = b[kk], b[ll]
			end
			for ii = kk+1, nn do
				local qq = ai[ii][kk]/ai[kk][kk]
				for jj=1, nn do
					if jj==kk then
						ai[ii][jj]=0
					else
						ai[ii][jj]=ai[ii][jj]-qq*ai[kk][jj]
					end
				end
				b[ii]=b[ii]-qq*b[kk]
			end
		end

		x[nn] = b[nn]/ai[nn][nn]

        local tt
        for ii=nn-1, 1, -1 do
            tt = 0
			for jj=1, nn-ii do
				tt    = tt + ai[ii][ii+jj]*x[ii+jj]
				x[ii] = (1/ai[ii][ii])*(b[ii] - tt)
			end
		end

		---
		for n = 1, period do
			sum=0
			for kk = 1, degree do
				sum = sum + x[kk+1]*math_pow(n,kk)
			end
			fx_buffer[index+n-period]=x[1] + sum
		end

        local sse = 0
        for n = 1, period do
            sse = sse + math_pow(fx_buffer[index+n-period] - input[n], 2)
        end

        sse = math_sqrt(sse/(period-1))*kstd

		for n = 1, period do
			sqh_buffer[index+n-period]=fx_buffer[index+n-period]+sse
			sql_buffer[index+n-period]=fx_buffer[index+n-period]-sse
		end

        calc_buffer[index] = true

		return fx_buffer, sqh_buffer, sql_buffer

	end

end

local function F_ATR(settings)

    local period    = (settings.period or 9)
    local save_bars = (settings.save_bars or period)

    local ATR     = {}
    local p_index
    local l_index

    return function(index)
        ATR[index]      = ATR[index-1] or 0
        if not C(index) then
            return ATR
        end
        if index ~= l_index then p_index = l_index end
        local high      = H(index)
        local low       = L(index)
        local p_close   = C(p_index or 1)
        ATR[index]      = high - low
        if p_index then
            ATR[index]  = (ATR[index-1]*(period-1) + math_max(math_abs(high - low), math_abs(high - p_close), math_abs(p_close - low)))/period
        end
        ATR[index-save_bars] = nil
        l_index = index
        return ATR
    end
end

---@param offset table
-- offset.type      = Тип отсутпа: '%' - в процентах, 'Price' - в шагах цены
-- offset.calc_kind = Вид расчета 'Range' - как процент от прошлой волны, 'Extr' - как отступ в цене от прошлого экстремума; ATR - по пробитю канала ATR
-- offset.value     = Значение отступа выраженное в цене инструмента или в процентах
local function ZZ_Processor(offset)

    -- myLog('new ZZ_Processor', offset)

    if offset.calc_kind == 'Range' and offset.type ~= '%' then
        local mes = 'Некорректно заданы настройки. Для вида расчета "range", тип отступа должен быть "%"'
        --myLog('new ZZ_Processor', mes)
        return false, mes
    end

    local depth         = offset.depth or 24
    local atr_type      = offset.calc_kind == 'ATR'
    local range_type    = offset.calc_kind == 'Range'
    local steps_offset  = offset.type == 'Steps'
    local perc_offset   = offset.type == '%'

    local zz_levels   = {}
    local l_buff      = {}
    local h_buff      = {}

    local last_high   = {}
    local last_low    = {}

    local last_max
    local last_min
    local trend       = {}
    local atr

    local ATR
    if atr_type then
        ATR = F_ATR({period = depth})
    end

    local offset_price
    local function calc_offset_price(val, sign, range)
        if range_type and range > 0 then
            return val + sign*range*offset.value/100
        end
        if atr_type and range > 0 then
            return val + sign*range*offset.value
        end
        if perc_offset then
            return (1 + sign*offset.value/100)*val
        end
        if steps_offset then
            return val + sign*offset.value
        end
    end

    local function check_trend_change(sign, price, close)
        return sign*(price - offset_price) < 0 and sign*(close - offset_price) < 0
    end

    local count_index = {}

    local bars = 0

    local function UpdateZZ(data, shift)
        zz_levels[#zz_levels + (shift or 0)] = zz_levels[#zz_levels + (shift or 0)] or {}
        zz_levels[#zz_levels].val   = data.val
        zz_levels[#zz_levels].time  = data.time
        zz_levels[#zz_levels].index = data.index
        -- if shift == 1 then
        --     myLog('new zz',#zz_levels, zz_levels[#zz_levels], 'last_max', last_max, 'last_min', last_min)
        -- end
    end

    local function update_last(last_val, new_val, index, time, shift)
        last_val.val    = new_val
        last_val.time   = os.date('%d.%m.%Y %H:%M:%S', time)
        last_val.index  = index
        local range     = atr_type and atr[index] or (last_max.val - last_min.val)
        offset_price    = calc_offset_price(last_val.val, -trend[index], range)
        UpdateZZ(last_val, shift or 0)
        SetValue(last_val.index, 1, last_val.val)
    end

    ---@param new_high number
    ---@param new_low number
    return function (new_high, new_low, close, time, index, online)

        local status, res1, res2, res3 = pcall(function()

            if atr_type then
                atr = ATR(index)
            end

            if not last_max or not last_min then
                last_min        = last_min or {val = new_low, time = time, index = index, trend = -1}
                last_max        = last_max or {val = new_high, time = time, index = index, trend = 1}
                offset_price    = calc_offset_price(new_high, -1, atr_type and atr[index] or (last_max.val - last_min.val))
            end

            if count_index[index] == 2 or online then
                if trend[index] == 1 and new_high > last_max.val then
                    SetValue(last_max.index or 1, 1, nil)
                    update_last(last_max, new_high, index, time)
                    -- myLog('--update max', last_max.time, 'offset_price', offset_price, last_max.val - last_min.val, last_max)
                end
                if trend[index] == -1 and new_low < last_min.val then
                    SetValue(last_min.index or 1, 1, nil)
                    update_last(last_min, new_low, index, time)
                    -- myLog('--update min', last_min.time, 'offset_price', offset_price, last_max.val - last_min.val, last_min)
                end
                return zz_levels, trend, (trend[index] == 1 and last_max or last_min)
            end

            if not count_index[index] then bars = bars + 1 end

            count_index[index]  = 1

            l_buff[index]       = new_low
            h_buff[index]       = new_high
            trend[index]        = trend[index - 1] or 1
            last_low[index]     = last_low[index - 1]
            last_high[index]    = last_high[index - 1]

            if bars <= depth then return zz_levels, trend, (trend[index] == 1 and last_max or last_min) end

            if trend[index] == 1 then
                if new_high and new_high > last_max.val then
                    SetValue(last_max.index or 1, 1, nil)
                    update_last(last_max, new_high, index, time)
                    return zz_levels, trend, (trend[index] == 1 and last_max or last_min)
                end
            end

            if trend[index] == -1 then
                if new_low and new_low < last_min.val then
                    SetValue(last_min.index or 1, 1, nil)
                    update_last(last_min, new_low, index, time)
                    return zz_levels, trend, (trend[index] == 1 and last_max or last_min)
                 end
            end

                -- if offset.calc_kind ~= 'Range' then
                local r_high    = math_max(unpack(h_buff, index - depth + 1, index))
                local r_low     = math_min(unpack(l_buff, index - depth + 1, index))

                if r_high == last_high[index] then
                    r_high = nil
                else
                    last_high[index] = r_high
                end
                if r_low == last_low[index] then
                    r_low = nil
                else
                    last_low[index] = r_low
                end

                if r_high ~= new_high then
                    new_high = nil
                end
                if r_low ~= new_low then
                    new_low = nil
                end
            -- end

            -- myLog('CalcTradeSignals bar', index, os.date('%d.%m.%Y %H:%M:%S', time), 'trend', trend[index], 'atr', atr[index], 'offset_price', offset_price, 'last_max', last_max, 'last_min', last_min)
            -- if index == Size() then
                -- myLog('CalcTradeSignals bar', index, os_date('%d.%m.%Y %H:%M:%S', time), 'trend', trend[index], 'new_high', new_high, 'new_low', new_low, 'r_high', r_high, 'r_low', r_low, input_data)
            -- end

            if trend[index] == 1 then
                if new_low and check_trend_change(trend[index], new_low, close) then
                    count_index[index]  = 2
                    trend[index]        = -1
                    update_last(last_min, new_low, index, time, 1)
                    -- myLog('new trend -1 new max', index, os.date('%d.%m.%Y %H:%M:%S', time), last_max.time, 'new_low', new_low, 'offset_price', offset_price, last_max.val - last_min.val, 'last_max', last_max, 'last_min', last_min)
                    return zz_levels, trend, last_min
                end
            end

            if trend[index] == -1 then
                if new_high and check_trend_change(trend[index], new_high, close) then
                    count_index[index]  = 2
                    trend[index]        = 1
                    update_last(last_max, new_high, index, time, 1)
                    -- myLog('new trend 1 new min', index, os.date('%d.%m.%Y %H:%M:%S', time), last_min.time, 'new_high', new_high, 'offset_price', offset_price, last_max.val - last_min.val, 'last_min', last_min, 'last_max', last_max)
                end
            end

            count_index[index-1]    = nil
            trend[index-2]          = nil
            last_low[index-2]       = nil
            last_high[index-2]      = nil
            h_buff[index - depth]   = nil
            l_buff[index - depth]   = nil

            return zz_levels, trend, (trend[index] == 1 and last_max or last_min)

        end)
        if not status then myLog('ZZ_Processor : '..tostring(res1)) end
        return res1, res2, res3
    end
end


local function Algo(Fsettings, all_lines)

    Fsettings                       = (Fsettings or {})
    local calc_kind                 = Fsettings['Вариант расчета'] or 'Range'
    local offset_type               = Fsettings['Тип отступа'] or '%'
    local depth                     = Fsettings['Окно поиска вершины (бар)'] or 24
    local offset_value              = Fsettings['Размер отступа'] or 24

    local show_calc_levels          = Fsettings['Рассчитывать уровни диапазона'] or 1
    local show_extra_calclevels     = Fsettings['Показывать расширения уровней'] or 0
    local calc_levels_regime        = Fsettings['Вариант расчета уровней'] or 1
    local deep_zz_calc_levels       = Fsettings['Глубина поиска последнего диапазона по вершинам'] or 10
    local show_change_trend         = Fsettings['Показывать метки смены направления'] or 1
    local show_zz_levels            = Fsettings['Показывать уровни от вершин'] or 1
    local show_cog                  = Fsettings['Показывать центр волны'] or 1
    local show_cog_to_show          = Fsettings['Число центров волны'] or 3
    local zz_levels_to_show         = Fsettings['Число уровней от вершин'] or 10
    local h_zz_levels_to_show       = Fsettings['Число исторических уровней от вершин'] or 2
    local show_target_zone          = Fsettings['Показывать целевую зону'] or 1
    local show_andrews              = Fsettings['Показывать вилы Эндрюса'] or 1
    local andrews_shift             = Fsettings['Сдвиг вершин для вил Эндрюса'] or 1
    local show_reg                  = Fsettings['Показывать регрессионный канал'] or 1
    local reg_std                   = Fsettings['Ширина регрессионного канала'] or 2
    local moves_for_target          = Fsettings['Число волн для целевой зоны по среднему'] or 5
    local target_zone_spread        = Fsettings['Ширина целевой зоны по среднему %'] or 10
    local show_label                = Fsettings['Показывать метку паттерна'] or 1
    local show_fibo_ext             = Fsettings['Показывать расширение фибоначчи'] or 1
    chart_id                        = Fsettings['Идентификатор графика'] or ''
    local label_shift               = Fsettings['Отступ метки от вершины'] or 250
    local white_label_color         = Fsettings['whiteLabelColor'] or 0

	for val in string.gmatch(offset_type or '*%', "([^;]+)") do
        if (val:find('*')) then
            offset_type = val:gsub('*', ''):gsub("^%s*(.-)%s*$", "%1")
            break
        end
    end
	for val in string.gmatch(calc_kind or '*Range', "([^;]+)") do
        if (val:find('*')) then
            calc_kind = val:gsub('*', ''):gsub("^%s*(.-)%s*$", "%1")
            break
        end
    end

    all_lines   = all_lines or 113

    error_log = {}

    local fAlgo
	local lines_data       --индексы и значения точек для отрисовки линий. 1 - значение, 2 - индекс
	local cog_points       --индексы точек для отрисовки линий CoG

    local scale             = 0
    local close, high

    local max_zz_to_show    = 20
    local cl_width          = 15
    local tm_width          = 50

    local last_trend
    local last_extr_val
    local begin_index
    local nzz               = 0
    local sorted_zz_levels  = {}
	local calculated_buffer = {}

    local zz_data, trend    = {}, {}

    local fibo_levels   = {100.0, 161.8, 261.8, 423.6}
    local fibo_ext      = {}
    for _, value in ipairs(fibo_levels) do
        fibo_ext[value] = 0
    end

    local fReg
    local Raw
    local reg_d  = 0

    local andr_d = 0

    local function get_label()
        local label = {}
        if white_label_color == 1  then
            label.R = 200
            label.G = 200
            label.B = 200
        else
            label.R = 0
            label.G = 0
            label.B = 0
        end
        label.TRANSPARENCY = 0
        label.TRANSPARENT_BACKGROUND = 1
        label.FONT_FACE_NAME = 'Verdana'
        label.FONT_HEIGHT = 10
        label.HINT = ''
        return label
    end

    local now_vol = 0
    local l2_text1 = ''
    local l3_text1 = ''
    local label1 = get_label()
    local label2 = get_label()
    local label3 = get_label()

    return function (index)

        local status, res = pcall(function()

            local time  = os_time(T(index))

            if fAlgo == nil or index == begin_index then
                if index == 1 and chart_id ~= '' then
                    DelAllLabels(chart_id)
                    AddedLabels = {}
                end
                begin_index = index
                local DSInfo  = getDataSourceInfo()
                scale         = getSecurityInfo(DSInfo.class_code, DSInfo.sec_code).scale
                fAlgo         = ZZ_Processor({type = offset_type, calc_kind = calc_kind, value = offset_value, depth = depth})
                fAlgo(H(index), L(index), C(index), time, index)

               if type(cog_points) == 'table' then
                    for nn = 1, #cog_points do
                        SetValue(cog_points[nn], 2, nil)
                    end
                end

                if show_reg == 1 then
                    Raw             = {}
                    fReg            = F_REG({period = zz_levels_to_show, method = 'REG', data_type = 'Any', kstd = reg_std}, Raw)
                end

                nzz                 = 0
                last_trend          = nil
                last_extr_val       = nil
                lines_data          = {}
                cog_points          = {}
                sorted_zz_levels    = {}
                calculated_buffer   = {}

                for nn = 1, all_lines do
                    lines_data[nn] = {}
                    lines_data[nn]["val"] = nil
                    lines_data[nn]["index"] = 1
                end

                return
            end

            if not calculated_buffer[index] then

                lines_data[1]["val"]    = nil
                lines_data[2]["val"]    = nil

                lines_data[25]["val"]   = nil
                SetValue(lines_data[25]["index"], 25, nil)

                lines_data[32]["val"]   = nil
                lines_data[33]["val"]   = nil

                --3-15 линии
                if show_calc_levels == 1 then
                    for nn = 3, 15 do
                        SetValue(index-1, nn, nil)
                        SetValue(lines_data[nn]["index"], nn, nil)
                        lines_data[nn]["index"] = lines_data[nn]["index"] + 1
                        SetValue(lines_data[nn]["index"], nn, lines_data[nn]["val"])
                    end
                end

                --16, 17 линии
                if show_target_zone == 1 then
                    for nn = 16, 17 do
                        SetValue(index-1, nn, nil)
                        SetValue(lines_data[nn]["index"], nn, nil)
                        lines_data[nn]["index"] = lines_data[nn]["index"] + 1
                        SetValue(lines_data[nn]["index"], nn, lines_data[nn]["val"])
                    end
                end
                --18, 21 линии
                if show_fibo_ext == 1 then
                    for nn = 18, 21 do
                        SetValue(index-1, nn, nil)
                        SetValue(lines_data[nn]["index"], nn, nil)
                        lines_data[nn]["index"] = lines_data[nn]["index"] + 1
                        SetValue(lines_data[nn]["index"], nn, lines_data[nn]["val"])
                    end
                end
                --22, 24 линии
                if show_target_zone == 1 then
                    for nn = 22, 24 do
                        SetValue(index-1, nn, nil)
                        SetValue(lines_data[nn]["index"], nn, nil)
                        lines_data[nn]["index"] = lines_data[nn]["index"] + 1
                        SetValue(lines_data[nn]["index"], nn, lines_data[nn]["val"])
                    end
                end

                if show_reg == 1 and lines_data[26]["val"] then
                    for nn = 26, 28 do
                        SetValue(index-1, nn, nil)
                        lines_data[nn]["val"] = lines_data[nn]["val"] + reg_d
                    end
                    -- myLog('Set', index-1, 'nil', index, lines_data[26]["val"])
                end

                if show_andrews == 1 and lines_data[29]["val"] then
                    for nn = 29, 31 do
                        if index-1 ~= lines_data[nn]["index"] then
                            SetValue(index-1, nn, nil)
                        end
                        lines_data[nn]["val"] = lines_data[nn]["val"] + andr_d
                    end
                    -- myLog('Set', index-1, 'nil', index, lines_data[30]["val"])
                end

                --34-114 линии
                if show_zz_levels == 1 then
                    for nn = 1, max_zz_to_show*2*2 do
                        SetValue(index-1, all_lines-nn+1, nil)
                    end
                end

            end

            close   = C(index)
            high    = H(index)

            local last = index == Size()

            if last and not calculated_buffer[index] and calculated_buffer[index-1] then
                fAlgo(H(index-1), L(index-1), C(index-1), time, index, false)
            end
			zz_data, trend  = fAlgo(high, L(index), close, time, index, last)
            --myLog('CalcTradeSignals bar', index, os_date('%d.%m.%Y %H:%M:%S', time), 'close', close, 'trend', trend[index], 'zz_data', zz_data[#zz_data])

            local last_extr     = #zz_data > 0 and zz_data[#zz_data]
            local need_recalc   = (last_trend ~= trend[index]) or (last_extr and last_extr_val ~= last_extr.val)

            if nzz ~= #zz_data then
                -- nzz = #zz_data
                while nzz < #zz_data do
                    nzz = nzz + 1
                    sorted_zz_levels[#sorted_zz_levels+1] = zz_data[nzz]
                    -- myLog('CalcTradeSignals bar', index, os.date('%d.%m.%Y %H:%M:%S', time), 'close', close, 'nzz', nzz, 'zz_data', sorted_zz_levels[#sorted_zz_levels])
                    if show_reg == 1 and nzz > 1 then
                        Raw[#Raw+1] = zz_data[nzz-1].val
                    end
                end

                if show_change_trend == 1 then
                    lines_data[trend[index] == 1 and 32 or 33]["val"]   = _G.O(index)
                end

                if show_reg == 1 and #Raw>=zz_levels_to_show then
                    local reg, reg_up, red_dw = fReg(#Raw, true)
                    local tot = #Raw
                    if reg and reg[tot] then

                        SetValue(zz_data[tot-1]["index"], 26, nil)
                        SetValue(lines_data[26]["index"], 26, nil)

                        SetValue(zz_data[tot-1]["index"], 27, nil)
                        SetValue(lines_data[27]["index"], 27, nil)

                        SetValue(zz_data[tot-1]["index"], 28, nil)
                        SetValue(lines_data[28]["index"], 28, nil)
                        -- SetValue(index-1, 26, nil)
                        -- myLog('Set', lines_data[26]["index"], zz_data[tot-1]["index"], index, 'nil')

                        local first = tot>zz_levels_to_show and tot-zz_levels_to_show+1 or 1

                        lines_data[26]["index"] = zz_data[first]["index"]
                        lines_data[27]["index"] = zz_data[first]["index"]
                        lines_data[28]["index"] = zz_data[first]["index"]

                        SetValue(zz_data[first]["index"], 26, reg[first])
                        SetValue(zz_data[tot]["index"], 26, reg[tot])

                        SetValue(zz_data[first]["index"], 27, reg_up[first])
                        SetValue(zz_data[tot]["index"], 27, reg_up[tot])

                        SetValue(zz_data[first]["index"], 28, red_dw[first])
                        SetValue(zz_data[tot]["index"], 28, red_dw[tot])

                        reg_d       = (reg[tot] - reg[first])/(zz_data[tot]["index"]-zz_data[first]["index"]+1)
                        local cur_d = reg_d*(index-zz_data[tot]["index"]+1)

                        lines_data[26]["val"]   = reg[tot] + cur_d
                        lines_data[27]["val"]   = reg_up[tot] + cur_d
                        lines_data[28]["val"]   = red_dw[tot] + cur_d

                        -- myLog('nzz', nzz, 'tot', tot, 'first', first, 'reg_d', reg_d)
                        -- myLog('Set', 'first', lines_data[26]["index"], '=', reg[first], 'zz', zz_data[tot]["index"], reg[tot], 'index', index, lines_data[26]["val"])
                    end

                end

                if nzz > 1 then
                    table_sort(sorted_zz_levels, function(a,b) return a["val"]<b["val"] end)
                end
                need_recalc = true
                now_vol     = 0
            end

            -- if last then
                -- myLog('CalcTradeSignals bar', index, os.date('%d.%m.%Y %H:%M:%S', time), 'close', close, 'last_extr', last_extr, 'trend', trend[index], 'zz_data', zz_data[#zz_data])
            -- end

            -- вывод данных
            if last and need_recalc and nzz > 4 then

                -- myLog('CalcTradeSignals bar', index, os.date('%d.%m.%Y %H:%M:%S', time), lines_data)
                last_trend      = trend[index] or (last_extr.val > zz_data[#zz_data-1].val and 1 or -1)
                last_extr_val   = last_extr.val

                -- ставим возвращаемые значения в nil
                -- for nn = 2, all_lines do
                --     lines_data[nn]["val"] = nil
                -- end

                --обнуляем линии на предыдущих свечках
                --2 линия
                lines_data[2]["val"] = nil
                for nn = 1, #cog_points do
                    SetValue(cog_points[nn], 2, nil)
                end

                --3-15 линии
                if show_calc_levels == 1 then
                    for nn = 3, 15 do
                        lines_data[nn]["val"] = nil
                        SetRangeValue(nn, lines_data[nn]["index"], index, nil)
                    end
                end

                --16, 17 линии
                if show_target_zone == 1 then
                    for nn = 16, 17 do
                        lines_data[nn]["val"] = nil
                        SetRangeValue(nn, lines_data[nn]["index"], index, nil)
                    end
                end
                --18, 21 линии
                if show_fibo_ext == 1 then
                    for nn = 18, 21 do
                        lines_data[nn]["val"] = nil
                        SetRangeValue(nn, lines_data[nn]["index"], index, nil)
                    end
                end
                --22, 24 линии
                if show_target_zone == 1 then
                    for nn = 22, 24 do
                        lines_data[nn]["val"] = nil
                        SetRangeValue(nn, lines_data[nn]["index"], index, nil)
                    end
                end

                SetValue(lines_data[25]["index"], 25, nil)
                for nn=0,4 do
                    if zz_data[#zz_data - nn] then
                        SetValue(zz_data[#zz_data - nn]["index"], 25, nil)
                    end
                end

                if show_target_zone == 1 then
                    for nn = 22, 24 do
                        lines_data[nn]["val"] = nil
                        SetRangeValue(nn, lines_data[nn]["index"], index, nil)
                    end
                end

                --34-113 линии
                if show_zz_levels == 1 then
                    for nn = 1, max_zz_to_show*2*2 do
                        lines_data[all_lines-nn+1]["val"] = nil
                        SetRangeValue(all_lines-nn+1, lines_data[all_lines-nn+1]["index"], index, nil)
                    end
                end

                local range_max =  0
                local range_min = high

                local dminZ = math_abs(sorted_zz_levels[1]["val"] - close)
                local dmaxZ = math_abs(sorted_zz_levels[#sorted_zz_levels]["val"] - close)

                local price_level
                if h_zz_levels_to_show~=0 then
                    if dminZ < dmaxZ then
                        for i=2,#sorted_zz_levels do
                            if close > sorted_zz_levels[i-1]["val"] and close <= sorted_zz_levels[i]["val"] then
                                price_level = i
                                break
                            end
                        end
                    else
                        for i=#sorted_zz_levels,2,-1 do
                            if close > sorted_zz_levels[i-1]["val"] and close <= sorted_zz_levels[i]["val"] then
                                price_level = i
                                break
                            end
                        end
                    end
                end

                local range_min_index = 1
                local range_max_index = #sorted_zz_levels

                if price_level then
                    range_min_index = price_level
                    range_max_index = price_level
                    local minj      = math_max(price_level-h_zz_levels_to_show,1)
                    local maxj      = math_min(price_level+h_zz_levels_to_show-1, #sorted_zz_levels)
                    for j = minj, maxj do
                        if sorted_zz_levels[j] then
                            if sorted_zz_levels[j]["val"] < range_min then
                                range_min = sorted_zz_levels[j]["val"]
                                range_min_index = j
                            end
                            if sorted_zz_levels[j]["val"] > range_max then
                                range_max = sorted_zz_levels[j]["val"]
                                range_max_index = j
                            end
                        end
                    end
                end


                deep_zz_calc_levels = math_min(deep_zz_calc_levels,#zz_data-1)
                zz_levels_to_show   = math_min(zz_levels_to_show,#zz_data-1)
                moves_for_target    = math_min(moves_for_target,#zz_data-1)

                local j = 1
                while j<=deep_zz_calc_levels do
                    if zz_data[nzz-j+1] then
                        if math_abs(zz_data[nzz-j+1]["val"] - close)/zz_data[nzz-j+1]["val"] > 0.5 then
                            deep_zz_calc_levels = math_min(5,#zz_data-1)
                            zz_levels_to_show   = math_min(zz_levels_to_show,deep_zz_calc_levels)
                            moves_for_target    = math_min(moves_for_target,deep_zz_calc_levels)
                            if j>deep_zz_calc_levels then
                                break
                            end
                        end
                        range_min = math_min(zz_data[nzz-j+1]["val"], range_min)
                        range_max = math_max(zz_data[nzz-j+1]["val"], range_max)
                    end
                    j = j+1
                end

                local pX = zz_data[nzz-4]["val"]
                local pA = zz_data[nzz-3]["val"]
                local pB = zz_data[nzz-2]["val"]
                local pC = zz_data[nzz-1]["val"]
                local pD = last_extr.val
                local iX = zz_data[nzz-4]["index"]
                local iA = zz_data[nzz-3]["index"]
                local iB = zz_data[nzz-2]["index"]
                local iC = zz_data[nzz-1]["index"]
                local iD = last_extr.index

                local XA = 0
                local AB = 0
                local BC = 0
                local CD = 0

                local vXA = 0
                local vAB = 0
                local vBC = 0
                local vCD = 0

                local ABtoXA = 0
                local XCtoXA = 0
                local ADtoXA = 0

                local CDtoAB = 0
                local BCtoAB = 0

                local cur_deviation = 0

                if zz_data[nzz-4] then

                    SetValue(iX, 25, pX)
                    SetValue(iA, 25, pA)
                    SetValue(iB, 25, pB)
                    SetValue(iC, 25, pC)
                    SetValue(iD, 25, pD)
                    lines_data[25]["index"] = iD
                    if iD == Size() then
                        lines_data[25]["val"] = pD
                    end

                    XA = math_abs(pX - pA)
                    AB = math_abs(pA - pB)
                    BC = math_abs(pB - pC)
                    local XC = math_abs(pX - pC)
                    CD = math_abs(pC - pD)
                    local AD = math_abs(pA - pD)
                    ABtoXA = rounding(100*AB/XA, 2)
                    XCtoXA = rounding(100*XC/XA, 2)
                    ADtoXA = rounding(100*AD/XA, 2)
                    BCtoAB = rounding(100*BC/AB, 2)
                    CDtoAB = rounding(100*CD/AB, 2)
                    cur_deviation = rounding(100*math_abs(close - pD)/CD, 2)

                    XA = rounding(XA, scale)
                    AB = rounding(AB, scale)
                    BC = rounding(BC, scale)
                    -- XC = rounding(XC, scale)
                    CD = rounding(CD, scale)
                    -- AD = rounding(AD, scale)

                    for i=1, iA - iX do
                        vXA = vXA + V(i + iX)
                    end
                    for i=1, iB - iA do
                        vAB = vAB + V(i + iA)
                    end
                    for i=1, iC - iB do
                        vBC = vBC + V(i + iB)
                    end
                    for i=1, iD - iC do
                        vCD = vCD + V(i + iC)
                    end

                end

                if show_calc_levels == 1 then

                    local lastRange
                    if calc_levels_regime == 1 then
                        if zz_data[nzz-1] == nil then
                            lastRange = 0
                        else
                            lastRange = math_abs(pD - pC)
                        end
                    else
                        lastRange = math_abs(range_max - range_min)
                    end

                    if lastRange ~=0 then

                        local increment = 2

                        if show_extra_calclevels == 1 then
                            for nn = 1, 2 do
                                SetValue(index-cl_width, nn+2, range_min - nn*lastRange/8)
                                lines_data[nn+2]["val"] = range_min - nn*lastRange/8
                                SetValue(index-cl_width, nn+13, range_max + nn*lastRange/8)
                                lines_data[nn+13]["val"] = range_max + nn*lastRange/8
                            end
                            increment = 1
                        end

                        for nn = 5, 13, increment do
                            local value = range_min + (nn-5)*lastRange/8
                            SetValue(index-cl_width, nn, value)
                            lines_data[nn]["val"] = value
                        end

                        for nn = 3, 15 do
                            lines_data[nn]["index"] = index-cl_width
                        end

                    end
                end

                if show_zz_levels == 1 then

                    local add
                    local nn = 0
                    local addedZZ = {}
                    for nz = 1, zz_levels_to_show do
                        if zz_data[nzz-nz+1] then
                            nn = nn + 1
                            if close > zz_data[nzz-nz+1]["val"] then
                                add = -40
                            else add = 0
                            end
                            addedZZ[zz_data[nzz-nz+1]["index"]] = 1
                            SetValue(zz_data[nzz-nz+1]["index"], all_lines-nn+1+add, zz_data[nzz-nz+1]["val"])
                            lines_data[all_lines-nn+1+add]["val"]   = zz_data[nzz-nz+1]["val"]
                            lines_data[all_lines-nn+1+add]["index"] = zz_data[nzz-nz+1]["index"]
                        end
                    end

                    if price_level then
                        for nr = range_min_index, range_max_index do
                            nn = nn + 1
                            if addedZZ[sorted_zz_levels[nr]["index"]] == nil then
                                if sorted_zz_levels[nr] then
                                    if close > sorted_zz_levels[nr]["val"] then
                                        add = -40
                                    else add = 0
                                    end
                                    SetValue(sorted_zz_levels[nr]["index"], all_lines-nn+1+add, sorted_zz_levels[nr]["val"])
                                    lines_data[all_lines-nn+1+add]["val"]   = sorted_zz_levels[nr]["val"]
                                    lines_data[all_lines-nn+1+add]["index"] = sorted_zz_levels[nr]["index"]
                                end
                            end
                        end
                    end

                end

                if show_target_zone == 1 then

                    local targetE, evE, mutE = get_pattern(zz_data)
                    -- myLog('targetE', targetE, evE, mutE)
                    if (targetE or 0) ~= 0 then

                        if targetE == pD then targetE = nil end

                        SetValue(index-tm_width, 22, targetE)
                        lines_data[22]["val"] = targetE
                        lines_data[22]["index"] = index-tm_width

                        SetValue(index-tm_width, 23, evE)
                        lines_data[23]["val"] = evE
                        lines_data[23]["index"] = index-tm_width

                        SetValue(index-tm_width, 24, mutE)
                        lines_data[24]["val"] = mutE
                        lines_data[24]["index"] = index-tm_width
                    else

                        local mean_range    = 0
                        local quant_range   = 0

                        for nmt = 1, moves_for_target*2-1, 2 do
                            if zz_data[nzz-nmt -1] then
                                mean_range = mean_range + math_abs(zz_data[nzz-nmt]["val"] - zz_data[nzz-nmt -1]["val"])
                                quant_range = quant_range + 1
                            end
                        end

                        -- myLog('quant_range', quant_range, 'pD', pD, 'pC', pC)

                        if quant_range ~= 0 then

                            if pD > pC then
                                mean_range = mean_range/quant_range
                            else
                                mean_range = -1*mean_range/quant_range
                            end

                            local outT1 = pD + mean_range*(1 - target_zone_spread/100)
                            SetValue(index-tm_width, 16, outT1)
                            lines_data[16]["val"] = outT1
                            lines_data[16]["index"] = index-tm_width
                            local outT2 = pD + mean_range*(1 + target_zone_spread/100)
                            SetValue(index-tm_width, 17, outT2)
                            lines_data[17]["val"] = outT2
                            lines_data[17]["index"] = index-tm_width

                        end
                    end

                end

                if show_fibo_ext == 1 then

                    if zz_data[nzz-3]  then

                        local fibo = getFiboExtention(last_trend, pA, pB, pC, fibo_ext)
                        local fibo_marks_width = math_max(index - iB, tm_width)

                        for i, value in ipairs(fibo_levels) do
                            local out_fibo = fibo[value]
                            if out_fibo then
                                if i > 2 then
                                    -- myLog('fibo', i, value, out_fibo, 'prev', fibo_levels[i-1], fibo[fibo_levels[i-1]])
                                    out_fibo = last_trend*(close - fibo[fibo_levels[i-1]]) > 0 and out_fibo or nil
                                end
                                out_fibo = (out_fibo and out_fibo > 0) and out_fibo or nil
                            end
                            SetValue(index-fibo_marks_width, 18 + i - 1, out_fibo)
                            lines_data[18 + i - 1]["val"]   = out_fibo
                            lines_data[18 + i - 1]["index"] = index-fibo_marks_width
                        end
                    end

                end

                local labelAtHigh = math_abs(close - range_max) < math_abs(close - range_min)

                if show_label == 1 and chart_id ~= '' then

                    local l_date, l_time = getCandleProp(index-label_shift)
                    local firsY
                    local secondY
                    local thirdY

                    if labelAtHigh then
                        firsY = range_max + 3*(range_max - range_min)/17
                        secondY = firsY - (range_max - range_min)/17
                        thirdY = secondY - (range_max - range_min)/17
                    else
                        firsY = range_min - (range_max - range_min)/17
                        secondY = firsY - (range_max - range_min)/17
                        thirdY = secondY - (range_max - range_min)/17
                    end

                    label1.YVALUE = firsY

                    local upIntervals = 0
                    local upcount = 0
                    local downIntervals = 0
                    local downcount = 0

                    for nmt = 0, moves_for_target*2-1, 2 do
                        if zz_data[nzz-nmt -1] then
                            if zz_data[nzz-nmt]["val"] > zz_data[nzz-nmt -1]["val"] then
                                upIntervals = upIntervals + zz_data[nzz-nmt]["index"] - zz_data[nzz-nmt -1]["index"]
                                upcount = upcount + 1
                            else
                                downIntervals = downIntervals + zz_data[nzz-nmt]["index"] - zz_data[nzz-nmt -1]["index"]
                                downcount = downcount + 1
                            end
                        end
                    end

                    --первая метка
                    label1.DATE = l_date
                    label1.TIME = l_time
                    local text = "B/XA "..tostring(ABtoXA)..", C/XA "..tostring(XCtoXA)..", D/XA "..tostring(ADtoXA)..", BC/AB "..tostring(BCtoAB)..", CD/AB "..tostring(CDtoAB)
                    label1.TEXT = text

                    if AddedLabels[1] then
                        SetLabelParams(chart_id, AddedLabels[1], label1)
                    else
                        local LabelID = AddLabel(chart_id, label1)

                        if LabelID  and LabelID ~= -1 then
                            AddedLabels[1] = LabelID --#AddedLabels+1
                        end
                    end

                    --вторая метка
                    label2.DATE = l_date
                    label2.TIME = l_time
                    label2.YVALUE = secondY
                    l2_text1 = "now "..tostring(cur_deviation).."%, ".."XA "..tostring(XA)..", AB "..tostring(AB)..", BC "..tostring(BC)..", CD "..tostring(CD)
                    if upcount ~= 0 and pC < close then
                        l2_text1 = l2_text1..", upInt "..tostring(math.ceil(upIntervals/upcount)).."/"..tostring(iD - iC)
                    end
                    if downcount ~= 0 and pC > close  then
                        l2_text1 = l2_text1..", downInt "..tostring(math.ceil(downIntervals/downcount)).."/"..tostring(iD - iC)
                    end
                    label2.TEXT = l2_text1.."/"..tostring(index - last_extr.index)

                    if AddedLabels[2] then
                        SetLabelParams(chart_id, AddedLabels[2], label2)
                    else
                        local label_id = AddLabel(chart_id, label2)

                        if label_id and label_id ~= -1 then
                            AddedLabels[2] = label_id --#AddedLabels+1
                        end
                    end

                    --третья метка
                    label3.DATE = l_date
                    label3.TIME = l_time
                    label3.YVALUE = thirdY
                    l3_text1 = "Volume XA: "..money_value(vXA).."; AB: "..money_value(vAB).."; BC: "..money_value(vBC).."; CD: "..money_value(vCD)
                    label3.TEXT = l3_text1..'; now: '..money_value(now_vol)

                    if AddedLabels[3] then
                        SetLabelParams(chart_id, AddedLabels[3], label3)
                    else
                        local label_id = AddLabel(chart_id, label3)
                        if label_id and label_id ~= -1 then
                            AddedLabels[3] = label_id --#AddedLabels+1
                        end
                    end

                end

                -- выводим центр движения
                if show_cog == 1 then

                    for nn = 0, show_cog_to_show - 1 do
                        if zz_data[nzz-nn - 1] then
                            local IndCoG = math.floor((zz_data[nzz-nn]["index"] + zz_data[nzz-nn-1]["index"])/2)
                            local valCoG = (zz_data[nzz-nn]["val"] + zz_data[nzz-nn-1]["val"])/2
                            SetValue(IndCoG, 2, valCoG)
                            cog_points[nn+1] = IndCoG
                        end
                    end

                end

                if show_andrews == 1 and (nzz > 3+andrews_shift) then

                    for nn = 29, 31 do
                        SetValue(lines_data[nn]["index"], nn, nil)
                    end
                    -- myLog('Set', lines_data[30]["index"], 'nil')

                    local p1 = zz_data[nzz-2-andrews_shift]["val"]
                    local p2 = zz_data[nzz-1-andrews_shift]["val"]
                    local p3 = zz_data[nzz-andrews_shift]["val"]
                    local i1 = zz_data[nzz-2-andrews_shift]["index"]
                    local i2 = zz_data[nzz-1-andrews_shift]["index"]
                    local i3 = zz_data[nzz-andrews_shift]["index"]

                    local pc = (p2 + p3)/2
                    local ic = math.floor((i2 + i3)/2)
                    andr_d   = (pc - p1)/(ic-i1)

                    local c1    = p1 + andr_d*(index-i1+1)
                    SetValue(i1, 29, p1)
                    SetValue(index, 29, c1)
                    lines_data[29]["index"] = i1
                    lines_data[29]["val"]   = c1

                    local c2    = p2 + andr_d*(index-i2+1)
                    SetValue(i2, 30, p2)
                    SetValue(index, 30, c2)
                    lines_data[30]["index"] = i2
                    lines_data[30]["val"]   = c2

                    local c3    = p3 + andr_d*(index-i3+1)
                    SetValue(i3, 31, p3)
                    SetValue(index, 31, c3)
                    lines_data[31]["index"] = i3
                    lines_data[31]["val"]   = c3

                    -- myLog('Set', 'first', lines_data[30]["index"], '=', p1, 'index', index, '=', lines_data[30]["val"])

                end

            end

            if show_label == 1 and last and not calculated_buffer[index] then
                if last_extr.index ~= index then
                    now_vol = now_vol + V(index-1)
                end
                local l_date, l_time = getCandleProp(index-label_shift)
                if label1 and AddedLabels[1] then
                    label1.DATE = l_date
                    label1.TIME = l_time
                    SetLabelParams(chart_id, AddedLabels[1], label1)
                end
                if label2 and AddedLabels[2] then
                    label2.DATE = l_date
                    label2.TIME = l_time
                    label2.TEXT = l2_text1.."/"..tostring(index - last_extr.index)
                    SetLabelParams(chart_id, AddedLabels[2], label2)
                end
                if label3 and AddedLabels[3] then
                    label3.DATE = l_date
                    label3.TIME = l_time
                    label3.TEXT = l3_text1..', now: '..money_value(now_vol)
                    SetLabelParams(chart_id, AddedLabels[3], label3)
                end
            end

            calculated_buffer[index] = true

            if nzz > 4 then
                SetValue(last_extr.index, 25, last_extr.val)
            end
            if last_extr and last_extr.index == index then
                lines_data[1]["val"]    = last_extr.val
                lines_data[25]["val"]   = last_extr.val
                lines_data[25]["index"] = last_extr.index
            end

        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
            return nil
        end

        -- myLog('ret', index, '30', lines_data[30]["val"])

        return	lines_data[1]["val"], lines_data[2]["val"], lines_data[3]["val"], lines_data[4]["val"], lines_data[5]["val"], lines_data[6]["val"], lines_data[7]["val"], lines_data[8]["val"], lines_data[9]["val"], lines_data[10]["val"],
        lines_data[11]["val"], lines_data[12]["val"], lines_data[13]["val"], lines_data[14]["val"], lines_data[15]["val"], lines_data[16]["val"], lines_data[17]["val"], lines_data[18]["val"], lines_data[19]["val"], lines_data[20]["val"],
        lines_data[21]["val"], lines_data[22]["val"], lines_data[23]["val"], lines_data[24]["val"], lines_data[25]["val"], lines_data[26]["val"], lines_data[27]["val"], lines_data[28]["val"], lines_data[29]["val"], lines_data[30]["val"],
        lines_data[31]["val"], lines_data[32]["val"], lines_data[33]["val"], lines_data[34]["val"], lines_data[35]["val"], lines_data[36]["val"], lines_data[37]["val"], lines_data[38]["val"], lines_data[39]["val"], lines_data[40]["val"],
        lines_data[41]["val"], lines_data[42]["val"], lines_data[43]["val"], lines_data[44]["val"], lines_data[45]["val"], lines_data[46]["val"], lines_data[47]["val"], lines_data[48]["val"], lines_data[49]["val"], lines_data[50]["val"],
        lines_data[51]["val"], lines_data[52]["val"], lines_data[53]["val"], lines_data[54]["val"], lines_data[55]["val"], lines_data[56]["val"], lines_data[57]["val"], lines_data[58]["val"], lines_data[59]["val"], lines_data[60]["val"],
        lines_data[61]["val"], lines_data[62]["val"], lines_data[63]["val"], lines_data[64]["val"], lines_data[65]["val"], lines_data[66]["val"], lines_data[67]["val"], lines_data[68]["val"], lines_data[69]["val"], lines_data[60]["val"],
        lines_data[71]["val"], lines_data[72]["val"], lines_data[73]["val"], lines_data[74]["val"], lines_data[75]["val"], lines_data[76]["val"], lines_data[77]["val"], lines_data[78]["val"], lines_data[79]["val"], lines_data[70]["val"],
        lines_data[81]["val"], lines_data[82]["val"], lines_data[83]["val"], lines_data[84]["val"], lines_data[85]["val"], lines_data[86]["val"], lines_data[87]["val"], lines_data[88]["val"], lines_data[89]["val"], lines_data[80]["val"],
        lines_data[91]["val"], lines_data[92]["val"], lines_data[93]["val"], lines_data[94]["val"], lines_data[95]["val"], lines_data[96]["val"], lines_data[97]["val"], lines_data[98]["val"], lines_data[99]["val"], lines_data[100]["val"],
        lines_data[101]["val"], lines_data[102]["val"], lines_data[103]["val"], lines_data[104]["val"], lines_data[105]["val"], lines_data[106]["val"], lines_data[107]["val"], lines_data[108]["val"], lines_data[109]["val"],
        lines_data[110]["val"], lines_data[111]["val"], lines_data[112]["val"], lines_data[113]["val"]
    end
end

function _G.Init()
    add_lines()
    for i = 34, 73 do
		_G.Settings.line[i] = {Color = RGB(0, 128, 255), Type = TYPE_DASH, Width = 1}
	end
	for i = 74, 113 do
		_G.Settings.line[i] = {Color = RGB(255, 64, 0), Type = TYPE_DASH, Width = 1}
	end
    local all_lines = #_G.Settings.line
    PlotLines = Algo(_G.Settings, all_lines)
    return all_lines
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index)
end

function _G.OnDestroy()
	if chart_id ~= '' then
		DelAllLabels(chart_id)
	end
end