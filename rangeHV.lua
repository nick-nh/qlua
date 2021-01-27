--logfile=io.open(getWorkingFolder().."\\LuaIndicators\\rangeHV.txt", "w")

min_price_step = 0

Settings=
{
	Name = "*rangeHV",
	period = 39,
	periodSlow = 39,
	bars = 1000,
	clasters = 100,
	showVWAP = 1,
	showEMAVWAP = 1,
	emaPeriod = 12,
	showSigmaVol = 0,
	showSigmaCenterLevel = 0,
	showTradeSignal = 0,
	line =
	{		
		{
			Name = "maxVol",
			Color = RGB(127, 127, 127),
			Type = TYPET_BAR, --TYPE_DASHDOT,
			Width = 3
		},
		{
			Name = "VWAP",
			Color = RGB(64, 64, 64),
			Type = TYPET_LINE, --TYPE_DASHDOT,
			Width = 1
		},
		{
			Name = "EMAVWAP",
			Color = RGB(64, 64, 64),
			Type = TYPET_LINE, --TYPE_DASHDOT,
			Width = 1
		},
		{
			Name = "maxVolFast",
			Color = RGB(0, 128, 192),
			Type = TYPET_BAR, --TYPE_DASHDOT,
			Width = 3
		},
		{
			Name = "VWAPFast",
			Color = RGB(0, 128, 192),
			Type = TYPET_LINE, --TYPE_DASHDOT,
			Width = 1
		},
		{
			Name = "EMAVWAPFast",
			Color = RGB(0, 128, 192),
			Type = TYPET_LINE, --TYPE_DASHDOT,
			Width = 1
		},
		{
			Name = "buy",
			Color = RGB(40,240,250),
			Type = TYPE_POINT,
			Width = 4
		},
		{
			Name = "sell",
			Color = RGB(255,0,255),
			Type = TYPE_POINT,
			Width = 4
		},
		{
			Name = "UpSigmaVol",
			Color = RGB(0, 0, 0),
			Type = TYPE_DASHDOT, --TYPE_DASHDOT,
			Width = 1
		},
		{
			Name = "DownSigmaVol",
			Color = RGB(0, 0, 0),
			Type = TYPE_DASHDOT, --TYPE_DASHDOT,
			Width = 1
		}
	}
}


function Init()
	myFunc = rangeBar()
	return #Settings.line
end


function OnCalculate(index)
	
	if index == 1 then
		DSInfo = getDataSourceInfo()     	
		min_price_step = getParamEx(DSInfo.class_code, DSInfo.sec_code, "SEC_PRICE_STEP").param_value
		scale = getSecurityInfo(DSInfo.class_code, DSInfo.sec_code).scale
	end	
	return myFunc(index, Settings)
		
end

function OnDestroy()
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
		if previous ==0 then
			return 0
		end
	
		return math.max(math.abs(H(i) - L(i)), math.abs(H(i) - C(previous)), math.abs(C(previous) - L(i)))
	else
		return C(i)
	end 
end

