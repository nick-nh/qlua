--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua
]]

local logfile = nil
--logfile				= io.open(_G.getWorkingFolder().."\\LuaIndicators\\volume.txt", "w")

local SEC_CODE 		= ""
local CLASS_CODE 	= ""
local myVol 		= function() end
local tradeDate
local floor 		= math.floor
local ceil 			= math.ceil
local os_time		= os.time
local os_date		= os.date
local string_find	= string.find
local bit_test		= _G.bit.test
local max_errors	= 10
local V     		= _G['V']
local T     		= _G['T']
local Size  		= _G['Size']
local message		= _G.message
local CandleExist	= _G.CandleExist
local SetValue		= _G.SetValue
local getItem		= _G.getItem
local getNumberOf	= _G.getNumberOf
local SearchItems	= _G.SearchItems
local call_count    = 0
local interval		= 60

local cache_VolAsk
local cache_VolBid
local OIDelta

_G.Settings = {
	Name 				= "*delta volume",
	-- Выводить объем баров
	showVolume			= 0,
	-- Признак инверсии значений объемной дельты. Продажа - отрицательные значения. Покупка -положительные значения
	inverse 			= 1,
	-- Признак расчета объемной дельты не по показателям сделки, а по количеству сделок за интервал времени
	-- Если установлено 1, то объемная дельта будет сформирована как разница числа сделок за интервал времени
	CountQuntOfDeals 	= 0,
	-- Признак расчета объемной дельты по количеству (объему) сделки
	-- Значения:
	-- 0 - расчет объемной дельты ведется по сумме (в деньгах) сделки
	-- 1 - расчет объемной дельты ведется по количеству сделки
	sum_quantity		= 1,
	-- Показывать объемную дельту
	showDelta			= 1,
	-- Показывать кумулятивную объемную дельту
	showCumDelta		= 0,
	-- Показывать дельту ОИ
	showOIDelta			= 0,
	-- Масштабный коэффициент вывода кумулятивной объемной дельты.
	-- Значение будет умножено на коэффициено, чтобы соотносилось с значением дельты
	delta_koeff 		= 0.1,
	-- Фильтр объема сделки при расчете объемной дельты.
	-- Задается как список значений, разделенных ;
	-- Пример: 1;2;5;10;100;
	-- Если задан, то при расчете дельты будут учитываться сделки толкьо указанных объемов
	dealFilter 			= '',
    -- Вариант определения направления сделки для расчета дельты
    -- 0 - направление из ТОС
    -- 1 - направление считается как дельта от прошлой цены. Если цена снизилась, то продажа, если повысилась, то покупка
	deltaType			= 0,
	line =
    {
        {
         Name 	= "Sell",
         Color 	= _G.RGB(255,128,128),
         Type 	= _G.TYPE_HISTOGRAM,
         Width 	= 3
        },
        {
         Name 	= "Buy",
         Color 	= _G.RGB(120,220,135),
         Type 	= _G.TYPE_HISTOGRAM,
         Width 	= 3
        },
		{
         Name 	= "Delta",
         Color 	= _G.RGB(0,0,0),
         Type 	= _G.TYPE_LINE,
         Width 	= 1
        },
		{
         Name 	= "OI Delta",
         Color 	= _G.RGB(0,0,0),
         Type 	= _G.TYPE_HISTOGRAM,
         Width 	= 2
        },
		{
         Name 	= "Volume",
         Color 	= _G.RGB(0,128, 255),
         Type 	= _G.TYPE_HISTOGRAM,
         Width 	= 3
        }
    }
}

-- ѕользовательcкие функции
local function myLog(text)
	if not logfile then return end
	logfile:write(tostring(os_date("%c",os_time())).." "..text.."\n");
	logfile:flush();
end

local function round(num, idp)
    if num then
        local mult = 10^(idp or 0)
        if num >= 0 then
            return floor(num * mult + 0.5) / mult
        else
            return ceil(num * mult - 0.5) / mult
        end
    else
        return num
    end
end

----------------------------------------------------------
---@param class_code string
---@param sec_code string
local function FilterTableLine(class_code, sec_code)

        return  class_code == CLASS_CODE and
                sec_code == SEC_CODE
end

local function filterQuantity(qty, filterString)
	if (filterString or '') == '' then
		return true
	end
	if string_find(filterString, tostring(qty)..";") ~= nil then
		return true
	end
	return false
end

