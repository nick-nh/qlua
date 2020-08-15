RSISettings = {
    period    = 29,
    Size = 1000
}

function initRSI()
    calcAlgoValue = nil
    RSI_H = nil
    RSI_L = nil
end

function RSI(iSec, ind, settings, DS)

    local period = settings.period or 29 -- period        
    local Size = settings.Size or 1000 

    local k = 2/(period+1)
    if ind == nil then ind = DS:Size() end
    Size = math.min(Size, DS:Size()) - 2
        
    calcAlgoValue = {}
    RSI_H={}
    RSI_L={}
    calcAlgoValue[ind-Size-1] = 0			
    RSI_H[ind-Size-1] = 0			
    RSI_L[ind-Size-1] = 0			
    
    for index = ind-Size, DS:Size() do
        calcAlgoValue[index] = calcAlgoValue[index-1] 
        RSI_H[index] = RSI_H[index-1] 
        RSI_L[index] = RSI_L[index-1] 
        
        if DS:C(index) ~= nil then       
            if DS:C(index) > DS:C(index-1) then
                RSI_H[index]=RSI_H[index-1]*(1-2/(period*2+1)) + (math.abs(DS:C(index)-DS:C(index-1)))*2/(period*2+1)
                RSI_L[index]=RSI_L[index-1]*(1-2/(period*2+1))
            else
                RSI_H[index]=RSI_H[index-1]*(1-2/(period*2+1))
                RSI_L[index]=RSI_L[index-1]*(1-2/(period*2+1)) + (math.abs(DS:C(index)-DS:C(index-1)))*2/(period*2+1)
            end
            
            calcAlgoValue[index]=round(RSI_H[index]/(RSI_H[index]+RSI_L[index])*100, 2)
        end
    end
        
    return calcAlgoValue 
    
end

function signalRSI(i, cell, settings, DS, signal)
    
    local testvalue = 50 -- сравниваемое значение 
    local signaltestvalue1 = calcAlgoValue[DS:Size()-1] or 0
    local signaltestvalue2 = calcAlgoValue[DS:Size()-2] or 0
    
    if calcAlgoValue[DS:Size()] == nil or DS:Size() == 0 then return end
    local calcVal = calcAlgoValue[DS:Size()] or 0
    
    if INTERVALS["visible"][cell] then
        local colorGradation = math.floor((math.abs(calcVal- 50)/50)*(255-200))
        local Color = RGB(255, 255, 255)
        if calcVal<=50 then
            Color = RGB(math.max(255 - 0.5*colorGradation, 255), 255 - 3*colorGradation, 255 - 3*colorGradation) -- оттенки красного
        else
            Color = RGB(255 - 3*colorGradation, math.max(255 - 0.7*colorGradation, 255), 255 - 3.4*colorGradation) --оттенки зеленого
        end

        SetCell(t_id, i, tableIndex[cell], tostring(calcVal), calcVal)
        cellSetColor(i, tableIndex[cell], Color, RGB(0,0,0))
    end

    if signal then
        local isMessage = SEC_CODES['isMessage'][i]
        local isPlaySound = SEC_CODES['isPlaySound'][i]
        local mes0 = tostring(SEC_CODES['names'][i]).." timescale "..INTERVALS["names"][cell]
        local mes = ""

        if signaltestvalue1 < 50 and signaltestvalue2 > 50 then
            mes = mes0..": Сигнал Sell"
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if signaltestvalue1 > 50 and signaltestvalue2 < 50 then
            mes = mes0..": Сигнал Buy"
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        --Теперь смотрим за текущей ситуацией
        signaltestvalue1 = calcAlgoValue[DS:Size()] or 0
        signaltestvalue2 = calcAlgoValue[DS:Size()-1] or 0
        if signaltestvalue1 > 70 and signaltestvalue2 < 70 then
            mes = mes0..": RSI превысил 70"
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if signaltestvalue1 > 53 and signaltestvalue2 < 53 then
            mes = mes0..": RSI оттолкнулся от 50 "
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if signaltestvalue1 < 47 and signaltestvalue2 > 47 then
            mes = mes0..": RSI отскочил от 50 "
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end    
        if signaltestvalue1 > 30 and signaltestvalue2 < 30 then
            mes = mes0..": RSI оттолкнулся от 30 "
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if signaltestvalue1 < 70 and signaltestvalue2 > 70 then
            mes = mes0..": RSI отскочил от 70 "
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end    
    end    

end
