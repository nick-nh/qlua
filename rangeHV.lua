--logfile=io.open(getWorkingFolder().."\\LuaIndicators\\rangeHV.txt", "w")

min_price_step = 0

Settings=
{
	Name = "*rangeHV",
	period = 50,
	bars = 1000,
	clasters = 50,
	showEMA = 1,
	line =
	{		
		{
			Name = "maxVol",
			Color = RGB(127, 127, 127),
			Type = TYPET_BAR, --TYPE_DASHDOT,
			Width = 3
		},
		{
			Name = "maxVolEMA",
			Color = RGB(255, 127, 50),
			Type = TYPET_LINE, --TYPE_DASHDOT,
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
		if tonumber(min_price_step) == 0 or min_price_step == nil then
			min_price_step = 1
		end
		--WriteLog ("min_price_step "..tostring(min_price_step))
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
	
		return math.max(math.abs(H(i) - L(i)), math.abs(H(i) - C(previous)), math.abs(C(previous) - L(i)))
	else
		return C(i)
	end 
end

function rangeBar()
	
	local cacheL={}
	local cacheH={}
	local CC={}
	local VV={}	
	local EMA={}	
	local calculated_buffer={}
		
	return function(ind, Fsettings, ds)
	
		local Fsettings=(Fsettings or {})
		
		local index = ind
		local period = Fsettings.period or 29
		local bars = Fsettings.bars or 1000
		local clasters = Fsettings.clasters or 50
		local showEMA = Fsettings.showEMA or 0

		local MAX = 0
		local MAXV = 0
		local MIN = 0
		local jj = 0
		local kk = 0
		local kEMA = 2/(period+1)
		
		local outEMA = nil			
			
		local minC = nil
		local maxC = nil
		
		if index == 1 then
            cacheL = {}
            cacheL[index] = 0			
            cacheH = {}
            cacheH[index] = 0			
            EMA = {}
            EMA[index] = 0			

			VV={}
			VV[index]=V(index)
			CC={}
			CC[1]={0, C(index)}
			calculated_buffer = {}

            return nil
		end
		
        if calculated_buffer[index] == nil then
			cacheL[index] = cacheL[index-1] 
			cacheH[index] = cacheH[index-1] 
			EMA[index] 	  = EMA[index-1] 
		end
            
		if not CandleExist(index) then
			return nil
		end

        cacheH[index] = H(index)
        cacheL[index] = L(index)
		VV[index]=V(index)
		
		if index <= math.max((Size() - bars - period - 3), period) then
			return nil
		end

		if calculated_buffer[index]~=nil then
			return calculated_buffer[index], outEMA
		end
		
		--WriteLog ("---------------------------------")
        --WriteLog ("OnCalc() ".."CandleExist("..index.."): "..tostring(CandleExist(index)).."; T("..index.."); "..isnil(toYYYYMMDDHHMMSS(T(index))," - "))
		--WriteLog ("C(index) "..tostring(C(index)))
		--WriteLog ("H(index) "..tostring(H(index)))
		--WriteLog ("L(index) "..tostring(L(index)))
        
        previous = index-period 
		
		if not CandleExist(previous) then
			previous = FindExistCandle(previous)
		end
        
		MAX = math.max(unpack(cacheH,math.max(previous+1, 1),index))
		MIN = math.min(unpack(cacheL,math.max(previous+1, 1),index))
		
		--WriteLog ("max "..tostring(MAX).." min "..tostring(MIN))
						----------------------------------------
		for i = 1, clasters do CC[i]={0, i/clasters*(MAX-MIN)+MIN} end

        local _p = index - previous

		for i = 0, _p-1 do
			if CandleExist(index-i) then
				jj=math.floor( (H(index-i)-MIN)/(MAX-MIN)*(clasters-1))+1
				kk=math.floor( (L(index-i)-MIN)/(MAX-MIN)*(clasters-1))+1
				for k=1,(jj-kk) do
					--WriteLog ("index-i "..tostring(index-i).." kk+k-1 "..tostring(kk+k-1).." jj "..tostring(jj).." kk "..tostring(kk).." CC[kk+k-1] "..tostring(CC[kk+k-1]))
					CC[kk+k-1][1]=CC[kk+k-1][1]+V(index-i)/(jj-kk)
				end
			end
		end
			--------------------
		
		--table.sort(CC, function(a,b) return a[1]>b[1] end)
		--priceMaxVol = CC[1][2]
		
		local priceMaxVol = 0
        for i = 1, clasters do 
            MAXV = math.max(MAXV, CC[i][1]) 
			if MAXV == CC[i][1] then
				priceMaxVol=CC[i][2]
			end
        end

		--minC = priceMaxVol
		--maxC = priceMaxVol
		--local sq=0.0

		--WriteLog ("MAXV*dev "..tostring(MAXV*dev))
        --WriteLog ("MAXV "..tostring(MAXV))
        --priceMaxVol = nil
		--for i = 1, clasters do
		--	WriteLog ("i "..tostring(i)..", CC[i] "..tostring(CC[i][1])..", price "..tostring(CC[i][2]))
		--	--if CC[i][1] == MAXV then priceMaxVol = i/clasters*(MAX-MIN)+MIN end
		--	
		--	--sq = sq + math.pow(CC[i]-MAXV,2)
		--	   	
		--	--if i > 2 then
		--		--if CC[i][1]>MAXV*dev and CC[i-1][1]<MAXV*dev and priceMaxVol == nil then minC = i/clasters*(MAX-MIN)+MIN end
		--		--if CC[i][1]<MAXV*dev and CC[i-1][1]>MAXV*dev and priceMaxVol~= nil then maxC = i/clasters*(MAX-MIN)+MIN end
		--		if CC[i][1]<MAXV*dev and CC[i][2] < priceMaxVol and minC == nil then minC = CC[i][2] end
		--		if CC[i][1]<MAXV*dev and CC[i][2] > priceMaxVol and maxC == nil then maxC = CC[i][2] end
		--	--end
		--end

		--sq = math.sqrt(sq/(period+1))*dev
               
		--WriteLog ("priceMaxVol "..tostring(priceMaxVol))
		--maxC = priceMaxVol + sq
		--minC = priceMaxVol - sq
		
		--WriteLog ("maxC "..tostring(maxC))
        --WriteLog ("minC "..tostring(minC))
		--WriteLog ("out2 "..tostring(out2))
		
		calculated_buffer[index] = priceMaxVol
		if showEMA == 1 then
			EMA[index]=round(kEMA*priceMaxVol+(1-kEMA)*EMA[index-1], 5)
			outEMA = EMA[index]
		end
		
		return priceMaxVol, outEMA 
		
	end
end

function WriteLog(text)

   logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n");
   logfile:flush();
   LASTLOGSTRING = text;

end;


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
