-- nnh Glukk Inc. nick-h@yandex.ru

require("StaticVar")

SEC_CODE = '' -- бумаги в файле настроек
SEC_CODES = {}
secString = ""
SEC_PRICE_STEP    = 1                    -- ШАГ ЦЕНЫ ИНСТРУМЕНТА
STEPPRICE = 1
scale = 5
leverage = 1

ChartId = "testBidAsk"

FILE_LOG_NAME = getScriptPath().."\\bidask.Log.txt" -- ИМЯ ЛОГ-ФАЙЛА
PARAMS_FILE_NAME = getScriptPath().."\\quantScript.csv" -- ИМЯ ЛОГ-ФАЙЛА

g_previous_time = os.time() -- помещение в переменную времени сервера в формате HHMMSS 

t_id = nil
tres_id = nil

isRun = true
notBusy = true
firstStart = true

timer = os.time()
refreshTime = 60
isTrade = true
serverTime = 1000
endTradeTime = 2345
curDate = nil

SeaGreen=12713921		--	RGB(193, 255, 193) нежно-зеленый
RosyBrown=12698111	--	RGB(255, 193, 193) нежно-розовый
a_width=10 -- ширина метки

LastReadDeals = 0
rescanSec = nil
rescanning = false

dirTradeType = 2 -- 1 - направление из ТОС, 2 - напрвление считается как дельта от прошлой цены. Если цена снизилась, то продажа, если повысилась, то покупка

SecData = {}
OpenSec = nil

function OnInit()
  
    logf = io.open(FILE_LOG_NAME, "w") -- открывает файл 
    local ParamsFile = io.open(PARAMS_FILE_NAME,"r")
    if ParamsFile == nil then
        isRun = false
        message("Не удалость прочитать файл настроек!!!")
        return false
    end
    
    --curDate = getInfoParam('TRADEDATE')
    curDate = os.date('*t', os.time())

    SEC_CODES['class_codes'] =           {} -- CLASS_CODE
    SEC_CODES['names'] =                 {} -- имена бумаг
    SEC_CODES['sec_codes'] =             {} -- коды бумаг

    myLog("Читаем файл параметров")
    local lineCount = 0
    for line in ParamsFile:lines() do
        myLog("Строка параметров "..line)
        lineCount = lineCount + 1
        if lineCount > 1 and line ~= "" then
            local per1, per2, per3, per4, per5, per6, per7, per8, per9, per10, per11 = line:match("%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*)")
            SEC_CODES['class_codes'][lineCount-1] = per1 
            SEC_CODES['names'][lineCount-1] = per2
            SEC_CODES['sec_codes'][lineCount-1] = per3

            local SEC_CODE = per3
            local CLASS_CODE = per1
 
	    if getSecurityInfo(CLASS_CODE, SEC_CODE) == nil then
                isRun = false
                message("Не удалость получить данные по инструменту: "..SEC_CODE.."/"..tostring(CLASS_CODE))
                myLog("Не удалость получить данные по инструменту: "..SEC_CODE.."/"..tostring(CLASS_CODE))
                return false
            end
         
            SEC_PRICE_STEP = getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value
            scale = getSecurityInfo(CLASS_CODE, SEC_CODE).scale
            STEPPRICE = getParamEx(CLASS_CODE, SEC_CODE, "STEPPRICE").param_value
            if tonumber(STEPPRICE) == 0 or STEPPRICE == nil then
                leverage = 1
            else    
                leverage = STEPPRICE/SEC_PRICE_STEP
            end

            SecData[SEC_CODE] = {}
            SecData[SEC_CODE]["AddedLabels"] = {}
            SecData[SEC_CODE]["ChartId"] = per4
            SecData[SEC_CODE]["showLabel"] = true
            SecData[SEC_CODE]["collectStats"] = tonumber(per8)
            SecData[SEC_CODE]["autoScan"] = tonumber(per9)
            SecData[SEC_CODE]["showHourVWAP"] = tonumber(per10)
            SecData[SEC_CODE]["showDayVWAP"] = tonumber(per11)
            SecData[SEC_CODE]["clasterSize"] = tonumber(per5)
            SecData[SEC_CODE]["clasterTime"] = tonumber(per6)
            SecData[SEC_CODE]["bigDealSize"] = tonumber(per7)
            SecData[SEC_CODE]["SEC_PRICE_STEP"] = SEC_PRICE_STEP
            SecData[SEC_CODE]["scale"] = scale
            SecData[SEC_CODE]["STEPPRICE"] = STEPPRICE
            SecData[SEC_CODE]["leverage"] = leverage

            SecData[SEC_CODE]["VolAsk"] = 0
            SecData[SEC_CODE]["VolBid"] = 0
            SecData[SEC_CODE]["allDelta"] = 0
            SecData[SEC_CODE]["lastDealPrice"] = 0
            SecData[SEC_CODE]["timeDelta"] = {}
            SecData[SEC_CODE]["quantTrades"] = {}
            SecData[SEC_CODE]["lastClaster"] = nil
            SecData[SEC_CODE]["priceProfile"] = {}
            SecData[SEC_CODE]["vwap"] = {datetime, price = 0, vprice = 0, vol = 0, labelId = nil}
            SecData[SEC_CODE]["h_vwap"] = {}
    
        end
    end

    myLog("-----------------------------------")
    
    ParamsFile:close()
    
    CreateTable()
    SetTableNotificationCallback(t_id, event_callback)
    SetTableNotificationCallback(tv_id, volume_event_callback)
    SetTableNotificationCallback(tres_id, tRes_event_callback)

    for i,v in pairs(SEC_CODES['sec_codes']) do      
                   
        local SEC_CODE = v
        local CLASS_CODE = SEC_CODES['class_codes'][i]

        if SecData[SEC_CODE]["autoScan"]==1 then
            if i == 1 then
                secString = SEC_CODE..";"
            else
                secString = secString..SEC_CODE..";"
            end
        end

        local last_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value)
        SetCell(t_id, i, 1, tostring(last_price), last_price) 
        local allVol = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"VALTODAY").param_value)
        SetCell(t_id, i, 2, format_num(allVol,2), allVol) 
        SetCell(t_id, i, 5, tostring(SecData[SEC_CODE]["clasterTime"]), SecData[SEC_CODE]["clasterTime"])
        SetCell(t_id, i, 6, tostring(SecData[SEC_CODE]["bigDealSize"]), SecData[SEC_CODE]["bigDealSize"])
        SetCell(t_id, i, 10, tostring(SecData[SEC_CODE]["ChartId"]))
        --DS:SetUpdateCallback(function(...) dsCallback(...) end)
    end