function rangeBar()
	
	local maxPrice={}
	local VWAP={}	
	local maxPricefast={}
	local VWAPfast={}	

	local UpSigmaVol={}	
	local DownSigmaVol={}	
	local UpSigmaVolfast={}	
	local DownSigmaVolfast={}	
	local Close = {}
	local Open = {}
	local High = {}
	local Low = {}
	local CC={}
	local CCfast={}
	local calculated_buffer={}
	local calcAlgoValue={}
	local trend={}
	local signal={}

	local EMA={}	
	local vEMA={}	
	local vfEMA={}	

	return function(ind, Fsettings, ds)
	
		local Fsettings=(Fsettings or {})
		
		local index = ind
		local periodHV = Fsettings.period or 59
		local periodHV2 = math.max(Fsettings.periodSlow or 150, Fsettings.period) 

		local maxPeriodHV = math.max(periodHV,periodHV2)
		
		local bars = Fsettings.bars or 1000
		local clasters = Fsettings.clasters or 50
		
		if bars == 0 then bars = Size()-100 end
		
		local showVWAP = Fsettings.showVWAP or 1
		local showEMAVWAP = Fsettings.showEMAVWAP or 0
		local emaPeriod = Fsettings.emaPeriod or period
		local showSigmaVol = Fsettings.showSigmaVol or 0
		local showSigmaCenterLevel = Fsettings.showSigmaCenterLevel or 0
		local showTradeSignal = Fsettings.showTradeSignal or 0
		
		local kvEMA = 2/(emaPeriod+1)
		
		local MAX = 0
		local MAXV = 0
		local MIN = 0
		local MAXfast = 0
		local MAXVfast = 0
		local MINfast = 0
		local jj = 0
		local kk = 0
				
		local outMaxPriceFast = nil			
		local outVWAP = nil			
		local outVWAPfast = nil			
		local outEMAVWAP = nil			
		local outEMAVWAPfast = nil			
		local outUpSigmaVol = nil			
		local outDownSigmaVol = nil			

		if index == 1 then
            maxPrice = {}
			maxPrice[index] = 0	

            VWAP = {}
			VWAP[index] = 0	
			if showSigmaVol == 1 or showSigmaCenterLevel == 1 then		
				UpSigmaVol = {}
				UpSigmaVol[index] = 0			
				DownSigmaVol = {}
				DownSigmaVol[index] = 0			
				UpSigmaVolfast = {}
				UpSigmaVolfast[index] = 0			
				DownSigmaVolfast = {}
				DownSigmaVolfast[index] = 0			
			end

			Close = {}
			Close[index] = 0
			Open = {}
			Open[index] = 0
			High = {}
			High[index] = 0
			Low = {}
			Low[index] = 0
			
			calculated_buffer = {}
			trend = {}
            trend[index] = 1			
			calcAlgoValue = {}
            calcAlgoValue[index] = C(index)			
			signal = {}
            signal[index] = {nil,nil}			
			
			if periodHV < periodHV2 then
				maxPricefast = {}
				maxPricefast[index] = 0			
				CCfast={}
				CCfast[1]={0, C(index)}
				VWAPfast = {}
				VWAPfast[index] = 0			
			end
			
			if showTradeSignal == 1 or showEMAVWAP == 1 then
				vEMA = {}
				vEMA[index] = C(index)			
				vfEMA = {}
				vfEMA[index] = C(index)			
			end

            return nil
		end
				
        if calculated_buffer[index] == nil then
			
			maxPrice[index] 		= maxPrice[index-1] 
			VWAP[index] 	  = VWAP[index-1] 
			if periodHV < periodHV2 then
				maxPricefast[index] 		= maxPricefast[index-1] 
				VWAPfast[index] 	  = VWAPfast[index-1] 
			end

			High[index] 			= High[index-1] 
			Low[index] 				= Low[index-1] 
			Close[index] 			= Close[index-1] 
			calcAlgoValue[index]  	= calcAlgoValue[index-1] 
			trend[index]  			= trend[index-1] 
			signal[index]  			= {nil,nil} 

			if showSigmaVol == 1 or showSigmaCenterLevel == 1 then		
				UpSigmaVol[index] 	      = UpSigmaVol[index-1] 
				DownSigmaVol[index] 	  = DownSigmaVol[index-1] 
				UpSigmaVolfast[index] 	  = UpSigmaVolfast[index-1] 
				DownSigmaVolfast[index]   = DownSigmaVolfast[index-1] 
			end
			if showTradeSignal == 1 or showEMAVWAP == 1 then
				vEMA[index] = vEMA[index-1] 
				vfEMA[index] = vfEMA[index-1] 
			end
		end
            
		if not CandleExist(index) then
			return nil
		end

		local beginIndex = math.max(Size() - bars, maxPeriodHV, emaPeriod)
		
		if index == beginIndex then
            maxPrice[index] = C(index)		
			VWAP[index] = C(index)
			if periodHV < periodHV2 then
				maxPricefast[index] = C(index)		
				VWAPfast[index] = C(index)
			end
			if showSigmaVol == 1 or showSigmaCenterLevel == 1 then		
				UpSigmaVol[index] = C(index)			
				DownSigmaVol[index] = C(index)			
				UpSigmaVolfast[index] = C(index)			
				DownSigmaVolfast[index] = C(index)			
			end
			
			calcAlgoValue[index] = C(index)			

			if showTradeSignal == 1 or showEMAVWAP == 1 then
				vEMA[index] = C(index)
				vfEMA[index] = C(index)
			end
		end

        Close[index] = C(index)			
        Open[index]  = O(index)			
        High[index]  = H(index)			
        Low[index] 	 = L(index)			

		if index < beginIndex then
			return nil
		end

		outMaxPrice = maxPrice[index]

		if periodHV < periodHV2 then
			outMaxPriceFast = maxPricefast[index]
		end
		if showVWAP == 1 then 
			outVWAP = VWAP[index]
			if periodHV < periodHV2 then
				outVWAPfast = VWAPfast[index]
			end			
		end
		if showEMAVWAP == 1 then
			outEMAVWAP = vEMA[index]
			if periodHV < periodHV2 then
				outEMAVWAPfast = vfEMA[index]
			end			
		end			
		
		if showSigmaVol == 1 then
			outUpSigmaVol = UpSigmaVol[index]
			outDownSigmaVol = DownSigmaVol[index]
		end	

		if calculated_buffer[index]~=nil then
			return outMaxPrice, outVWAP, outEMAVWAP, outMaxPriceFast, outVWAPfast, outEMAVWAPfast, signal[index][1], signal[index][2], outUpSigmaVol, outDownSigmaVol
		end
				
		local previous = index-maxPeriodHV		

		local _p = index - previous

		if C(previous) == nil then
			previous = FindExistCandle(previous)
		end
		
		MAX = High[math.max(previous+1, 1)]
		MIN = Low[math.max(previous+1, 1)]      
		for i=math.max(previous+1, 1)+1,index do
			MAX = math.max(High[i], MAX)
			MIN = math.min(Low[i], MIN)
		end 

		for i = 1, clasters do CC[i]={0, i/clasters*(MAX-MIN)+MIN} end

		local previousFast = index-periodHV		

		local needCalcFast = false
		if periodHV < maxPeriodHV then           
			if C(previousFast) == nil then
				previousFast = FindExistCandle(previousFast)
			end

			MAXfast = High[math.max(previousFast+1, 1)]
			MINfast = Low[math.max(previousFast+1, 1)]      
			for i=math.max(previousFast+1, 1)+1,index do
				MAXfast = math.max(High[i], MAXfast)
				MINfast = math.min(Low[i], MINfast)
			end 
			for i = 1, clasters do CCfast[i]={0, i/clasters*(MAXfast-MINfast)+MINfast} end
			needCalcFast = true
		end 
		
		local numProf = 0
		local avgVol = 0
		local numProffast = 0
		local avgVolfast = 0

		VWAP[index] = 0
		local allVolume = 0
		VWAPfast[index] = 0
		local allVolumefast = 0

		for i = 0, _p-1 do
			if C(index-i) ~= nil then
				jj=math.floor( (H(index-i)-MIN)/(MAX-MIN)*(clasters-1))+1
				kk=math.floor( (L(index-i)-MIN)/(MAX-MIN)*(clasters-1))+1
				for k=1,(jj-kk) do
					if CC[kk+k-1][1] == 0 then numProf = numProf + 1 end
					CC[kk+k-1][1]=CC[kk+k-1][1]+V(index-i)/(jj-kk)
					VWAP[index] = VWAP[index] + CC[kk+k-1][2]*V(index-i)/(jj-kk)
					avgVol = avgVol + V(index-i)/(jj-kk)
					allVolume = allVolume + V(index-i)/(jj-kk)
				end
				if needCalcFast and index-i>=previousFast+1 then
					jj=math.floor( (H(index-i)-MINfast)/(MAXfast-MINfast)*(clasters-1))+1
					kk=math.floor( (L(index-i)-MINfast)/(MAXfast-MINfast)*(clasters-1))+1
					for k=1,(jj-kk) do
						if CCfast[kk+k-1][1] == 0 then numProffast = numProffast + 1 end
						CCfast[kk+k-1][1]=CCfast[kk+k-1][1]+V(index-i)/(jj-kk)
						avgVolfast = avgVolfast + V(index-i)/(jj-kk)
						VWAPfast[index] = VWAPfast[index] + CCfast[kk+k-1][2]*V(index-i)/(jj-kk)
						allVolumefast = allVolumefast + V(index-i)/(jj-kk)
					end
				end
			end
		end

		VWAP[index] = VWAP[index]/allVolume
		
		if needCalcFast then
			VWAPfast[index] = VWAPfast[index]/allVolumefast
		end

		if showTradeSignal == 1 or showEMAVWAP == 1 then
			vEMA[index]=round(kvEMA*VWAP[index]+(1-kvEMA)*vEMA[index-1], 5)
			if needCalcFast then
				vfEMA[index]=round(kvEMA*VWAPfast[index]+(1-kvEMA)*vfEMA[index-1], 5)
			end			
		end
		
		local sigma = 0
		local sigmafast = 0
		local maxClaster = 0
		local maxClasterfast = 0

		if numProf > 0 then
			avgVol = round(avgVol/numProf, 5)
		else 
			avgVol = 0
		end
		if numProffast > 0 then
			avgVolfast = round(avgVolfast/numProffast, 5)
		else 
			avgVolfast = 0
		end
		
        for i = 1, clasters do 
            MAXV = math.max(MAXV, CC[i][1]) 
			sigma = sigma + math.pow(CC[i][1] - avgVol, 2)
			if MAXV == CC[i][1] then
				maxPrice[index]=CC[i][2]
				maxClaster = i
			end
			if needCalcFast then
				MAXVfast = math.max(MAXVfast, CCfast[i][1]) 
				sigmafast = sigmafast + math.pow(CCfast[i][1] - avgVolfast, 2)
				if MAXVfast == CCfast[i][1] then
					maxPricefast[index]=CCfast[i][2]
					maxClasterfast = i
				end
			end
		end

		if showSigmaVol == 1 or showSigmaCenterLevel == 1 then
			if numProf > 1 then
				sigma = round(math.sqrt(sigma/(numProf-1)), 2)
			else 
				sigma = 0
			end	
			if numProffast > 1 then
				sigmafast = round(math.sqrt(sigmafast/(numProffast-1)), 2)
			else 
				sigmafast = 0
			end	

			if sigma > 0 then
				local find = false
				local i = maxClaster+1
				for i=maxClaster+1,clasters do
					if CC[i][1] < MAXV - sigma and not find then
						UpSigmaVol[index] = CC[i][2]
						find = true
					end
					if CC[i][1] > MAXV - sigma and find then
						find = false
					end
				end
				find = true
				for i=maxClaster-1,1, -1 do
					if CC[i][1] < MAXV - sigma and not find then
						DownSigmaVol[index] = CC[i][2]
						find = true
					end
					if CC[i][1] > MAXV - sigma and find then
						find = false
					end
				end
			end
			if sigmafast > 0 then
				local find = false
				local i = maxClasterfast+1
				for i=maxClasterfast+1,clasters do
					if CCfast[i][1] < MAXVfast - sigmafast and not find then
						UpSigmaVolfast[index] = CCfast[i][2]
						find = true
					end
					if CCfast[i][1] > MAXVfast - sigmafast and find then
						find = false
					end
				end
				find = true
				for i=maxClasterfast-1,1, -1 do
					if CCfast[i][1] < MAXVfast - sigmafast and not find then
						DownSigmaVolfast[index] = CCfast[i][2]
						find = true
					end
					if CCfast[i][1] > MAXVfast - sigmafast and find then
						find = false
					end
				end
			end
		end
				
		calculated_buffer[index] = maxPrice[index]
		outMaxPrice = maxPrice[index]

		if periodHV < periodHV2 then
			outMaxPriceFast = maxPricefast[index]
		end
		if showVWAP == 1 then 
			outVWAP = VWAP[index]
			if periodHV < periodHV2 then
				outVWAPfast = VWAPfast[index]
			end			
		end
		if showEMAVWAP == 1 then
			outEMAVWAP = vEMA[index]
			if periodHV < periodHV2 then
				outEMAVWAPfast = vfEMA[index]
			end			
		end			

		if showSigmaVol == 1 then
			outUpSigmaVol = UpSigmaVol[index]
			outDownSigmaVol = DownSigmaVol[index]
		end	
		if showSigmaCenterLevel == 1 then
			outMaxPrice = (UpSigmaVol[index] + DownSigmaVol[index])/2
			if needCalcFast then
				outMaxPriceFast = (UpSigmaVolfast[index] + DownSigmaVolfast[index])/2
			end
		end	

		if index <= Size() - bars + math.max(maxPeriodHV, emaPeriod) then
			return outMaxPrice, outVWAP, outEMAVWAP, outMaxPriceFast, outVWAPfast, outEMAVWAPfast, signal[index][1], signal[index][2], outUpSigmaVol, outDownSigmaVol
		end	
                
		if showTradeSignal == 1 then
	
			local isUpPinBar = C(index)>O(index) and (H(index)-C(index))/(H(index) - L(index))>=0.5 
			local isLowPinBar = C(index)<O(index) and (C(index)-L(index))/(H(index) - L(index))>=0.5         
				
            local isBuy = trend[index] <= 0 and vEMA[index] > vEMA[index-1] 
            local isSell = trend[index] >= 0 and vEMA[index] < vEMA[index-1]
			
			if isBuy then
				trend[index] = 1
			end
			if isSell then
				trend[index] = -1
			end
			
            --WriteLog("index "..tostring(index)..", trend "..tostring(trend[index])..", isBuy "..tostring(isBuy)..", isSell "..tostring(isSell)..", Close "..tostring(Close[index])..", vfEMA "..tostring(vfEMA[index])..", VWAP "..tostring(VWAP[index]))

			if trend[index-1]>0 and trend[index-2]<=0 then
				signal[index][1] = O(index)
			end
			if trend[index-1]<0 and trend[index-2]>=0 then
				signal[index][2] = O(index)
			end
			if trend[index-1]==0 and trend[index-2]<0 then
				signal[index][1] = O(index)
			end
			if trend[index-1]==0 and trend[index-2]>0 then
				signal[index][2] = O(index)
			end

		end

		return outMaxPrice, outVWAP, outEMAVWAP, outMaxPriceFast, outVWAPfast, outEMAVWAPfast, signal[index][1], signal[index][2], outUpSigmaVol, outDownSigmaVol
		
	end
