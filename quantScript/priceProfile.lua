--logfile=io.open(getWorkingFolder().."\\LuaIndicators\\qlua_log.txt", "w")

require("StaticVar")

Settings ={
    Name = "*priceProfile",
    shift = 150,
    ChartId = "testGraphTQBR"
}	

lines = 150

function Init()
	Settings.line = {}
	for i = 1, lines do
		Settings.line[i] = {}
		Settings.line[i] = {Color = RGB(165, 165, 165), Type = TYPE_LINE, Width = 2}
    end
        
    algoF = getResults()
    return lines
end
 

function OnCalculate(index)	
	return algoF(index, Settings)
end

function getResults()
    
    local outlines = {}
    local priceProfile = {}
	local calculated_buffer={}

    return function(index, Fsettings)

        local shift = Fsettings.shift or 150
        local bars = 50

		if index == 1 then
			calculated_buffer = {}
			return nil
        end
        
        if index == Size() then
                    
            stv.UseNameSpace(Fsettings.ChartId)
            algoResults = stv.GetVar('priceProfile')
            
            priceProfile = {}
            outlines = {}
            
            if algoResults ~= nil and type(algoResults) == "table" and calculated_buffer[index] == nil then
                
                --WriteLog("ChartId "..tostring(Settings.ChartId).." algoResults "..tostring(algoResults).."  "..tostring(type(algoResults)))
                
                for i=1,lines do
                    SetValue(index-shift-1, i, nil)
                    for j = 1, bars do
                        SetValue(index-shift+j-1, i, nil)
                    end
                end

                MAXV = 0
                local maxCount = 0 

                for i, profileItem in pairs(algoResults) do
                    MAXV=math.max(MAXV,profileItem.vol)
                end
                
                --WriteLog('maxV '..tostring(MAXV))

                for i, profileItem in pairs(algoResults) do
                    maxCount = maxCount + 1
                    profileItem.vol=math.floor(profileItem.vol/MAXV*bars)
                    --WriteLog('price '..tostring(profileItem.price)..' vol '..tostring(profileItem.vol))
                    for j = 1, profileItem.vol do
                        --WriteLog('set at index '..tostring(index-shift+j-1)..' line '..tostring(maxCount)..' price '..tostring(profileItem.price))
                        SetValue(index-shift+j-1, maxCount, profileItem.price)
                    end
                    if maxCount == lines then break end
                end

                calculated_buffer[index] = true
            end

            --stv.SetVar('priceProfile', nil)

        end

        return nil
    end
end
        
function WriteLog(text)

    logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n");
    logfile:flush();
    LASTLOGSTRING = text;
 
 end
