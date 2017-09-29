
Settings = 
{
	Name = "*FiboEmaATR",
 	showEMA = 1,
	periodEMA = 64,
	bars = 100,
  	vTypeEMA = "C",
 	showTEMA = 1,
	periodTEMA = 112,
  	vTypeTEMA = "C",
 	showTHV = 0,
	periodTHV = 24,
  	vTypeTHV = "C",
	show100 = 0,
	show161 = 0,
	show261 = 0,
	show423 = 1,
 	line=
	{
		{
			Name = "EMA",
			Color = RGB(128, 0, 0),
			Type = TYPE_LINE,
			Width = 1
		}
	,
		{
			Name = "423.6%",
			Color = RGB(0, 0, 0),
			Type = TYPE_POINT,
			Width = 1
		}
	,
		{
			Name = "261.8%",
			Color = RGB(128, 255, 128),
			Type = TYPE_POINT,
			Width = 1
		}
	,
		{
			Name = "161.8%",
			Color = RGB(255, 128, 255),
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
			Name = "100%",
			Color = RGB(0, 0, 0),
			Type = TYPE_POINT,
			Width = 1
		}
	,
		{
			Name = "161.8%",
			Color = RGB(255, 128, 255),
			Type = TYPE_POINT,
			Width = 1
		}
	,
		{
			Name = "261.8%",
			Color = RGB(128, 255, 128),
			Type = TYPE_POINT,
			Width = 1
		}
	,
		{
			Name = "423.6%",
			Color = RGB(0, 0, 0),
			Type = TYPE_POINT,
			Width = 1
		},
        {
          Name = "TEMA",
          Color = RGB(255,0,0),
          Type = TYPE_LINE,
          Width = 1
 		},
        {
          Name = "THV",
          Color = RGB(0,128,128),
          Type = TYPE_LINE,
          Width = 1
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
		if previous == 1 then
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
----------------------------------------------------------
function FiboEMA()
	
	local cache_EMA={}
	local cache_ATR={}
	local THMA=fTHV()
	
	local cache_TEMA1={}
	local cache_TEMA2={}
	local cache_TEMA3={}
	
	local cache_HMA = {}
	local cache_ValueTHV = {}
	
	return function(ind, Fsettings)
		
		local Fsettings=(Fsettings or {})
		local index = ind
		local periodEMA = Fsettings.periodEMA or 63
		local vTypeEMA = Fsettings.vTypeEMA or "C"
		local bars = Fsettings.bars or 100
		
		local showEMA = Fsettings.showEMA or 1
		local show100 = Fsettings.show100 or 0
		local show161 = Fsettings.show161 or 0
		local show261 = Fsettings.show261 or 1
		local show423 = Fsettings.show423 or 1
		
		local showTEMA = Fsettings.showTEMA or 1
		local periodTEMA = Fsettings.periodTEMA or 112
		local vTypeTEMA = Fsettings.vTypeTEMA or "C"
		local showTHV = Fsettings.showTHV or 0
		
		local periodTHV = Fsettings.periodTHV or 14
		local koefTHV = Fsettings.koefTHV or 1
		local vTypeTHV = Fsettings.vTypeTHV or "C"

		local inc = 0
		
		local HiPrice = 0
		local LowPrice = 0
		
		local top = 0
		local bottom = 0
		local k = 2/(periodEMA+1)
		local kk = 2/(periodEMA+1)
		
		local kT = 2/(periodTEMA+1)
		local valueTEMA = 0
		local valueTHV = 0
		
		local outEMA = nil
		local outp100 = nil
		local outp161 = nil
		local outp261 = nil
		local outp423 = nil
		local outm100 = nil
		local outm161 = nil
		local outm261 = nil
		local outm423 = nil
		local outTEMA = nil
		local outTHV = nil

		if index == 1 then
			
			cache_EMA = {}
			cache_ATR={}
			cache_EMA[index]=0
			cache_ATR[index]=0
			
			if showTEMA == 1 then
				cache_TEMA1 = {}
				cache_TEMA2 = {}
				cache_TEMA3 = {}
				
				if CandleExist(index) then
					cache_TEMA1[index]= dValue(index, vTypeTEMA)
					cache_TEMA2[index]= dValue(index, vTypeTEMA)
					cache_TEMA3[index]= dValue(index, vTypeTEMA)
				else 
					cache_TEMA1[index]= 0
					cache_TEMA2[index]= 0
					cache_TEMA3[index]= 0
				end
			end
			if showTHV == 1 then
				cache_ValueTHV = {}
				cache_HMA[index]= THMA(index, periodTHV, koefTHV, 0)
			end
			
			return nil
			
		end
		
		cache_ATR[index] = cache_ATR[index-1]
		cache_EMA[index]=cache_EMA[index-1]

		if showTEMA == 1 then
			cache_TEMA1[index] = cache_TEMA1[index-1] 
			cache_TEMA2[index] = cache_TEMA2[index-1]
			cache_TEMA3[index] = cache_TEMA3[index-1]
		end
		if showTHV == 1 then
			cache_ValueTHV[index] = cache_ValueTHV[index-1] 
			cache_HMA[index] = cache_HMA[index-1]
		end
		
		if not CandleExist(index) then
			return nil
		end

		 --Average True Range
		local previous = math.max(index-1, 1)
			
		if not CandleExist(previous) then
			previous = FindExistCandle(previous)
		end
		if previous == 0 then
			return nil
		end
		
		local ATR = math.max(math.abs(H(index) - L(index)), math.abs(H(index) - C(previous)), math.abs(C(previous) - L(index))) 
		cache_ATR[index] = kk*ATR+(1-kk)*cache_ATR[index-1]
		
		valueEMA = dValue(index, vTypeEMA)	
		cache_EMA[index]=k*valueEMA+(1-k)*cache_EMA[index-1]
		
		if showTEMA == 1 then
			valueTEMA = dValue(index, vTypeTEMA)	
			cache_TEMA1[index]=kT*valueTEMA+(1-kT)*cache_TEMA1[index-1]
			cache_TEMA2[index]=kT*cache_TEMA1[index]+(1-kT)*cache_TEMA2[index-1]
			cache_TEMA3[index]=kT*cache_TEMA2[index]+(1-kT)*cache_TEMA3[index-1]
			
			outTEMA = 3*cache_TEMA1[index] - 3*cache_TEMA2[index] + cache_TEMA3[index]
		end
		
		if showEMA== 1 then
			outEMA = cache_EMA[index]
		end
		
		if showTHV == 1 then
			cache_ValueTHV[index] = dValue(index, vTypeTHV) or cache_ValueTHV[index-1]	
			cache_HMA[index] = THMA(index, periodTHV, koefTHV, cache_ValueTHV)
			outTHV = cache_HMA[index]
		end
			
		if index >= Size() - bars then
			inc = cache_ATR[index] or 0
			
			if show423 == 1 then
				outp423 = cache_EMA[index]+inc*4.236
				outm423 = cache_EMA[index]-inc*4.236
			end
			if show261 == 1 then
				outp261 = cache_EMA[index]+inc*2.618
				outm261 = cache_EMA[index]-inc*2.618
			end
			if show161 == 1 then
				outp161 = cache_EMA[index]+inc*1.618
				outm161 = cache_EMA[index]-inc*1.618
			end
			if show100 == 1 then
				outp100 = cache_EMA[index]+inc
				outm100 = cache_EMA[index]-inc
			end
		end
		
		return outEMA, outp423, outp261, outp161, outp100, outm100, outm161, outm261, outm423, outTEMA, outTHV

			
	end
end
----------------------------

function Init()
	myFiboEMA = FiboEMA()
	return #Settings.line
end

function OnCalculate(index)

	return myFiboEMA(index, Settings)
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
