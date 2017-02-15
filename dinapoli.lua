 --logfile=io.open("C:\\SBERBANK\\QUIK_SMS\\LuaIndicators\\qlua_log.txt", "w")

 Settings = 
{
	Name = "*Dinapoli",
	period = 64,
	bars = 300,
	display_mode = 1,
	all_time_max = 0,
	line=
	{
		{
			Name = "SMA",
			Color = RGB(0, 128, 0),
			Type = TYPE_LINE,
			Width = 2
		}
	,
		{
			Name = "(-60;60)",
			Color = RGB(150, 150, 150),
			Type = TYPE_HISTOGRAM,
			Width = 2
		}
	,
		{
			Name = "(-80;-60]||[60;80)",
			Color = RGB(230, 240, 8),
			Type = TYPE_HISTOGRAM,
			Width = 2
		}
	,
		{
			Name = "(-100;-80]||[80;100)",
			Color = RGB(80, 170, 255),
			Type = TYPE_HISTOGRAM,
			Width = 2
		}
	,
		{
			Name = "(--;-100]||[100;++)",
			Color = RGB(255, 0, 0),
			Type = TYPE_HISTOGRAM,
			Width = 2
		}	
	,	
		{
			Name = "60;80",
			Color = RGB(230, 240, 8),
			Type = TYPE_LINE,
			Width = 1
		}
	,	
		{
			Name = "-80;-60",
			Color = RGB(230, 240, 8),
			Type = TYPE_LINE,
			Width = 1
		}
	,	
		{
			Name = "80;100",
			Color = RGB(80, 170, 255),
			Type = TYPE_LINE,
			Width = 1
		}
	,	
		{
			Name = "-100;-80",
			Color = RGB(80, 170, 255),
			Type = TYPE_LINE,
			Width = 1
		}
	,	
		{
			Name = "100;++",
			Color = RGB(255, 0, 0),
			Type = TYPE_LINE,
			Width = 1
		}
	,	
		{
			Name = "--;-100",
			Color = RGB(255, 0, 0),
			Type = TYPE_LINE,
			Width = 1
		}		
	}
}

----------------------------------------------------------
function DinapoliSMA()
	
	local TrendlessOSBuffer={}
	local ExtBuffer1={}
	local ExtBuffer2={}
	local ExtBuffer3={}
	local ExtBuffer4={}
	local top={}
	local bottom={}

	local H_tmp={}
	local L_tmp={}
	
	local SMA=fSMA()
	
	return function(ind, _p, _b, _dm, _alm, ds)
		local period = _p
		local index = ind
		local Display_mode = _dm
		local bars = _b
		local all_time_max = _alm
				
		local OBLevel = 0;          --граница уровня перекупленности
		local OSLevel = 0;  		--граница уровня перепроданности
	    
		local EightyOBlvl=0.8*OBLevel;                --методика расчёта 80% перекупленности
	    local EightyOSlvl=0.8*OSLevel;                --методика расчёта 80% перепроданности
	    local SixtyOBlvl=0.6*OBLevel;                 --методика расчёта 60% перекупленности
	    local SixtyOSlvl=0.6*OSLevel;                 --методика расчёта 60% перепроданности
		
		if index == 1 then
			TrendlessOSBuffer = {}
			ExtBuffer1={}
			ExtBuffer2={}
			ExtBuffer3={}
			ExtBuffer4={}
			top={}
			bottom={}
			
			TrendlessOSBuffer[index]=0
			
			ExtBuffer1[index]=0
			ExtBuffer2[index]=0
			ExtBuffer3[index]=0
			ExtBuffer4[index]=0
			top[index]=0
			bottom[index]=0
			return nil, nil, nil, nil, nil, SixtyOBlvl, SixtyOSlvl, EightyOBlvl, EightyOSlvl, OBLevel, OSLevel
		end
							
		if index <= period or not CandleExist(index) then
			TrendlessOSBuffer[index] = TrendlessOSBuffer[index-1]
			top[index]=top[index-1]
			bottom[index]=bottom[index-1]
			return nil, nil, nil, nil, nil, SixtyOBlvl, SixtyOSlvl, EightyOBlvl, EightyOSlvl, OBLevel, OSLevel
		end
		
		TrendlessOSBuffer[index]= C(index) - SMA(index, period)--SMA(index, {Period=period, Metod = "SMA", VType="C", round="off"}, ds)	
		
		if TrendlessOSBuffer[index] > top[index-1] then
			top[index] = TrendlessOSBuffer[index];
		else
			top[index] = top[index-1]
		end
	  
		if TrendlessOSBuffer[index] < bottom[index-1] then
			bottom[index] = TrendlessOSBuffer[index];
		else
			bottom[index] = bottom[index-1]
		end
		
		if index <= bars then
			return nil, nil, nil, nil, nil, SixtyOBlvl, SixtyOSlvl, EightyOBlvl, EightyOSlvl, OBLevel, OSLevel
		end
		
		current = TrendlessOSBuffer[index]				
			
		local val_h=0 
		local val_l=0
		
		firstIndex = index - bars
		
		if index > bars and all_time_max == 0 then						
			val_h=math.max(unpack(TrendlessOSBuffer,index-bars,index)) 
			val_l=math.min(unpack(TrendlessOSBuffer,index-bars,index))				
		end

		if val_h == 0 then
			val_h = top[index]
		end
		if val_l == 0 then
			val_l = bottom[index]
		end
				
		OBLevel = val_h
		OSLevel = val_l
		
		EightyOBlvl=0.8*OBLevel;                --методика расчёта 80% перекупленности
	    EightyOSlvl=0.8*OSLevel;                --методика расчёта 80% перепроданности
	    SixtyOBlvl=0.6*OBLevel;                 --методика расчёта 60% перекупленности
	    SixtyOSlvl=0.6*OSLevel;                 --методика расчёта 60% перепроданности
		
		if (current>0.6*OSLevel and current<0.6*OBLevel)       --если значние индикатора находится в диапазоне (-60%;60%)                 
		then
			 ExtBuffer1[index]=current;                            --то отображается гистограмма ExtBuffer1[]                
			 ExtBuffer2[index]=0.0;                                
			 ExtBuffer3[index]=0.0; 
			 ExtBuffer4[index]=0.0;                      
			
		else                                                 --если значение индикатора не входит в диапазон (-60%;60%), то проверяется следующее условие                                    
			
			 if ((current>0.8*OSLevel and current<=0.6*OSLevel) or (current>=0.6*OBLevel and current<0.8*OBLevel)) --если значение индикатора в диапазоне (-80%;-60%] или [60%;80%)                  
			 then
				ExtBuffer1[index]=0.0;                
				ExtBuffer2[index]=current;                         --то отображается гистограмма ExtBuffer2[]
				ExtBuffer3[index]=0.0; 
				ExtBuffer4[index]=0.0;                      
			           
			 else                                             --если значение индикатора не входит и в диапазон (-80%;-60%]||[60%;80%), то проверяется следующее условие
			   
				if ((current>OSLevel and current<=0.8*OSLevel) or (current>=0.8*OBLevel and current<OBLevel))  --если значение индикатора в диапазоне (-100%;-80%] или [80%;100%)                  
				then
				   ExtBuffer1[index]=0.0;                
				   ExtBuffer2[index]=0.0;
				   ExtBuffer3[index]=current;                      --то отображается ExtBuffer3[]
				   ExtBuffer4[index]=0.0;                      
				                  
				else                                           --если значение индикатора не входит и в диапазон (-100%;-80%]||[80%;100%), то проверяется следующее условие
				  
				   if (current<=OSLevel or current>=OBLevel)    --если значение индикатора входит в диапазон (--;-100%]||[100%;++)                 
					then
					  ExtBuffer1[index]=0.0;                
					  ExtBuffer2[index]=0.0;
					  ExtBuffer3[index]=0.0; 
					  ExtBuffer4[index]=current;                   --то отображается ExtBuffer4[] 
					end 
				end
			end
		end   
		
		if Display_mode == 1 then
			return nil, ExtBuffer1[index], ExtBuffer2[index], ExtBuffer3[index], ExtBuffer4[index] , nil, nil, nil, nil, nil, nil
		elseif Display_mode == 2 then
			return TrendlessOSBuffer[index], nil, nil, nil, nil , nil, nil, nil, nil, nil, nil
		elseif Display_mode == 3 then -- отладка
			return nil, ExtBuffer1[index], ExtBuffer2[index], ExtBuffer3[index], ExtBuffer4[index] , SixtyOBlvl, SixtyOSlvl, EightyOBlvl, EightyOSlvl, OBLevel, OSLevel
		end
				
	end
