--logfile=io.open("C:\\SBERBANK\\QUIK_SMS\\LuaIndicators\\qlua_log.txt", "w")

Settings=
{
	Name = "*NRTR_EMA_Sar4.1",
	period = 84,
	value_type = "ATR",
	multiple = 1.2,
	use_awg = 1,
	show_awg = 0,
	awg_type = 2, -- 1 EMA, 2 THV
	awg_period = 32, 
	koef_thv = 1,
	vType_awg = "C",	
	showSar = 1,
	SarPeriod = 64,
	SarPeriod2 = 256,
	SarDeviation = 2,
	show_regime = 3, --0 all, 1 NRTR, 2 Sar, 3 only Sar
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
		Name = "SAR_buy",
		Color = RGB(0,255,128),
		Type = TYPE_TRIANGLE_UP,
		Width = 3
		},
		{
		Name = "SAR_sell",
		Color = RGB(255,0,0),
		Type = TYPE_TRIANGLE_DOWN,
		Width = 3
		},
		{
		Name = "Sar",
		Color = RGB(0, 64, 0),
		Type = TYPET_BAR,
		Width = 1
		},
		{
		Name = "EMA",
		Color = RGB(255,128,10),
		Type = TYPE_LINE,
		Width = 1
		}
	}
}


function Init()
	myNRTR = cached_NRTR()
	return #Settings.line
end


function OnCalculate(index)
	
	return myNRTR(index, Settings)
		
end

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
function FindExistCandle(I)

	local out = I
	
	while not CandleExist(out) and out > 0 do
		out = out -1
	end	
	
	return out
 
end

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
	
		local previous = i-1
		
		if not CandleExist(previous) then
			previous = FindExistCandle(previous)
		end
	
		return math.max(math.abs(H(i) - L(i)), math.abs(H(i) - C(previous)), math.abs(C(previous) - L(i)))
	else
		return C(i)
	end 
