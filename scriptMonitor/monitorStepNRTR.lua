NRTRSettings = {
    Length    = 32,            -- ПЕРИОД        
    Kv = 1.7,                  -- коэффициент
    ATRfactor = 0.15,          -- коэффициент
    StepSize = 0,              -- шаг
    Percentage = 0,
    Switch = 1,                --1 - HighLow, 2 - CloseClose
    Size = 500,
    testZone = 10
}

NRTR_PARAMS_FILE_NAME = getScriptPath().."\\nrtrMonitor.csv" -- ИМЯ ЛОГ-ФАЙЛА
NRTRParamsFile = nil

smax1 = {}
smin1 = {}
trend = {}
NRTR_SEC_CODES = nil

function initstepNRTR()
    
    if NRTRParamsFile == nil then
        NRTRParamsFile = io.open(NRTR_PARAMS_FILE_NAME,"r")
        if NRTRParamsFile ~= nil then
            
            local lineCount = 0
            NRTR_SEC_CODES = {}
            NRTR_SEC_CODES['sec_codes'] =         {} -- 
            NRTR_SEC_CODES['ChartId'] =           {} -- ChartId
            NRTR_SEC_CODES['interval'] =          {} -- 
            NRTR_SEC_CODES['isLong'] =            {} -- 
            NRTR_SEC_CODES['isShort'] =           {} -- 
            NRTR_SEC_CODES['Length'] =            {} -- Length
            NRTR_SEC_CODES['Kv'] =                {} -- Kv
            for line in NRTRParamsFile:lines() do
                lineCount = lineCount + 1
                if lineCount > 1 and line ~= "" then
                    local per1, per2, per3, per4, per5, per6, per7 = line:match("%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*)")
                    NRTR_SEC_CODES['sec_codes'][lineCount-1] = per1
                    NRTR_SEC_CODES['ChartId'][lineCount-1] = per2
                    NRTR_SEC_CODES['interval'][lineCount-1] = tonumber(per3)
                    NRTR_SEC_CODES['isLong'][lineCount-1] = tonumber(per4)
                    NRTR_SEC_CODES['isShort'][lineCount-1] = tonumber(per5)
                    NRTR_SEC_CODES['Length'][lineCount-1] = tonumber(per6)
                    NRTR_SEC_CODES['Kv'][lineCount-1] = tonumber(per7)
                end
            end
        end
    
        NRTRParamsFile:close()
    end

    calcAlgoValue=nil
    smax1=nil
    smin1=nil
    trend=nil
end

function findSettings(iSec, interval, settings)

    if NRTR_SEC_CODES ~= nil then
        for i,_SEC_CODE in ipairs(NRTR_SEC_CODES['sec_codes']) do      
            if SEC_CODES['sec_codes'][iSec] == _SEC_CODE and interval == NRTR_SEC_CODES['interval'][i] then
                settings.Length = NRTR_SEC_CODES['Length'][i] 
                settings.Kv = NRTR_SEC_CODES['Kv'][i] 
                settings.ChartId = NRTR_SEC_CODES['ChartId'][i] 
                settings.isLong = NRTR_SEC_CODES['isLong'][i] 
                settings.isShort = NRTR_SEC_CODES['isShort'][i]
                --myLog('sec '..tostring(_SEC_CODE)) 
                --myLog('interval '..tostring(interval)) 
                --myLog('length '..tostring(settings.Length)) 
                --myLog('kv '..tostring(settings.Kv)) 
                return settings
            end
        end
    end
    return settings
end

