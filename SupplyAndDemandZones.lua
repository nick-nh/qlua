--[[
    edgeful - supply and demand zones

    Этот индикатор автоматически рисует зоны предложения (потенциальное сопротивление) и зоны спроса (потенциальную поддержку) на вашем графике.
    Он использует одно строгое правило: зона создаётся только тогда, когда рынок производит измеримый импульсный сдвиг от свечи.
    Свеча, непосредственно предшествующая этому импульсу, сохраняется как зона — область, где цена была в последний раз сбалансирована до возникновения дисбаланса.

    Зоны определяются исключительно тем, насколько большой свеча относительно недавней волатильности.

    Как обнаруживается зона:

    1. Базовая волатильность. ATR (длина по умолчанию 14) измеряет «нормальный» размер свечи для текущего рыночного режима.
    2. Импульсный тест. Тело каждой закрытой свечи сравнивается с ATR. Свеча рассматривается как импульс только если её тело имеет импульсную силу не менее × ATR (по умолчанию 1,5× ATR). Фитили здесь игнорируются — фитили отражают отторжение, а не обязательство.
    3. Исходная свеча. Когда бычий импульс закрывается, последняя медвежья или додзи-свеча перед ней становится зоной спроса. Когда медвежий импульс закрывается, последняя бычья или додзи-свеча перед ней становится зоной предложения.
    4. Геометрия зоны. По умолчанию зона — это тело исходной свечи (диапазон от открытия до закрытия). Включение «3. Построение Зоны» = HL расширяет его до полного диапазона свечи (от High до Low) для более консервативных входов с более глубокими стопами.

    Когда зона удаляется:

    — C (закрытие) (по умолчанию) — зона удаляется только тогда, когда свеча закрывается за дальним краем. Фильтрует внутрибарные фитили, которые фактически не нарушают структуру.
    - HL  — зона убирается, как только фитиль пробивает дальний край. Более строго, меньше сохранившихся зон, но быстрее реагирует на ликвидность.

    https://www.tradingview.com/script/vOpLnN91-edgeful-supply-and-demand-zones/
]]

_G.load   = _G.loadfile or _G.load

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\SDZones.txt", "w")

local message           = _G['message']
local RGB               = _G['RGB']
-- local TYPE_LINE      = _G['TYPE_LINE']
local SetRangeValue     = _G['SetRangeValue']

-- Доступ к OHLC (поддержка коротких и длинных имён)
local _O = _G.O
local _H = _G.H
local _L = _G.L
local _C = _G.C

-- Параметры
local MAX_DEMAND     = 15
local MAX_SUPPLY     = 15
local N_DEMAND_LINES = MAX_DEMAND * 2
local N_SUPPLY_LINES = MAX_SUPPLY * 2
local N_TOTAL_LINES  = N_DEMAND_LINES + N_SUPPLY_LINES

_G.Settings = {
    Name = "*Supply and demand zones",
    ['1. Период ATR']                   = 14,
    ['2. Коэффициент импульса (*ATR)']  = 1.5,
    ['3. Построение Зоны. Варианты: ']  = 'B = тело свечи, HL = high - low',
    ['3.1 Зона']                        = 'HL',
    ['4. Пробой зоны. Варианты: ']      = 'С = закрытием свечи, HL = high или low свечи',
    ['4.1 Метод']                       = 'C',
    ['5. Минимальные значенения зоны']  = 'если 0 - фильтр отключен',
    ['6. Мин. ширина зоны в ATR']       = 0.3,
    ['7. Мин. расстояние между центрами зон в ATR'] = 0.3,
    ['8. Мин. ширина зоны в пунктах']   = 0,
    line = {},
}

local demandColor = RGB(0, 200, 0)
local supplyColor = RGB(220, 50, 50)

for i = 1, N_DEMAND_LINES do
    local z, tp = math.ceil(i / 2), (i % 2 == 1)
    table.insert(_G.Settings.line, {
        Name  = "Demand" .. z .. (tp and "Up" or "Dw"),
        Color = demandColor, Type = _G.TYPET_BAR, Width = 1,
    })
end
for i = 1, N_SUPPLY_LINES do
    local z, tp = math.ceil(i / 2), (i % 2 == 1)
    table.insert(_G.Settings.line, {
        Name  = "Supply" .. z .. (tp and "Up" or "Dw"),
        Color = supplyColor, Type = _G.TYPET_BAR, Width = 1,
    })
end

local lines     = N_TOTAL_LINES
local error_log = {}

local function log_tostring(...)
    local a = table.pack(...)
    if a.n == 1 then return tostring(a[1]) end
    for i = 1, a.n do a[i] = tostring(a[i]) end
    return table.concat(a, " ", 1, a.n)
