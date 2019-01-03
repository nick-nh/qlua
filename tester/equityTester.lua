--logfile=io.open(getWorkingFolder().."\\LuaIndicators\\qlua_log.txt", "w")

require("StaticVar")

Settings ={
    Name = "*equity",
    ChartId = "testGraph",
    line = 
        {
            {
            Name = "equity",
            Color = RGB(0, 0, 0),
            Type = TYPE_LINE,
            Width = 2
            }
        }
    }	

equity = nil    

function Init()
    return 1
end

out = nil

function OnCalculate(index)
    
    local indValue = nil

    if index == Size() then
        
        stv.UseNameSpace(Settings.ChartId)
        equity = stv.GetVar('equity')
        if equity ~= nil then
            
            out = nil
            for i=1,index do
                indValue = equity[i]
                --WriteLog("ind "..tostring(i).." val "..tostring(indValue))
                SetValue(i, 1, indValue)
                if indValue ~= nil then
                    out = indValue
                end
            end

            stv.SetVar('equity', nil)

        end
    end

    return out

end
        
function WriteLog(text)

    logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n");
    logfile:flush();
    LASTLOGSTRING = text;
 
 end