function stepNRTR(iSec, ind, _settings, DS, interval)

    --local interval = 0
    --if ind > 1 and DS:T(ind) ~= nil and DS:T(ind-1) ~= nil then
    --    --myLog('ind '..tostring(ind)..'DS:T(ind) '..tostring(DS:T(ind))..'DS:T(ind-1) '..tostring(DS:T(ind-1))) 
    --    interval = (os.time(DS:T(ind)) - os.time(DS:T(ind-1)))/60
    --end
    local settings = findSettings(iSec, interval, _settings)
    local Length = settings.Length or 29            -- perios        
    local Kv = settings.Kv or 1                     -- miltiply
    local ATRfactor = settings.ATRfactor or 0.15     
    local StepSize = settings.StepSize or 0         -- fox stepSize
    local Percentage = settings.Percentage or 0
    local Switch = settings.Switch or 1             --1 - HighLow, 2 - CloseClose
    local Size = settings.Size or 1000 

    local ratio=Percentage/100.0*SEC_PRICE_STEP
    local smax0 = 0
    local smin0 = 0
    
    if ind == nil then ind = DS:Size() end
    
    Size = math.min(Size, DS:Size()) - 2
    local kawg = 2/(Length+1)

    calcAlgoValue = {}
    calcAlgoValue[ind] = 0			
    emaATR = {}
    emaATR[ind-Size-1] = 0			
    smax1 = {}
    smin1 = {}
    trend = {}
    smax1[ind-Size-1] = 0
    smin1[ind-Size-1] = 0
    trend[ind-Size-1] = 1

    for index = ind-Size, DS:Size() do    
        calcAlgoValue[index] = calcAlgoValue[index-1] 
        emaATR[index] = emaATR[index-1] 
        smax1[index] = smax1[index-1] 
        smin1[index] = smin1[index-1] 
        trend[index] = trend[index-1] 
        
        if DS:C(index) ~= nil then        
            local previous = index-1            
            if DS:C(previous) == nil then
                previous = FindExistCandle(previous)
            end            
            
            local Step=StepSizeCalc(Length,Kv,StepSize,Switch,index)
            local iATR = math.max(math.abs(DS:H(index) - DS:L(index)), math.abs(DS:H(index) - DS:C(previous)), math.abs(DS:C(previous) - DS:L(index))) or 0
            emaATR[index] = kawg*iATR+(1-kawg)*emaATR[index-1]
            
            if Step == 0 then Step = 1 end
            
            local SizeP=Step*SEC_PRICE_STEP
            local Size2P=2*SizeP            
            
            local result		
            
            if Switch == 1 then     
                smax0=DS:L(previous)+Size2P
                smin0=DS:H(previous)-Size2P    
            else   
                smax0=DS:C(previous)+Size2P
                smin0=DS:C(previous)-Size2P
            end
            
            if DS:C(index)>smax1[index] and (DS:C(index)-smax1[index]) > ATRfactor*emaATR[index] then
                trend[index] = 1 
            end
            if DS:C(index)<smin1[index] and (smin1[index]-DS:C(index)) > ATRfactor*emaATR[index] then
                trend[index]= -1
            end
    
            if trend[index]>0 then
                if smin0<smin1[index] then smin0=smin1[index] end
                result=smin0+SizeP
            else
                if smax0>smax1[index] then smax0=smax1[index] end
                result=smax0-SizeP
            end
                
            smax1[index] = smax0
            smin1[index] = smin0
            
            if trend[index]>0 then
                calcAlgoValue[index]=(result+ratio/Step)-Step*SEC_PRICE_STEP
            end
            if trend[index]<0 then
                calcAlgoValue[index]=(result+ratio/Step)+Step*SEC_PRICE_STEP		
            end	
        end
    end	
            
    return calcAlgoValue 
    
end

