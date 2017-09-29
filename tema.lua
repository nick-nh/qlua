Settings =
 {
	Name = "*TEMA",
	periodTEMA = 112,
	vTypeTEMA = "C",
	periodEMA = 64,
	vTypeEMA = "C",
	showTEMA = 1,
	showEMA = 1,
	line =
     {
         {
          Name = "TEMA",
          Color = RGB(255,0,0),
          Type = TYPE_LINE,
          Width =2
         },
         {
          Name = "EMA",
          Color = RGB(128,0,0),
          Type = TYPE_LINE,
          Width =2
         }
     }
 }

function dValue(i,param)
local v = param or "C"
	
	if not CandleExist(i) then
		return nil
	end
	
	if  v == "O" then
		return O(i)
	elseif   v == "H" then
		return H(i)
	elseif   v == "L" then
		return L(i)
	elseif   v == "C" then
		return C(i)
	elseif   v == "V" then
		return V(i)
	elseif   v == "M" then
		return (H(i) + L(i))/2
	elseif   v == "T" then
		return (H(i) + L(i)+C(i))/3
	elseif   v == "W" then
		return (H(i) + L(i)+2*C(i))/4
	elseif   v == "ATR" then
		local previous = math.max(i-1, 1)
			
		if not CandleExist(previous) then
			previous = FindExistCandle(previous)
		end
		if previous == 0 then
			return 0
		end
	
		return math.max(math.abs(H(i) - L(i)), math.abs(H(i) - C(previous)), math.abs(C(previous) - L(i)))
	else
		return C(i)
	end 
end

function FindExistCandle(I)

	local out = I
	
	while not CandleExist(out) and out > 0 do
		out = out -1
	end	
	
	return out
 
end

 function Init()
	myTEMA = TEMA()
	return #Settings.line
 end

 function OnCalculate(index)
	return myTEMA(index, Settings)
 end
 
 function TEMA()
	
	local cache_EMA={}
	local cache_TEMA1={}
	local cache_TEMA2={}
	local cache_TEMA3={}
	
	return function(ind, Fsettings)
		
		local Fsettings=(Fsettings or {})
		local index = ind
		local periodTEMA = Fsettings.periodTEMA or 112
		local showTEMA = Fsettings.showTEMA or 1
		local vTypeTEMA = Fsettings.vTypeTEMA or "C"
		local periodEMA = Fsettings.periodEMA or 63
		local showEMA = Fsettings.showEMA or 1
		local vTypeEMA = Fsettings.vTypeEMA or "C"

		local kTEMA = 2/(periodTEMA+1)
		local kEMA = 2/(periodEMA+1)
		
		local valueTEMA = 0
		local valueEMA = 0
		
		local outTEMA = nil
		local outEMA = nil

		if index == 1 then
			cache_EMA = {}
			cache_TEMA1 = {}
			cache_TEMA2 = {}
			cache_TEMA3 = {}
			if CandleExist(index) then
				cache_EMA[index]= dValue(index, vTypeEMA)
				cache_TEMA1[index]= dValue(index, vTypeTEMA)
				cache_TEMA2[index]= dValue(index, vTypeTEMA)
				cache_TEMA3[index]= dValue(index, vTypeTEMA)
			else 
				cache_EMA[index]= 0
				cache_TEMA1[index]= 0
				cache_TEMA2[index]= 0
				cache_TEMA3[index]= 0
			end
			return nil
		end
		
		cache_EMA[index] = cache_EMA[index-1] 
		cache_TEMA1[index] = cache_TEMA1[index-1] 
		cache_TEMA2[index] = cache_TEMA2[index-1]
		cache_TEMA3[index] = cache_TEMA3[index-1]
		
		if not CandleExist(index) then
			return nil
		end

		valueTEMA = dValue(index, vTypeTEMA)	
		cache_TEMA1[index]=kTEMA*valueTEMA+(1-kTEMA)*cache_TEMA1[index-1]
		cache_TEMA2[index]=kTEMA*cache_TEMA1[index]+(1-kTEMA)*cache_TEMA2[index-1]
		cache_TEMA3[index]=kTEMA*cache_TEMA2[index]+(1-kTEMA)*cache_TEMA3[index-1]
		
		valueEMA = dValue(index, vTypeEMA)	
		cache_EMA[index]=kEMA*valueEMA+(1-kEMA)*cache_EMA[index-1]
		
		if showTEMA == 1 then
			outTEMA = 3*cache_TEMA1[index] - 3*cache_TEMA2[index] + cache_TEMA3[index]
		end
		if showEMA == 1 then
			outEMA = cache_EMA[index]
		end
		
		return outTEMA, outEMA
			
	end
end

function round(num, idp)
if idp and num then
   local mult = 10^(idp or 0)
   if num >= 0 then return math.floor(num * mult + 0.5) / mult
   else return math.ceil(num * mult - 0.5) / mult end
else return num end
end
