--nick-h@yandex.ru
--https://github.com/nick-nh/qlua

local logfile
--logfile               = io.open(getWorkingFolder().."\\LuaIndicators\\volume.txt", "w")
local SEC_CODE      = ""
local CLASS_CODE    = ""
local myVol         = function() end
local tradeDate
local floor         = math.floor
local ceil          = math.ceil
local os_time       = os.time
local os_date       = os.date
local max_errors    = 10

Settings = {
    Name                = "*delta volume",
    showVolume          = 0,
    inverse             = 0,
    CountQuntOfDeals    = 0,
    sum_quantity        = 1,
    showdelta           = 1,
    delta_koeff         = 0.1,
    dealFilter          = '',
    deltaType           = 0, -- 0 - исходя из данных таблицы обезличенных сделок; 1 - исходя из движения цены: снижение - продажа, повышение - покупка.
    line =
    {
        {
         Name = "Sell",
         Color = RGB(255,128,128),
         Type = TYPE_HISTOGRAM,
         Width =3
        },
        {
         Name = "Buy",
         Color = RGB(120,220,135),
         Type = TYPE_HISTOGRAM,
         Width = 3
        },
        {
         Name = "Delta",
         Color = RGB(0,0,0),
         Type = TYPE_LINE,
         Width = 1
        },
        {
         Name = "Volume",
         Color = RGB(0,128, 255),
         Type = TYPE_HISTOGRAM,
         Width = 3
        }
    }
}

-- ѕользовательcкие функции
local function myLog(text)
    if not logfile then return end
    logfile:write(tostring(os_date("%c",os_time())).." "..text.."\n");
    logfile:flush();
end

local function round(num, idp)
    if num then
        local mult = 10^(idp or 0)
        if num >= 0 then
            return floor(num * mult + 0.5) / mult
        else
            return ceil(num * mult - 0.5) / mult
        end
    else
        return num
    end
end

----------------------------------------------------------

local function filterQuantity(qty, filterString)
    if (filterString or '') == '' then
        return true
    end
    if string.find(filterString, tostring(qty)..";") ~= nil then
        return true
    end
    return false
end

local function ReadTrades(index, timeFrom, timeTo, firstindex, cache_VolAsk, cache_VolBid, inverse, sum_quantity, filterString, CountQuntOfDeals, deltaType)

    local status,res = pcall(function()
        -- Перебирает все сделки в таблице "Сделки"

        local all_trades_count = getNumberOf("all_trades")
        --myLog("all_trades_count "..tostring(all_trades_count))

        if all_trades_count~=0 and timeTo ~= nil then
            local trade     = getItem("all_trades", 0)
            local datetime  = os_time(trade.datetime)
            if datetime > timeTo then
                return
            end
        end

        --myLog("firstindex "..firstindex)

        local endIndex      = all_trades_count-1
        local beginIndex    = firstindex

        local last_price = 0
        if deltaType == 1 then
            local last_trade = getItem("all_trades", beginIndex-1)
            if last_trade then
                last_price = last_trade.price
            end
        end

        if endIndex > 0 then
            for i = beginIndex, endIndex, 1 do

                local trade = getItem("all_trades", i)
                if trade and trade.sec_code == SEC_CODE and trade.class_code == CLASS_CODE then

                    --myLog("trade ".."i("..i..")".."SEC_CODE: "..trade.sec_code.."; deal time "..os_date("%c", os_time(trade.datetime)).."; price "..tostring(trade.price).."; vol "..tostring(trade.qty).."; itsSell "..tostring(itsSell).."; cache_VolAsk: "..tostring(cache_VolAsk[index]).."; cache_VolBid: "..tostring(cache_VolBid[index]));
                    local datetime = os_time(trade.datetime)
                    if datetime >= timeFrom then
                        if timeTo == nil or datetime < timeTo then
                            local value
                            if filterString == '' or filterQuantity(trade.qty, filterString) then
                                if CountQuntOfDeals == 1 then
                                    value = 1
                                elseif sum_quantity == 0 then
                                    value = trade.value
                                else
                                    value = trade.qty
                                end
                                local itsSell = bit.test(trade.flags, 0)
                                if deltaType == 1 then
                                    if last_price~=0 and trade.price~=last_price then
                                        trade.itsSell = trade.price<last_price
                                    end
                                    last_price = trade.price
                                end
                                if itsSell then --продажа
                                    if inverse == 0 then
                                        cache_VolAsk[index] = cache_VolAsk[index] + value
                                    else
                                        cache_VolAsk[index] = cache_VolAsk[index] - value
                                    end
                                else
                                    cache_VolBid[index] = cache_VolBid[index] + value
                                end
                                --myLog("deal ".."i("..i..")".."SEC_CODE: "..trade.sec_code.."; deal time "..os_date("%c", os_time(trade.datetime)).."; price "..tostring(trade.price).."; vol "..tostring(trade.qty).."; itsSell "..tostring(itsSell).."; cache_VolAsk: "..tostring(cache_VolAsk[index]).."; cache_VolBid: "..tostring(cache_VolBid[index]));
                            end
                        else
                            return i-1
                        end
                    end
                end
        end
        return endIndex
        end
    end)
    if not status then
        --myLog('Error ReadTrades: '..res)
        return firstindex-1
    end
    return res
