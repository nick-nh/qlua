--logfile=io.open(getWorkingFolder().."\\LuaIndicators\\openHour.txt", "w")

Settings = 
{ 
Name = "*hour open",
showMaxMin = 0, 
line = 
    { 
 
        { 
            Name = "HourOpen", 
            Color = RGB (0, 128, 255), 
            Type = TYPET_BAR, 
            Width = 2 
        }, 
        { 
            Name = "HourMax", 
            Color = RGB (89, 213, 107), 
            Type = TYPET_BAR, 
            Width = 2 
        }, 
        { 
            Name = "HourMin", 
            Color = RGB (251, 82, 0), 
            Type = TYPET_BAR, 
            Width = 2 
        }, 
        { 
            Name = "HourMiddle", 
            Color = RGB (128, 128, 128), 
            Type = TYPET_BAR, 
            Width = 2 
        } 
    } 
} 

function WriteLog(text)

    logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n");
    logfile:flush();
    LASTLOGSTRING = text;
 
 end

function Init ()
    return #Settings.line -- кол-во линий 
end 

hourOpen = nil 
hourMax = nil
hourMin = nil
HourMiddle = nil
hourOpenIndex = 0
Close = {}
Open = {}
High = {}
Low = {}

function OnCalculate (index) 
    
    if index == 1 then 
        local source_info	= getDataSourceInfo() 
        if source_info.interval > 60 then 
            message("interval must be less then 60")
            return nil
        end 
        hourOpen = nil 
        hourMax = nil
        hourMin = nil
        HourMiddle = nil
        hourOpenIndex = 1
        Close = {}
        Close[index] = C(index)
        Open = {}
        Open[index] = O(index)
        High = {}
        High[index] = H(index)
        Low = {}
        Low[index] = L(index)
        return nil
    end 
    
    Close[index] = Close[index-1]
    Open[index]  = Open[index-1]
    High[index]  = High[index-1]
    Low[index]   = Low[index-1]
     
    if not CandleExist(index) then return hourOpen end

    Close[index] = C(index)
    Open[index] = O(index)
    High[index] = H(index)
    Low[index] = L(index)
    
    local t = T(index) 
    local t1 = T(hourOpenIndex) 
    
    if t.hour > t1.hour or t.week_day ~= t1.week_day then 
        if Settings.showMaxMin==1 then 
            --hourMax = math.max(Close[hourOpenIndex], Open[hourOpenIndex])
            --hourMin = math.min(Close[hourOpenIndex], Open[hourOpenIndex])
            hourMax = High[hourOpenIndex]
            hourMin = Low[hourOpenIndex]
            for i=hourOpenIndex+1,index-1 do
                --hourMax = math.max(Close[i], Open[i], hourMax)
                --hourMin = math.min(Close[i], Open[i], hourMin)
                hourMax = math.max(High[i], hourMax)
                hourMin = math.min(Low[i], hourMin)
            end
            HourMiddle = (hourMax+hourMin)/2 
            for i=hourOpenIndex,index-1 do
                SetValue(i, 2, hourMax)				
                SetValue(i, 3, hourMin)				
                SetValue(i, 4, HourMiddle)				
            end
        end
        hourOpenIndex = index 
        hourOpen = O(index) 
    end
    
    return hourOpen 
end