function StepSizeCalc(Len, Km, Size, Switch, index)

	local result
	local Range = 0
	local rangeEMA = {}	
	local k = 2/(Len+1)

	if Size == 0 then
		 
		local Range=0.0
		local ATRmax=-1000000
		local ATRmin=1000000
		if Switch == 1 then     
			Range=DS:H(index-Len-1)-DS:L(index-Len-1)
		else   
			Range=math.abs(DS:O(index-Len-1)-DS:C(index-Len-1))
		end
		rangeEMA[1] = Range

		for iii=1, Len do	
			if DS:C(index-Len+iii-1) ~= nil then				
				
				if Switch == 1 then     
					Range=DS:H(index-Len+iii-1)-DS:L(index-Len+iii-1)
				else   
					Range=math.abs(DS:O(index-Len+iii-1)-DS:C(index-Len+iii-1))
				end
				rangeEMA[iii+1] = k*Range+(1-k)*rangeEMA[iii]
			end
		end

		result = round(Km*rangeEMA[#rangeEMA]/SEC_PRICE_STEP, nil)
		 
	else result=Km*Size
	end

	return result

	--[[
	local result

	if Size == 0 then
		 
		local Range=0.0
		local ATRmax=-1000000
		local ATRmin=1000000

		for iii=1, Len do	
			--WriteLog("DS:C(index-iii) "..tostring(DS:C(index-iii)))
			if DS:C(index-iii) ~= nil then				
				if Switch == 1 then     
					Range=DS:H(index-iii)-DS:L(index-iii)
				else   
					Range=math.abs(DS:O(index-iii)-DS:C(index-iii))
				end
				if Range>ATRmax then ATRmax=Range end
				if Range<ATRmin then ATRmin=Range end
				--WriteLog("Range "..tostring(Range))
				--WriteLog("ATRmax "..tostring(ATRmax))
				--WriteLog("ATRmin "..tostring(ATRmin))
			end
		end
		result = round(0.5*Km*(ATRmax+ATRmin)/SEC_PRICE_STEP, nil)
		 
	else result=Km*Size
	end

	return result
	]]--
end

function NRTRTest(i, cell, _settings, DS, signal)
    
    local interval = INTERVALS["values"][cell]
    local settings = findSettings(iSec, interval, _settings)

    --local testvalue = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value) or 0
    local index = DS:Size()
    local isNewCandle = SEC_CODE_INDEX[i][cell] < DS:Size()
    local testvalue = GetCell(t_id, i, tableIndex["Текущая цена"]).value
    local price_step = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value) or 0
    local scale = getSecurityInfo(CLASS_CODE, SEC_CODE).scale
    local signaltestvalue1 = calcAlgoValue[index-1] or 0
    local signaltestvalue2 = calcAlgoValue[index-2] or 0
    local testZone = settings.testZone or 10

    if calcAlgoValue[index] == nil or index == 0 then return end
    local calcVal = round(calcAlgoValue[index] or 0, scale)

    local testSignalZone = price_step*testZone
    local downTestZone = calcVal-testSignalZone
    local upTestZone = calcVal+testSignalZone

    if INTERVALS["visible"][cell] then
        local Color = RGB(255, 255, 255)
        if testvalue > downTestZone and testvalue < calcVal then
            Color = RGB(255, 220, 220)
        elseif testvalue < upTestZone and testvalue > calcVal then
            Color = RGB(220, 255, 220)
        elseif testvalue < downTestZone then
            Color = RGB(255,168,164)
        elseif testvalue > upTestZone then
            Color = RGB(165,227,128)
        end
        SetCell(t_id, i, tableIndex[cell], tostring(calcVal), calcVal)
        cellSetColor(i, tableIndex[cell], Color, RGB(0,0,0))
    end

    if signal then
        local isMessage = SEC_CODES['isMessage'][i]
        local isPlaySound = SEC_CODES['isPlaySound'][i]
        local mes0 = tostring(SEC_CODES['names'][i]).." timescale "..INTERVALS["names"][cell]
        local mes = ""
        
        if signaltestvalue1 < DS:C(index-1) and signaltestvalue2 > DS:C(index-2) and DS:O(index) > calcVal then
            mes = mes0..": Сигнал Buy"
            myLog(mes)
            --myLog("Значение алгоритма -1 "..tostring(signaltestvalue1).." Закрытие свечи-1 "..DS:C(index-1))
            --myLog("Значение алгоритма -2 "..tostring(signaltestvalue2).." Закрытие свечи-2 "..DS:C(index-2))
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
            if settings.ChartId ~= nil and isNewCandle then
                openLong = nil
                closeLong = nil
                if settings.isLong == 1 then
                    openLong = DS:O(index)
                end
                openShort = nil
                closeShort = nil
                if settings.isShort == 1 then
                    closeShort = DS:O(index)
                end
                addDeal(index, settings.ChartId, openLong, openShort, closeLong, closeShort, DS:T(index))
            end
        end
        if signaltestvalue1 > DS:C(index-1) and signaltestvalue2 < DS:C(index-2) and DS:O(index) < calcVal then
            mes = mes0..": Сигнал Sell"
            myLog(mes)
            --myLog("Значение алгоритма -1 "..tostring(signaltestvalue1).." Закрытие свечи-1 "..DS:C(index-1))
            --myLog("Значение алгоритма -2 "..tostring(signaltestvalue2).." Закрытие свечи-2 "..DS:C(index-2))
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
            if settings.ChartId ~= nil and isNewCandle then                
                openLong = nil
                closeLong = nil
                if settings.isLong == 1 then
                    closeLong = DS:O(index)
                end
                openShort = nil
                closeShort = nil
                if settings.isShort == 1 then
                    openShort = DS:O(index)
                end
                addDeal(index, settings.ChartId, openLong, openShort, closeLong, closeShort, DS:T(index))
            end
        end

        if testvalue < upTestZone and DS:C(index-1) > upTestZone then
            mes = mes0..": Цена опустилась к зоне "..tostring(upTestZone)
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if testvalue > downTestZone and DS:C(index-1) < downTestZone then
            mes = mes0..": Цена поднялась к зоне "..tostring(downTestZone)
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if testvalue > upTestZone and DS:C(index-1) < upTestZone then
            mes = mes0..": Цена оттолкнулась от зоны "..tostring(upTestZone)
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if testvalue < downTestZone and DS:C(index-1) > downTestZone then
            mes = mes0..": Цена опустилась от зоны "..tostring(downTestZone)
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
	end

end
