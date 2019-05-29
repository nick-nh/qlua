Settings = {
Name        = "*ATR (Average True Range)", 
round       = "off",
Period      = 14,
inPercent   = 1,
line = {{
    Name = "ATR", 
    Type = TYPE_LINE, 
    Color = RGB(0, 0, 0)
    }
    }
}
            
function Init() 
    func = ATR()
    return #Settings.line
end

function OnCalculate(Index) 
    return func(Index, Settings)
end

function ATR() --Average True Range ("ATR")
    local f_TR = TR()
    local ATR = {}
    return function (I, Fsettings, ds)
        local Out = nil
        local Fsettings = (Fsettings or {})
        local P         = (Fsettings.Period or 14)
        local R         = (Fsettings.round or "off")
        local PR        = (Fsettings.inPercent or 0)
        if I<P then
            ATR[I] = 0
        elseif I==P then
            local sum=0
            for i = 1, P do
                sum = sum +f_TR(i,{round="off"},ds)*(PR == 1 and (200/(Value(I,"High",ds) + Value(I,"Low",ds))) or 1)
            end
            ATR[I]=sum / P
        elseif I>P then
            ATR[I]=(ATR[I-1] * (P-1) + f_TR(I,{round="off"},ds)*(PR == 1 and (200/(Value(I,"High",ds) + Value(I,"Low",ds))) or 1)) / P
        end
        if I>=P then
            Out = ATR[I]
            return rounding(Out, R)
        else
            return nil
        end
    end
end

function TR() --True Range ("TR")
    return function (I, Fsettings, ds)
        local Fsettings=(Fsettings or {})
        local R = (Fsettings.round or "off")
        local Out = nil
        if I==1 then
            Out =   math.abs(Value(I,"Difference", ds))
        else
            Out =   math.max(math.abs(Value(I,"Difference", ds)), 
                    math.abs(Value(I,"High",ds) - Value(I-1,"Close",ds)), 
                    math.abs(Value(I-1,"Close",ds)-Value(I,"Low",ds)))
        end
        return rounding(Out, R)
    end
end

function rounding(num, round) 
    if round and string.upper(round)== "ON" then round=0 end
    if num and tonumber(round) then
        local mult = 10^round
        if num >= 0 then return math.floor(num * mult + 0.5) / mult
        else return math.ceil(num * mult - 0.5) / mult end
    else return num end
end

function Value(I,VType,ds) 
local Out = nil
VType=(VType and string.upper(string.sub(VType,1,1))) or "A"
    if VType == "O" then        --Open
        Out = (O and O(I)) or (ds and ds:O(I))
    elseif VType == "H" then    --High
        Out = (H and H(I)) or (ds and ds:H(I))
    elseif VType == "L" then    --Low
        Out = (L and L(I)) or (ds and ds:L(I))
    elseif VType == "C" then    --Close
        Out = (C and C(I)) or (ds and ds:C(I))
    elseif VType == "V" then    --Volume
        Out = (V and V(I)) or (ds and ds:V(I)) 
    elseif VType == "M" then    --Median
        Out = ((Value(I,"H",ds) + Value(I,"L",ds)) / 2)
    elseif VType == "T" then    --Typical
        Out = ((Value(I,"M",ds) * 2 + Value(I,"C",ds))/3)
    elseif VType == "W" then    --Weighted
        Out = ((Value(I,"T",ds) * 3 + Value(I,"O",ds))/4) 
    elseif VType == "D" then    --Difference
        Out = (Value(I,"H",ds) - Value(I,"L",ds))
    elseif VType == "A" then    --Any
        if ds then Out = ds[I] else Out = nil end
    end
return Out
end
