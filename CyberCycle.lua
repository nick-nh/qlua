--logfile=io.open("C:\\SBERBANK\\QUIK_SMS\\LuaIndicators\\qlua_log.txt", "w")

Settings = 
{
	Name = "*CyclePeriod",
	alpha = 0.07,
	cycletype = 2, -- 0 simple cycle, 1 cycle period, 2 - adaptive cycle
	periodATR = 182,
	ddd=0.75,
	bars = 150,
	showsignal = 0,
	line=
	{
		{
			Name = "Trigger Line",
			Color = RGB(255, 0, 0),
			Type = TYPE_DASHDOT,
			Width = 1
		},
		{
			Name = "Cycle",
			Color = RGB(0, 128, 0),
			Type = TYPE_LINE,
			Width = 2
		},
		{
			Name = "xSarATR",
			Color = RGB(0, 0, 255),
			Type = TYPE_TRIANGLE_UP,
			Width = 3
		}
	,
		{
			Name = "xSarATR",
			Color = RGB(255, 0, 0),
			Type = TYPE_TRIANGLE_DOWN,
			Width = 3
		}
	,	
		{
			Name = "100;++",
			Color = RGB(0, 0, 0),
			Type = TYPE_LINE,
			Width = 1
		}
	,	
		{
			Name = "middle",
			Color = RGB(0, 0, 0),
			Type = TYPE_LINE,
			Width = 1
		}
	,	
		{
			Name = "--;-100",
			Color = RGB(0, 0, 0),
			Type = TYPE_LINE,
			Width = 1
		}		
	}
}

-- Пользовательcкие функции
function WriteLog(text)

   logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n");
   logfile:flush();
   LASTLOGSTRING = text;

end;

function toYYYYMMDDHHMMSS(datetime)
   if type(datetime) ~= "table" then
      --message("в функции toYYYYMMDDHHMMSS неверно задан параметр: datetime="..tostring(datetime))
      return ""
   else
      local Res = tostring(datetime.year)
      if #Res == 1 then Res = "000"..Res end
      local month = tostring(datetime.month)
      if #month == 1 then Res = Res.."0"..month; else Res = Res..month; end
      local day = tostring(datetime.day)
      if #day == 1 then Res = Res.."0"..day; else Res = Res..day; end
      local hour = tostring(datetime.hour)
      if #hour == 1 then Res = Res.."0"..hour; else Res = Res..hour; end
      local minute = tostring(datetime.min)
      if #minute == 1 then Res = Res.."0"..minute; else Res = Res..minute; end
      local sec = tostring(datetime.sec);
      if #sec == 1 then Res = Res.."0"..sec; else Res = Res..sec; end;
      return Res
   end
end --toYYYYMMDDHHMMSS

function isnil(a,b)
   if a == nil then
      return b
   else
      return a
   end;
end;

function CyberCycle()
	
	local Price={}
	local Smooth={}
	local Cycle={}
	local aCycle={}
	local Trigger={}
	local CyclePeriod={}
	local InstPeriod={}
	local Q1={}
	local I1={}
	local DeltaPhase={}
	
	local CycleLine={}
	local TriggerLine={}
	
	--SAR
	local cache_H={}
	local cache_L={}
	local cache_SAR={}
	local cache_ST={}
	local AMA2={}
	local CC={}
	local CC_N={}	
	local cache_ATR={}
	--SAR
	
	--local SMA=fSMA()
	
	return function(ind, _a, _t, _p4,_ddd, _b, _s)
		
		local index = ind
		local alpha = _a
		local cycletype = _t
		local ZZZ = 0
		local bars = _b
		local showsignal = _s
				
		local DC, MedianDelta, alpha1
		
		local out1 = nil
		local out2 = nil
		local out3 = nil
		local out4 = nil
		
		if index == 1 then
			Price = {}
			Smooth={}
			Cycle={}
			aCycle={}
			Trigger={}
			CyclePeriod={}
			InstPeriod={}
			Q1={}
			I1={}
			DeltaPhase={}
			
			CycleLine={}
			TriggerLine={}
			
			Smooth[index]=0
			Cycle[index]=0
			aCycle[index]=0
			Trigger[index]=0
			CyclePeriod[index]=0
			InstPeriod[index]=0
			Q1[index]=0
			I1[index]=0
			DeltaPhase[index]=0
			
			CycleLine[index]=0
			TriggerLine[index]=0
			
			if CandleExist(index) then
				Price[index] = (H(index) + L(index))/2
			else 
				Price[index] = 0
			end
			
			--SAR
			cache_H={}
			cache_L={}
			cache_SAR={}
			cache_ST={}
			AMA2={}
			CC={}
			CC_N={}
			cache_ATR={}