local function ReadTradesProcessor(inverse, sum_quantity, filterString, CountQuntOfDeals, deltaType)

	local last_price = 0
	local last_oi
	local cache_search
	local cache_index
	local cache_i = 0

	return function(index, timeFrom, timeTo, firstindex)

		local status,res = pcall(function()
			-- Перебирает все сделки в таблице "Сделки"

			local all_trades_count = getNumberOf("all_trades")
			--myLog("firstindex "..tostring(firstindex).." all_trades_count "..tostring(all_trades_count).." cache_index "..tostring(cache_index))

			if all_trades_count~=0 and timeTo ~= nil then
				local trade 	= getItem("all_trades", 0)
				local datetime 	= os_time(trade.datetime)
				if datetime > timeTo then
					return
				end
			end

			local t1 = cache_search
			if not cache_search or index >= cache_index then
				t1 = SearchItems("all_trades", firstindex, all_trades_count-1, FilterTableLine, 'class_code,sec_code')
				cache_search = nil
				cache_i 	 = nil
				-- myLog("SearchItems firstindex "..tostring(firstindex).." #t1 "..tostring(t1 and #t1))
			end
			if firstindex == 0 then
				cache_search 	= t1
				cache_index 	= Size()-1
			end

			if t1 then

				for i = (cache_i or 1), #t1, 1 do

					local trade = getItem("all_trades", t1[i])

					if trade then

						-- if not cache_search then
						-- 	myLog("trade ".."i("..i..")".."SEC_CODE: "..trade.sec_code.."; deal time "..os_date("%c", os_time(trade.datetime)).."; price "..tostring(trade.price).."; vol "..tostring(trade.qty).."; itsSell "..tostring(itsSell).."; cache_VolAsk: "..tostring(cache_VolAsk[index]).."; cache_VolBid: "..tostring(cache_VolBid[index]));
						-- end
						local datetime = os_time(trade.datetime)
						if datetime >= timeFrom then
							if timeTo == nil or datetime < timeTo then
								local value
								if (filterString or '') == '' or filterQuantity(trade.qty, filterString) then
									if CountQuntOfDeals == 1 then
										value = 1
									elseif sum_quantity == 0 then
										value = trade.value
									else
										value = trade.qty
									end
									local itsSell = bit_test(trade.flags, 0)
									if deltaType == 1 then
										if last_price~=0 and trade.price~=last_price then
											trade.itsSell = trade.price < last_price
										end
										last_price = trade.price
									end
									if last_oi then
										OIDelta[index] = OIDelta[index] + (trade.open_interest - last_oi)
									end
									last_oi = trade.open_interest
									if itsSell then --продажа
										if inverse == 0 then
											cache_VolAsk[index] = cache_VolAsk[index] + value
										else
											cache_VolAsk[index] = cache_VolAsk[index] - value
										end
									else
										cache_VolBid[index] = cache_VolBid[index] + value
									end
									-- if not cache_search then
									-- 	myLog(" ---- count deal ".."i("..t1[i]..")".."SEC_CODE: "..trade.sec_code.."; deal time "..os_date("%c", os_time(trade.datetime)).."; price "..tostring(trade.price).."; vol "..tostring(trade.qty).."; itsSell "..tostring(itsSell).."; cache_VolAsk: "..tostring(cache_VolAsk[index]).."; cache_VolBid: "..tostring(cache_VolBid[index]));
									-- end
								end
							else
								if cache_search then cache_i = i-1 end
								return t1[i-1] or firstindex-1
							end
						end
					end
				end
				return t1[#t1]
			end
			return firstindex-1
		end)
		if not status then
			myLog('Error ReadTrades: '..tostring(res))
			return firstindex-1
		end
		return res
	end
end

local function FindExistCandle(index)
	local out = index
	while not CandleExist(out) and out <= Size() do
		out = out +1
	end
	return out
end

local function Vol(Fsettings)

	local Delta				= {}
	local LastReadDeals 	= -1
	local last_index		= Size()
	local errors			= 0
	local ReadTrades		= function() return -1 end
	local error_log			= {}

	Fsettings 				= Fsettings or {}
	local showDelta 		= Fsettings.showDelta or 0
	local showCumDelta 		= Fsettings.showCumDelta or 0
	local showOIDelta 		= Fsettings.showOIDelta or 0
	local showVolume 		= Fsettings.showVolume or 0
	local inverse 			= Fsettings.inverse or 0
	local CountQuntOfDeals 	= Fsettings.CountQuntOfDeals or 0
	local sum_quantity 		= Fsettings.sum_quantity or 1
	local delta_koeff 		= Fsettings.delta_koeff or 0
	local deltaType 		= Fsettings.deltaType or 0
	local filterString 		= Fsettings.dealFilter or ''

	return function(index)

		local status, res = pcall(function()

			if index == 1 then
				--myLog("tradeDate "..os_date("%c",os_time(tradeDate))..' index '..tostring(index)..' call_count '..tostring(call_count))
				last_index				= Size()
				cache_VolBid			= {}
				cache_VolAsk			= {}
				Delta					= {}
				Delta[index]			= 0
				OIDelta					= {}
				OIDelta[index]			= 0
				LastReadDeals			= -1
				ReadTrades				= call_count == 0 and ReadTrades or ReadTradesProcessor(inverse, sum_quantity, filterString, CountQuntOfDeals, deltaType)
				call_count				= call_count + 1
			end

			Delta[index] 			= Delta[index-1] or 0
			OIDelta[index] 			= OIDelta[index] or 0
			cache_VolAsk[index]		= cache_VolAsk[index] or 0
			cache_VolBid[index]		= cache_VolBid[index] or 0

			if not CandleExist(index) then
				return nil
			end
			local timeFrom 	= os_time(T(index))
			local timeTo 	= round(os_time(T(index)) + interval*60, 0)
			if index < Size() then
				local nextCandle = FindExistCandle(index+1)
				if nextCandle < Size()+1 then
					timeTo = T(nextCandle)
					if tradeDate.year ~= timeTo.year or tradeDate.month ~= timeTo.month or tradeDate.day ~= timeTo.day then
						if showVolume == 1 then
							return nil, nil, nil, V(index)
						else
							return nil, nil, nil, nil
						end
					end
					timeTo = os_time(timeTo)
				end
			end

			local function calc_delta(ind)
				local localDelta
				if inverse == 0 then
					localDelta = cache_VolBid[ind]-cache_VolAsk[ind]
				else
					localDelta = cache_VolBid[ind]+cache_VolAsk[ind]
				end
				Delta[ind] = Delta[ind] + localDelta*delta_koeff
			end

			--myLog("------------------------------------------------------------")
			--myLog("OnCalc() ".."CandleExist("..index.."): "..tostring(CandleExist(index)).."; T("..index..") "..os_date("%c",timeFrom).."; LastReadDeals "..tostring(LastReadDeals));
			--myLog("timeFrom "..os_date("%c",timeFrom))
			--myLog("timeTo "..os_date("%c", timeTo))
			if last_index < Size() then
				LastReadDeals = ReadTrades(index-1, os_time(T(last_index)), timeFrom, LastReadDeals+1)
				calc_delta(last_index)
				SetValue(last_index, 1, showDelta == 1 and cache_VolAsk[last_index])
				SetValue(last_index, 2, showDelta == 1 and cache_VolBid[last_index])
				SetValue(last_index, 3, showCumDelta == 1 and Delta[last_index])
				SetValue(last_index, 4, showOIDelta == 1 and OIDelta[last_index])
				SetValue(last_index, 5, showVolume == 1 and V(last_index))
				last_index 				= Size()
				OIDelta[index - 2] 		= nil
				Delta[index - 2] 		= nil
				cache_VolAsk[index - 2]	= nil
				cache_VolBid[index - 2]	= nil
			end
			LastReadDeals = ReadTrades(index, timeFrom, timeTo, LastReadDeals+1)
			--myLog("LastReadDeals "..tostring(LastReadDeals))
			--myLog("cache_VolAsk "..tostring(cache_VolAsk[index])..", cache_VolBid "..tostring(cache_VolBid[index]))
			--myLog('all vol '..tostring(cache_VolAsk[index] + cache_VolBid[index]))

			calc_delta(index)

		end)
		if not status then
			errors = errors + 1
			if errors > max_errors then message(_G.Settings.Name ..': Слишком много ошибок при работе индикатора.') end
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog('Error CalcFunc: '..tostring(res))
                message('Error CalcFunc: '..tostring(res))
            end
            return nil
		end

		----myLog("Delta "..tostring(Delta[index]))
		return showDelta == 1 and cache_VolAsk[index], showDelta == 1 and cache_VolBid[index], showCumDelta == 1 and Delta[index], showOIDelta == 1 and OIDelta[index], showVolume == 1 and V(index)
	end
end

function _G.OnCalculate(index)
	if index == 1 then
		local DSInfo 	= _G.getDataSourceInfo()
		SEC_CODE 		= DSInfo.sec_code
		CLASS_CODE 		= DSInfo.class_code
		interval 		= DSInfo.interval
		tradeDate 		= _G.getTradeDate()
		--myLog("OnCalculate 1 "..tostring(SEC_CODE).."|"..tostring(CLASS_CODE)..", tradeDate "..tostring(tradeDate)..' Size '..tostring(Size())..' interval '..tostring(interval))
	end
	return myVol(index)
end

function _G.Init()
	myVol = Vol(_G.Settings)
	return 5
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnDestroy()
	if logfile then logfile:close() end
end