end

function updateSecs()
    for i,v in pairs(SEC_CODES['sec_codes']) do      
            
        if isRun == false then break end

        local SEC_CODE = v
        local CLASS_CODE =SEC_CODES['class_codes'][i]

        local last_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value)
        local lp = GetCell(t_id, i, 1).value or last_price
        if lp < last_price then
            Highlight(t_id, i, 1, SeaGreen, QTABLE_DEFAULT_COLOR,1000)
        elseif lp > last_price then
            Highlight(t_id, i, 1, RosyBrown, QTABLE_DEFAULT_COLOR,1000)
        end   
        SetCell(t_id, i, 1, tostring(last_price), last_price) 
    
        local allVol = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"VALTODAY").param_value)
        SetCell(t_id, i, 2, format_num(allVol, 2), allVol) 
            
        SetCell(t_id, i, 3, format_num(SecData[SEC_CODE]["allDelta"], 2), SecData[SEC_CODE]["allDelta"]) 
        if SecData[SEC_CODE]["allDelta"] > 0 then
            SetColor(t_id, i, 3, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
        elseif SecData[SEC_CODE]["allDelta"] < 0 then
            SetColor(t_id, i, 3, RGB(227,165,165), RGB(0,0,0), RGB(227,165,165), RGB(0,0,0))
        else
            SetColor(t_id, i, 3, RGB(200,200,200), RGB(0,0,0), RGB(200,200,200), RGB(0,0,0))
        end
        SetCell(t_id, i, 4, format_num(SecData[SEC_CODE]["vwap"].price, SecData[SEC_CODE]["scale"]), SecData[SEC_CODE]["vwap"].price)
        
        local isScan = string.find(secString, SEC_CODE..";") ~= nil

        if SecData[SEC_CODE]["showDayVWAP"] == 1 and isScan then
            addPriceLabel(SEC_CODE, SecData[SEC_CODE]["vwap"], 5, -2)
        end

        local ss = getInfoParam("SERVERTIME")
        local hh = 1
        if string.len(ss) >= 5 then            
            hh = tonumber(mysplit(ss,":")[1])
        end
        --myLog("SEC_CODE "..SEC_CODE.." "..tostring(hh).." "..tostring(SecData[SEC_CODE]["h_vwap"][hh]))
        if SecData[SEC_CODE]["showHourVWAP"] == 1 and isScan then
            if SecData[SEC_CODE]["h_vwap"][hh]~=nil then
                addPriceLabel(SEC_CODE, SecData[SEC_CODE]["h_vwap"][hh], 3, 0) 
            end 
        end 
        --if SecData[SEC_CODE]["collectStats"] == 1 then
            --table.sort(SecData[SEC_CODE]["priceProfile"], function(a,b) return (a['price'] or 0) < (b['price'] or 0) end)
            --for i,v in pairs(SecData[SEC_CODE]["priceProfile"]) do
            --    myLog('price '..tostring(v.price)..' vol '..tostring(v.vol))
            --end
            if SecData[SEC_CODE]["ChartId"]~='' then
                stv.UseNameSpace(SecData[SEC_CODE]["ChartId"])
                stv.SetVar('priceProfile', SecData[SEC_CODE]["priceProfile"])
                stv.SetVar('timeDelta', SecData[SEC_CODE]["timeDelta"])
            end
        --end
    end
end

--function OnAllTrade()
--    updateSecs()
--end

function main()
    
    while isRun do 

        if rescanSec~=nil and not rescanning then
            rescanning = true
            rescanBigDeals(SEC_CODES['sec_codes'][rescanSec], SEC_CODES['class_codes'][rescanSec])        
        end
        local ss = getInfoParam("SERVERTIME")
        if string.len(ss) >= 5 then            
            local hh = mysplit(ss,":")
            local str=hh[1]..hh[2]
            serverTime = tonumber(str)
        end
        if serverTime >= endTradeTime then
            isTrade = false
        end

        if notBusy and not rescanning then
            notBusy = false
            --myLog("-----------------------------------")
            --myLog("LastReadDeals "..tostring(LastReadDeals))
            LastReadDeals = ReadTrades(LastReadDeals+1, 0, nil, 0)	               
            notBusy = true
            
            if firstStart then
                for i,v in pairs(SEC_CODES['sec_codes']) do      
                    if SecData[v]["showHourVWAP"] == 1 then
                        for k,n in pairs(SecData[v]["h_vwap"]) do
                            addPriceLabel(v, n, 3, 0) 
                        end 
                    end 
                end 
                --updateSecs()
            end
            updateSecs()
            firstStart = false
        end

        if OpenSec~=nil and isTrade and notBusy and os.time() - timer > refreshTime then
            timer = os.time()
            openResults()
        end
    
        sleep(100)			
    end
end

function CreateTable() -- Функция создает таблицу
    
    t_id = AllocTable()
    tres_id = AllocTable()
    
    AddColumn(t_id, 0, "SEC", true, QTABLE_STRING_TYPE, 15)
    AddColumn(t_id, 1, "price", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(t_id, 2, "volume", true, QTABLE_DOUBLE_TYPE, 23)
    AddColumn(t_id, 3, "delta", true, QTABLE_DOUBLE_TYPE, 23)
    AddColumn(t_id, 4, "vwap", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 5, "clTime", true, QTABLE_INT_TYPE, 10)
    AddColumn(t_id, 6, "bDSize", true, QTABLE_INT_TYPE, 10)
    AddColumn(t_id, 7, "", true, QTABLE_STRING_TYPE, 15)
    AddColumn(t_id, 8, "", true, QTABLE_STRING_TYPE, 15)
    AddColumn(t_id, 9, "", true, QTABLE_STRING_TYPE, 20)
    AddColumn(t_id, 10, "chartID", true, QTABLE_STRING_TYPE, 20)

    tbl = CreateWindow(t_id) 
    SetWindowPos(t_id, 90, 120, 970, #SEC_CODES['names']*20)
    SetWindowCaption(t_id, "Quant scan") -- Устанавливает заголовок
    
    -- Добавляет строки
    for i,v in pairs(SEC_CODES['names']) do
        InsertRow(t_id, i)
        SetCell(t_id, i, 0, v)  --i строка, 0 - колонка, v - значение
        local columnName = 'Start' 
        local columnColor = RGB(128,222,128)
        if SecData[SEC_CODES['sec_codes'][i]]["autoScan"] == 1 then
            columnName = 'Stop'
            columnColor = RGB(255,168,164)
        end
        SetCell(t_id, i, 7, columnName)  --i строка, 0 - колонка, v - значение 
        SetColor(t_id, i, 7, columnColor, RGB(0,0,0), columnColor, RGB(0,0,0))
        SetCell(t_id, i, 8, "del Labels")  --i строка, 0 - колонка, v - значение 
        SetColor(t_id, i, 8, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
        SetCell(t_id, i, 9, "rescan BigDeals")  --i строка, 0 - колонка, v - значение 
        SetColor(t_id, i, 9, RGB(128,222,128), RGB(0,0,0), RGB(128,222,128), RGB(0,0,0))
    end    

    AddColumn(tres_id, 0, "size", true, QTABLE_INT_TYPE, 10)
    AddColumn(tres_id, 1, "quant", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(tres_id, 2, "vol", true, QTABLE_DOUBLE_TYPE, 25)
    AddColumn(tres_id, 3, "invVol", true, QTABLE_DOUBLE_TYPE, 25)    
    AddColumn(tres_id, 4, "vwap", true, QTABLE_DOUBLE_TYPE, 15)    

    tv_id = AllocTable() -- таблица ввода значения

end

function event_callback(t_id, msg, par1, par2)
    if (msg==QTABLE_CLOSE) then
        isRun = false
    end
    if msg == QTABLE_CHAR then --ChartID
        if tostring(par2) == "8" then
            local newString = string.sub(GetCell(t_id, par1, 10).image, 1, string.len(GetCell(t_id, par1, 10).image)-1)
            SetCell(t_id, par1, 10, newString)
        else
           local inpChar = string.char(par2)
           local newString = GetCell(t_id, par1, 10).image..string.char(par2)            
           SetCell(t_id, par1, 10, newString)
        end
    end    
    if msg == QTABLE_LBUTTONDBLCLK then         
        if par2 == 3 then
            OpenSec = SEC_CODES['sec_codes'][par1]
            timer = os.time()
            openResults()
        end
        if par2 == 5 or par2==6 then
            tstr = par1
            tcell = par2
            AddColumn(tv_id, 0, "Значение", true, QTABLE_INT_TYPE, 25)
            tv = CreateWindow(tv_id) 
            SetWindowCaption(tv_id, "Введите значение")
            SetWindowPos(tv_id, 290, 260, 250, 100)                                
            InsertRow(tv_id, 1)
            SetCell(tv_id, 1, 0, GetCell(t_id, par1, par2).image, GetCell(t_id, par1, par2).value)  --i строка, 0 - колонка, v - значение 
        end
        if par2 == 7 then
            local SEC_CODE = SEC_CODES['sec_codes'][par1]
            local columnName = 'Start' 
            local columnColor = RGB(128,222,128)
            --myLog('old sec string '..secString)

            if SecData[SEC_CODE]["autoScan"]==1 then
                secString = string.gsub( secString,SEC_CODE..";",'')
                SecData[SEC_CODE]["autoScan"] = 0
            else 
                SecData[SEC_CODE]["autoScan"] = 1   
                columnName = 'Stop'
                columnColor = RGB(255,168,164)
                
                delAllLabels(SEC_CODE)

                if string.len(secString) == 0 then
                    secString = SEC_CODE..";"
                else
                    secString = secString..SEC_CODE..";"
                end

                resetSec(SEC_CODE, par1)
                SecData[SEC_CODE]["clasterTime"] = GetCell(t_id, par1, 5).value
                SecData[SEC_CODE]["bigDealSize"] = GetCell(t_id, par1, 6).value
                rescanSec = par1
            end

            --myLog('new sec string '..secString)
            SetCell(t_id, par1, 7, columnName)  --i строка, 0 - колонка, v - значение 
            SetColor(t_id, par1, 7, columnColor, RGB(0,0,0), columnColor, RGB(0,0,0))
        end
        if par2 == 8 then
            delAllLabels(SEC_CODES['sec_codes'][par1])
            SecData[SEC_CODES['sec_codes'][par1]]["showLabel"] = true
        end
        if par2 == 9 then
            local SEC_CODE = SEC_CODES['sec_codes'][par1]
            resetSec(SEC_CODE, par1)
            SecData[SEC_CODE]["clasterTime"] = GetCell(t_id, par1, 5).value
            SecData[SEC_CODE]["bigDealSize"] = GetCell(t_id, par1, 6).value
            rescanSec = par1
        end
    end    
end

function volume_event_callback(tv_id, msg, par1, par2)
    
    if par1 == -1 then
        return
    end
    if msg == QTABLE_CHAR then
        if tostring(par2) == "8" then
            local newPrice = string.sub(GetCell(tv_id, par1, 0).image, 1, string.len(GetCell(tv_id, par1, 0).image)-1)
            SetCell(tv_id, par1, 0, tostring(newPrice))
            SetCell(t_id, tstr, tcell, GetCell(tv_id, par1, 0).image, tonumber(GetCell(tv_id, par1, 0).image))
        else
           local inpChar = string.char(par2)
           local newPrice = GetCell(tv_id, par1, 0).image..string.char(par2)            
           SetCell(tv_id, par1, 0, tostring(newPrice))
           SetCell(t_id, tstr, tcell, GetCell(tv_id, par1, 0).image, tonumber(GetCell(tv_id, par1, 0).image))
       end
    end
end

function tRes_event_callback(tres_id, msg, par1, par2)

    if (msg==QTABLE_CLOSE) then
        OpenSec = nil
    end
    if msg == QTABLE_LBUTTONDBLCLK then         
        if par2 == 0 then
           openResults("size")
        end
        if par2 == 1 then
           openResults("quant")
        end
        if par2 == 2 then
           openResults("vol")
        end
        if par2 == 3 then
           openResults("invVol")
        end
        if par2 == 4 then
           openResults("vwap")
        end
    end
    
end

function OnStop()
    isRun = false
    myLog("Script Stoped") 
    logf:close() -- Закрывает файл 
    if t_id~= nil then
        DestroyTable(t_id)
    end
end

function SelectItems(tables,s,e,p)

	local t,fields={},""

		for key,val in pairs(p) do
			fields = fields .. "," .. tostring(key)                    
			t[#t+1] = val
		end

	local function fn(...)

		local args = {...}
			for key,val in ipairs(args) do
				if t[key] ~= val then
					return false
				end
			end
			return true
	end
    return SearchItems(tables,s,e,fn,fields)
end

function filterQuantity(qty, filterString)
 	
	if filterString == nul or filterString == "" then
		return true
	end

	if string.find(filterString, tostring(qty)..";") ~= nil then
		return true
	end

	return false	
	
end 

function resetSec(SEC_CODE, line)
    SecData[SEC_CODE]["VolAsk"] = 0
    SecData[SEC_CODE]["VolBid"] = 0
    SecData[SEC_CODE]["allDelta"] = 0
    SecData[SEC_CODE]["timeDelta"] = {}
    SecData[SEC_CODE]["quantTrades"] = {}
    SecData[SEC_CODE]["lastClaster"] = nil
    SecData[SEC_CODE]["priceProfile"] = {}
    SecData[SEC_CODE]["vwap"] = {datetime, price = 0, vprice = 0, vol = 0, labelId = nil}
    SecData[SEC_CODE]["h_vwap"] = {}
    SecData[SEC_CODE]["ChartId"] = GetCell(t_id, line, 10).image
end

function addTradeStat(trade, value, itsSell)
    -- trade stats                        
    --local itsSell = bit.band(trade.flags, 0x1) ~= 0

    if SecData[trade.sec_code]["collectStats"] == 1 then
    
        if SecData[trade.sec_code]["quantTrades"][trade.qty] == nil then
            SecData[trade.sec_code]["quantTrades"][trade.qty] = {} 
            SecData[trade.sec_code]["quantTrades"][trade.qty]["quant"] = 0
            SecData[trade.sec_code]["quantTrades"][trade.qty]["vol"] = 0
            SecData[trade.sec_code]["quantTrades"][trade.qty]["invVol"] = 0
            SecData[trade.sec_code]["quantTrades"][trade.qty]["vwap"] = 0
        end

        SecData[trade.sec_code]["quantTrades"][trade.qty]["quant"] = SecData[trade.sec_code]["quantTrades"][trade.qty]["quant"] + 1
        SecData[trade.sec_code]["quantTrades"][trade.qty]["vol"] = SecData[trade.sec_code]["quantTrades"][trade.qty]["vol"] + value
        SecData[trade.sec_code]["quantTrades"][trade.qty]["vwap"] = SecData[trade.sec_code]["quantTrades"][trade.qty]["vwap"] + value*trade.price
        
        if itsSell then
            --myLog("sell value "..tostring(value))
            SecData[trade.sec_code]["VolAsk"] = SecData[trade.sec_code]["VolAsk"] + value
            SecData[trade.sec_code]["quantTrades"][trade.qty]["invVol"] = SecData[trade.sec_code]["quantTrades"][trade.qty]["invVol"] - value
        else
            --myLog("buy value "..tostring(value))
            SecData[trade.sec_code]["VolBid"] = SecData[trade.sec_code]["VolBid"] + value
            SecData[trade.sec_code]["quantTrades"][trade.qty]["invVol"] = SecData[trade.sec_code]["quantTrades"][trade.qty]["invVol"] + value
        end
    
    end
    -- trade stats                        
     
    -- price profile
    local clasterStep = SecData[trade.sec_code]["clasterSize"]*SecData[trade.sec_code]["SEC_PRICE_STEP"]
    local clasterPrice = math.floor(trade.price/clasterStep)*clasterStep
    local clasterIndex = clasterPrice*math.pow(10, SecData[trade.sec_code]["scale"])
    
    if SecData[trade.sec_code]["priceProfile"][clasterIndex] == nil then
        SecData[trade.sec_code]["priceProfile"][clasterIndex] = {['price'] = clasterPrice, ["vol"] = 0}
    end
    SecData[trade.sec_code]["priceProfile"][clasterIndex]["vol"] = SecData[trade.sec_code]["priceProfile"][clasterIndex]["vol"] + value
    
    local dayIndex = (trade.datetime.year*10000+trade.datetime.month*100+trade.datetime.day)*10000
    local timeIndex = (trade.datetime.hour)*100+(trade.datetime.min)
    local hourIndex = (trade.datetime.day)*100+(trade.datetime.hour)
    
    SecData[trade.sec_code]["timeDelta"][dayIndex] = true

    if SecData[trade.sec_code]["timeDelta"][dayIndex+timeIndex] == nil then
        SecData[trade.sec_code]["timeDelta"][dayIndex+timeIndex] = {buyVol = 0, sellVol = 0}
    end

    if itsSell then
        SecData[trade.sec_code]["allDelta"] = SecData[trade.sec_code]["allDelta"] - value
        SecData[trade.sec_code]["timeDelta"][dayIndex+timeIndex].sellVol = SecData[trade.sec_code]["timeDelta"][dayIndex+timeIndex].sellVol + value
    else
        SecData[trade.sec_code]["allDelta"] = SecData[trade.sec_code]["allDelta"] + value
        SecData[trade.sec_code]["timeDelta"][dayIndex+timeIndex].buyVol = SecData[trade.sec_code]["timeDelta"][dayIndex+timeIndex].buyVol + value
    end	
    -- price profile

    --VWAP
    SecData[trade.sec_code]["vwap"].vprice = SecData[trade.sec_code]["vwap"].vprice + value*trade.price
    SecData[trade.sec_code]["vwap"].vol = SecData[trade.sec_code]["vwap"].vol + value
    SecData[trade.sec_code]["vwap"].price = SecData[trade.sec_code]["vwap"].vprice/SecData[trade.sec_code]["vwap"].vol
    SecData[trade.sec_code]["vwap"].datetime = trade.datetime
    
    if SecData[trade.sec_code]["h_vwap"][hourIndex] == nil then
        SecData[trade.sec_code]["h_vwap"][hourIndex] = {datetime, price = 0, vprice = 0, vol = 0, labelId = nil}
    end
    SecData[trade.sec_code]["h_vwap"][hourIndex].vprice = SecData[trade.sec_code]["h_vwap"][hourIndex].vprice + value*trade.price
    SecData[trade.sec_code]["h_vwap"][hourIndex].vol =    SecData[trade.sec_code]["h_vwap"][hourIndex].vol + value
    SecData[trade.sec_code]["h_vwap"][hourIndex].price =  SecData[trade.sec_code]["h_vwap"][hourIndex].vprice/SecData[trade.sec_code]["h_vwap"][hourIndex].vol
    SecData[trade.sec_code]["h_vwap"][hourIndex].datetime = trade.datetime
    --VWAP
end

function ReadTrades(firstindex)
   
	local trade = nil
	local datetime = nil
   -- ѕеребирает все сделки в таблице "—делки"
	
	local all_trades_count = getNumberOf("all_trades")
    	
	local endIndex = all_trades_count-1
	local beginIndex = firstindex

    --myLog("beginIndex "..tostring(beginIndex))
    --myLog("endIndex "..tostring(endIndex))

	if endIndex > 0 then
 
		for i = beginIndex, endIndex, 1 do      
			
			local trade = getItem ("all_trades", i)
			
			if trade ~= nil then
				if string.find(secString, trade.sec_code..";") ~= nil and (curDate.day == trade.datetime.day or curDate.wday==1 or curDate.wday==7) then
				
                    local datetime = os.time(trade.datetime)
                                                    
                    local value = 0                                                               
                    --myLog("sec "..tostring(trade.sec_code).." i "..tostring(i).." deal "..tostring(trade.trade_num).." "..isnil(toYYYYMMDDHHMMSS(trade.datetime)))
                    --if CountQuntOfDeals == 1 then
                    --    value = 1
                    --elseif sum_quantity == 0 then
                    --    value = trade.value
                    --else
                        value = trade.qty
                    --end
                     
                    local itsSell = bit.band(trade.flags, 0x1) ~= 0
                    if dirTradeType == 2 and SecData[trade.sec_code]["lastDealPrice"]~=0 and trade.price~=SecData[trade.sec_code]["lastDealPrice"] then
                        --myLog("itsSell "..tostring(itsSell).." ".."lastDealPrice "..tostring(SecData[trade.sec_code]["lastDealPrice"]).." ".."trade.price "..tostring(trade.price).." ".."new type "..tostring(trade.price<SecData[trade.sec_code]["lastDealPrice"]))
                        itsSell = trade.price<SecData[trade.sec_code]["lastDealPrice"] 
                    end
                    SecData[trade.sec_code]["lastDealPrice"] = trade.price

                    -- clastering
                    if SecData[trade.sec_code]["lastClaster"] == nil then
                        SecData[trade.sec_code]["lastClaster"] = {datetime = trade.datetime, mcs = trade.datetime.mcs, qty = 0, value = 0, price = 0, isSell = itsSell, sellVol = 0, buyVol = 0} -- time, qty, vol, wvap
                    end
                    local needNewClaster = false
                    --myLog("sec "..tostring(trade.sec_code).." ".."trade.datetime.sec "..tostring(trade.datetime.sec).." ".."last sec "..tostring(SecData[trade.sec_code]["lastClaster"]["datetime"].sec).." min "..tostring(SecData[trade.sec_code]["lastClaster"]["datetime"].min))
                    if SecData[trade.sec_code]["clasterTime"] == 0 and SecData[trade.sec_code]["lastClaster"]["mcs"] ~= trade.datetime.mcs then
                        needNewClaster = true
                    elseif SecData[trade.sec_code]["clasterTime"] ~= 0 and ((trade.datetime.sec-SecData[trade.sec_code]["lastClaster"]["datetime"].sec+1) > SecData[trade.sec_code]["clasterTime"] or SecData[trade.sec_code]["lastClaster"]["datetime"].min ~= trade.datetime.min or SecData[trade.sec_code]["lastClaster"]["datetime"].hour ~= trade.datetime.hour) then
                        needNewClaster = true
                    end
                    if needNewClaster then
                        SecData[trade.sec_code]["lastClaster"]["price"] = SecData[trade.sec_code]["lastClaster"]["price"]/SecData[trade.sec_code]["lastClaster"]["value"]
                        local clasterQty = SecData[trade.sec_code]["lastClaster"]["qty"]
                        if SecData[trade.sec_code]["bigDealSize"]~=0 and clasterQty >= SecData[trade.sec_code]["bigDealSize"] then
                            myLog("big deal "..trade.sec_code.." qnt "..tostring(clasterQty).." "..isnil(toYYYYMMDDHHMMSS(trade.datetime)))                            
                            if SecData[trade.sec_code]["lastClaster"]["buyVol"]>SecData[trade.sec_code]["lastClaster"]["sellVol"] then
                                SecData[trade.sec_code]["lastClaster"]["isSell"] = false
                            elseif SecData[trade.sec_code]["lastClaster"]["buyVol"]>SecData[trade.sec_code]["lastClaster"]["sellVol"] then
                                SecData[trade.sec_code]["lastClaster"]["isSell"] = true
                            end                                
                            addBigDealLabel(trade.sec_code, SecData[trade.sec_code]["lastClaster"])
                        end
                        SecData[trade.sec_code]["lastClaster"] = {datetime = trade.datetime, mcs = trade.datetime.mcs, qty = 0, value = 0, price = 0, isSell = itsSell, sellVol = 0, buyVol = 0} -- time, qty, vol, wvap
                    end
                                        
                    SecData[trade.sec_code]["lastClaster"]["qty"] = SecData[trade.sec_code]["lastClaster"]["qty"] + trade.qty
                    SecData[trade.sec_code]["lastClaster"]["value"] = SecData[trade.sec_code]["lastClaster"]["value"] + trade.value
                    SecData[trade.sec_code]["lastClaster"]["price"] = SecData[trade.sec_code]["lastClaster"]["price"] + trade.value*trade.price
                    if itsSell then --продажа
                        SecData[trade.sec_code]["lastClaster"]["sellVol"] = SecData[trade.sec_code]["lastClaster"]["sellVol"] + trade.qty
                    else
                        SecData[trade.sec_code]["lastClaster"]["buyVol"] = SecData[trade.sec_code]["lastClaster"]["buyVol"] + trade.qty
                    end
                    -- clastering
                    
                    addTradeStat(trade, value, itsSell)
                                                            
				end
			end
			
        end
        			
    end
    
    return endIndex
end

function rescanBigDeals(sec_code, class_code)
   	
	local all_trades_count = getNumberOf("all_trades")
    	
	local endIndex = LastReadDeals
	local beginIndex = 1

    params = {sec_code=sec_code,class_code=class_code}
    local t1 = SelectItems("all_trades", 1, endIndex, params)
    if t1 ~= nil then
        endIndex = #t1
    else
        endIndex = 0
    end

    --myLog("rescan begin "..tostring(beginIndex).." - "..tostring(endIndex))

    local lastClaster = nil

	for i = beginIndex, endIndex, 1 do      
		
		local trade = getItem ("all_trades", t1[i])
		
        if trade ~= nil then
            
            local datetime = os.time(trade.datetime)

            if curDate.day == trade.datetime.day or curDate.wday==1 or curDate.wday==7 then

                local value = 0
                --if CountQuntOfDeals == 1 then
                --    value = 1
                --elseif sum_quantity == 0 then
                --    value = trade.value
                --else
                    value = trade.qty
                --end
                
                local itsSell = bit.band(trade.flags, 0x1) ~= 0
                if dirTradeType == 2 and SecData[trade.sec_code]["lastDealPrice"]~=0 and trade.price~=SecData[trade.sec_code]["lastDealPrice"] then
                    itsSell = trade.price<SecData[trade.sec_code]["lastDealPrice"] 
                end
                SecData[trade.sec_code]["lastDealPrice"] = trade.price

                --myLog("deal "..trade.sec_code.." qnt "..tostring(trade.qty).." deal n:"..tostring(trade.trade_num).." "..isnil(toYYYYMMDDHHMMSS(trade.datetime)))                            
                
                if lastClaster == nil then
                    lastClaster = {datetime = trade.datetime, mcs = trade.datetime.mcs, qty = 0, value = 0, price = 0, isSell = itsSell, sellVol = 0, buyVol = 0} -- time, qty, vol, wvap
                end
                local needNewClaster = false
                if SecData[trade.sec_code]["clasterTime"] == 0 and lastClaster["mcs"] ~= trade.datetime.mcs then
                    needNewClaster = true
                elseif SecData[trade.sec_code]["clasterTime"] ~= 0 and ((trade.datetime.sec-lastClaster["datetime"].sec+1) > SecData[trade.sec_code]["clasterTime"] or lastClaster["datetime"].min ~= trade.datetime.min or lastClaster["datetime"].hour ~= trade.datetime.hour) then
                    needNewClaster = true
                end

                --myLog("needNewClaster "..tostring(needNewClaster))

                if needNewClaster then
                    if lastClaster["value"]~=0 then
                        lastClaster["price"] = lastClaster["price"]/lastClaster["value"]
                    else
                        lastClaster["price"] = trade.price
                    end
                    local clasterQty = lastClaster["qty"]

                    --myLog("clasterQty "..tostring(clasterQty).." bigDealSize "..tostring(SecData[trade.sec_code]["bigDealSize"]))
                
                    if SecData[trade.sec_code]["bigDealSize"]~=0 and clasterQty >= SecData[trade.sec_code]["bigDealSize"] then
                        myLog("big deal "..trade.sec_code.." qnt "..tostring(clasterQty).." "..isnil(toYYYYMMDDHHMMSS(trade.datetime)))                            
                        if lastClaster["buyVol"]>lastClaster["sellVol"] then
                            lastClaster["isSell"] = false
                        elseif lastClaster["buyVol"]>lastClaster["sellVol"] then
                            lastClaster["isSell"] = true
                        end                                
                        addBigDealLabel(trade.sec_code, lastClaster)
                    end
                    lastClaster = {datetime = trade.datetime, mcs = trade.datetime.mcs, qty = 0, value = 0, price = 0, isSell = itsSell, sellVol = 0, buyVol = 0} -- time, qty, vol, wvap
                end

                lastClaster["qty"] = lastClaster["qty"] + trade.qty
                lastClaster["value"] = lastClaster["value"] + trade.value
                lastClaster["price"] = lastClaster["price"] + trade.value*trade.price
                if itsSell then --sell
                    lastClaster["sellVol"] = lastClaster["sellVol"] + trade.qty
                else
                    lastClaster["buyVol"] = lastClaster["buyVol"] + trade.qty
                end

                --if lastClaster == nil then
                --    lastClaster = {datetime = trade.datetime, mcs = trade.datetime.mcs, qty = 0, value = 0, price = 0, isSell = itsSell} -- time, qty, vol, wvap
                --elseif lastClaster["mcs"] ~= trade.datetime.mcs then
                --    lastClaster["price"] = lastClaster["price"]/lastClaster["value"]
                --    local clasterQty = lastClaster["qty"]
                --    if SecData[trade.sec_code]["bigDealSize"]~=0 and clasterQty >= SecData[trade.sec_code]["bigDealSize"] then
                --        myLog("big deal "..trade.sec_code.." qnt "..tostring(clasterQty).." deal n:"..tostring(trade.trade_num).." "..isnil(toYYYYMMDDHHMMSS(trade.datetime)))                            
                --        addBigDealLabel(trade.sec_code, lastClaster)
                --    end
                --    lastClaster = {datetime = trade.datetime, mcs = trade.datetime.mcs, qty = 0, value = 0, price = 0, isSell = itsSell} -- time, qty, vol, wvap
                --end
                --
                --lastClaster["qty"] = lastClaster["qty"] + trade.qty
                --lastClaster["value"] = lastClaster["value"] + trade.value
                --lastClaster["price"] = lastClaster["price"] + trade.value*trade.price
                
                addTradeStat(trade, value, itsSell)
            end
        end
    end

    if SecData[sec_code]["showHourVWAP"] == 1 then
        for k,n in pairs(SecData[sec_code]["h_vwap"]) do
            addPriceLabel(sec_code, n, 3, 0) 
        end 
    end 
    if SecData[sec_code]["showDayVWAP"] == 1 then
        addPriceLabel(sec_code, SecData[sec_code]["vwap"], 5, -2)
    end

    if curDate.wday==1 or curDate.wday==7 then
        updateSecs()
    end

    rescanSec = nil
    rescanning = false
end

function addBigDealLabel(sec_code, claster)
    if SecData[sec_code]["ChartId"]~="" and SecData[sec_code]["showLabel"] then
       
        if #SecData[sec_code]["AddedLabels"] > 500 then 
            message("Слишком много меток на графике "..sec_code);
            SecData[sec_code]["showLabel"] = false
            return;
        end

        local tt = claster.datetime
        local label = 
        {
            TEXT="",
            HINT="",
            FONT_FACE_NAME = "Arial",
            FONT_HEIGHT = 4,
            R = 64,
            G = 200,
            B = 64,
            TRANSPARENT_BACKGROUND = 1,
            ALIGNMENT = "RIGHT",
            YVALUE = 0,
            DATE = (tt.year*10000+tt.month*100+tt.day),
            TIME = ((tt.hour)*10000+(tt.min-2)*100)
        }	
        
        label.YVALUE=tonumber(claster.price)
        label.TEXT="       "..string.rep("II", math.floor(a_width*tonumber(claster.qty)/SecData[sec_code]["bigDealSize"])+1)
        label.HINT= "vol "..format_num(claster.qty,0).." t:"..isnil(toYYYYMMDDHHMMSS(claster.datetime))
        if claster.isSell then
			label.R=255
			label.G=64
        end
        
        local lastLabel = #SecData[sec_code]["AddedLabels"]
        --myLog("all labels "..tostring(lastLabel))
        --myLog("new label "..tostring(SecData[sec_code]["AddedLabels"][lastLabel + 1]))
        --myLog("label.YVALUE "..tostring(label.YVALUE).." label.date "..tostring(label.DATE).." label.time "..tostring(label.TIME))
        --myLog(SecData[sec_code]["ChartId"].." label.TEXT "..tostring(label.TEXT))
        SecData[sec_code]["AddedLabels"][lastLabel + 1] = AddLabel(SecData[sec_code]["ChartId"], label)
    end
end

function addPriceLabel(sec_code, claster, font_height, hourShift)
    
    if SecData[sec_code]["ChartId"]~="" then
       
        local tt = claster.datetime
        if tt~=nil then
            local label = 
            {
                TEXT="",
                HINT="",
                FONT_FACE_NAME = "Arial",
                FONT_HEIGHT = font_height,
                R = 64,
                G = 64,
                B = 200,
                TRANSPARENT_BACKGROUND = 1,
                ALIGNMENT = "RIGHT",
                YVALUE = 0,
                DATE = (tt.year*10000+tt.month*100+tt.day),
                TIME = ((tt.hour+hourShift)*10000)
                --TIME = ((tt.hour-1)*10000+(tt.min)*100)
            }	
            
            label.YVALUE=tonumber(claster.price)
            label.TEXT="       "..string.rep("oo", 20)
            label.HINT= "vwap "..format_num(claster.price,SecData[sec_code]["scale"])
            
            --myLog("hh"..tostring(tt.hour).." labelId "..tostring(claster.labelId))
            if claster.labelId == nil then
                claster.labelId = AddLabel(SecData[sec_code]["ChartId"], label)
            else
                SetLabelParams(SecData[sec_code]["ChartId"], claster.labelId, label)
            end
        end
    end
end

function delAllLabels(sec_code)
  
    local lastLabel = #SecData[sec_code]["AddedLabels"]
    for i=1,lastLabel do
       DelLabel(SecData[sec_code]["ChartId"], SecData[sec_code]["AddedLabels"][i]) 
       SecData[sec_code]["AddedLabels"][i] = nil
    end
    --myLog("del all labels "..tostring(#SecData[sec_code]["AddedLabels"]))
    
    DelLabel(SecData[sec_code]["ChartId"], SecData[sec_code]["vwap"].labelId)
    SecData[sec_code]["vwap"].labelId = nil

    for k,n in pairs(SecData[sec_code]["h_vwap"]) do
        DelLabel(SecData[sec_code]["ChartId"], n.labelId) 
        --myLog("dal label SEC_CODE "..sec_code.." hh "..tostring(k).." "..tostring(n.labelId))
        n.labelId = nil
    end 

end

function openResults(sortColumn)
    
    local resultsSortTable = {} 
    local count = 0
    for kk,v in pairs(SecData[OpenSec]["quantTrades"]) do
        count = count + 1        
        --myLog("size "..tostring(kk).." quant "..tostring(SecData[OpenSec]["quantTrades"][kk]["quant"]).." vol "..tostring(SecData[OpenSec]["quantTrades"][kk]["vol"]).." invVol "..tostring(SecData[OpenSec]["quantTrades"][kk]["invVol"]))
        resultsSortTable[count] = {}
        resultsSortTable[count]["size"] = kk
        resultsSortTable[count]["quant"] = SecData[OpenSec]["quantTrades"][kk]["quant"]
        resultsSortTable[count]["vol"] = round(SecData[OpenSec]["quantTrades"][kk]["vol"], 2)
        resultsSortTable[count]["invVol"] = round(SecData[OpenSec]["quantTrades"][kk]["invVol"], 2)
        resultsSortTable[count]["vwap"] = round(SecData[OpenSec]["quantTrades"][kk]["vwap"]/SecData[OpenSec]["quantTrades"][kk]["vol"], scale)
    end    

    if sortColumn == nil then sortColumn = "quant" end

    table.sort(resultsSortTable, function(a,b) return a[sortColumn]<b[sortColumn] end)

    if IsWindowClosed(tres_id) then
        
        tres = CreateWindow(tres_id)
        SetWindowCaption(tres_id, "Results") 
        SetWindowPos(tres_id, 190, 190, 550, 750)

    end
    
    Clear(tres_id)
    
    --count = math.min(count, 30)

    for kk = 1, count do

        InsertRow(tres_id, kk)
        SetCell(tres_id, kk, 0, tostring(resultsSortTable[kk]["size"]), resultsSortTable[kk]["size"])
        SetCell(tres_id, kk, 1, format_num(resultsSortTable[kk]["quant"], 0), resultsSortTable[kk]["quant"])
        SetCell(tres_id, kk, 2, format_num(resultsSortTable[kk]["vol"], 2), resultsSortTable[kk]["vol"])
        SetCell(tres_id, kk, 3, format_num(resultsSortTable[kk]["invVol"], 2), resultsSortTable[kk]["invVol"])
        SetCell(tres_id, kk, 4, format_num(resultsSortTable[kk]["vwap"], SecData[OpenSec]["scale"]), resultsSortTable[kk]["vwap"])
        if resultsSortTable[kk]["invVol"] > 0 then
            SetColor(tres_id, kk, 3, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
        else
            SetColor(tres_id, kk, 3, RGB(227,165,165), RGB(0,0,0), RGB(227,165,165), RGB(0,0,0))
        end

    end    

end

-- функция записывает в лог строчку с временем и датой 
function myLog(str)
    if logf==nil then return end
  
    local current_time=os.time()--tonumber(timeformat(getInfoParam("SERVERTIME"))) -- помещене в переменную времени сервера в формате HHMMSS 
    if (current_time-g_previous_time)>1 then -- если текущая запись произошла позже 1 секунды, чем предыдущая
        logf:write("\n") -- добавляем пустую строку для удобства чтения
    end
    g_previous_time = current_time 
  
    logf:write(os.date().."; ".. str .. "\n")
  
    if str:find("Script Stoped") ~= nil then 
        logf:write("======================================================================================================================\n\n")
        logf:write("======================================================================================================================\n")
    end
    logf:flush() -- Сохраняет изменения в файле
end

function toYYYYMMDDHHMMSS(datetime)
    if type(datetime) ~= "table" then
       --message("в функции toYYYYMMDDHHMMSS неверно задан параметр: datetime="..tostring(datetime))
       return ""
    else
       local Res = tostring(datetime.year)
       if #Res == 1 then Res = "000"..Res end
       local month = tostring(datetime.month)
       if #month == 1 then Res = Res.."/0"..month; else Res = Res..'/'..month; end
       local day = tostring(datetime.day)
       if #day == 1 then Res = Res.."/0"..day; else Res = Res..'/'..day; end
       local hour = tostring(datetime.hour)
       if #hour == 1 then Res = Res.." 0"..hour; else Res = Res..' '..hour; end
       local minute = tostring(datetime.min)
       if #minute == 1 then Res = Res..":0"..minute; else Res = Res..':'..minute; end
       local sec = tostring(datetime.sec);
       if #sec == 1 then Res = Res..":0"..sec; else Res = Res..':'..sec; end;
       return Res
    end
end --toYYYYMMDDHHMMSS
 
function isnil(a,b)
    if a == nil then
       return b
    else
       return a
    end;
end

function comma_value(amount)
    local formatted = amount
    while true do  
      formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
      if (k==0) then
        break
      end
    end
    return formatted
end

function format_num(amount, decimal, prefix, neg_prefix)
    local str_amount,  formatted, famount, remain
  
    decimal = decimal or 5  -- default sec scale decimal places
    neg_prefix = neg_prefix or "-" -- default negative sign
  
    famount = math.abs(round(amount,decimal))
    famount = math.floor(famount)
  
    remain = round(math.abs(amount) - famount, decimal)
  
          -- comma to separate the thousands
    formatted = comma_value(famount)
  
          -- attach the decimal portion
    if (decimal > 0) then
      remain = string.sub(tostring(remain),3)
      formatted = formatted .. "." .. remain ..
                  string.rep("0", decimal - string.len(remain))
    end
  
          -- attach prefix string e.g '$' 
    formatted = (prefix or "") .. formatted 
  
          -- if value is negative then format accordingly
    if (amount<0) then
      if (neg_prefix=="()") then
        formatted = "("..formatted ..")"
      else
        formatted = neg_prefix .. formatted 
      end
    end
  
    return formatted
end

function round(num, idp)
	if idp and num then
	   local mult = 10^(idp or 0)
	   if num >= 0 then return math.floor(num * mult + 0.5) / mult
	   else return math.ceil(num * mult - 0.5) / mult end
	else return num end
end

function FindExistCandle(I)

	local out = I
	
	while DS:C(out) == nil and out > 0 do
		out = out -1
	end	
	
	return out
 
end

function mysplit(inputstr, sep)
     
    if sep == nil then
             sep = "%s"
     end
     local t={} 
     local i=1
     for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
             t[i] = str
             i = i + 1
     end
     return t
end