end
	----------------------------

function Init()
	myDinapoliSMA = DinapoliSMA()
     
	return #Settings.line
end

function OnCalculate(index)
	--if index < Settings.period then
	--	return nil, nil, nil, nil, nil, nil, nil, nil, nil
	--end
   --WriteLog ("OnCalc() ".."CandleExist("..index.."): "..tostring(CandleExist(index)).."; T("..index.."); "..isnil(toYYYYMMDDHHMMSS(T(index))," - ").."; C("..index.."): "..isnil(C(index),"-"));

	return myDinapoliSMA(index, Settings.period, Settings.bars, Settings.display_mode, Settings.all_time_max)
end

-- Пользовательcкие функции
function WriteLog(text)

   logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n");
   logfile:flush();
   LASTLOGSTRING = text;

end;

function isnil(a,b)
   if a == nil then
      return b
   else
      return a
   end;
end;

function toYYYYMMDDHHMMSS(datetime)
   if type(datetime) ~= "table" then
      message("в функции toYYYYMMDDHHMMSS неверно задан параметр: datetime="..tostring(datetime))
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


function highestHigh(BB, index, period)

	if index == 1 then
		return nil
	else

		local highestHigh = 0		
		
		for i = math.max(index - period, 2), index, 1 do
			
			if BB[index] > highestHigh and BB[index] > 0 then
				highestHigh = BB[index]
			end
			
		end
	
		return highestHigh 
	
	end
end

function lowestLow(BB, index, period)

	if index == 1 then
		return nil
	else

		local lowestLow = 0
		
		for i = math.max(index - period, 2), index, 1 do
						
			if BB[index] < lowestLow and BB[index] < 0 then
				lowestLow = BB[index]
			end
			
		end
	
		return lowestLow 
	
	end
end

function fSMA()
		
	return function (Index, Period, idp)
		
		local Out = 0
		   
		   if Index >= Period then
			  local sum = 0
			  local quant = 0
			  for i = Index-Period+1, Index do
				 if C(i) ~= nil then
					 sum = sum + C(i) or 0
					 quant = quant + 1
				 end
			  end
			  if quant ~=0 then
				Out = sum/quant
			  end
		   end
		   
		return Out
	end
end
