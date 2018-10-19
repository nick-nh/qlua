--logfile=io.open(getWorkingFolder().."\\LuaIndicators\\priceProfile_log.txt", "w")

require("StaticVar")

Settings ={
    Name = "*priceProfile",
    shift = 150,
    ChartId = "Sheet11"
}	

lines = 150
min_price_step = 1
scale = 2

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

    if index == 1 then
		DSInfo = getDataSourceInfo()     	
		min_price_step = getParamEx(DSInfo.class_code, DSInfo.sec_code, "SEC_PRICE_STEP").param_value
		scale = getSecurityInfo(DSInfo.class_code, DSInfo.sec_code).scale
	end

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
            outlines = {}
            return nil
        end

        if index == Size() then
                    
            stv.UseNameSpace(Fsettings.ChartId)
            algoResults = stv.GetVar('priceProfile')
            
            priceProfile = {}

            if algoResults ~= nil and type(algoResults) == "table" and calculated_buffer[index] == nil then -- 
                
                --WriteLog("ChartId "..tostring(Settings.ChartId).." algoResults "..tostring(algoResults).."  "..tostring(type(algoResults)))               
                --WriteLog('----------------------')
                --WriteLog('index '..tostring(index))

                for i=1,#outlines do                   
                    --WriteLog('line '..tostring(i).." price "..tostring(GetValue(index-shift-1, i)).." - "..tostring(GetValue(outlines[i].index, i)).." vol "..tostring(outlines[i].index-index+151))
                
                    SetValue(index-shift-1,          i, nil)
                    SetValue(index-shift,            i, nil)
                    SetValue(outlines[i].index,   i, nil)
                    
                    outlines[i].index = index-shift
                    outlines[i].val = nil
                end            

                local MAXV = 0
                local maxPrice = 0
                --local maxPrice = 0
                --local minPrice = H(index)
                
                local maxCount = 0 
                for i, profileItem in pairs(algoResults) do
                    MAXV=math.max(MAXV,profileItem.vol)
                    maxPrice=math.max(maxPrice,profileItem.price)
                    --maxPrice=math.max(maxPrice,profileItem.price)
                    --minPrice=math.max(minPrice,profileItem.price)
                    maxCount = maxCount + 1
                    priceProfile[maxCount] = {price = profileItem.price, vol = profileItem.vol}
                end
                
                if maxPrice == 0 then
                   maxPrice = O(index) 
                end
                
                table.sort(priceProfile, function(a,b) return (a['vol'] or 0) > (b['vol'] or 0) end)

                --WriteLog('maxV '..tostring(MAXV)..' tblMax '..tostring(priceProfile[1].vol))
                --WriteLog('new set')
                
                --local clasterStep = math.floor((maxPrice - minPrice)*lines)
                --local profileLines = #priceProfile

                for i=1,lines do                                        

                    outlines[i] = {index = index-shift+bars, val = maxPrice}

                    if priceProfile[i]~=nil then
                        
                        --if profileLines>lines then
                        --    priceProfile[i].price = math.floor(priceProfile[i].price/clasterStep)*clasterStep
                        --end       

                        priceProfile[i].vol=math.floor(priceProfile[i].vol/MAXV*bars) 

                        if priceProfile[i].vol>0 then
                            outlines[i].index = index-shift+priceProfile[i].vol
                            outlines[i].val = priceProfile[i].price                           
                        end                                               
                    end                   
                    SetValue(index-shift,       i, outlines[i].val)
                    SetValue(outlines[i].index, i, outlines[i].val)
                    --WriteLog('line '..tostring(i).." price "..tostring(GetValue(index-shift, i)).." - "..tostring(GetValue(outlines[i].index, i)).." vol "..tostring(outlines[i].index-index+shift))
                end                

                calculated_buffer[index] = true
                --stv.SetVar('priceProfile', nil)
            end
        end

        return nil
    end
end
        
function WriteLog(text)

    logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n");
    logfile:flush();
    LASTLOGSTRING = text;
 
 end
