rangeSettings = {
    bars = 14,
    ratioFactor = 0.7,
    kstd = 2,
    Size = 300
}

range_PARAMS_FILE_NAME = getScriptPath().."\\rangeMonitor.csv" -- ИМЯ ЛОГ-ФАЙЛА
rangeParamsFile = nil
range_SEC_CODES = nil

function initRangeBar()

    if rangeParamsFile == nil then
        rangeParamsFile = io.open(range_PARAMS_FILE_NAME,"r")
        if rangeParamsFile ~= nil then
            
            local lineCount = 0
            range_SEC_CODES = {}
            range_SEC_CODES['sec_codes'] =         {} -- 
            range_SEC_CODES['ChartId'] =           {} -- ChartId
            range_SEC_CODES['interval'] =          {} -- 
            range_SEC_CODES['isLong'] =            {} -- 
            range_SEC_CODES['isShort'] =           {} -- 
            range_SEC_CODES['bars'] =              {} -- bars
            range_SEC_CODES['ratioFactor'] =       {} -- ratioFactor
            range_SEC_CODES['kstd'] =              {} -- kstd
            for line in rangeParamsFile:lines() do
                lineCount = lineCount + 1
                if lineCount > 1 and line ~= "" then
                    local per1, per2, per3, per4, per5, per6, per7, per8 = line:match("%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*)")
                    range_SEC_CODES['sec_codes'][lineCount-1] = per1
                    range_SEC_CODES['ChartId'][lineCount-1] = per2
                    range_SEC_CODES['interval'][lineCount-1] = tonumber(per3)
                    range_SEC_CODES['isLong'][lineCount-1] = tonumber(per4)
                    range_SEC_CODES['isShort'][lineCount-1] = tonumber(per5)
                    range_SEC_CODES['bars'][lineCount-1] = tonumber(per6)
                    range_SEC_CODES['ratioFactor'][lineCount-1] = tonumber(per7)
                    range_SEC_CODES['kstd'][lineCount-1] = tonumber(per8)
                end
            end
        end
    
        rangeParamsFile:close()
    end

    calcAlgoValue = nil
	cacheL={}
	cacheH={}
    cacheC={}
    rangeStart = {}
    prevRangeStart = {}
    lastRange = {}
end

function findRangeSettings(iSec, interval, _settings)

    if range_SEC_CODES ~= nil then
        for i,_SEC_CODE in ipairs(range_SEC_CODES['sec_codes']) do      
            --myLog('interval '..tostring(interval)..'_SEC_CODE '..tostring(_SEC_CODE)..' bars '..tostring(range_SEC_CODES['bars'][i])) 
            if SEC_CODES['sec_codes'][iSec] == _SEC_CODE and interval == range_SEC_CODES['interval'][i] then
                settings = {}
                settings.bars =         range_SEC_CODES['bars'][i] 
                settings.ratioFactor =  range_SEC_CODES['ratioFactor'][i] 
                settings.kstd =         range_SEC_CODES['kstd'][i] 
                settings.ChartId =      range_SEC_CODES['ChartId'][i] 
                settings.isLong =       range_SEC_CODES['isLong'][i] 
                settings.isShort =      range_SEC_CODES['isShort'][i]
                return settings
            end
        end
    end
    return _settings
end

