--logfile=io.open(getWorkingFolder().."\\LuaIndicators\\priceProfile_log.txt", "w")

require("StaticVar")

Settings ={
    Name = "*priceProfile",
    shift = 150,
    ChartId = "Sheet11"
}	

lines = 150

function Init()
	Settings.line = {}
	for i = 1, lines do
		Settings.line[i] = {}
		Settings.line[i] = {Color = RGB(185, 185, 185), Type = TYPE_LINE, Width = 2}
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
	--local calculated_buffer={}

    return function(index, Fsettings)

        local shift = Fsettings.shift or 150
        local bars = 50

		if index == 1 then
			--calculated_buffer = {}
            outlines = {}
            for i=1,lines do
                outlines[i] = {index = 1, val = nil}
            end
            return nil
        end
        
        if index == Size() then
                    
            stv.UseNameSpace(Fsettings.ChartId)
            algoResults = stv.GetVar('priceProfile')
            
            priceProfile = {}

            if algoResults ~= nil and type(algoResults) == "table" then -- and calculated_buffer[index] == nil
                
                --WriteLog("ChartId "..tostring(Settings.ChartId).." algoResults "..tostring(algoResults).."  "..tostring(type(algoResults)))
                
                --WriteLog('----------------------')
                --WriteLog('index '..tostring(index))

                for i=1,lines do
                    
                    SetValue(index-shift-1,          i, nil)
                    SetValue(index-shift,            i, nil)
                    SetValue(outlines[i].index,   i, nil)
                    
                    outlines[i].index = index-shift
                    outlines[i].val = nil
                end            

                local MAXV = 0
                
                for i, profileItem in pairs(algoResults) do
                    MAXV=math.max(MAXV,profileItem.vol)
                end
                
                --WriteLog('maxV '..tostring(MAXV))
                
                local maxCount = 0 
                for i, profileItem in pairs(algoResults) do
                    
                    maxCount = maxCount + 1
                    profileItem.vol=math.floor(profileItem.vol/MAXV*bars)
                    
                    outlines[maxCount].index = index-shift+profileItem.vol
                    outlines[maxCount].val = profileItem.price

                    SetValue(index-shift,                 maxCount, outlines[maxCount].val)
                    SetValue(outlines[maxCount].index, maxCount, outlines[maxCount].val)
                    
                    if maxCount == lines then break end
                end

                --calculated_buffer[index] = true
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
