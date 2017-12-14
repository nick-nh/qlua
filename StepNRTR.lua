--logfile=io.open("C:\\SBERBANK\\QUIK_SMS\\LuaIndicators\\qlua_log.txt", "w")

min_price_step = 0
sec_code = ""
timescale = ""
local w32 = require("w32")

Settings=
{
	Name = "*StepNRTR",
	Length = 5,
	value_type = "ATR",
	Kv = 1.5,
	StepSize = 0,
	Percentage = 0,
	Switch = 1, --1 - HighLow, 2 - CloseClose
	ShowLine = 1,
	PlaySound = 1,
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
		Color = RGB(0, 64, 0),
		Type = TYPE_LINE, --TYPE_DASHDOT,
		Width = 2
		}
	}
}


function Init()
	myNRTR = cached_NRTR()
	return #Settings.line
end


function OnCalculate(index)
	
	if index == 1 then
		DSInfo = getDataSourceInfo()     	
		sec_code = DSInfo.sec_code
		timescale = DSInfo.interval
		min_price_step = getParamEx(DSInfo.class_code, DSInfo.sec_code, "SEC_PRICE_STEP").param_value
		--WriteLog ("min_price_step "..tostring(min_price_step))
	end
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
	local smax1={}
	local smin1={}
	local trend={}
	
	local isMessage={}
	
	return function(ind, Fsettings, ds)
	
		local Fsettings=(Fsettings or {})
		local p = 0
		local ATR = 0
		
		local index = ind
		local Length = Fsettings.Length or 64
		local Kv = Fsettings.Kv or 1
		local v_type = Fsettings.value_type or "ATR"
		local StepSize = Fsettings.StepSize or 0		
		local Percentage = Fsettings.Percentage or 0
		local Switch = Fsettings.Switch or 1
		local ShowLine = Fsettings.ShowLine or 0
		local PlaySound = Fsettings.PlaySound or 0
		
		local ratio=Percentage/100.0*min_price_step	
		local out1 = nil
		local out2 = nil
		local out3 = nil
		
		SetValue(index-11, 3, nil)			
		SetValue(index-1, 3, nil)			
				
		if index == 1 then
			cache_NRTR = {}
			cache_NRTR[index] = 0			
			smax1 = {}
			smin1 = {}
			trend = {}
			smax1[index] = L(index)
			smin1[index] = H(index)
			trend[index] = 1
			isMessage = {}
			return nil
		end
		
		cache_NRTR[index] = cache_NRTR[index-1] 
		smax1[index] = smax1[index-1] 
		smin1[index] = smin1[index-1] 
		trend[index] = trend[index-1] 
		
		if not CandleExist(index) then
			return nil
		end
		if index <= (Length + 3) then
			return nil
		end

		--WriteLog ("---------------------------------")
		--WriteLog ("index "..tostring(index))
		--WriteLog ("C(index) "..tostring(C(index)))
		--WriteLog ("H(index) "..tostring(H(index)))
		--WriteLog ("L(index) "..tostring(L(index)))
		
		local Step=StepSizeCalc(Length,Kv,StepSize,index)
		if Step == 0 then Step = 1 end
		
		local SizeP=Step*min_price_step
		local Size2P=2*SizeP
		
		--WriteLog ("Step "..tostring(Step))

		local result
		
		local previous = index-1
		
		if not CandleExist(previous) then
			previous = FindExistCandle(previous)
		end
		
		if Switch == 1 then     
			smax0=L(previous)+Size2P
			smin0=H(previous)-Size2P    
		else   
			smax0=C(previous)+Size2P
			smin0=C(previous)-Size2P
		end
		
		--WriteLog ("smax0 "..tostring(smax0))
		--WriteLog ("smin0 "..tostring(smin0))
		--WriteLog ("smax1[index] "..tostring(smax1[index]))
		--WriteLog ("smin1[index] "..tostring(smin1[index]))

		if C(index)>smax1[index] then trend[index] = 1 end
		if C(index)<smin1[index] then trend[index]= -1 end
		--WriteLog ("trend "..tostring(trend[index]))

		if trend[index]>0 then
			if smin0<smin1[index] then smin0=smin1[index] end
			result=smin0+SizeP
		else
			if smax0>smax1[index] then smax0=smax1[index] end
			result=smax0-SizeP
		end
		--WriteLog ("result "..tostring(result))
	 		
		smax1[index] = smax0
		smin1[index] = smin0
		--WriteLog ("smax0 "..tostring(smax0))
		--WriteLog ("smin0 "..tostring(smin0))
		--WriteLog ("smax1[index] "..tostring(smax1[index]))
		--WriteLog ("smin1[index] "..tostring(smin1[index]))
		
		if trend[index]>0 then
			cache_NRTR[index]=(result+ratio/Step)-Step*min_price_step
		end
		if trend[index]<0 then
			cache_NRTR[index]=(result+ratio/Step)+Step*min_price_step		
		end	
		
		if trend[index]>0 and trend[index-1]<0 then
			out1 = O(index)
			out2 = nil
		end

		if trend[index]<0 and trend[index-1]>0 then
			out1 = nil
			out2 = O(index)
		end
				
		--сообщения
		if index == Size() and trend[index-1]>0 and trend[index-2]<0 and isMessage[index] == nil then
			message("Buy "..tostring(sec_code).." timescale "..tostring(timescale))
			if PlaySound == 1 then
				PaySoundFile("c:\\windows\\media\\Alarm03.wav")
			end
			isMessage[index] = 1
		end

		if index == Size() and trend[index-1]<0 and trend[index-2]>0 and isMessage[index] == nil then
			message("Sell "..tostring(sec_code).." timescale "..tostring(timescale))
			if PlaySound == 1 then
				PaySoundFile("c:\\windows\\media\\Alarm03.wav")
			end
			isMessage[index] = 1
		end
		
		
		if ShowLine == 1 then
			SetValue(index-10, 3, cache_NRTR[index])			
			out3 = cache_NRTR[index]
		end
		
		return out1, out2, out3 
		
	end
end

function WriteLog(text)

   logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n");
   logfile:flush();
   LASTLOGSTRING = text;

end;

function PaySoundFile(file_name)
  w32.mciSendString("CLOSE QUIK_MP3") 
  w32.mciSendString("OPEN \"" .. file_name .. "\" TYPE MpegVideo ALIAS QUIK_MP3")
  w32.mciSendString("PLAY QUIK_MP3")
end

function StepSizeCalc(Len, Km, Size, index)

	local result

	if Size == 0 then
		 
		local Range=0.0
		local ATRmax=-1000000
		local ATRmin=1000000

		for iii=1, Len do	
			if CandleExist(index-iii) then				
				Range=H(index-iii)-L(index-iii)
				if Range>ATRmax then ATRmax=Range end
				if Range<ATRmin then ATRmin=Range end
			end
		end
		result = round(0.5*Km*(ATRmax+ATRmin)/min_price_step, nil)
		 
	else result=Km*Size
	end

	return result
end


function round(num, idp)
	if idp and num then
	   local mult = 10^(idp or 0)
	   if num >= 0 then return math.floor(num * mult + 0.5) / mult
	   else return math.ceil(num * mult - 0.5) / mult end
	else return num end
end
