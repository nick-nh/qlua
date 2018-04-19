Settings=
{
	Name = "*VWAP",
	line =
	{		
		{
		Name = "VWAP",
		Color = RGB(0, 0, 255),
		Type = TYPE_LINE, --TYPE_DASHDOT,
		Width = 2
		},
		{
		Name = "pVWAP",
		Color = RGB(255, 128, 0),
		Type = TYPE_LINE, --TYPE_DASHDOT,
		Width = 2
		}
	}
}


function Init()
	return #Settings.line
end

DSInfo = nil

function OnCalculate(index)
    
    local vwap = nil
    local prevVwap = nil

    if index == 1 then
        DSInfo = getDataSourceInfo()     	
    end
    if index == Size() then
        SetValue(index-41, 1, nil)			        
        SetValue(index-1, 1, nil)			        
        SetValue(index-41, 2, nil)			        
        SetValue(index-1, 2, nil)			        
		vwap = tonumber(getParamEx(DSInfo.class_code, DSInfo.sec_code,"WAPRICE").param_value)
		prevVwap = tonumber(getParamEx(DSInfo.class_code, DSInfo.sec_code,"PREVWAPRICE").param_value)
		if vwap == 0 then vwap = nil end
        SetValue(index-40, 1,vwap)			        
        SetValue(index-40, 2,prevVwap)			        
	end
    
    return vwap, prevVwap
		
end