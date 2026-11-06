--[[
    nick-h@yandex.ru
    https://github.com/nick-nh/qlua

   Индикатор для трейдеров, который помогает устанавливать динамические стоп-уровни.
   Его разработала Синтия Кейс (Cynthia Kase) — специалист по техническому анализу и управлению рисками.
   Идея в том, чтобы стоп-уровень сам подстраивался под волатильность рынка: расширялся, когда рынок нервничает, и сужался в спокойные периоды.

   https://docs.wickra.org/Indicators/Indicator-KaseDevStop
]]

_G.load   = _G.loadfile or _G.load

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\KaseDevStops.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
-- local os_time       = os.time

local O             = _G['O']
local C             = _G['C']
local H             = _G['H']
local L             = _G['L']
-- ======================== НАСТРОЙКИ ========================
_G.Settings = {
    Name        = "*KaseDevStops",
    -- Периоды расчёта (значения по умолчанию, рекомендованные Cynthia Kase)
    ['1. Период среднего и TRD']    = 20,      -- numBars: период для среднего и стандартного отклонения TRD
    ['2. Расчет SMA для тренда. Подсказка:'] = 'Указать периоды и тип данных',
    ['2.1 Период быстрой SMA']      = 10,      -- barsInFMA: быстрая MA для определения направления
    ['2.2 Период медленной SMA']    = 21,      -- barsInSMA: медленная MA для определения направления
    ['3. Типы данных']              = 'O, H, L, C, M (Median), T (Typical), W (Weighted)',
    ['3.1 Тип данных SMA']          = 'C',     -- Close

    -- Множители стандартного отклонения для линий
    ['4. Множители. Подсказка:']     = 'Значение 0 - не показывать',
    ['4.0 Показывать Warning']       = 1,       -- Warning Line (часто 0.0, т.е. просто среднее)
    ['4.1 Множитель STD для Dev1']   = 1.0,     -- Dev1
    ['4.2 Множитель STD для Dev2']   = 2.2,     -- Dev2
    ['4.3 Множитель STD для Dev3']   = 3.6,     -- Dev3 (самый широкий стоп)

    -- Настройки отображения (4 линии)
    line = {
        { Name = 'Warning', Color = RGB(128, 128, 128), Type = TYPE_LINE, Width = 1 },
        { Name = 'Dev1',    Color = RGB(167, 1, 30),    Type = TYPE_LINE, Width = 1 },
        { Name = 'Dev2',    Color = RGB(255, 128, 164), Type = TYPE_LINE, Width = 2 },
        { Name = 'Dev3',    Color = RGB(0, 128, 255),   Type = TYPE_LINE, Width = 2 }
    }
}
-- ===========================================================

local PlotLines     = function(index) return index end
local error_log     = {}
local lines         = #_G.Settings.line

local function log_tostring(...)
    local args = table.pack(...)
    if args.n == 1 then
        return tostring(args[1])
    end
    for i = 1, args.n do
        args[i] = tostring(args[i])
    end
    return table.concat(args, " ", 1, args.n)
end

function log(...)
    if logFile == nil then return end
    logFile:write(log_tostring(...).."\n")
    logFile:flush()
end

------------------------------------------------------------------
-- БЛОК РАСЧЁТА KASE DEVSTOPS
------------------------------------------------------------------
local df = {}
df['C'] = function(i) return _G.C(i) end
df['H'] = function(i) return _G.H(i) end
df['L'] = function(i) return _G.L(i) end
df['O'] = function(i) return _G.O(i) end
df['M'] = function(i) return (_G.H(i) + _G.L(i))/2 end
df['T'] = function(i) return (_G.H(i) + _G.L(i) + _G.O(i))/3 end
df['W'] = function(i) return (_G.H(i) + _G.L(i) + _G.O(i) + _G.C(i))/4 end

