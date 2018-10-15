Settings = {}
Settings.Name = '*bar index'
Settings.line = 
{
    {
    Name = "bar index",
    Color = RGB(0, 0, 0),
    Type = TYPE_HISTOGRAM,
    Width = 2
    }
}

function Init()
    return #Settings.line
end
 
function OnCalculate(index)	
	return index
end
