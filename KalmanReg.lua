--[[
    Kalman filter Regression

    nick-h@yandex.ru
	https://github.com/nick-nh/qlua
]]
_G.unpack 		= rawget(table, "unpack") or _G.unpack

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\KalmanReg.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local CandleExist   = _G['CandleExist']
local SetValue      = _G['SetValue']
local O             = _G['O']
local C             = _G['C']
local H             = _G['H']
local L             = _G['L']
local line_color    = RGB(0, 128, 255)
local os_time	    = os.time

_G.Settings= {
    Name 		= "*KLR",
    ['1. Период регрессии']     = 100,
    ['2. Порядок регрессии']    = 1,
    ['3. Отклонение1']		    = 2.0,
    ['4. Коэфф. забывания']     = 0.95,
	['5. Вариант данных']	    = 'C', -- C, O, H, L, M, T, W
    line = {
        {
            Name = "KLR",
            Color = line_color,
            Type = TYPE_LINE,
            Width = 1
        },
        {
            Name = "+KLR1",
            Color = RGB(0, 128, 0),
            Type = TYPE_LINE,
            Width = 1
        },
        {
            Name = "-KLR1",
            Color = RGB(192, 0, 0),
            Type = TYPE_LINE,
            Width = 1
        },
        {
            Name  = 'hKLR',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 2
        },
        {
            Name  = 'h+KLR',
            Color = RGB(89,213, 107),
            Type  = TYPE_LINE,
            Width = 2
        },
        {
            Name  = 'h-KLR',
            Color = RGB(255, 58, 0),
            Type  = TYPE_LINE,
            Width = 2
        }
    }
}

local PlotLines     = function(index) return index end
local error_log     = {}
local lines         = #_G.Settings.line

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

function myLog(...)
	if logFile==nil then return end
    logFile:write(tostring(os.date("%c",os_time())).." "..log_tostring(...).."\n");
    logFile:flush();
end
------------------------------------------------------------------
    --Moving Average
------------------------------------------------------------------

local df = {}
df['C'] = function(i) return C(i) end
df['H'] = function(i) return H(i) end
df['L'] = function(i) return L(i) end
df['O'] = function(i) return O(i) end
df['M'] = function(i) return (H(i) + L(i))/2 end
df['T'] = function(i) return (H(i) + L(i) + O(i))/3 end
df['W'] = function(i) return (H(i) + L(i) + O(i) + C(i))/4 end

-- Класс KalmanFilter с поддержкой скользящего окна
local KalmanFilter = {}
KalmanFilter.__index = KalmanFilter

function KalmanFilter.new(num_vars, window_size, delta, R)
    local self = setmetatable({}, KalmanFilter)
    self.num_vars = num_vars or 1
    self.window_size = window_size or 10  -- Размер скользящего окна
    self.delta = delta or 0.99
    self.R = R or 1

    -- Инициализация коэффициентов и матрицы ковариации
    self.theta = {}
    for i = 1, num_vars do self.theta[i] = 0 end

    self.P = {}
    for i = 1, num_vars do
        self.P[i] = {}
        for j = 1, num_vars do
            self.P[i][j] = (i == j) and 1000 or 0
        end
    end

    -- Буфер для хранения последних точек
    self.buffer = {}
    self.buffer_size = 0

    return self
end