end

local function FindExistCandle(index)
    local out = index
    while not CandleExist(out) and out <= Size() do
        out = out +1
    end
    return out
end

local function Vol()

    local cache_VolBid  = {}
    local cache_VolAsk  = {}
    local Delta         = {}
    local interval      = 0
    local LastReadDeals = -1
    local last_index    = Size()
    local errors        = 0

    return function(index, Fsettings)

        Fsettings               = Fsettings or {}
        local showdelta         = Fsettings.showdelta or 0
        local showVolume        = Fsettings.showVolume or 0
        local inverse           = Fsettings.inverse or 0
        local CountQuntOfDeals  = Fsettings.CountQuntOfDeals or 0
        local sum_quantity      = Fsettings.sum_quantity or 1
        local delta_koeff       = Fsettings.delta_koeff or 0
        local deltaType         = Fsettings.deltaType or 0
        local filterString      = Fsettings.dealFilter or ''

        local outVol = nil

        local status = pcall(function()

            if errors > max_errors then return end

            if index == 1 then
                --myLog("tradeDate "..os_date("%c",os_time(tradeDate)))
                last_index              = Size()
                interval                = round((os_time(T(Size())) - os_time(T(Size()-1)))/60)
                cache_VolBid            = {}
                cache_VolAsk            = {}
                Delta                   = {}
                Delta[index]            = 0
                LastReadDeals           = -1
            end

            Delta[index]            = Delta[index-1] or 0
            cache_VolAsk[index]     = cache_VolAsk[index] or 0
            cache_VolBid[index]     = cache_VolBid[index] or 0

            if not CandleExist(index) then
                return nil
            end
            local timeFrom  = os_time(T(index))
            local timeTo    = round(os_time(T(index)) + interval*60, 0)
            if index < Size() then
                local nextCandle = FindExistCandle(index+1)
                if nextCandle < Size()+1 then
                    timeTo = T(nextCandle)
                    if tradeDate.year ~= timeTo.year or tradeDate.month ~= timeTo.month or tradeDate.day ~= timeTo.day then
                        if showVolume == 1 then
                            return nil, nil, nil, V(index)
                        else
                            return nil, nil, nil, nil
                        end
                    end
                    timeTo = os_time(timeTo)
                end
            end

            local function calc_delta(ind)
                local localDelta
                if inverse == 0 then
                    localDelta = cache_VolBid[ind]-cache_VolAsk[ind]
                else
                    localDelta = cache_VolBid[ind]+cache_VolAsk[ind]
                end
                Delta[ind] = Delta[ind] + localDelta*delta_koeff
            end

            --myLog("------------------------------------------------------------")
            --myLog("OnCalc() ".."CandleExist("..index.."): "..tostring(CandleExist(index)).."; T("..index..") "..os_date("%c",timeFrom).."; LastReadDeals "..tostring(LastReadDeals));
            --myLog("timeFrom "..os_date("%c",timeFrom))
            --myLog("timeTo "..os_date("%c", timeTo))
            if last_index < Size() then
                LastReadDeals = ReadTrades(index-1, os_time(T(last_index)), timeFrom, LastReadDeals+1, cache_VolAsk, cache_VolBid, inverse, sum_quantity, filterString, CountQuntOfDeals, deltaType)
                calc_delta(last_index)
                SetValue(last_index, 1, cache_VolAsk[last_index])
                SetValue(last_index, 2, cache_VolBid[last_index])
                SetValue(last_index, 3, showdelta == 1 and Delta[last_index])
                SetValue(last_index, 4, showVolume == 1 and V(last_index))
                last_index = Size()
            end
            LastReadDeals = ReadTrades(index, timeFrom, timeTo, LastReadDeals+1, cache_VolAsk, cache_VolBid, inverse, sum_quantity, filterString, CountQuntOfDeals, deltaType)
            --myLog("LastReadDeals "..tostring(LastReadDeals))
            --myLog("cache_VolAsk "..tostring(cache_VolAsk[index])..", cache_VolBid "..tostring(cache_VolBid[index]))
            --myLog('all vol '..tostring(cache_VolAsk[index] + cache_VolBid[index]))

            calc_delta(index)

        end)
        if not status then
            errors = errors + 1
            if errors > max_errors then message(Settings.Name ..': Слишком много ошибок при работе индикатора.') end
            --myLog('Error CalcFunc: '..res)
            return nil
        end

        ----myLog("Delta "..tostring(Delta[index]))
        if showVolume == 1 then
            outVol = V(index)
        end
        if showdelta == 0 then
            return cache_VolAsk[index], cache_VolBid[index], nil, outVol
        else
            return cache_VolAsk[index], cache_VolBid[index], Delta[index], outVol
        end
    end
end

function OnCalculate(index)
    if index == 1 then
        local DSInfo    = getDataSourceInfo()
        SEC_CODE        = DSInfo.sec_code
        CLASS_CODE      = DSInfo.class_code
        tradeDate       = getTradeDate()
    end
    return myVol(index, Settings)
end

function Init()
    myVol = Vol()
    return #Settings.line
end

function OnDestroy()
    if logfile then logfile:close() end
end