end

function WriteLog(text)

   logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n");
   logfile:flush();
   LASTLOGSTRING = text;

end

function round(num, idp)
	if idp and num then
	   local mult = 10^(idp or 0)
	   if num >= 0 then return math.floor(num * mult + 0.5) / mult
	   else return math.ceil(num * mult - 0.5) / mult end
	else return num end
end

function toYYYYMMDDHHMMSS(datetime)
    if type(datetime) ~= "table" then
       --message("в функции toYYYYMMDDHHMMSS неверно задан параметр: datetime="..tostring(datetime))
       return ""
    else
       local Res = tostring(datetime.year)
       if #Res == 1 then Res = "000"..Res end
       local month = tostring(datetime.month)
       if #month == 1 then Res = Res.."/0"..month; else Res = Res..'/'..month; end
       local day = tostring(datetime.day)
       if #day == 1 then Res = Res.."/0"..day; else Res = Res..'/'..day; end
       local hour = tostring(datetime.hour)
       if #hour == 1 then Res = Res.." 0"..hour; else Res = Res..' '..hour; end
       local minute = tostring(datetime.min)
       if #minute == 1 then Res = Res..":0"..minute; else Res = Res..':'..minute; end
       local sec = tostring(datetime.sec);
       if #sec == 1 then Res = Res..":0"..sec; else Res = Res..':'..sec; end;
       return Res
    end
 end --toYYYYMMDDHHMMSS
 
 function isnil(a,b)
    if a == nil then
       return b
    else
       return a
    end;
 end
