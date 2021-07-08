Settings =
 {
	Name = "*HeikenAshi",
	line =
     {
         {
          Name = "HeikenAshiUP",
          Color = RGB(0,255,0),
          Type = TYPE_POINT,
          Width =3
         },
         {
          Name = "HeikenAshiDown",
          Color = RGB(255,0,0),
          Type = TYPE_POINT,
          Width =3
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
	myHA = HA()
	return #Settings.line
 end

 function OnCalculate(index)
	return myHA(index, Settings)
 end
 
 function HA()
	
	local cache_O={}
	local cache_C={}
	
	return function(ind, Fsettings)
		
		local Fsettings=(Fsettings or {})
		local index = ind

		local openHA
		local closeHA
		local highHA
		local lowHA
		
		local outDown
		local outUP
		
		if index == 1 then
			cache_O = {}
			cache_C = {}
			cache_O[index]= 0
			cache_C[index]= 0
			return nil
		end
		
		cache_O[index] = cache_O[index-1] 
		cache_C[index] = cache_C[index-1] 
		
		if not CandleExist(index) then
			return nil
		end

		cache_O[index]=O(index)
		cache_C[index]=C(index)
		
		openHA = (cache_O[index-1] + cache_C[index-1])/2
		closeHA = (O(index) + H(index) + L(index) + C(index))/4
		highHA = math.max(H(index), math.max(openHA, closeHA))
		lowHA = math.min(L(index), math.min(openHA, closeHA))
		
		cache_O[index] = openHA
		cache_C[index] = closeHA
		
		if openHA < closeHA then
			outDown = nil
			outUP = (H(index) + L(index))/2
		elseif openHA > closeHA then
			outDown = (H(index) + L(index))/2
			outUP = nil
		end
		
		return outUP, outDown
			
	end
end

function round(num, idp)
if idp and num then
   local mult = 10^(idp or 0)
   if num >= 0 then return math.floor(num * mult + 0.5) / mult
   else return math.ceil(num * mult - 0.5) / mult end
else return num end
end
