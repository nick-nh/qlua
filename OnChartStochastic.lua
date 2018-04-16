--logfile=io.open("C:\\SBERBANK\\QUIK_SMS\\LuaIndicators\\qlua_log.txt", "w")

min_price_step = 0

Settings =
 {
	Name = "*OnChart Stochastic",
	PeriodK = 5,
	SlowK = 3,
	SlowD = 3,
	UseDiNapoliStoch = 0,
	periodEMA = 20,
	overBought = 80,
	overSold = 20,
	color = 0,
	line =
     {
        {
          Name = "overBought",
          Color = RGB(128,128,64),
          Type = TYPE_DASH,
          Width =1
        },
        {
          Name = "EMA",
          Color = RGB(128,128,64),
          Type = TYPE_DASH,
          Width =1
        },
        {
          Name = "overSold",
          Color = RGB(128,128,64),
          Type = TYPE_DASH,
          Width =1
        },
        {
          Name = "%K Up",
          Color = RGB(10,255,0),
          Type = TYPE_POINT,
          Width =3
		},
		{
          Name = "%K Down",
          Color = RGB(255,10,0),
          Type = TYPE_POINT,
          Width =3
        },
		{
          Name = "%K",
          Color = RGB(255,10,0),
          Type = TYPE_LINE,
          Width =2
        },
        {
          Name = "%D",
          Color = RGB(0,128,128),
          Type = TYPE_DASH,
          Width =1
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
			return nil
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
	myfunc = Stoch()
	return #Settings.line
 end

 function OnCalculate(index)
	--WriteLog ("OnCalc() ".."CandleExist("..index.."): "..tostring(CandleExist(index)));
	if index == 1 then
		DSInfo = getDataSourceInfo()     	
		min_price_step = getParamEx(DSInfo.class_code, DSInfo.sec_code, "SEC_PRICE_STEP").param_value
	end
	return myfunc(index, Settings)
 end
 
function WriteLog(text)

   logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n");
   logfile:flush();
   LASTLOGSTRING = text;

end

 function Stoch()
	
	local cache_ValueHH = {}
	local cache_ValueLL = {}
	local cache_StoBuffer = {}
	local cache_SigBuffer = {}
	local cache_EMA = {}
	local cache_StoEMA = {}
	
	return function(ind, Fsettings)
		
		local Fsettings=(Fsettings or {})
		local index = ind
		local PeriodK = Fsettings.PeriodK or 5
		local SlowK = Fsettings.SlowK or 3
		local SlowD = Fsettings.SlowD or 3
		local UseDiNapoliStoch = Fsettings.UseDiNapoliStoch or 0
		local periodEMA = Fsettings.periodEMA or 20
		local overBought = Fsettings.overBought or 80
		local overSold = Fsettings.overSold or 20
		local color = Fsettings.color or 0

		local out1 = nil
		local out2 = nil
		local out3 = nil
		local out4 = nil
        local out5 = nil
		local out6 = nil
        local out7 = nil
        
		local HH = 0 
		local LL = 0
		local Range = 0
		local Res = 0
		local k = 2/(periodEMA+1)
		local kK = 2/(SlowK+1)
		local kD = 2/(SlowD+1)
				
		if index == 1 then
			cache_ValueHH = {}
			cache_ValueLL = {}
			cache_StoBuffer = {}
			cache_SigBuffer = {}
			cache_StoEMA = {}
			cache_EMA = {}
			
			cache_ValueHH[index]= 0
			cache_ValueLL[index]= 0
			cache_StoBuffer[index]= 0
			cache_SigBuffer[index]= 0
			cache_StoEMA[index]= 0
			cache_EMA[index]= 0
			
			return nil
		end
				
		cache_ValueHH[index] = dValue(index, "H") or cache_ValueHH[index-1]	
		cache_ValueLL[index] = dValue(index, "L") or cache_ValueLL[index-1]	
		cache_StoBuffer[index] = cache_StoBuffer[index-1]
		cache_SigBuffer[index] = cache_SigBuffer[index-1]
		cache_StoEMA[index] = cache_StoEMA[index-1]
		cache_EMA[index] = cache_EMA[index-1]

		if not CandleExist(index) or index <= PeriodK then
			return nil
		end
				
		HH = math.max(unpack(cache_ValueHH,index-PeriodK,index)) 
		LL = math.min(unpack(cache_ValueLL,index-PeriodK,index))		
		
		Range = math.max(HH-LL,1*min_price_step)
		
		Res=100*(C(index)-LL)/Range;

        cache_EMA[index]=k*C(index)+(1-k)*cache_EMA[index-1]

		if UseDiNapoliStoch == 1 then
			cache_StoBuffer[index]=cache_StoBuffer[index-1]+(Res-cache_StoBuffer[index-1])/SlowK            --stochastic line
			cache_StoEMA[index] = kK*cache_StoBuffer[index]+(1-kK)*cache_StoEMA[index-1]
			cache_SigBuffer[index]=cache_SigBuffer[index-1]+(cache_StoBuffer[index]-cache_SigBuffer[index-1])/SlowD --signal line
		else
			cache_StoEMA[index] = Res
			cache_SigBuffer[index] = kD*Res+(1-kD)*cache_SigBuffer[index-1]
		end
				
		out1 = cache_EMA[index]+(Range*(overBought-50)/100)
		out2 = cache_EMA[index]
		out3 = cache_EMA[index]-(Range*(50 - overSold)/100)
		if color == 1 then
			if cache_StoEMA[index] >= cache_StoEMA[index-1] then
				out4 = cache_EMA[index]+(cache_StoEMA[index] - 50)/100*Range
				out5 = nil
			else
				out4 = nil
				out5 = cache_EMA[index]+(cache_StoEMA[index] - 50)/100*Range
			end
		else
			out6 = cache_EMA[index]+(cache_StoEMA[index] - 50)/100*Range
		end
		out7 = cache_EMA[index]+(cache_SigBuffer[index]- 50)/100*Range
				
		return out1, out2, out3, out4, out5, out6, out7
			
	end
end