end
function log(...)
    if logFile == nil then return end
    logFile:write(log_tostring(...) .. "\n"); logFile:flush()
end

-- ?? Ядро: детект зон по закрытым барам ????????????????????????????????????
local function CalcProcessor(settings, begin_index)
    settings = settings or {}
    local atr_period    = settings['1. Период ATR'] or 14
    local art_mult      = settings['2. Коэффициент импульса (*ATR)'] or 1.5
    local use_body      = (settings['3.1 Зона'] or 'B') == 'B'
    local mitigation    = (settings['4.1 Метод'] or 'HL') == 'HL' and 1 or 0

    local min_zone_atr  = settings['6. Мин. ширина зоны в ATR'] or 0
    local min_gap_atr   = settings['7. Мин. расстояние между центрами зон в ATR']   or 0
    local min_zone_pts  = settings['8. Мин. ширина зоны в пунктах'] or 0

    local lastBearTop, lastBearBot, lastBearIdx = nil, nil, nil
    local lastBullTop, lastBullBot, lastBullIdx = nil, nil, nil

    local demandSlots, supplySlots = {}, {}
    for i = 1, MAX_DEMAND do demandSlots[i] = nil end
    for i = 1, MAX_SUPPLY do supplySlots[i] = nil end

    local next_bar      = begin_index
    local last_index    = begin_index
    local out           = {}

    local function clear_demand_zone(s, z, index)
        local ul = (s - 1) * 2 + 1
        local dl = (s - 1) * 2 + 2
        SetRangeValue(ul, z.startIdx, index, nil)
        SetRangeValue(dl, z.startIdx, index, nil)
        out[ul] = nil
        out[dl] = nil
        log('index', index, os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), 'clear зоны', z.type, ul, dl, 'slot', s, 'from index', z.startIdx, z.bot, z.top)
    end
    local function clear_supply_zone(s, z, index)
        local ul = N_DEMAND_LINES + (s - 1) * 2 + 1
        local dl = N_DEMAND_LINES + (s - 1) * 2 + 2
        SetRangeValue(ul, z.startIdx, index, nil)
        SetRangeValue(dl, z.startIdx, index, nil)
        out[ul] = nil
        out[dl] = nil
        log('index', index, os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), 'clear зоны', z.type, ul, dl, 'slot', s, 'from index', z.startIdx, z.bot, z.top)
    end


    -- TR бара i (pc = close предыдущего, либо close самого бара для самого первого)
    local atr_value, atr_count, atr_sum = nil, 0, 0
    local function getTR(i)
        local h, l = _H(i), _L(i)
        local pc   = (i > begin_index) and _C(i - 1) or _C(i)
        return math.max(h - l, math.abs(h - pc), math.abs(l - pc))
    end

    -- Ширина зоны проходит все активные фильтры?
    local function passes_width_filter(top, bot)
        local w = top - bot
        if atr_value and min_zone_atr > 0 and w < atr_value * min_zone_atr then
            return false
        end
        if min_zone_pts > 0 and w < min_zone_pts then
            return false
        end
        return true
    end

    -- Центр новой зоны слишком близко к центру уже существующей?
    local function too_close(slots, maxN, center, minDist)
        if minDist <= 0 then return false end
        for s = 1, maxN do
            local z = slots[s]
            if z then
                if math.abs(z.center - center) < minDist then return true end
            end
        end
        return false
    end

    local function process_demand_zone(index)
        if not passes_width_filter(lastBearTop, lastBearBot) then return end
        local center = (lastBearTop + lastBearBot) * 0.5
        local minDist = atr_value and atr_value * min_gap_atr or 0
        if too_close(demandSlots, MAX_DEMAND, center, minDist) then return end
        local slot
        for s = 1, MAX_DEMAND do
            if not demandSlots[s] then slot = s; break end
        end
        if not slot then                       -- все заняты ? вытесняем самую старую
            local oldest, os = 1, math.huge
            for s = 1, MAX_DEMAND do
                local z = demandSlots[s]
                if z and z.startIdx < os then
                    -- clear_demand_zone(s, z, index)
                    os = z.startIdx
                    oldest = s
                end
            end
            slot = oldest
        end
        demandSlots[slot] = { type = 'demand', top = lastBearTop, bot = lastBearBot, center = (lastBearTop + lastBearBot)*0.5, startIdx = index }
        log('index', index, os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), 'new demand-зона', slot, lastBearBot, lastBearTop)
    end
    local function process_supply_zone(index)
        if not passes_width_filter(lastBullTop, lastBullBot) then return end
        local center = (lastBullTop + lastBullBot) * 0.5
        local minDist = atr_value and atr_value * min_gap_atr or 0
        if too_close(supplySlots, MAX_SUPPLY, center, minDist) then return end
        local slot
        for s = 1, MAX_SUPPLY do
            if not supplySlots[s] then slot = s; break end
        end
        if not slot then
            local oldest, os = 1, math.huge
            for s = 1, MAX_SUPPLY do
                local z = supplySlots[s]
                if z and z.startIdx < os then
                    -- clear_supply_zone(s, z, index)
                    os = z.startIdx
                    oldest = s
                end
            end
            slot = oldest
        end
        supplySlots[slot] = { type = 'supply', top = lastBullTop, bot = lastBullBot, center = (lastBullTop + lastBullBot)*0.5, startIdx = index }
        log('index', index, os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), 'new supply-зона', slot, lastBullBot, lastBullTop)
    end

    -- Обработка бара i как ЗАКРЫТОГО
    local function processClosedBar(index)
        -- 1. ATR (Wilder RMA, как ta.atr)
        local tr = getTR(index)
        if atr_count < atr_period then
            atr_count = atr_count + 1
            atr_sum   = atr_sum + tr
            atr_value = atr_sum / atr_count
            return
        else
            atr_value = atr_value + (tr - atr_value) / atr_period
        end

        -- 2. Трекеры последней противоположной свечи (по i-1)
        if index > begin_index then
            local pO, pC = _O(last_index), _C(last_index)
            local pH, pL = _H(last_index), _L(last_index)
            if pC > pO then
                lastBullTop = use_body and math.max(pO, pC) or pH
                lastBullBot = use_body and math.min(pO, pC) or pL
                lastBullIdx = last_index
            end
            if pC < pO then
                lastBearTop = use_body and math.max(pO, pC) or pH
                lastBearBot = use_body and math.min(pO, pC) or pL
                lastBearIdx = last_index
            end
        end

        -- 3. Импульс на баре i
        local open, close   = _O(index), _C(index)
        local body          = math.abs(close - open)
        local isBull        = close > open
        local isBear        = close < open
        local isImp         = atr_value and body > 0 and (body >= atr_value * art_mult) or false

        -- 4. Создание demand-зоны
        if isImp and isBull and lastBearIdx then
            process_demand_zone(index)
        end

        -- 5. Создание supply-зоны
        if isImp and isBear and lastBullIdx then
            process_supply_zone(index)
        end

        -- 6. Митигация
        local demandBreak = (mitigation == 0) and close or _L(index)
        local supplyBreak = (mitigation == 0) and close or _H(index)

        for s = 1, MAX_DEMAND do
            local z = demandSlots[s]
            if z and demandBreak < z.bot then
                clear_demand_zone(s, z, index)
                demandSlots[s] = nil
            end
        end
        for s = 1, MAX_SUPPLY do
            local z = supplySlots[s]
            if z and supplyBreak > z.top then
                clear_supply_zone(s, z, index)
                supplySlots[s] = nil
            end
        end
        last_index = index
    end

    return function(index)
        -- Обрабатываем все бары, которые уже закрылись (i < index)
        while next_bar < index do
            processClosedBar(next_bar)
            next_bar = next_bar + 1
        end

        -- Вывод для текущего бара = состояние после последнего закрытого
        for s = 1, MAX_DEMAND do
            local z = demandSlots[s]
            if z then
                out[(s - 1) * 2 + 1] = z.top
                out[(s - 1) * 2 + 2] = z.bot
            end
        end
        for s = 1, MAX_SUPPLY do
            local z = supplySlots[s]
            if z then
                out[N_DEMAND_LINES + (s - 1) * 2 + 1] = z.top
                out[N_DEMAND_LINES + (s - 1) * 2 + 2] = z.bot
            end
        end

        log(' == new index', index, os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), table.unpack(out, 1, lines))

        return out
    end, out
end

local function Algo(settings)
    settings  = settings or {}
    error_log = {}

    local fCalc, begin_index, out

    return function(index)
        if begin_index == nil or index == begin_index then
            begin_index = index
            fCalc, out = CalcProcessor(settings, begin_index)
        end
        local ok, err = pcall(fCalc, index)
        if not ok then
            if not error_log[tostring(err)] then
                error_log[tostring(err)] = true
                log(tostring(err)); message(tostring(err))
            end
            return nil
        end
        return table.unpack(out, 1, lines)
    end
end

local PlotLines = function(index) return index end

function _G.Init()
    PlotLines = Algo(_G.Settings)
    return lines
end
function _G.OnChangeSettings() _G.Init() end
function _G.OnCalculate(index)   return PlotLines(index) end