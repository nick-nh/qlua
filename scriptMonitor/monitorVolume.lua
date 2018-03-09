function initVolume()
    lastVolume = {}
    volumeEMA = {}
end

function Volume(iSec)

    local seccode = SEC_CODES['sec_codes'][iSec]
    local classcode = SEC_CODES['class_codes'][iSec]
    local period = 10                             -- период усреднения объема        
    local volumeFactor = 4                        -- превышение раз, чтоюы считать объем повышенным        
    local k = 2/(period+1)
    
    if volumeEMA[seccode] == nil then
        volumeEMA[seccode] = {}
    end
    
    local lastSECVolume = tonumber(getParamEx(classcode,seccode,"valtoday").param_value)
    --myLog(SEC_CODES['names'][i].." lastSECVolume: "..tostring(lastSECVolume))
    
    if lastVolume[seccode] == nil then
        lastVolume[seccode] = lastSECVolume
    end
    local intervalVolume = lastSECVolume - lastVolume[seccode]
    volumeEMA[seccode][#volumeEMA[seccode] + 1] = intervalVolume
    lastVolume[seccode] = lastSECVolume

 
    local ind = #volumeEMA[seccode]
    if ind==period then
        local sum = 0
        for n=2, ind do
            sum = sum + volumeEMA[seccode][n]
        end
        volumeEMA[seccode][ind] = sum/(ind-1)
    elseif ind>period then
        volumeEMA[seccode][ind]=round(k*volumeEMA[seccode][ind]+(1-k)*volumeEMA[seccode][ind-1], 5)
        
        local isMessage = SEC_CODES['isMessage'][iSec]
        local isPlaySound = SEC_CODES['isPlaySound'][iSec]
        local mes0 = tostring(SEC_CODES['names'][iSec])
        if intervalVolume > volumeEMA[seccode][ind]*volumeFactor then
            local mes = mes0..": прошел повышенный тиковый объем"
            myLog(mes)
            myLog("interval vol: "..tostring(intervalVolume))
            myLog(SEC_CODES['names'][iSec].." volEMA: "..tostring(volumeEMA[seccode][ind]))
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
    end  
end