function rangeBar(iSec, ind, _settings, DS, interval)

    --local interval = 0
    --if ind > 1 and DS:T(ind) ~= nil and DS:T(ind-1) ~= nil then
    --    myLog('ind '..tostring(ind)..'DS:T(ind) '..tostring(DS:T(ind).hour)..' DS:T(ind-1) '..tostring(DS:T(ind-1).hour).." delta "..tostring(os.time(DS:T(ind)) - os.time(DS:T(ind-1)))) 
    --    interval = (os.time(DS:T(ind)) - os.time(DS:T(ind-1)))/60
    --end
    
    --myLog(SEC_CODES['sec_codes'][iSec].." bars "..tostring(_settings.bars).." ratioFactor "..tostring(_settings.ratioFactor).." kstd "..tostring(_settings.kstd))

    local settings = findRangeSettings(iSec, interval, _settings)

    local Size = settings.Size or 500
    local bars = settings.bars or 64
    local ratioFactor = settings.ratioFactor or 3
    local kstd = settings.kstd or 1
    local degree = 1

    --myLog(SEC_CODES['sec_codes'][iSec].." bars "..tostring(bars).." ratioFactor "..tostring(ratioFactor).." kstd "..tostring(kstd))

    if ind == nil then ind = DS:Size() end
    Size = math.min(Size, DS:Size()) - 2

    local p = 0
    local n = 0
    local f = 0
    local qq = 0
    local mm = 0
    local tt = 0
    local ii = 0
    local jj = 0
    local kk = 0
    local ll = 0
    local nn = 0
    local sq = 0
    local i0 = 0
    
    local mi = 0
    local ai={{1,2,3,4}, {1,2,3,4}, {1,2,3,4}, {1,2,3,4}}		
    local b={}
    local x={}
    
    p = bars 
    nn = degree+1

    local index = ind-Size

    calcAlgoValue = {}
    calcAlgoValue[index] = 0
    cacheL = {}
    cacheL[index] = 0			
    cacheH = {}
    cacheH[index] = 0			
    cacheC = {}
    cacheC[index] = 0			
    rangeStart = {}
    rangeStart[index] = nil			
    prevRangeStart = {}
    prevRangeStart[index] = nil			
    
    lastRange = {}
    lastRange[index] = {0, 0, 0, 0}
    
    --- sx 
    sx={}
    sx[1] = p+1
    
    for mi=1, nn*2-2 do
        sum=0
        for n=i0, i0+p do
            sum = sum + math.pow(n,mi)
        end
        sx[mi+1]=sum
    end

    for index = ind-Size+1, DS:Size() do

        calcAlgoValue[index] = calcAlgoValue[index-1] 
        cacheL[index] = cacheL[index-1] 
        cacheH[index] = cacheH[index-1] 
        cacheC[index] = cacheC[index-1] 
        rangeStart[index] = rangeStart[index-1] 
        prevRangeStart[index] = prevRangeStart[index-1] 
        lastRange[index] = lastRange[index-1] 

        if DS:C(index) ~= nil then       
            if index - (ind-Size) > bars then

                cacheH[index] = DS:H(index)
                cacheL[index] = DS:L(index)
                cacheC[index] = DS:C(index)

                local fx_buffer={}

                --- syx 
                for mi = 1, nn do
                    sum = 0
                    for n=0, p do
                        if DS:C(index+n-bars)~=nil then
                            if mi==1 then
                                sum = sum + DS:C(index+n-bars)
                            else
                                sum = sum + DS:C(index+n-bars)*math.pow(n,mi-1)
                            end
                        end
                    end
                    b[mi]=sum
                end
                    
                --- Matrix 
                for jj=1, nn do
                    for ii=1, nn do
                        kk=ii+jj-1
                        ai[ii][jj]=sx[kk]
                    end
                end
                    
                --- Gauss 
                for kk=1, nn-1 do
                    ll=0
                    mm=0
                    for ii=kk, nn do
                        if math.abs(ai[ii][kk])>mm then
                            mm=math.abs(ai[ii][kk])
                            ll=ii
                        end
                    end
                        
                    if ll==0 then
                        return nil
                    end
                    if ll~=kk then

                        for jj=1, nn do
                            tt=ai[kk][jj]
                            ai[kk][jj]=ai[ll][jj]
                            ai[ll][jj]=tt
                        end
                        tt=b[kk]
                        b[kk]=b[ll]
                        b[ll]=tt
                    end
                    for ii=kk+1, nn do
                        qq=ai[ii][kk]/ai[kk][kk]
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
                
                x[nn]=b[nn]/ai[nn][nn]
                
                for ii=nn-1, 1, -1 do
                    tt=0
                    for jj=1, nn-ii do
                        tt=tt+ai[ii][ii+jj]*x[ii+jj]
                        x[ii]=(1/ai[ii][ii])*(b[ii]-tt)
                    end
                end
                
                ---
                for n = 1, p do
                    sum=0
                    for kk=1, degree do
                        sum = sum + x[kk+1]*math.pow(n,kk)
                    end
                    fx_buffer[n]=x[1]+sum
                end

                -- Std 
                sq=0.0
                for n = 1, p do
                    if DS:C(index+n-bars)~=nil then
                        sq = sq + math.pow(DS:C(index+n-bars)-fx_buffer[n],2)
                    end
                end
                
                sq = math.sqrt(sq/(p-1))*kstd

                local scale = getSecurityInfo(CLASS_CODE, SEC_CODE).scale
                calcAlgoValue[index] = round(fx_buffer[#fx_buffer], scale)

                local deltaRatio = math.abs(fx_buffer[#fx_buffer]-fx_buffer[1])/fx_buffer[1]*100
        
                previous = rangeStart[index] or index-bars
		
                if DS:C(previous) == nil then
                    previous = FindExistCandle(previous)
                end
                
                local maxC = math.max(unpack(cacheC,math.max(previous, 1),index-1))
                local minC = math.min(unpack(cacheC,math.max(previous, 1),index-1))
                        
                --if deltaRatio < ratioFactor and math.abs(DS:C(index) - fx_buffer[#fx_buffer]) < sq  then                    
                if deltaRatio < ratioFactor and fx_buffer[#fx_buffer] < maxC and fx_buffer[#fx_buffer] > minC and math.abs(maxC-minC) < 2*sq then
                    
                    --lastRange[index] = {maxC, minC, previous, index}        
                    --if rangeStart[index] == nil then
                    --    rangeStart[index] = previous
                    --end

                    if rangeStart[index] == nil then
                        if prevRangeStart[index]~=nil then
                            if previous - prevRangeStart[index] < bars then
                                previous = prevRangeStart[index]
                                maxC = math.max(unpack(cacheC,math.max(previous, 1),index-1))
                                minC = math.min(unpack(cacheC,math.max(previous, 1),index-1))       
                            end
                        end
                        rangeStart[index] = previous
                    end
    
                    lastRange[index] = {maxC, minC, previous, index}        
    
                else
                    if rangeStart[index] ~=nil then
                        prevRangeStart[index] = rangeStart[index]    
                    end
                    rangeStart[index] = nil
                end
 
            end
        end                
    end
        
    return calcAlgoValue 
    
end

function rangeTest(i, cell, settings, DS, signal)
        
    local index = DS:Size()
    local scale = getSecurityInfo(CLASS_CODE, SEC_CODE).scale

    if calcAlgoValue[DS:Size()] == nil or DS:Size() == 0 then return end
	local testvalue = GetCell(t_id, i, tableIndex["Текущая цена"]).value
    local calcValMax = round(lastRange[index][1] or 0, scale)
    local calcValMin = round(lastRange[index][2] or 0, scale)

    if INTERVALS["visible"][cell] then
        local Color = RGB(255, 255, 255)
        local returnValue = round(calcAlgoValue[DS:Size()] or 0, scale)
        if testvalue<calcValMin then
            returnValue = calcValMin
            Color = RGB(255,168,164)
        end    
        if testvalue>calcValMax then
            returnValue = calcValMax
            Color = RGB(165,227,128)
        end

        SetCell(t_id, i, tableIndex[cell], tostring(returnValue), returnValue)
        cellSetColor(i, tableIndex[cell], Color, RGB(0,0,0))
    end

    if signal then
        local isMessage = SEC_CODES['isMessage'][i]
        local isPlaySound = SEC_CODES['isPlaySound'][i]
        local mes0 = tostring(SEC_CODES['names'][i]).." timescale "..INTERVALS["names"][cell]
        local mes = ""

        if DS:C(index-1) < lastRange[index][2] and DS:C(index-2) > lastRange[index][2] and DS:C(index) <= lastRange[index][2] then
            mes = mes0..": выход из диапазона вниз"
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if DS:C(index-1) > lastRange[index][2] and DS:C(index-2) < lastRange[index][2] and DS:C(index) >= lastRange[index][2]then
            mes = mes0..": возврат в диапазон снизу"
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if DS:C(index-1) > lastRange[index][1] and DS:C(index-2) < lastRange[index][1] and DS:C(index) >= lastRange[index][1] then
            mes = mes0..": выход из диапазона вверх"
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if DS:C(index-1) < lastRange[index][1] and DS:C(index-2) > lastRange[index][1] and DS:C(index) <= lastRange[index][1] then
            mes = mes0..": возврат в диапазон сверху"
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
    end    

end
