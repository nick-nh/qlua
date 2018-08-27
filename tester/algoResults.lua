--logfile=io.open(getWorkingFolder().."\\LuaIndicators\\qlua_log.txt", "w")

require("StaticVar")

Settings ={
    Name = "*algoResults",
    ChartId = "testGraphTQBR",
    line = 
        {
            {
            Name = "algoResults1",
            Color = RGB(255, 128, 128),
            Type = TYPE_LINE,
            Width = 2
            },
            {
            Name = "algoResults2",
            Color = RGB(128, 0, 0),
            Type = TYPE_LINE,
            Width = 2
            },
            {
            Name = "algoResults3",
            Color = RGB(0, 128, 128),
            Type = TYPE_LINE,
            Width = 2
            },
            {
            Name = "algoResults4",
            Color = RGB(128, 128, 255),
            Type = TYPE_LINE,
            Width = 2
            },
            {
            Name = "algoResults5",
            Color = RGB(128, 128, 128),
            Type = TYPE_LINE,
            Width = 2
            }
        }
    }	

function Init()
    algoF = getResults()
    return #Settings.line
end
 

function OnCalculate(index)	
	return algoF(index, Settings)
end

function getResults()
    

    local indValue = nil
    local outlines = {}

    return function(index, Fsettings)

        if index == Size() then
                    
            stv.UseNameSpace(Fsettings.ChartId)
            algoResults = stv.GetVar('algoResults')
            --WriteLog("ChartId "..tostring(Settings.ChartId).." algoResults "..tostring(algoResults).." # "..tostring(#algoResults))
            if algoResults ~= nil and type(algoResults) == "table" then
                
                local itisTable = false

                for k,v in pairs(algoResults) do                    
                    if type(v) == "table" then
                        itisTable = true
                    end
                    break		
                end

                if itisTable then                   
                    for i=1,index do
                        local maxCount = 0                    
                        for k,v in pairs(algoResults) do 
                            if maxCount == 5 then break end                   
                            if algoResults[k] == nil then
                                indValue = nil
                            else 
                                indValue = algoResults[k][i]                   
                            end                    
                            --WriteLog("line "..tostring(k).." index "..tostring(i).." "..tostring(indValue).." "..type(indValue))
                            maxCount = maxCount + 1
                            SetValue(i, maxCount, indValue)
                            if indValue~=nil then
                                outlines[maxCount] = indValue
                            end
                            --loadstring("out"..tostring(k).." = indValue")()
                            --WriteLog("out1 "..tostring(out1).." out2 "..tostring(out2))
                            --out1 = indValue
                            --out2 = indValue
                        end           
                    end
                else
                    for i=1,index do                    
                        indValue = algoResults[i]
                        --WriteLog("line "..tostring(1).." index "..tostring(i).." "..tostring(indValue).." "..type(indValue))
                        SetValue(i, 1, indValue)
                        SetValue(i, 2, nil)
                        SetValue(i, 3, nil)
                        SetValue(i, 4, nil)
                        SetValue(i, 5, nil)
                        if indValue~=nil then
                            outlines[1] = indValue
                        end
                end
                end
            end
            stv.SetVar('algoResults', nil)

        end

        return unpack(outlines)
    end
end
        
function WriteLog(text)

    logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n");
    logfile:flush();
    LASTLOGSTRING = text;
 
 end