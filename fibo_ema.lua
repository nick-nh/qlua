
Settings = 
{
	Name = "*FiboEma",
	period = 30,
	bars = 100,
	line=
	{
		{
			Name = "EMA",
			Color = RGB(0, 128, 0),
			Type = TYPE_LINE,
			Width = 2
		}
	,
		{
			Name = "423.6%",
			Color = RGB(0, 128, 255),
			Type = TYPE_LINE,
			Width = 1
		}
	,
		{
			Name = "261.8%",
			Color = RGB(128, 255, 128),
			Type = TYPE_LINE,
			Width = 1
		}
	,
		{
			Name = "161.8%",
			Color = RGB(255, 128, 255),
			Type = TYPE_LINE,
			Width = 1
		}
	,
		{
			Name = "100%",
			Color = RGB(0, 0, 0),
			Type = TYPE_POINT,
			Width = 1
		}
	,
		{
			Name = "100%",
			Color = RGB(0, 0, 0),
			Type = TYPE_POINT,
			Width = 1
		}
	,
		{
			Name = "161.8%",
			Color = RGB(255, 128, 255),
			Type = TYPE_LINE,
			Width = 1
		}
	,
		{
			Name = "261.8%",
			Color = RGB(128, 255, 128),
			Type = TYPE_LINE,
			Width = 1
		}
	,
		{
			Name = "423.6%",
			Color = RGB(0, 128, 255),
			Type = TYPE_LINE,
			Width = 1
		}
	}
}

function dValue(i,param)
local v = param or "C"
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
		return math.max(math.abs(H(i) - L(i)), math.abs(H(i) - C(i-1)), math.abs(C(i-1) - L(i)))
	else
		return C(i)
	end 
end

----------------------------------------------------------
function FiboEMA()
	
	local cache_EMA={}
	local cache_ATR={}
	
	return function(ind, _p, _b)
		local period = _p
		local index = ind
		local bars = _b
		
		local inc = 0
		
		local HiPrice = 0
		local LowPrice = 0
		
		local top = 0
		local bottom = 0
		local k = 2/(_p+1)
		local kk = 2/(_b+1)

		if index == 1 then
			cache_EMA = {}
			cache_ATR={}
			cache_EMA[index]=(C(index)+O(index))/2
			cache_ATR[index]=0
			return nil, nil, nil, nil, nil, nil, nil, nil, nil
		end
				
		cache_EMA[index]=k*C(index)+(1-k)*cache_EMA[index-1]
		cache_ATR[index] = kk*dValue(index, "ATR")+(1-kk)*cache_ATR[index-1]
		

		if index <= bars then
			return nil, nil, nil, nil, nil, nil, nil, nil, nil
		end
		
		for i = index - bars + 1, index, 1 do
		
			top = H(i) - cache_EMA[i]
			bottom = L(i) - cache_EMA[i]
			
			if top > HiPrice then
				HiPrice = top;
			end
	  
			if bottom < LowPrice then
				LowPrice = bottom;
			end
			
		end
		
		if math.abs(HiPrice) > math.abs(LowPrice) then
			inc = HiPrice
		else
			inc = LowPrice
		end
			
		inc = math.abs(inc) + cache_ATR[index]*2
		
		return cache_EMA[index], cache_EMA[index]+inc*0.618, cache_EMA[index]+inc*0.5, cache_EMA[index]+inc*0.382, cache_EMA[index]+inc*0.236, cache_EMA[index]-inc*0.236, cache_EMA[index]-inc*0.382, cache_EMA[index]-inc*0.5, cache_EMA[index]-inc*0.618
		--return cache_EMA[index], cache_EMA[index]+inc*1.618, cache_EMA[index]+inc*1, cache_EMA[index]+inc*0.618, cache_EMA[index]+inc*0.5, cache_EMA[index]-inc*0.5, cache_EMA[index]-inc*0.618, cache_EMA[index]-inc*1, cache_EMA[index]-inc*1.618

			
	end
end
----------------------------

function Init()
	myFiboEMA = FiboEMA()
	return 9
end

function OnCalculate(index)
	--if index < Settings.period then
	--	return nil, nil, nil, nil, nil, nil, nil, nil, nil
	--end

	return myFiboEMA(index, Settings.period, Settings.bars)
end

function highestHigh(index, period)

	if index == 1 then
		return nil
	else

		local highestHigh = H(index)
		
		
		for i = math.max(index - period, 2), index, 1 do
			
			if H(i) > highestHigh then
				highestHigh = H(i)
			end
			
		end
	
		return highestHigh 
	
	end
end

function lowestLow(index, period)

	if index == 1 then
		return nil
	else

		local lowestLow = L(index)
		
		for i = math.max(index - period, 2), index, 1 do
						
			if L(i) < lowestLow then
				lowestLow = L(i)
			end
			
		end
	
		return lowestLow 
	
	end
end
------------------------------------------------------------------
--Вспомогательные функции
------------------------------------------------------------------
function round(num, idp)
if idp and num then
   local mult = 10^(idp or 0)
   if num >= 0 then return math.floor(num * mult + 0.5) / mult
   else return math.ceil(num * mult - 0.5) / mult end
else return num end
end

function fWMA()

	return function (Index, Period, ds, idp)
	local Out = nil
	   if Index >= Period then
	  
		local sum = 0
		local step = Period
		
		  for i = Index-Period+1, Index do
			if ds[i] == nil then
				ds[i] = 0
			end
			sum = (step*ds[i]) + sum
			 step = step - 1
		  end
		
		  Out = (2*sum)/(Period*(Period-1))
	   end
	   return round(Out,idp)
	end
	
end