end
function cached_NRTR()
	
	local cache_NRTR={}
	local cache_Value={}
	local cache_HPrice={}
	local cache_LPrice={}
	local ATR_MA=fWMA()
	local THV=fTHV()
	local cache_ValueAwg={}
	local cache_awgEMA={}
	--Sar
	local cache_SAR={}
	local cache_ST={}
	local EMA={}
	local BB={}
	--Sar
	
	return function(ind, Fsettings)
	
		local Fsettings=(Fsettings or {})
		local p = 0
		local ATR = 0
		
		local index = ind
		local period = Fsettings.period or 84
		local multiple = Fsettings.multiple or 1.2
		local v_type = Fsettings.value_type or "ATR"
		local show_regime = Fsettings.show_regime or 1
		
		local use_awg = Fsettings.use_awg or 0
		local show_awg = Fsettings.show_awg or 0
		local awg_period = Fsettings.awg_period or 24
		local kawg = 2/(awg_period+1)
		local awg_type = Fsettings.awg_type or 1
		local koef_thv = Fsettings.koef_thv or 1
		local vType_awg = Fsettings.vType_awg or "C"
		
		--Sar
		local SarPeriod = Fsettings.SarPeriod or 32
		local SarPeriod2 = Fsettings.SarPeriod2 or 256
		local SarDeviation = Fsettings.SarDeviation or 3
		local showSar = Fsettings.showSar or 3
		local sigma = 0
		--Sar
		
		local out1 = nil
		local out2 = nil
		local out3 = nil
		local out4 = nil
		local out5 = nil
		local out6 = nil
				
		if index == 1 then
			cache_NRTR = {}
			cache_Value = {}
			cache_ValueAwg = {}
			cache_awgEMA = {}
			cache_HPrice = {}
			cache_LPrice = {}
			--Sar
			if showSar == 1 then
				cache_SAR={}
				cache_ST={}
				EMA={}
				BB={}
			end
			--Sar
			
			cache_Value[index] = 0
			cache_ValueAwg[index] = 0
			cache_NRTR[index] = 0
			cache_LPrice[index] = C(index) or 0
			cache_HPrice[index] = C(index) or 0
			if awg_type == 1 then
				cache_awgEMA[index] = 0
			else
				cache_awgEMA[index]= THV(index, awg_period, koef_thv, 0)
			end
			
			--Sar
			if showSar == 1 then
				if not CandleExist(index) then
					BB[index]=0
					cache_SAR[index]=0
					EMA[index]=0
					cache_ST[index]=1
				else 
					BB[index]=0
					cache_SAR[index]=L(index)-2*(H(index)-L(index))
					EMA[index]=(C(index)+O(index))/2
					cache_ST[index]=1
				end
			end
			--Sar
			
			return nil
		end
		
		cache_NRTR[index] = cache_NRTR[index-1] 
		cache_Value[index] = cache_Value[index-1]
		cache_ValueAwg[index] = cache_ValueAwg[index-1]
		cache_HPrice[index] = cache_HPrice[index-1]
		cache_LPrice[index] = cache_LPrice[index-1]
		cache_awgEMA[index] = cache_awgEMA[index-1]
		
		--Sar
		if showSar == 1 then
			EMA[index]=EMA[index-1]
			BB[index]=BB[index-1]
			cache_SAR[index]=cache_SAR[index-1] 
			cache_ST[index]=cache_ST[index-1]
		end
		--Sar
		
		--WriteLog ("index "..tostring(index))
		--WriteLog ("CandleExist(index) "..tostring(CandleExist(index)))
		--WriteLog ("cache_awgEMA[index] "..tostring(cache_awgEMA[index]))
		
		if not CandleExist(index) then
			if awg_type == 2 then
				--WriteLog ("call")
				call = THV(index, awg_period, koef_thv, 0)
			end
			return nil
		end
						   
		 --Average True Range
		cache_Value[index] = dValue(index, v_type) or cache_Value[index-1]
		cache_ValueAwg[index] = dValue(index, vType_awg) or cache_ValueAwg[index-1] 	
		ATR = ATR_MA(index, period, cache_Value, nil)
		
		--WriteLog ("cache_awgEMA[index-1] "..tostring(cache_awgEMA[index-1]))
		if use_awg == 1 then
			if awg_type == 1 then
				cache_awgEMA[index]=kawg*C(index)+(1-kawg)*cache_awgEMA[index-1]		
			else
				cache_awgEMA[index] = THV(index, awg_period, koef_thv, cache_ValueAwg)
			end
		end
		if show_awg == 1 then
			out6 = cache_awgEMA[index]
		end
				
		if index <= math.max(period, SarPeriod) then
			return nil
		end
		
		if show_regime ~= 3 then
			p = cache_NRTR[index-1] or C(index)
			
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
				
				if use_awg == 1 and C(index)<= cache_awgEMA[index] then 
					trend = -1;
					cache_LPrice[index] = C(index)
					cache_NRTR[index] = C(index) + ATR*multiple
				else
					cache_NRTR[index] = cache_HPrice[index] - ATR*multiple

					if C(index) <= cache_NRTR[index]  then -- and 
						trend = -1;
						cache_LPrice[index] = C(index)
						cache_NRTR[index] = C(index) + ATR*multiple
					end
				end
			end
				
			if trend <= 0 then
				
				cache_LPrice[index] = math.min( C(index), cache_LPrice[index] )
				
				if use_awg == 1 and C(index)>= cache_awgEMA[index] then 
					trend = 1;
					cache_HPrice[index] = C(index)
					cache_NRTR[index] = C(index) - ATR*multiple
				else
					cache_NRTR[index] = cache_LPrice[index] + ATR*multiple
					
					if C(index) >= cache_NRTR[index] then
						trend = 1
						cache_HPrice[index] = C(index)
						cache_NRTR[index] = C(index) - ATR*multiple
					end
				end
					
			end
			
			local previous = math.max(index-1, 1)
				
			if CandleExist(previous) and show_regime <= 1 then
				previous = FindExistCandle(previous)
			
				if (C(index) > cache_NRTR[index] and C(previous) < cache_NRTR[index-1]) then
					out1 = cache_NRTR[index]
					out2 = nil
				end

				if C(index) < cache_NRTR[index] and C(previous) > cache_NRTR[index-1] then
					out1 = nil
					out2 = cache_NRTR[index]
				end
			end
		end

		--Sar
		if showSar == 1 then
		
			EMA[index]=(2/(SarPeriod/2+1))*C(index)+(1-2/(SarPeriod/2+1))*EMA[index-1]
			BB[index]=(2/(SarPeriod2/2+1))*(C(index)-EMA[index])^2+(1-2/(SarPeriod2/2+1))*BB[index-1]

			sigma=BB[index]^(1/2)
			
			if index ==2 then
				return nil
			end
	------------------------------------------------------------------		
			if cache_ST[index]==1 then
					
				cache_SAR[index]=math.max((EMA[index]-sigma*SarDeviation),cache_SAR[index-1])
							
				if (cache_SAR[index] > C(index)) then 
					cache_ST[index] = 0
					cache_SAR[index]=EMA[index]+sigma*SarDeviation
				end
			elseif cache_ST[index]==0 then
					
				cache_SAR[index]=math.min((EMA[index]+sigma*SarDeviation),cache_SAR[index-1])
			
				if (cache_SAR[index] < C(index)) then 
					cache_ST[index] = 1
					cache_SAR[index]=EMA[index]-sigma*SarDeviation*1
				end
			end
			
			previous = FindExistCandle(index-1)
			if CandleExist(previous) and (show_regime == 0 or show_regime == 2) then
			
				if (C(index) > cache_SAR[index] and C(previous) < cache_SAR[index-1]) then
					out3 = cache_SAR[index-1]
					out4 = nil
				end

				if C(index) < cache_SAR[index] and C(previous) > cache_SAR[index-1] then
					out3 = nil
					out4 = cache_SAR[index-1]
				end
			end
			
			out5 = cache_SAR[index]
			
		end
		--Sar
		
		return out1, out2,	out3, out4,	out5, out6
		
	end
