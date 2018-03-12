function initVSA()
    cache_volEMA = nil
end

function VSA(iSec, ind, settings, DS)

    local period = settings.period or 29            -- period        
    local Size = settings.Size or 1000 
    local volumeFactor = settings.volumeFactor or 1
    local k = 2/(period+1)
    if ind == nil then ind = DS:Size() end
    Size = math.min(Size, DS:Size()) - 2

    if SEC_CODES['volEMA'] == nil then
        SEC_CODES['volEMA'] = {}
    end
    if SEC_CODES['volEMA'][iSec] == nil then   
        SEC_CODES['volEMA'][iSec] = {}
        cache_volEMA = {}     
    else
        cache_volEMA = SEC_CODES['volEMA'][iSec]     
    end    
    
    if ind ==0 then
        return cache_volEMA
    elseif ind == DS:Size() then

        if cache_volEMA[ind-1] == nil then            
            --первый расчет
            cache_volEMA[ind-Size-1] = (DS:C(ind)+DS:O(ind))/2			
            
            -- расчет EMA объема 
            for index = ind-Size, DS:Size() do
                cache_volEMA[index] = cache_volEMA[index-1] 
                
                if DS:C(index) ~= nil then
                    cache_volEMA[index]=round(k*math.pow(DS:V(index), volumeFactor)+(1-k)*cache_volEMA[index-1], 5)
                end        
            end
        end

        if DS:C(ind) ~= nil then
            --myLog(SEC_CODES['names'][iSec].." ind "..tostring(ind).." cache_volEMA: "..tostring(cache_volEMA[ind-1]))
            cache_volEMA[ind]=round(k*math.pow(DS:V(ind), volumeFactor)+(1-k)*cache_volEMA[ind-1], 5)
        end        
        
    end
    
    SEC_CODES['volEMA'][iSec] = cache_volEMA
    return cache_volEMA 

end

function signalVSA(i, cell, settings, DS, signal)

    if signal then

        local period = settings.period or 29            -- period        
        local volumeFactor = settings.volumeFactor or 1
        local overEMAVolumeFactor = settings.overEMAVolumeFactor or 2
        local useClosePrice = settings.useClosePrice or true
        
        index = DS:Size()-1
        cache_volEMA = SEC_CODES['volEMA'][i]     
        --myLog(SEC_CODES['names'][i].." ind "..tostring(index).." cache_volEMA: "..tostring(cache_volEMA[index]).." ind vol: "..tostring(DS:V(index)))
 
        local priceMin = DS:L(index)
        local priceMax = DS:H(index) 

        if useClosePrice then           
            priceMin = math.min(DS:O(index), DS:C(index))
            priceMax = math.max(DS:O(index), DS:C(index))
        end

        local volClimaxCurrent = DS:V(index) * (priceMax - priceMin)
        local volChurnCurrent = 0
        
        if volClimaxCurrent > 0 then       
            volChurnCurrent = DS:V(index) / (priceMax - priceMin)
        end
        
        local volClimaxLocal = 0
        local volChurnLocal = 0
        local climax = 0
        local churn = 0
        local priceMinLocal = 0
        local priceMaxLocal = 0

        local isChurn = false
        local isClimaxHigh = false
        local isClimaxChurn = false
        local isClimaxLow = false
        
        for n=index-period + 1,index do
        
            if DS:C(n) ~= nil then
            
                priceMinLocal = DS:L(n)
                priceMaxLocal = DS:H(n)
                    
                if useClosePrice then           
                    priceMinLocal = math.min(DS:O(n), DS:C(n))
                    priceMaxLocal = math.max(DS:O(n), DS:C(n))
                end
                    
                climax = DS:V(n) * (priceMaxLocal - priceMinLocal) 
                
                -- Previous maximal price range can be found here                
                if climax >= volClimaxLocal then
                    volClimaxLocal = climax
                end
                
                -- Previous consolidation can be found her                
                if climax > 0 then           
                    churn = DS:V(n) / (priceMaxLocal - priceMinLocal)                   
                    if churn >= volChurnLocal then
                        volChurnLocal = churn 
                    end
                end
                    
            end
            
        end
                    
        
        if (volClimaxCurrent == volClimaxLocal and DS:C(index) < (priceMax + priceMin) / 2) then
            -- When volume is higher than all previous and price is going down - start or end of the down trend
            isClimaxLow = true --Climax Low
        elseif (volClimaxCurrent == volClimaxLocal and volChurnCurrent == volChurnLocal) then
            -- When volume is extra high and price is not changing - absolute consolidation or fast accummulation / distribution
           isClimaxChurn = true --Climax Churn
        elseif (volClimaxCurrent == volClimaxLocal and DS:C(index) > (priceMax + priceMin) / 2) then
            -- When volume is higher than all previous and price is going up - start or end of the up trend
            isClimaxHigh = true --Climax High
        elseif (volChurnCurrent == volChurnLocal) then
            -- When volume is equal to one seen before mark it as accummulation / distribution - profit is taken
            isChurn = true --Churn                        
        end
    
        local isMessage = SEC_CODES['isMessage'][i]
        local isPlaySound = SEC_CODES['isPlaySound'][i]
        local mes0 = tostring(SEC_CODES['names'][i])
        if DS:V(index) > cache_volEMA[index]*overEMAVolumeFactor then
            local mes = mes0..": прошел повышенный объем"
            myLog(mes)
            --myLog("interval vol: "..tostring(DS:V(index-1)))
            --myLog(SEC_CODES['names'][iSec].." volEMA: "..tostring(cache_volEMA[index]))
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if isClimaxHigh then
            local mes = mes0..": прошел повышенный объем на росте: Climax High"
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if isClimaxLow then
            local mes = mes0..": прошел повышенный объем на падении: Climax Low"
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if isChurn then
            local mes = mes0..": прошел повышенный объем на малом спреде: Churn"
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if isClimaxChurn then
            local mes = mes0..": прошел повышенный объем на большом спреде: Climax Churn"
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end

    end --signal

end