------------------
			if CandleExist(index) then
				CC[index]=C(index)
				CC_N[index]=(C(index)+H(index)+L(index))/3
				cache_H[index]=H(index)
				cache_L[index]=L(index)
				cache_SAR[index]=L(index)-2*(H(index)-L(index))
				AMA2[index]=(C(index)+O(index))/2
				cache_ST[index]=1
				cache_ATR[index]=math.abs(H(index)-L(index))
			else 
				CC[index]=0
				CC_N[index]=0
				cache_H[index]=0
				cache_L[index]=0
				cache_SAR[index]=0
				AMA2[index]=0
				cache_ST[index]=1
				cache_ATR[index]=0
			end
			--SAR
			
			return out1, out2, out3, out4
		end

		out1 = nil
		out2 = nil
		out3 = nil
		out4 = nil
		
			Price[index]=Price[index-1]
			Cycle[index]=Cycle[index-1]
			aCycle[index]=aCycle[index-1]
			CyclePeriod[index]=CyclePeriod[index - 1]
			InstPeriod[index]=InstPeriod[index-1]
			Q1[index]=Q1[index-1]
			I1[index]=I1[index-1]
			DeltaPhase[index]=DeltaPhase[index-1]
			Smooth[index]=Smooth[index-1]
			Trigger[index]=Trigger[index-1]
			
			CycleLine[index]=CycleLine[index-1]
			TriggerLine[index]=TriggerLine[index-1]

			--SAR
			cache_ATR[index]=cache_ATR[index-1]
			CC[index]=CC[index-1]
			CC_N[index]=CC_N[index-1]
			cache_H[index]=cache_H[index-1] 
			cache_L[index]=cache_L[index-1]
			cache_SAR[index]=cache_SAR[index - 1]
			AMA2[index]=AMA2[index-1]
			cache_ST[index]=cache_ST[index-1]
			--WriteLog ("not ATR[index] "..tostring(cache_ATR[index]))
			--WriteLog ("not ATR[index-1] "..tostring(cache_ATR[index-1]))
			--SAR
			
		if not CandleExist(index) or index ==2 then
			return out1, out2, out3, out4
		end

		Price[index] = (H(index) + L(index))/2
		
		local previous = index-1
		if not CandleExist(previous) then
			previous = FindExistCandle(previous)
		end
		
		--WriteLog ("previous "..tostring(previous))
		if previous == 0 then
			return nil
		end
		
		--SAR
		
		if showsignal == 1 then
			ZZZ=math.max(math.abs(H(index)-L(index)),math.abs(H(index)-C(previous)),math.abs(L(index)-C(previous)))
			--WriteLog ("ZZZ "..tostring(ZZZ))
			--WriteLog ("ATR[index-1] "..tostring(cache_ATR[index-1]))
			cache_ATR[index]=(cache_ATR[index-1]*(_p4-1)+ZZZ)/_p4
			cache_SAR[index]=cache_SAR[index-1]
			CC[index]=C(index)
			AMA2[index]=(2/(_p4/2+1))*CC[index]+(1-2/(_p4/2+1))*AMA2[index-1]
			CC_N[index]=(C(index)-AMA2[index])/2+AMA2[index]
			cache_ST[index]=cache_ST[index-1]
			cache_H[index]=cache_H[index-1] 
			cache_L[index]=cache_L[index-1]
		end
		--SAR
		
		if index < 4 then
			Cycle[index]=Cycle[index-1]
			aCycle[index]=aCycle[index-1]
			CyclePeriod[index]=CyclePeriod[index -1]
			InstPeriod[index]=InstPeriod[index-1]
			Q1[index]=Q1[index-1]
			I1[index]=I1[index-1]
			DeltaPhase[index]=DeltaPhase[index-1]
			Smooth[index]=Smooth[index-1]

			CycleLine[index]=CycleLine[index-1]
			TriggerLine[index]=TriggerLine[index-1]

			return out1, out2, out3, out4
		end
		
		Smooth[index] = (Price[index]+2*Price[index - 1]+2*Price[index - 2]+Price[index - 3])/6.0
		Cycle[index]=(Price[index]-2.0*Price[index - 1]+Price[index - 2])/4.0
		aCycle[index]=(Price[index]-2.0*Price[index - 1]+Price[index - 2])/4.0
		
		
		if index < 7 then
			Cycle[index]=Cycle[index-1]
			aCycle[index]=aCycle[index-1]
			CyclePeriod[index]=CyclePeriod[index-1]
			InstPeriod[index]=InstPeriod[index-1]
			Q1[index]=Q1[index-1]
			I1[index]=I1[index-1]
			DeltaPhase[index]=DeltaPhase[index-1]

			CycleLine[index]=CycleLine[index-1]
			TriggerLine[index]=TriggerLine[index-1]

			return out1, out2, out3, out4
		end
					
		Cycle[index]=(1.0-0.5*alpha) *(1.0-0.5*alpha) *(Smooth[index]-2.0*Smooth[index - 1]+Smooth[index - 2])
						+2.0*(1.0-alpha)*Cycle[index - 1]-(1.0-alpha)*(1.0-alpha)*Cycle[index - 2]			   
		
		Trigger[index] = Cycle[index-1]	
		
		if cycletype == 0 then
			out1 = Trigger[index]
			out2 = Cycle[index] 
		else
		        
			Q1[index] = (0.0962*Cycle[index]+0.5769*Cycle[index-2]-0.5769*Cycle[index-4]-0.0962*Cycle[index-6])*(0.5+0.08*(InstPeriod[index-1] or 0))
			I1[index] = Cycle[index-3]
							
			if Q1[index]~=0.0 and Q1[index-1]~=0.0 then 
				DeltaPhase[index] = (I1[index]/Q1[index]-I1[index-1]/Q1[index-1])/(1.0+I1[index]*I1[index-1]/(Q1[index]*Q1[index-1]))
			else DeltaPhase[index] = 0	
			end
			if DeltaPhase[index] < 0.1 then
				DeltaPhase[index] = 0.1
			end	
			if DeltaPhase[index] > 0.9 then
				DeltaPhase[index] = 0.9
			end
					
			MedianDelta = Median(DeltaPhase[index],DeltaPhase[index-1], Median(DeltaPhase[index-2], DeltaPhase[index-3], DeltaPhase[index-4]))
			 
			if MedianDelta == 0.0 then
				DC = 15.0
			else
				DC = 6.28318/MedianDelta + 0.5
			end	
			
			InstPeriod[index] = 0.33 * DC + 0.67 * (InstPeriod[index-1] or 0)
			CyclePeriod[index] = 0.15 * InstPeriod[index] + 0.85 * CyclePeriod[index-1]
			Trigger[index] = CyclePeriod[index-1]
			
		end
				
		if cycletype == 1 then
			out1 = Trigger[index]
			out2 = CyclePeriod[index] 
		elseif cycletype == 2 then
			alpha1 = 2.0/(CyclePeriod[index]+1.0)
			
			aCycle[index]=(1.0-0.5*alpha1) *(1.0-0.5*alpha1) *(Smooth[index]-2.0*Smooth[index - 1]+Smooth[index - 2])
							+2.0*(1.0-alpha1)*aCycle[index - 1]-(1.0-alpha1)*(1.0-alpha1)*aCycle[index - 2]			   
		
			out1 = aCycle[index-1]
			out2 = aCycle[index]
		end
		
					
		CycleLine[index]=out1
		TriggerLine[index]=out2
		
		local val_h=0 
		local val_l=0
		
		if index > bars then						
			val_h=math.max(unpack(CycleLine,index-bars,index)) 
			val_l=math.min(unpack(CycleLine,index-bars,index))				
		end

		out3 = nil
		out4 = nil

		if showsignal == 1 then
			if cache_ST[index]==1  then				
				if cache_H[index] < CC[index] then 
					cache_H[index]=CC[index]
				end
				cache_SAR[index]=math.max((cache_H[index]-cache_ATR[index]*_ddd),cache_SAR[index-1])
				if (cache_SAR[index] > CC_N[index])and(cache_SAR[index] > C(index)) then 
					cache_ST[index]=0
					cache_L[index]=CC[index]
					cache_SAR[index]=cache_L[index]+cache_ATR[index]*_ddd*1
					
					--out4 = cache_H[index]-cache_ATR[index]*_ddd
					out4 = out2
				end
			end
	---------------------------------------------------------------------------------------
			if cache_ST[index]==0 then
				if cache_L[index] > CC[index] then 
					cache_L[index]=CC[index]
				end
				cache_SAR[index]=math.min((cache_L[index]+cache_ATR[index]*_ddd),cache_SAR[index-1])
				if (cache_SAR[index] < CC_N[index])and (cache_SAR[index] < C(index)) then 
					cache_ST[index]=1
					cache_H[index]=CC[index]
					cache_SAR[index]=cache_H[index]-cache_ATR[index]*_ddd*1
					
					--out3 = cache_L[index]+cache_ATR[index]*_ddd
					out3 = out2
				end
			end
		end
		--SAR

		return out1, out2, out3, out4, val_h, (val_h + val_l)/2, val_l
	end
end
	----------------------------

function Init()
	myCyberCycle = CyberCycle()
	return #Settings.line
end

function OnCalculate(index)

	--WriteLog ("OnCalc() ".."CandleExist("..index.."): "..tostring(CandleExist(index)).."; T("..index.."); "..isnil(toYYYYMMDDHHMMSS(T(index))," - ").."; C("..index.."): "..isnil(C(index),"-"));
	return myCyberCycle(index, Settings.alpha, Settings.cycletype, Settings.periodATR,Settings.ddd, Settings.bars, Settings.showsignal)
end

function Median(x, y, z)     
   return (x+y+z) - math.min(x,math.min(y,z)) - math.max(x,math.max(y,z)) 
end

function fSMA()
		
	return function (Index, Period, bb)
		
		local Out = 0
		   
		   if Index >= Period then
			  local sum = 0
			  for i = Index-Period+1, Index do
				 sum = sum + bb[i]
			  end
			  Out = sum/Period
		   end
		   
		return Out
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
