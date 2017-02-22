--logfile=io.open("C:\\SBERBANK\\QUIK_SMS\\LuaIndicators\\qlua_log.txt", "w")

Settings = 
{
	Name = "*CyclePeriod",
	alpha = 0.07,
	cycletype = 2, -- 0 simple cycle, 1 cycle period, 2 - adaptive cycle
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
----------------------------------------------------------

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
	
	--local SMA=fSMA()
	
	return function(ind, _a, _t)
		
		local index = ind
		local alpha = _a
		local cycletype = _t
				
		local DC, MedianDelta, alpha1
		
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
			
			Smooth[index]=0
			Cycle[index]=0
			aCycle[index]=0
			Trigger[index]=0
			CyclePeriod[index]=0
			InstPeriod[index]=0
			Q1[index]=0
			I1[index]=0
			DeltaPhase[index]=0
			
			if CandleExist(index) then
				Price[index] = (H(index) + L(index))/2
			else 
				Price[index] = 0
			end
			
			return nil, nil
		end
		
		if not CandleExist(index) then
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
			return nil, nil
		end
		
		Price[index] = (H(index) + L(index))/2
		
		if index < 4 then
			Cycle[index]=Cycle[index-1]
			aCycle[index]=aCycle[index-1]
			CyclePeriod[index]=CyclePeriod[index -1]
			InstPeriod[index]=InstPeriod[index-1]
			Q1[index]=Q1[index-1]
			I1[index]=I1[index-1]
			DeltaPhase[index]=DeltaPhase[index-1]
			Smooth[index]=Smooth[index-1]
			return nil, nil
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
			return nil, nil
		end
					
		Cycle[index]=(1.0-0.5*alpha) *(1.0-0.5*alpha) *(Smooth[index]-2.0*Smooth[index - 1]+Smooth[index - 2])
						+2.0*(1.0-alpha)*Cycle[index - 1]-(1.0-alpha)*(1.0-alpha)*Cycle[index - 2]			   
		
		Trigger[index] = Cycle[index-1]	
		
		if cycletype == 0 then
			return Trigger[index], Cycle[index] 
		end
		        
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
				
		if cycletype == 1 then
			return Trigger[index], CyclePeriod[index] 
		end
		
		alpha1 = 2.0/(CyclePeriod[index]+1.0)
        
		aCycle[index]=(1.0-0.5*alpha1) *(1.0-0.5*alpha1) *(Smooth[index]-2.0*Smooth[index - 1]+Smooth[index - 2])
						+2.0*(1.0-alpha1)*aCycle[index - 1]-(1.0-alpha1)*(1.0-alpha1)*aCycle[index - 2]			   
		
		return aCycle[index-1], aCycle[index] 
	end
end
	----------------------------

function Init()
	myCyberCycle = CyberCycle()
	return #Settings.line
end

function OnCalculate(index)

	--WriteLog ("OnCalc() ".."CandleExist("..index.."): "..tostring(CandleExist(index)).."; T("..index.."); "..isnil(toYYYYMMDDHHMMSS(T(index))," - ").."; C("..index.."): "..isnil(C(index),"-"));
	return myCyberCycle(index, Settings.alpha, Settings.cycletype)
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