local function F_SUM(settings)

    local period    = (settings.period or 9)
    local save_bars = (settings.save_bars or period)

    local S_ACC = {}
    local S_TMP = {}
    local bars  = 0
    local l_index
    return function(index, val)
        S_TMP[index]    = S_TMP[index-1] or 0
        if not val then
            return S_TMP
        end
        if l_index ~= index then
            S_ACC[#S_ACC + 1] = (S_ACC[#S_ACC] or 0) + val
            l_index = index
            bars = bars + 1
        else
            S_ACC[#S_ACC] = (S_ACC[#S_ACC - 1] or 0) + val
        end
        if bars > period then
            if #S_ACC > period + 1 then table.remove(S_ACC, 1) end
            S_TMP[index] = S_ACC[#S_ACC] - (S_ACC[1] or 0)
        else
            S_TMP[index] = S_ACC[#S_ACC]
        end
        S_TMP[index-save_bars] = nil
        return S_TMP
    end, S_TMP, S_ACC
end

local function F_SMA(settings)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close"):upper():sub(1,1)
    local save_bars = settings.save_bars or period

    local fSum      = F_SUM(settings)
    local SMA_TMP   = {}
    local bars      = 0
    local l_index
    return function(index)
        SMA_TMP[index]  = SMA_TMP[index-1] or 0
        local val = df[data_type](index)
        if not val then return SMA_TMP end
        local sum = fSum(index, val)[index]
        if l_index ~= index then
            l_index = index
            bars = bars + 1
        end
        bars            = bars < period and bars or period
        SMA_TMP[index]  = sum/bars
        SMA_TMP[index-save_bars] = nil
        return SMA_TMP
    end, SMA_TMP
end

local function CalcProcessor(settings)

    -- Параметры
    local period      = settings['1. Период среднего и TRD']      or 30
    local fast_period = settings['2.1 Период быстрой SMA'] or 10
    local slow_period = settings['2.2 Период медленной SMA'] or 21
    local data_type   = settings['3.1 Тип данных SMA'] or 'C'

    local mults = {
        settings['4.0. Показывать Warning'] or 1,
        settings['4.1. Множитель STD для Dev1'] or 1.0,
        settings['4.2. Множитель STD для Dev2'] or 2.2,
        settings['4.3. Множитель STD для Dev3'] or 3.6
    }

    local last_index
    local trend = {0, 0}
    local high  = {0, 0}
    local low   = {0, 0}

    -- Состояние тренда
    local pivot_high  = {0, 0}  -- экстремум с момента последнего переворота (для лонга)
    local pivot_low   = {0, 0}  -- экстремум с момента последнего переворота (для шорта)

    local ffMA, fast_ma     = F_SMA({period = fast_period, data_type = data_type})
    local sfMA, slow_ma     = F_SMA({period = slow_period, data_type = data_type})

    local tfSum, trd_sum, trd_acc  = F_SUM({period = period})
    local ttfSum, trd_sum_sq       = F_SUM({period = period})

    -- Буфер для хранения последних значений линий (чтобы не пересчитывать каждый раз)
    local out = { nil, nil, nil, nil }

    return function(index)

        if index ~= last_index then
            high[1]         = high[2]
            low[1]          = low[2]
            trend[1]        = trend[2]
            pivot_high[1]   = pivot_high[2]
            pivot_low[1]    = pivot_low[2]
        end
        -- -------------------------------------------------
        -- 1. Получаем данные текущего бара (цены уже доступны в глобальном контексте Quik)
        --    H(index), L(index) — high, low
        -- -------------------------------------------------
        high[2] = H(index)
        low[2]  = L(index)

        if not high[2] or not low[2] then
            return out
        end

        -- -------------------------------------------------
        -- 2. Расчёт двухбарного истинного диапазона (TRD)
        --    TRD_t = max(high_t, high_{t-1}) - min(low_t, low_{t-1})
        -- -------------------------------------------------
        local trd_value = nil
        if high[1] ~= nil and low[1] ~= nil then
            local max_h = math.max(high[2], high[1])
            local min_l = math.min(low[2], low[1])
            trd_value   = max_h - min_l
        end

        log('new index', index, 'trd_value', trd_value)

        if not trd_value then return out end
        -- -------------------------------------------------
        -- 3. Накопление статистики TRD (среднее и стандартное отклонение)
        -- -------------------------------------------------
        tfSum(index, trd_value)
        ttfSum(index, trd_value*trd_value)

        -- -------------------------------------------------
        -- 4. Расчёт быстрой и медленной MA для определения направления
        --    Используем простые скользящие средние (SMA) по ценам закрытия.
        -- -------------------------------------------------
        ffMA(index)
        sfMA(index)

        -- Определение направления
        trend[2] = trend[1]
        if fast_ma[index] and slow_ma[index] then
            if fast_ma[index] > slow_ma[index] then
                trend[2] = 1
            elseif fast_ma[index] < slow_ma[index] then
                trend[2] = -1
            end
            -- Если равны, оставляем предыдущий тренд
        end

        -- Если тренд ещё не определён, выходим
        if trend[2] == 0 then
            return out
        end

        -- -------------------------------------------------
        -- 5. Обновление экстремумов (pivot) с учётом направления
        -- -------------------------------------------------
        if trend[2] > 0 then
            -- Восходящий тренд: отслеживаем максимум high с момента переворота
            if pivot_high[1] == nil then
                pivot_high[2] = high[2]
            else
                pivot_high[2] = math.max(pivot_high[1], high[2])
            end
            -- При смене направления сбрасываем противоположный экстремум
            pivot_low[2] = nil
        else
            -- Нисходящий тренд: отслеживаем минимум low с момента переворота
            if pivot_low[1] == nil then
                pivot_low[2] = low[2]
            else
                pivot_low[2] = math.min(pivot_low[1], low[2])
            end
            pivot_high[2] = nil
        end

        -- -------------------------------------------------
        -- 6. Расчёт среднего и стандартного отклонения TRD
        -- -------------------------------------------------
        local mean_trd = nil
        local std_trd  = nil

        if #trd_acc == period + 1 then
            mean_trd = trd_sum[index] / period
            local variance = (trd_sum_sq[index] / period) - (mean_trd * mean_trd)
            if variance < 0 then variance = 0 end -- защита от отрицательных значений из-за погрешности
            std_trd = math.sqrt(variance)
        end

        -- Если статистики ещё недостаточно, возвращаем nil для линий
        if mean_trd == nil or std_trd == nil then
            return out
        end

        -- -------------------------------------------------
        -- 7. Расчёт линий DevStops
        --    Для восходящего тренда: стопы ниже цены (pivot_high - band)
        --    Для нисходящего тренда: стопы выше цены (pivot_low + band)
        -- -------------------------------------------------
        local function calc_stop(m)
            if not m then return end
            if mults[m] == 0 then return end
            local band = mean_trd + (m == 1 and 0 or mults[m]) * std_trd
            if trend[2] > 0 then
                -- Восходящий тренд: стоп под ценой, "собачка" вверх (ratchet up)
                return pivot_high[2] - band
            else
                -- Нисходящий тренд: стоп над ценой, "собачка" вниз (ratchet down)
                return pivot_low[2] + band
            end
        end

        -- Рассчитываем все четыре линии
        out[1] = calc_stop(1) -- Warning
        out[2] = calc_stop(2) -- Dev1
        out[3] = calc_stop(3) -- Dev2
        out[4] = calc_stop(4) -- Dev3

        -- log(index, os.date('%Y-%m-%d %H:%M', os.time(_G.T(index))), 'trend', trend[2], 'mean_trd', mean_trd, 'std_trd', std_trd, 'out', table.unpack(out, 1, lines))

        last_index = index

        return out
    end
end

------------------------------------------------------------------
-- СТАНДАРТНЫЕ ФУНКЦИИ ШАБЛОНА
------------------------------------------------------------------

local function Algo(settings)

    settings           = (settings or {})
    error_log = {}

    local fMA, err
    local out = {}
    local begin_index

    return function (index)

        local status, res = pcall(function()

            if fMA == nil or index == begin_index then
                begin_index = index
                fMA, err  = CalcProcessor(settings)
                if not fMA and not error_log[tostring(err)] then
                    error_log[tostring(err)] = true
                    log(tostring(err))
                    message(tostring(err))
                end
                fMA(index)
                return
            end
            if fMA then
                out = fMA(index)
            end

        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                log(tostring(res))
                message(tostring(res))
            end
            return nil
        end
        return table.unpack(out, 1, lines)
    end
end

function _G.Init()
    PlotLines = Algo(_G.Settings)
    return lines
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index)
end