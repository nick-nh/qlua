Settings = 
{ 
Name = "*WeekDayOpen",
showDay = 0,
showWeek = 1,
showMaxMin = 0, 
line = 
    { 
        { 
            Name = "dayOpen", 
            Color = RGB (0, 255, 0), 
            Type = TYPET_BAR, 
            Width = 2 
        }, 
        { 
            Name = "dayMax", 
            Color = RGB (89, 213, 107), 
            Type = TYPET_BAR, 
            Width = 2 
        }, 
        { 
            Name = "dayMin", 
            Color = RGB (251, 82, 0), 
            Type = TYPET_BAR, 
            Width = 2 
        }, 
        { 
            Name = "dayMiddle", 
            Color = RGB (128, 128, 128), 
            Type = TYPET_BAR, 
            Width = 2 
        }, 
        { 
            Name = "weekOpen", 
            Color = RGB (0, 128, 255), 
            Type = TYPET_BAR, 
            Width = 2 
        }, 
        { 
            Name = "weekMax", 
            Color = RGB (89, 213, 107), 
            Type = TYPET_BAR, 
            Width = 2 
        }, 
        { 
            Name = "weekMin", 
            Color = RGB (251, 82, 0), 
            Type = TYPET_BAR, 
            Width = 2 
        }, 
        { 
            Name = "weekMiddle", 
            Color = RGB (128, 128, 128), 
            Type = TYPET_BAR, 
            Width = 2 
        } 
    } 
} 

dayOpen = nil 
dayMax = nil 
dayMin = nil 
dayMiddle = nil
weekOpen = nil 
weekMax = nil 
weekMin = nil 
weekMiddle = nil
dayOpenIndex = 0 
weekOpenIndex = 0
Close = {}
Open = {}
High = {}
Low = {}


function Init ()
    return #Settings.line -- кол-во линий 
end 


function OnCalculate (index)
    
    if index == 1 then
        dayOpen = nil 
        dayMax = nil 
        dayMin = nil 
        dayMiddle = nil 
        weekOpen = nil 
        weekMax = nil 
        weekMin = nil 
        weekMiddle = nil 
        dayOpenIndex = 1
        weekOpenIndex = 1
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
     
    if not CandleExist(index) then return dayOpen, nil, nil, nil, weekOpen end

    Close[index] = C(index)
    Open[index] = O(index)
    High[index] = H(index)
    Low[index] = L(index)
           
    local t = T(index) 
    local t1 = T(index-1) 

    if (t.day > t1.day or t.month > t1.month or t.year > t1.year) and Settings.showDay == 1 then 
        if Settings.showMaxMin==1 then 
            --dayMax = math.max(Close[dayOpenIndex], Open[dayOpenIndex])
            --dayMin = math.min(Close[dayOpenIndex], Open[dayOpenIndex])
            dayMax = High[dayOpenIndex]
            dayMin = Low[dayOpenIndex]
            for i=dayOpenIndex+1,index-1 do
                --dayMax = math.max(Close[i], Open[i], dayMax)
                --dayMin = math.min(Close[i], Open[i], dayMin)
                dayMax = math.max(High[i], dayMax)
                dayMin = math.min(Low[i], dayMin)
            end
            dayMiddle = (dayMax+dayMin)/2 
            for i=dayOpenIndex,index-1 do
                SetValue(i, 2, dayMax)				
                SetValue(i, 3, dayMin)				
                SetValue(i, 4, dayMiddle)				
            end
        end
        dayOpenIndex = index 
        dayOpen = O(index) 
    end
    if (t.week_day < t1.week_day or t.month > t1.month or t.year > t1.year) and Settings.showWeek == 1 then 
        if Settings.showMaxMin==1 then 
            --weekMax = math.max(Close[weekOpenIndex], Open[weekOpenIndex])
            --weekMin = math.min(Close[weekOpenIndex], Open[weekOpenIndex])
            weekMax = High[weekOpenIndex]
            weekMin = Low[weekOpenIndex]
            for i=weekOpenIndex+1,index-1 do
                --weekMax = math.max(Close[i], Open[i], weekMax)
                --weekMin = math.min(Close[i], Open[i], weekMin)
                weekMax = math.max(High[i], weekMax)
                weekMin = math.min(Low[i], weekMin)
            end
            weekMiddle = (weekMax+weekMin)/2 
            for i=weekOpenIndex,index-1 do
                SetValue(i, 6, weekMax)				
                SetValue(i, 7, weekMin)				
                SetValue(i, 8, weekMiddle)				
            end
        end
        weekOpenIndex = index 
        weekOpen = O(index) 
    end
    
    return dayOpen, nil, nil, nil, weekOpen 
end