-- Обновление фильтра с учетом скользящего окна
function KalmanFilter:update(y, x)
    -- Добавляем новую точку в буфер
    self.buffer[#self.buffer+1] = {y = y, x = x}
    self.buffer_size = self.buffer_size + 1

    -- Если буфер переполнен, удаляем самую старую точку
    if self.buffer_size > self.window_size then
        table.remove(self.buffer, 1)
        self.buffer_size = self.window_size
    end

    -- Полный пересчет матриц для текущего окна
    self:reset_for_window()

    -- Прогнозируем значение
    local y_pred = 0
    for i = 1, self.num_vars do
        y_pred = y_pred + self.theta[i] * x[i]
    end

    return self.theta, y_pred
end

-- Пересчет параметров для текущего окна
function KalmanFilter:reset_for_window()
    -- Временные переменные для пересчета
    local new_theta = {}
    for i = 1, self.num_vars do new_theta[i] = 0 end

    local new_P = {}
    for i = 1, self.num_vars do
        new_P[i] = {}
        for j = 1, self.num_vars do
            new_P[i][j] = (i == j) and 1000 or 0
        end
    end

    -- Обработка всех точек в буфере
    for _, point in ipairs(self.buffer) do
        local y = point.y
        local x = point.x

        -- Предсказание
        local y_pred = 0
        for i = 1, self.num_vars do
            y_pred = y_pred + new_theta[i] * x[i]
        end

        -- Ошибка предсказания
        local err = y - y_pred

        -- Обновление матрицы ковариации
        local P_x = {}
        for i = 1, self.num_vars do
            P_x[i] = 0
            for j = 1, self.num_vars do
                P_x[i] = P_x[i] + new_P[i][j] * x[j]
            end
        end

        local x_P_x = 0
        for i = 1, self.num_vars do
            x_P_x = x_P_x + x[i] * P_x[i]
        end

        -- Коэффициент усиления Калмана
        local K = {}
        local denom = x_P_x + self.R
        for i = 1, self.num_vars do
            K[i] = P_x[i] / denom
        end

        -- Обновление коэффициентов
        for i = 1, self.num_vars do
            new_theta[i] = new_theta[i] + K[i] * err
        end

        -- Обновление матрицы ковариации
        for i = 1, self.num_vars do
            for j = 1, self.num_vars do
                new_P[i][j] = (new_P[i][j] - K[i] * P_x[j]) / self.delta
            end
        end
    end

    -- Обновляем основные параметры
    self.theta = new_theta
    self.P = new_P
end

-- Возвращает предсказания для всех точек в текущем окне
function KalmanFilter:predict_all()
    local predictions = {}
    for _, point in ipairs(self.buffer) do
        local y_pred = 0
        for i = 1, self.num_vars do
            y_pred = y_pred + self.theta[i] * point.x[i]
        end
        predictions[#predictions+1] = y_pred
    end
    return predictions
end

-- Обновление с возвратом прогнозов для всего окна
function KalmanFilter:update_with_predictions(y, x)
    -- Добавляем новую точку
    self.buffer[#self.buffer+1] = {y = y, x = x}

    -- Удаляем старую точку при превышении размера окна
    if #self.buffer > self.window_size then
        table.remove(self.buffer, 1)
    end

    -- Получаем прогнозы ДО обновления модели
    local predictions = self:predict_all()

    -- Обновляем модель
    self:update(y, x)

    -- Возвращаем:
    -- 1. Обновленные коэффициенты
    -- 2. Прогнозы для всех точек окна
    -- 3. Само окно данных (для отладки)
    return self.theta, predictions, self.buffer
end

-- Прогнозы после обновления модели
function KalmanFilter:get_updated_predictions()
    local updated_preds = {}
    for _, point in ipairs(self.buffer) do
        local y_pred = 0
        for i = 1, self.num_vars do
            y_pred = y_pred + self.theta[i] * point.x[i]
        end
        updated_preds[#updated_preds+1] = y_pred
    end
    return updated_preds
end

local function F_KLREG(settings)

    settings            = (settings or {})
    local period        = settings.period or 100
    local degree        = settings.degree or 1
    local kf_delta      = settings.kf_delta or 0.95
    local calc_sd       = settings.calc_sd
    local data_type     = (settings.data_type or "C"):upper():sub(1,1)
    local save_bars     = (settings.save_bars or period)
	local last_cal_bar
    local calc_buffer
    if calc_sd == nil then calc_sd = true end

    local _
    local kf
    local data
    local reg  = {}
    local sd   = {}
    local wnd  = {}
    local begin_index

    local function get_x(index)
        return index
    end
    local function get_y(index)
        return df[data_type](index)
    end

    local function new_point(x)
        local x_vector = {1, x}
        for d = 2, degree do
            x_vector[#x_vector+1] = x^d
        end
        return x_vector
    end

    local function train_kf()
        for t = 1, #data do
            local x_vector = new_point(data[t].x)
            kf:update(data[t].y, x_vector)
        end
    end

    return function(index)

        if index <= period then return reg, sd, wnd end

        if (not kf and index > period) or index == begin_index then
            begin_index = index
            calc_buffer = {}
            local i     = 0
            local j     = period
            data        = {}
            while not data[1] and i < index do
                data[j] = {x = get_x(index-i-1), y = get_y(index-i-1)}
                i = i + 1
                if data[j].y then
                    j = j - 1
                end
            end

            kf = KalmanFilter.new(degree+1, period, kf_delta, 1.0)
            train_kf()
            last_cal_bar = index
        end

		if calc_buffer[index] ~= nil then
			return reg, sd, wnd
		end

        if not CandleExist(index) or index < period then
			return reg, sd, wnd
		end
        if last_cal_bar ~= index and data[1] then
            table.remove(data, 1)
            local x         = get_x(index-1)
            local y         = get_y(index-1)
            data[period]    = {x = x, y = y}
            local x_vector = new_point(get_x(index-1))
            kf:update(y, x_vector)
            local predict = kf:get_updated_predictions()
            reg[index]          = predict[period]
            wnd[index]          = predict
            if calc_sd then
                local sq = 0.0
                for n=1, period do
                    sq = sq + (data[n].y - predict[n])^2
                end
                sd[index]   = math.sqrt(sq/(period-1))
            end
        end
        last_cal_bar = index

        calc_buffer[index]      = true
        reg[index-save_bars]    = nil
        sd[index-save_bars]     = nil


        return reg, sd, wnd

	end, reg, sd, wnd

end

local function Algo(settings)

    settings = (settings or {})

    local period    = settings['1. Период регрессии']     or 14
    local degree    = settings['2. Порядок регрессии']    or 1
    local kstd1     = settings['3. Отклонение1']          or 2
    local kf_delta  = settings['4. Коэфф. забывания']     or 0.95
    local data_type = settings['5. Вариант данных']	      or 'C'

    error_log = {}

    local fMA, reg, sd, wnd
	local out 	= {}
    local begin_index

    return function (index)

        local status, res = pcall(function()

			out = {}

            if fMA == nil or index == begin_index then
                begin_index     = index

                fMA, reg, sd, wnd  = F_KLREG({period = period, degree = degree, kf_delta = kf_delta, data_type = data_type})
                if not fMA and not error_log[tostring(reg)] then
                    error_log[tostring(reg)] = true
                    myLog(tostring(reg))
                    message(tostring(reg))
                end
                fMA(index)
                return
            end

			SetValue(index-period, 4, nil)
			SetValue(index-period, 5, nil)
			SetValue(index-period, 6, nil)

            if fMA then
                fMA(index)
                out[1] = reg[index]
                out[2] = sd[index] and reg[index] + sd[index]*kstd1
                out[3] = sd[index] and reg[index] - sd[index]*kstd1
                if wnd[index] then
                    for n = 1, #wnd[index] do
                        out[4] = wnd[index][n]
                        if kstd1 > 0 and sd[index] then
                            out[5] = wnd[index][n]+sd[index]*kstd1
                            out[6] = wnd[index][n]-sd[index]*kstd1
                        end
                        SetValue(index+n-period, 4, out[4])
                        SetValue(index+n-period, 5, out[5])
                        SetValue(index+n-period, 6, out[6])
                    end
                end
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
        return unpack(out, 1, lines)
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