SMA="SMA"
WMA="WMA"
EMA="EMA"
SMMA="SMMA"
WILLMA="WILLMA"


Settings=
{
	Name = "**NRTR_LUA",
	period = 21,
	multiple = 0.7,
	value_type = "ATR",
	showNRTR = 0,
	line =
	{		
		{
		Name = "NRTR_buy",
		Color = RGB(40,240,250),
		Type = TYPE_POINT,
		Width = 4
		},
		{
		Name = "NRTR_sell",
		Color = RGB(255,0,255),
		Type = TYPE_POINT,
		Width = 4
		},
		{
		Name = "NRTR",
		Color = RGB(128,0,255),
		Type = TYPE_POINT,
		Width = 2
		}
	}
}


function Init()
	myNRTR = cached_NRTR()
	NRTR_buy = nil
	NRTR_sell = nil
	return 3
end


function OnCalculate(index)

	if index < Settings.period then
		return nil, nil
	end
	
	NRTR_buy = nil
	NRTR_sell = nil
	NRTR_1 = nil

	NRTR, NRTR_1 = myNRTR(index, Settings.period, Settings.value_type, Settings.multiple)

	NRTR_1 = NRTR_1 or C(index)
	
	if C(index) > NRTR and C(index-1) < NRTR_1 then
		NRTR_buy = NRTR
		NRTR_sell = nil
	end

	if C(index) < NRTR and C(index-1) > NRTR_1 then
		NRTR_buy = nil
		NRTR_sell = NRTR
	end
	
	if Settings.showNRTR == 1 then
		return NRTR_buy, NRTR_sell, NRTR 
	else
		return NRTR_buy, NRTR_sell 
	end
	
end

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

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
function cached_NRTR()
	
	local cache_NRTR={}
	local cache_EMA={}
	local cache_HPrice={}
	local cache_LPrice={}
	local ATR_MA=fWMA()
	
	return function(ind, _p, v_t, _m, kk)
	
		local p = 0
		local ATR = 0
		local p_ema = 0

		local v_type = v_t
		
		local period = _p
		local multiple = _m
		local index = ind
		local k = kk or 2/(period+1)
		
		local trend = 0
		local reverse = 0
		local HiPrice = 0
		local LowPrice = 0
		
		if index == 1 then
			cache_NRTR = {}
			cache_EMA = {}
			cache_HPrice = {}
			cache_LPrice = {}
			
			cache_EMA[index] = math.abs(H(i) - L(i))
			cache_NRTR[index] = C(index)
			cache_LPrice[index] = C(index)
			cache_HPrice[index] = C(index)
			return nil
		end
		
				
		p = cache_NRTR[index-1] or C(index)
				
		--p_ema = cache_EMA[index-1] or dValue(index, v_type)
		--ATR = k*dValue(index, v_type)+(1-k)*p_ema
		--ATR = (cache_EMA[index-1]*(period-1)+ dValue(index, v_type)) / period
		   
		 --Average True Range
		cache_EMA[index] = dValue(index, v_type)
		ATR = ATR_MA(index, period, cache_EMA, nil)
		
		if C(index) <= p then
			trend = 1
		end
		if C(index) >= p then
			trend = -1
		end
		
		cache_HPrice[index] = highestHigh(index, period)
		cache_LPrice[index] = lowestLow(index, period)
		
		if trend >= 0 then
			
			cache_HPrice[index] = math.max( C(index), cache_HPrice[index])
			reverse = cache_HPrice[index] - ATR*multiple

			if C(index) <= reverse then
				trend = -1;
				cache_LPrice[index] = C(index)
				reverse = C(index) + ATR*multiple
			end
			
		end
			
		if trend <= 0 then
			
			cache_LPrice[index] = math.min( C(index), cache_LPrice[index] )
			reverse = cache_LPrice[index] + ATR*multiple
			
			if C(index) >= reverse then
				trend = 1
				cache_HPrice[index] = C(index)
				reverse = C(index) - ATR*multiple
			end
				
		end

		cache_NRTR[index] = reverse
		return reverse, cache_NRTR[index-1]
		
		
	end
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
