--logfile=io.open("C:\\SBERBANK\\QUIK_SMS\\LuaIndicators\\timeDelta.txt", "w")

require("StaticVar")

SEC_CODE = "";
CLASS_CODE = ""; 
DSInfo = nil;
Vol_Coeff = 1;
interval = 0

startTrade = 1000
endTrade = 2345

Settings =
 {
     Name = "*timeDelta",
	 showVolume=0,
	 inverse = 1,
	 showdelta=1,
	 delta_koeff = 1,
	 ChartId = "Sheet11",
	 line =
     {
         {
          Name = "Sell",
          Color = RGB(255,128,128),
          Type = TYPE_HISTOGRAM,
          Width =3
         },
         {
          Name = "Buy",
          Color = RGB(120,220,135),
          Type = TYPE_HISTOGRAM,
          Width = 3
         },
		 {
          Name = "Delta",
          Color = RGB(0,0,0),
          Type = TYPE_LINE,
          Width = 1
         },
		 {
          Name = "Volume",
          Color = RGB(0,128, 255),
          Type = TYPE_HISTOGRAM,
          Width = 3
         }
     }
 }

-- ѕользовательcкие функции
function WriteLog(text)
   logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n");
   logfile:flush();
   LASTLOGSTRING = text;
end;

function OnDestroy()
  --logfile:close() -- Закрывает файл 
end

function toYYYYMMDDHHMMSS(datetime)
    if type(datetime) ~= "table" then
       return ""
    else
       local Res = tostring(datetime.year)
       if #Res == 1 then Res = "000"..Res end
       Res = Res.."."
       local month = tostring(datetime.month)
       if #month == 1 then Res = Res.."0"..month else Res = Res..month end
       Res = Res.."."
       local day = tostring(datetime.day)
       if #day == 1 then Res = Res.."0"..day else Res = Res..day end
       Res = Res.." "
       local hour = tostring(datetime.hour)
       if #hour == 1 then Res = Res.."0"..hour else Res = Res..hour end
       Res = Res..":"
       local minute = tostring(datetime.min)
       if #minute == 1 then Res = Res.."0"..minute else Res = Res..minute end
       Res = Res..":"
       local sec = tostring(datetime.sec);
       if #sec == 1 then Res = Res.."0"..sec else Res = Res..sec end
       return Res
    end
end

function isnil(a,b)
   if a == nil then
      return b
   else
      return a
   end;
end;
----------------------------------------------------------

function Init()
	myVol = Vol()
	return #Settings.line
end
 
function OnCalculate(index)
    
	if index == 1 then
		DSInfo = getDataSourceInfo()     	
		SEC_CODE = DSInfo.sec_code
		CLASS_CODE = DSInfo.class_code
		Vol_Coeff = getLotSizeBySecCode(DSInfo.sec_code)
		interval = DSInfo.interval
		stv.UseNameSpace(Settings.ChartId)
	end
          
   return myVol(index, Settings)
end
 
function getLotSizeBySecCode(sec_code)
   local status = getParamEx("TQBR", sec_code, "lotsize"); -- Ѕеру размер лота дл¤ кода класса "TQBR"
   return math.ceil(status.param_value);                   -- ќтбрасываю ноли после зап¤той
end;
 
function Vol()
		
	local cache_VolBid={}
	local cache_VolAsk={}
	local Delta={}
	
	return function(index, Fsettings, ds)
				
		local Fsettings=(Fsettings or {})
		local showdelta = (Fsettings.showdelta or 0)
		local showVolume = (Fsettings.showVolume or 0)
		local inverse = (Fsettings.inverse or 0)
		local delta_koeff = (Fsettings.delta_koeff or 0)

		local outVol = nil

		if index == 1 then
			cache_VolBid={}
			cache_VolAsk={}			
			Delta={}			
			Delta[1] = 0		
			cache_VolAsk[1]= 0
			cache_VolBid[1]= 0
		end
		
		Delta[index] = 0		
		cache_VolAsk[index]= 0
		cache_VolBid[index]= 0

		--WriteLog ("------------------------------------------------------------")
		--WriteLog ("OnCalc() ".."CandleExist("..index.."): "..tostring(CandleExist(index)).."; T("..index.."); "..isnil(toYYYYMMDDHHMMSS(T(index))," - "));
		--WriteLog ("Delta[index] "..tostring(Delta[index]).." Delta[index-1] "..tostring(Delta[index-1]))
		
		if not CandleExist(index) then
			return nil
		end
		
		local dayIndex = (T(index).year*10000+T(index).month*100+T(index).day)*10000
		local hourIndex = (T(index).hour)*100
		local minIndex = T(index).min
		local endIndex = (T(Size()).hour)*100+(T(Size()).min+interval)
		
		if index ~= Size() then
			endIndex = (T(index+1).hour)*100+(T(index+1).min)
		end
		
		--WriteLog ("dayIndex "..tostring(dayIndex).." timeIndex "..tostring(hourIndex+minIndex).." endIndex "..tostring(endIndex))

		local algoResults = stv.GetVar('timeDelta')
        --WriteLog("ChartId "..tostring(Fsettings.ChartId).." algoResults "..tostring(algoResults).."  "..tostring(type(algoResults)))
		local stopCount = false

		if type(algoResults) == 'table' then
			if algoResults[dayIndex]~=nil then
				while not stopCount do
					--WriteLog (" --- timeIndex "..tostring(hourIndex+minIndex))
					if algoResults[dayIndex+hourIndex+minIndex]~=nil then
						cache_VolBid[index] = cache_VolBid[index] + algoResults[dayIndex+hourIndex+minIndex].buyVol	
						if inverse == 0 then
							cache_VolAsk[index] = cache_VolAsk[index] + algoResults[dayIndex+hourIndex+minIndex].sellVol
						else
							cache_VolAsk[index] = cache_VolAsk[index] - algoResults[dayIndex+hourIndex+minIndex].sellVol
						end
					end
					minIndex = minIndex + 1
					if minIndex == 60 then
						minIndex = 0
						hourIndex = hourIndex+100
					end
					if hourIndex+minIndex >= endIndex or (hourIndex+minIndex == 2400) then
						stopCount = true
					end	
				end
			end
		end
	
		local localDelta = 0
		
		if inverse == 0 then
			localDelta = cache_VolBid[index]-cache_VolAsk[index]
		else
			localDelta = cache_VolBid[index]+cache_VolAsk[index]
		end

		--WriteLog ("localDelta "..tostring(localDelta).." delta_koeff "..tostring(delta_koeff))
		--WriteLog ("cache_VolAsk "..tostring(cache_VolAsk[index]).." cache_VolBid "..tostring(cache_VolBid[index]))

		local previous = index-1		
        if not CandleExist(previous) then
            previous = FindExistCandle(previous)
		end	
					
		if index > 1 and previous > 0 then
			Delta[index] = localDelta*delta_koeff + Delta[index-1]
		else
			Delta[index] = localDelta*delta_koeff		
		end	
		
		if showVolume == 1 then
			outVol = V(index)
		end
		
		if showdelta == 0 then
			return cache_VolAsk[index], cache_VolBid[index], nil, outVol
		else
			return cache_VolAsk[index], cache_VolBid[index], Delta[index], outVol
		end
		
			
	end
end

function FindExistCandle(I)

	local out = I	
	while not CandleExist(out) and out > 0 do
		out = out-1
	end		
	return out
 
end
