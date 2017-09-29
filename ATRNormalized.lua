Settings = {
Name = "*ATR Normalized + DayRange", 
round = "off",
showATR = 1,
Period = 64,
NATR = 0,
NATR_percent = 20,
line = {
	{
	Name = "Day Range Pos",
	Type = TYPE_HISTOGRAM, 
	Color = RGB(128, 255, 128),
	Width = 4
	},
	{
	Name = "Day Range Neg",
	Type = TYPE_HISTOGRAM, 
	Color = RGB(255, 128, 128),
	Width = 4
	},
	{
	Name = "ATR", 
	Type = TYPE_LINE, 
	Color = RGB(0, 0, 0),
	Width = 2
	},
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
		local Fsettings=(Fsettings or {})
		local P = (Fsettings.Period or 64)
		local showATR = (Fsettings.showATR or 1)
		local R = (Fsettings.round or "off")
		local NATR_percent = (Fsettings.NATR_percent or 0)
		local NATR = (Fsettings.NATR or 0)
		local delta = 0
		
		local previous = I-1
			
		if not CandleExist(previous) then
			previous = FindExistCandle(previous)
		end
		if CandleExist(I) and previous ~= 0 then
			delta=C(I)-C(previous)
			out_incrementum = math.abs(delta)
		else
			out_incrementum = 0
		end
		
		if showATR == 1 then	
			if NATR == 0 then
			
				if I<P then
					ATR[I] = 0
				elseif not CandleExist(I) then
					ATR[I] = ATR[I-1]
				elseif I==P then
					local sum=0
					for i = 1, P do
						sum = sum +f_TR(i,{round="off"},ds)
					end
					ATR[I]=sum / P
				elseif I>P then
					ATR[I]=(ATR[I-1] * (P-1) + f_TR(I,{round="off"},ds)) / P
				end
				
				Out = ATR[I]
				
			else
			
				local myATR = {}

				for i = 0, P-1 do
					myATR[i] = f_TR(I-i,{round="off"},ds)		
				end
				
				table.sort(myATR)
				
				local cut_num = math.ceil((P*NATR_percent)*0.01/2)
				local sred = 0
				
				for i = cut_num, P-cut_num-1 do
					sred = sred + myATR[i]		
				end
				
				Out=sred/(P-cut_num*2)
				
			end
		end
		
		if I>=P then
			if delta>0 then 
				return out_incrementum, nil, rounding(Out, R)
			else 
				return nil, out_incrementum, rounding(Out, R)
			end
		else
			return 0,0,nil
		end
		
	end
end

	----------------------------
function FindExistCandle(I)

	local out = I
	
	while not CandleExist(out) and out > 0 do
		out = out -1
	end	
	
	return out
 
end

function TR() --True Range ("TR")
	return function (I, Fsettings, ds)
	local Fsettings=(Fsettings or {})
	local R = (Fsettings.round or "off")
	local Out = nil
	local previous = I-1
		
	if not CandleExist(I) then
		return 0
	end
	if not CandleExist(previous) then
		previous = FindExistCandle(previous)
	end
	
	if previous == 0 then
		return 0
	end
	
	if I==1 then
		Out = math.abs(Value(I,"Difference", ds))
	else	
		Out = math.max(math.abs(Value(I,"Difference", ds)), 
			math.abs(Value(I,"High",ds) - Value(previous,"Close",ds)), 
			math.abs(Value(previous,"Close",ds)-Value(I,"Low",ds)))
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
	if VType == "O" then		--Open
		Out = (O and O(I)) or (ds and ds:O(I))
	elseif VType == "H" then 	--High
		Out = (H and H(I)) or (ds and ds:H(I))
	elseif VType == "L" then	--Low
		Out = (L and L(I)) or (ds and ds:L(I))
	elseif VType == "C" then	--Close
		Out = (C and C(I)) or (ds and ds:C(I))
	elseif VType == "V" then	--Volume
		Out = (V and V(I)) or (ds and ds:V(I)) 
	elseif VType == "M" then	--Median
		Out = ((Value(I,"H",ds) + Value(I,"L",ds)) / 2)
	elseif VType == "T" then	--Typical
		Out = ((Value(I,"M",ds) * 2 + Value(I,"C",ds))/3)
	elseif VType == "W" then	--Weighted
		Out = ((Value(I,"T",ds) * 3 + Value(I,"O",ds))/4) 
	elseif VType == "D" then	--Difference
		Out = (Value(I,"H",ds) - Value(I,"L",ds))
	elseif VType == "A" then	--Any
		if ds then Out = ds[I] else Out = nil end
	end
return Out
end