end

function WriteLog(text)

   logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n");
   logfile:flush();
   LASTLOGSTRING = text;

end;

function highestHigh(index, period)

	if index == 1 then
		return nil
	else

		local highestHigh = H(index)
				
		for i = math.max(index - period, 2), index, 1 do			
			if CandleExist(i) then				
				if H(i) > highestHigh then
					highestHigh = H(i)
				end				
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
						
			if CandleExist(i) then
				if L(i) < lowestLow then
					lowestLow = L(i)
				end
			end
			
		end
	
		return lowestLow 
	
	end
end
------------------------------------------------------------------
--THV
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

function fTHV()
	
	local g_ibuf_104={}
	local gda_108={}
	local gda_112={}
	local gda_116={}
	local gda_120={}
	local gda_124={}
	local gda_128={}
	
	return function(ind, _p, _k, ds)
		local period = _p
		local index = ind
		local koef = _k

		local ild_0
		local ld_8

		local gd_188 = koef * koef
		local gd_196 = 0
		local gd_196 = gd_188 * koef
		local gd_132 = -gd_196
		local gd_140 = 3.0 * (gd_188 + gd_196)
		local gd_148 = -3.0 * (2.0 * gd_188 + koef + gd_196)
		local gd_156 = 3.0 * koef + 1.0 + gd_196 + 3.0 * gd_188
		local gd_164 = period
		if gd_164 < 1.0 then gd_164 = 1 end
		gd_164 = (gd_164 - 1.0) / 2.0 + 1.0
		local gd_172 = 2 / (gd_164 + 1.0)
		local gd_180 = 1 - gd_172
		
		if index == 1 then
			g_ibuf_104={}
			gda_108={}
			gda_112={}
			gda_116={}
			gda_120={}
			gda_124={}
			gda_128={}
			
			g_ibuf_104[index]=0
			gda_108[index]=0
			gda_112[index]=0
			gda_116[index]=0
			gda_120[index]=0
			gda_124[index]=0
			gda_128[index]=0
			
			return 0
		end
		  
		g_ibuf_104[index] = g_ibuf_104[index-1] 
		gda_108[index] = gda_108[index-1]
		gda_112[index] = gda_112[index-1]
		gda_116[index] = gda_116[index-1] 
		gda_120[index] = gda_120[index-1]
		gda_124[index] = gda_124[index-1]
		gda_128[index] = gda_128[index-1] 
		
		--WriteLog ("ds[index] "..tostring(ds[index]))
		--WriteLog ("gda_108[index] "..tostring(gda_108[index]))
		
		if not CandleExist(index) then
			return 0
		end			
		
		gda_108[index] = gd_172 * ds[index] + gd_180 * (gda_108[index - 1])
		gda_112[index] = gd_172 * (gda_108[index]) + gd_180 * (gda_112[index - 1])
		gda_116[index] = gd_172 * (gda_112[index]) + gd_180 * (gda_116[index - 1])
		gda_120[index] = gd_172 * (gda_116[index]) + gd_180 * (gda_120[index - 1])
		gda_124[index] = gd_172 * (gda_120[index]) + gd_180 * (gda_124[index - 1])
		gda_128[index] = gd_172 * (gda_124[index]) + gd_180 * (gda_128[index - 1])
		g_ibuf_104[index] = gd_132 * (gda_128[index]) + gd_140 * (gda_124[index]) + gd_148 * (gda_120[index]) + gd_156 * (gda_116[index])
		
		local out = g_ibuf_104[index]
		 			
		return out
	end	
	
end
