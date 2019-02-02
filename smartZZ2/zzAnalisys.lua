-- nnh Glukk Inc. nick-h@yandex.ru

--Скрипт собирающий статистику по паттернам ABCD->E
--Строится по алгоритму Зиг-Заг
--Данные выволдятся в файл


SEC_CODE           = 'SiH9'                   
CLASS_CODE         = 'SPBFUT'                   
INTERVAL           = INTERVAL_M3                   
SCALE = 2
SEC_PRICE_STEP = 1

roundStep = 10 -- шаг округления процентных отношений. 67 -> 60

DS = nil

RESULTS_FILE_NAME = getScriptPath().."\\zzAnalisys_"..SEC_CODE..'_'..INTERVAL..".csv" -- ИМЯ res-ФАЙЛА
FILE_LOG_NAME = getScriptPath().."\\zzAnalisys_.txt" -- ИМЯ ЛОГ-ФАЙЛА

resFile = nil
logFile = nil

logging = true
g_previous_time = os.time() -- помещение в переменную времени сервера в формате HHMMSS 

function main()

    resFile = getResFile(RESULTS_FILE_NAME)
    if logging then
        logFile = io.open(FILE_LOG_NAME, "w") -- открывает файл 
        
        local logFile = io.open(FILE_LOG_NAME,"r")
        if logFile == nil then
            message("Не удалость прочитать файл настроек!!!")
            return
        end
    end

    DS = CreateDataSource(CLASS_CODE,SEC_CODE,INTERVAL)
    if DS == nil then
        message('ОШИБКА получения доступа к свечам! '..Error)
        myLog('ОШИБКА получения доступа к свечам! '..Error)
        -- Завершает выполнение скрипта
        return
    end
    if DS:Size() == 0 then 
        DS:SetEmptyCallback()
    end

    SCALE = getSecurityInfo(CLASS_CODE, SEC_CODE).scale
    SEC_PRICE_STEP = getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value

    initZZ()
    Settings = {}
    Settings.Depth = 24
    Settings.deviation = 12
    Settings.Backstep = 9
    for i=1,DS:Size() do
        classicCached_ZZ(i, Settings)        
    end
    writeRes('classic')

    initZZ()
    Settings = {}
    Settings.WaitBars = 2
    Settings.deviation = 35
    Settings.gapDeviation = 70
    for i=1,DS:Size() do
        cached_ZZ(i, Settings)        
    end
    writeRes('deviation')    

end

-- Функция ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK при остановке скрипта
function OnStop()    
    if logFile~=nil then logFile:close() end    -- Закрывает файл 
    if resFile~=nil then resFile:close() end    -- Закрывает файл 
end

function getResFile(RESULTS_FILE_NAME)
    
    local resFile = io.open(RESULTS_FILE_NAME,"w")
    if resFile == nil then
        message("Не удалость прочитать файл результатов!!!")
        return nil
    end

    local firstString = "Type;SEC;INTERVAL;Up/Down;ipA;ipB;ipC;ipD;ipE;pA;pB;pC;pD;pE;iAB;iBC;iCD;iAD;iDE;AB;BC;CD;AD;DE;BC/AB;CD/AB;CD/BC;DE/CD;rBC/AB;rCD/AB;rCD/BC;rDE/CD"

    resFile:write(firstString.."\n")
    resFile:flush()

    return resFile

end

function writeRes(Type)

    local sizeOfZZLevels = #ZZLevels
    if sizeOfZZLevels<4 then return end

    for i=1,sizeOfZZLevels,3 do
        if sizeOfZZLevels-i>4 then
            writePattern(Type,i) 
        end
    end    
    for i=2,sizeOfZZLevels,3 do
        if sizeOfZZLevels-i>4 then
            writePattern(Type,i) 
        end
    end 
    for i=3,sizeOfZZLevels,3 do
        if sizeOfZZLevels-i>4 then
            writePattern(Type,i) 
        end
    end     
        
end

function writePattern(Type, i)

    local ipA = ZZLevels[i+0]["index"]
    local ipB = ZZLevels[i+1]["index"]
    local ipC = ZZLevels[i+2]["index"]
    local ipD = ZZLevels[i+3]["index"]
    local ipE = ZZLevels[i+4]["index"]
    
    local pA  = ZZLevels[i+0]["val"]
    local pB  = ZZLevels[i+1]["val"]
    local pC  = ZZLevels[i+2]["val"]
    local pD  = ZZLevels[i+3]["val"]
    local pE  = ZZLevels[i+4]["val"]
    
    local iAB = ZZLevels[i+1]["index"] - ZZLevels[i+0]["index"]
    local iBC = ZZLevels[i+2]["index"] - ZZLevels[i+1]["index"]
    local iCD = ZZLevels[i+3]["index"] - ZZLevels[i+2]["index"]
    local iAD = ZZLevels[i+3]["index"] - ZZLevels[i+0]["index"]
    local iDE = ZZLevels[i+4]["index"] - ZZLevels[i+3]["index"]

    local AB    = round(math.abs(ZZLevels[i+1]["val"] - ZZLevels[i+0]["val"]), SCALE)
    local BC    = round(math.abs(ZZLevels[i+2]["val"] - ZZLevels[i+1]["val"]), SCALE)
    local CD    = round(math.abs(ZZLevels[i+3]["val"] - ZZLevels[i+2]["val"]), SCALE)
    local AD    = round(math.abs(ZZLevels[i+3]["val"] - ZZLevels[i+0]["val"]), SCALE)
    local absDE = round(math.abs(ZZLevels[i+4]["val"] - ZZLevels[i+3]["val"]), SCALE)
    local DE    = round(ZZLevels[i+4]["val"] - ZZLevels[i+3]["val"], SCALE)

    local BCtoAB    = round(100*BC/AB, SCALE)
    local CDtoAB    = round(100*CD/AB, SCALE)
    local CDtoBC    = round(100*CD/BC, SCALE)
    local DEtoCD    = round(100*DE/CD, SCALE)
    local rBCtoAB   = round(math.floor(100*BC/AB/roundStep)*roundStep, SCALE)
    local rCDtoAB   = round(math.floor(100*CD/AB/roundStep)*roundStep, SCALE)
    local rCDtoBC   = round(math.floor(100*CD/BC/roundStep)*roundStep, SCALE)
    local roundFunc = DE>=0 and math.floor or math.ceil
    local rDEtoCD   = round(roundFunc(100*DE/CD/roundStep)*roundStep, SCALE)

    local stringLine = Type..';'..SEC_CODE..';'..INTERVAL..';'..(pA>pD and 'Down' or 'Up')..';'..
    string.gsub(tostring(ipA),'[\.]+', ',')..';'..string.gsub(tostring(ipB),'[\.]+', ',')..';'..string.gsub(tostring(ipC),'[\.]+', ',')..';'..string.gsub(tostring(ipD),'[\.]+', ',')..';'..string.gsub(tostring(ipE),'[\.]+', ',')..';'..
    string.gsub(tostring(pA),'[\.]+', ',')..';'..string.gsub(tostring(pB),'[\.]+', ',')..';'..string.gsub(tostring(pC),'[\.]+', ',')..';'..string.gsub(tostring(pD),'[\.]+', ',')..';'..string.gsub(tostring(pE),'[\.]+', ',')..';'..
    string.gsub(tostring(iAB),'[\.]+', ',')..';'..string.gsub(tostring(iBC),'[\.]+', ',')..';'..string.gsub(tostring(iCD),'[\.]+', ',')..';'..string.gsub(tostring(iAD),'[\.]+', ',')..';'..string.gsub(tostring(iDE),'[\.]+', ',')..';'..
    string.gsub(tostring(AB),'[\.]+', ',')..';'..string.gsub(tostring(BC),'[\.]+', ',')..';'..string.gsub(tostring(CD),'[\.]+', ',')..';'..string.gsub(tostring(AD),'[\.]+', ',')..';'..string.gsub(tostring(DE),'[\.]+', ',')..';'..
    string.gsub(tostring(BCtoAB),'[\.]+', ',')..';'..string.gsub(tostring(CDtoAB),'[\.]+', ',')..';'..string.gsub(tostring(CDtoBC),'[\.]+', ',')..';'..string.gsub(tostring(DEtoCD),'[\.]+', ',')..';'..
    string.gsub(tostring(rBCtoAB),'[\.]+', ',')..';'..string.gsub(tostring(rCDtoAB),'[\.]+', ',')..';'..string.gsub(tostring(rCDtoBC),'[\.]+', ',')..';'..string.gsub(tostring(rDEtoCD),'[\.]+', ',')

    resFile:write(stringLine.."\n")
    resFile:flush()

end

function initZZ()

    ZZLevels={}

    cache_ST={} -- тренд
	H_index={} -- индексы максимумов
	L_index={} -- индексы минимумов
	HiBuffer={} -- знечени¤ максимов предшествующего движени¤
	LowBuffer={} -- знечени¤ минимумов предшествующего движени¤
	UpThrust={} -- значени¤ количества свечей смены движени¤
	breakBars={} -- значени¤ экстремума свечей пробити¤ уровн¤
	breakIndex={} -- индексы свечей пробити¤ уровн¤
    Ranges={} -- знечени¤ предшествующих движений дл¤ предсказани¤
    
	CC={} -- значени¤ закрыти¤ свечей	
	CH={} -- значени¤ максимумов
	CL={} -- значени¤ минимумов	
	HighMapBuffer={} -- знечени¤ максимов предшествующего движени¤
	LowMapBuffer={} -- знечени¤ минимумов предшествующего движени¤		
	Peak={}	    
    lastlow = 0
    lasthigh = 0
    last_peak = 0
    lastindex = -1
    peak_count = 0    

end

function cached_ZZ(ind, Fsettings)
	
		local Fsettings=(Fsettings or {})
		local index = ind
		local deviation = Fsettings.deviation or 27
		local gapDeviation = Fsettings.gapDeviation or 70
		local WaitBars = Fsettings.WaitBars or 2
		
		local currentRange = 0
        index = math.max(index,1)
        
		if index == 1 then
			CH={}
			CL={}
			cache_ST={}
			CC={}
			UpThrust={}
			breakBars={}
			breakIndex={}
			
			HiBuffer={}
			LowBuffer={}

			H_index={}
			L_index={}
			ZZLevels={}
            calculated_buffer = {}
            
			Ranges={}

			CC[index]=DS:C(index)
			CH[index]=0
			CL[index]=0
			cache_ST[index]=1
			
			UpThrust[index]=0
			breakBars[index]=0
			breakIndex[index]=0
			
			HiBuffer[index]=0
			LowBuffer[index]=0
			
			H_index[index]=index
			L_index[index]=index
			
			return
		end
			
		CC[index]=CC[index-1]
					
		if CH[index] == nil then
			CH[index]=CH[index-1] 
		end
		if CL[index] == nil then
			CL[index]=CL[index-1] 
		end
		if H_index[index] == nil then
			H_index[index]=H_index[index-1] 
		end
		if L_index[index] == nil then
			L_index[index]=L_index[index-1] 
		end
		if UpThrust[index] == nil then
			UpThrust[index]=UpThrust[index-1] 
		end
		if breakBars[index] == nil then
			breakBars[index]=breakBars[index-1] 
		end
		if breakIndex[index] == nil then
			breakIndex[index]=breakIndex[index-1] 
		end
		if HiBuffer[index] == nil then
			HiBuffer[index]=HiBuffer[index-1] 
		end
		if LowBuffer[index] == nil then
			LowBuffer[index]=LowBuffer[index-1] 
		end		
		if cache_ST[index] == nil then
			cache_ST[index]=cache_ST[index-1]		
		end
		
		if DS:C(index) == nil then
			return
		end

		local isBreak=0
								
		CC[index]=DS:C(index)
		
		---------------------------------------------------------------------------------------				
		----------------------------------------------------------------------		
		
		-- расчет
		currentRange = math.abs(CH[index] - CL[index])
		
		if cache_ST[index]==1 then --растущий тренд
				
			if CH[index] <= DS:H(index) then -- новый максимум
				
				CH[index]=DS:H(index)					
				H_index[index]=index					
				
				if CL[index] == 0 then -- дл¤ первой расчетной свечи
					CL[index] = DS:L(index)
					L_index[index] = index
					LowBuffer[index] = DS:L(index)
				end	
				
				if breakBars[index] ~= 0 then
					--WriteLog ("fake break");
					breakBars[index] = 0
					breakIndex[index] = 0
					UpThrust[index] = 0
				end
				
			elseif (currentRange*deviation/100) < math.abs(CC[index] - CH[index]) then --прошли больше чем отклонение от движени¤				

				if UpThrust[index] == 0 then
					UpThrust[index] = index										
				end
				
				if breakBars[index] == 0 or (breakBars[index] ~= 0 and breakBars[index] >= DS:L(index)) then
					breakBars[index] = DS:L(index)
					breakIndex[index] = index
				end
				
				if ((index - UpThrust[index]) > WaitBars and UpThrust[index] ~= 0) or (currentRange*gapDeviation/100) < math.abs(CC[index] - CH[index]) then -- ждем закреплени¤ пробо¤
					
					--мен¤ем тренд						
					
					cache_ST[index]=0 
					
					if breakBars[index] < DS:L(index) then
						CL[index] = breakBars[index]
						L_index[index] = breakIndex[index]
					else
						CL[index] = DS:L(index)
						L_index[index] = index					
					end
					
					RegisterPeak(H_index[index], CH[index], Peak, 0, ZZLevels)			

					UpThrust[index] = 0
					breakBars[index] = 0
					breakIndex[index] = 0
					isBreak = 1
					
					HiBuffer[index] = CH[index]
					
				end
				
			elseif breakBars[index] ~= 0 and breakBars[index] >= DS:L(index) then						
				breakBars[index] = DS:L(index)
				breakIndex[index] = index
			end
									
		
		elseif cache_ST[index]==0 then --падающий тренд
															
			if CL[index] >= DS:L(index) then -- новый минимум
				
				CL[index]=DS:L(index)
				L_index[index]=index						
				
				if breakBars[index] ~= 0 then
					breakBars[index] = 0
					breakIndex[index] = 0
					UpThrust[index] = 0
				end
				
			elseif (currentRange*deviation/100) < math.abs(CC[index] - CL[index]) then --прошли больше чем отклонение от движени¤
				
				if UpThrust[index] == 0 then
					UpThrust[index] = index										
				end
				
				if breakBars[index] == 0 or (breakBars[index] ~= 0 and breakBars[index] <= DS:H(index)) then
					breakBars[index] = DS:H(index)
					breakIndex[index] = index
				end
					
				if ((index - UpThrust[index]) > WaitBars and UpThrust[index] ~= 0) or (currentRange*gapDeviation/100) < math.abs(CC[index] - CH[index]) then -- ждем закреплени¤ пробо¤
				--мен¤ем тренд			
				
					cache_ST[index]=1 
					if breakBars[index] > DS:L(index) then
						CH[index] = breakBars[index]
						H_index[index] = breakIndex[index]
					else
						CH[index] = DS:H(index)
						H_index[index] = index					
					end

                    RegisterPeak(L_index[index], CL[index], Peak, 0, ZZLevels)			
														
					breakBars[index] = 0
					breakIndex[index] = 0
					UpThrust[index] = 0
					isBreak = 1
					
					LowBuffer[index] = CL[index]
				end
				
			elseif breakBars[index] ~= 0 and breakBars[index] <= DS:H(index) then					
				breakBars[index] = DS:H(index)
				breakIndex[index] = index				
			end
						
		end			

end

function classicCached_ZZ(ind, Fsettings)
			
		local Fsettings=(Fsettings or {})
		local index = ind
        
        local Depth = Fsettings.Depth or 12
		local deviation = Fsettings.deviation or 5
		local Backstep = Fsettings.Backstep or 3
		local endIndex = Fsettings.endIndex or DS:Size()
		        
        local searchBoth = 0;
        local searchPeak = 1;
        local searchLawn = -1;

		if index == 1 then
			CC={}
			CH={}
			CL={}

			Peak={}
			
			HighMapBuffer={}
			LowMapBuffer={}

			ZZLevels={}
			------------------
			CC[index]=0
			CH[index]=0
			CL[index]=0
			
			Peak[index]=nil
			
			HighMapBuffer[index]=0
			LowMapBuffer[index]=0
			
            lastindex = -1;		
            lastlow = 0;
            lasthigh = 0;
            last_peak = 0;
            peak_count = 0;        

			return nil
		end
			
		CC[index]=CC[index-1]					
		CH[index]=CH[index-1] 
        CL[index]=CL[index-1]
    		
		if index < Depth or DS:C(index) == nil then
            HighMapBuffer[index]=HighMapBuffer[index-1]
            LowMapBuffer[index]=LowMapBuffer[index-1]       
		    Peak[index]=nil
			return Peak[index]
		end

        CC[index]=DS:C(index)
		CH[index]=DS:H(index) 
		CL[index]=DS:L(index) 
        
		if index < endIndex then
            HighMapBuffer[index]=HighMapBuffer[index-1]
            LowMapBuffer[index]=LowMapBuffer[index-1]       
		    Peak[index]=nil
			return Peak[index]
		end
        
        local sizeOfZZLevels = #ZZLevels
        local searchMode = searchBoth;
                        
            lastindex = index
            
            HighMapBuffer[index]=0 
            LowMapBuffer[index]=0        
		    Peak[index]=nil
            
            
            local start;
            local last_peak;
            local last_peak_i;
            
            start = Depth;
            
            i = GetPeak(index, -3, Peak, ZZLevels);
            
            if i == -1 then
                last_peak_i = 0;
                last_peak = 0;
            else
                last_peak_i = i;
                last_peak = Peak[i];
                start = i;
            end
            
            for i = start, index, 1 do
                Peak[i]=nil;
                LowMapBuffer[i]=0.0;
                HighMapBuffer[i]=0.0;
            end
            
            searchMode = searchBoth;
            if LowMapBuffer[start]~=0 then
                searchMode = searchPeak
            elseif HighMapBuffer[start]~=0 then
                searchMode = searchLawn
            end        
            
            for i = start, index-1, 1 do
                
                -- fill high/low maps
                local range = i - Depth + 1;
                local val;
                
                -- get the lowest low for the last depth is
                val = math.min(unpack(CL, range, i));
                if val == lastlow then
                    -- if lowest low is not changed - ignore it
                    val = nil;
                else
                    -- keep it
                    lastlow = val;
                    -- if current low is higher for more than Deviation pips, ignore
                    if (CL[i] - val) > (SEC_PRICE_STEP * deviation) then
                        val = nil;
                    else
                        -- check for the previous backstep lows
                        for k = i - 1, i - Backstep + 1, -1 do
                            if (LowMapBuffer[k] ~= 0) and (LowMapBuffer[k] > val) then
                                LowMapBuffer[k] = 0;
                            end
                        end
                    end
                end
                if CL[i] == val then
                    LowMapBuffer[i] = val;
                else
                    LowMapBuffer[i] = 0;
                end
                
                -- get the highest high for the last depth is
                val = math.max(unpack(CH, range, i));
                if val == lasthigh then
                    -- if lowest low is not changed - ignore it
                    val = nil;
                else
                    -- keep it
                    lasthigh = val;
                    -- if current low is higher for more than Deviation pips, ignore
                    if (val - CH[i]) > (SEC_PRICE_STEP * deviation) then
                        val = nil;
                    else
                        -- check for the previous backstep lows
                        for k = i - 1, i - Backstep + 1, -1 do
                            if (HighMapBuffer[k] ~= 0) and (HighMapBuffer[k] < val) then
                                HighMapBuffer[k] = 0;
                            end
                        end
                    end
                end
                
                if CH[i] == val then
                    HighMapBuffer[i] = val;
                else
                    HighMapBuffer[i] = 0
                end
                
            end
                        
            peak_count = 0
            if start ~= Depth then
                peak_count = - 3;
            end
                        
            for i = start, index-1, 1 do
                
                sizeOfZZLevels = #ZZLevels
                
                if searchMode == searchBoth then
                    if (HighMapBuffer[i] ~= 0) then
                        last_peak_i = i;
                        last_peak = CH[i]
                        searchMode = searchLawn;
                        LowMapBuffer[i] = 0
                        peak_count = RegisterPeak(i, last_peak, Peak, peak_count, ZZLevels);
                    elseif (LowMapBuffer[i] ~= 0) then
                        last_peak_i = i;
                        last_peak = CL[i] --owBuffer[i];
                        searchMode = searchPeak;
                        peak_count = RegisterPeak(i, last_peak, Peak, peak_count, ZZLevels);
                    end
                elseif searchMode == searchPeak then
                    if (LowMapBuffer[i] ~= 0 and LowMapBuffer[i] < last_peak and HighMapBuffer[i] == 0) then
                        Peak[last_peak_i] = nil
                        last_peak = LowMapBuffer[i];
                        last_peak_i = i;
                        ReplaceLastPeak(i, last_peak, Peak, peak_count, ZZLevels);
                    end
                    if HighMapBuffer[i] ~= 0 and LowMapBuffer[i] == 0 then
                        last_peak = HighMapBuffer[i];
                        last_peak_i = i;
                        searchMode = searchLawn;
                        peak_count = RegisterPeak(i, last_peak, Peak, peak_count, ZZLevels);
                    end
                elseif searchMode == searchLawn then
                    if (HighMapBuffer[i] ~= 0 and HighMapBuffer[i] > last_peak and LowMapBuffer[i] == 0) then
                        Peak[last_peak_i] = nil
                        last_peak = HighMapBuffer[i];
                        last_peak_i = i;
                        ReplaceLastPeak(i, last_peak, Peak, peak_count, ZZLevels);
                    end
                    if LowMapBuffer[i] ~= 0 and HighMapBuffer[i] == 0 then
                        last_peak = LowMapBuffer[i];
                        last_peak_i = i;
                        searchMode = searchPeak;
                        peak_count = RegisterPeak(i, last_peak, Peak, peak_count, ZZLevels);
                    end
                end
            end
                                    
end
            
function RegisterPeak(index, val, Peak, peak_count, ZZLevels)
    
    peak_count = peak_count + 1;
    Peak[index] = val;

	local sizeOfZZLevels = #ZZLevels + 1
    if peak_count <= 0 and #ZZLevels > 0 then
        ZZLevels[#ZZLevels+peak_count]["val"] = val
        ZZLevels[#ZZLevels+peak_count]["index"] = index
    else        
        ZZLevels[sizeOfZZLevels] = {}                    			
        ZZLevels[sizeOfZZLevels]["val"]   = val
        ZZLevels[sizeOfZZLevels]["index"] = index
    end

    myLog('sizeOfZZLevels: '..tostring(sizeOfZZLevels)..', val: '..tostring(ZZLevels[sizeOfZZLevels]["val"])..', index: '..tostring(ZZLevels[sizeOfZZLevels]["index"]))
    return peak_count

end

function ReplaceLastPeak(index, val, Peak, peak_count, ZZLevels)
    Peak[index] = val;

    local sizeOfZZLevels = #ZZLevels
    if peak_count <= 0 and #ZZLevels > 0 then
        ZZLevels[#ZZLevels+peak_count]["val"] = val
		ZZLevels[#ZZLevels+peak_count]["index"] = index
	else	
		ZZLevels[sizeOfZZLevels]["val"]   = val
		ZZLevels[sizeOfZZLevels]["index"] = index
	end

end

function GetPeak(index, offset, Peak, ZZLevels)

    local counterZ = 0
    for i=index,1, -1 do
        if Peak[i]~=nil then
            counterZ = counterZ + 1
            if counterZ == 3 then
                return i
            end
        end
    end

    return -1;
    
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
end

-- функция записывает в лог строчку с временем и датой 
function myLog(str)
    if not logging or logFile==nil then return end

    local current_time=os.time()--tonumber(timeformat(getInfoParam("SERVERTIME"))) -- помещене в переменную времени сервера в формате HHMMSS 
    if (current_time-g_previous_time)>1 then -- если текущая запись произошла позже 1 секунды, чем предыдущая
        logFile:write("\n") -- добавляем пустую строку для удобства чтения
    end
    g_previous_time = current_time 

    logFile:write(os.date().."; ".. str .. ";\n")

    if str:find("Script Stoped") ~= nil then 
        logFile:write("======================================================================================================================\n\n")
        logFile:write("======================================================================================================================\n")
    end
    logFile:flush() -- Сохраняет изменения в файле
end

function dValue(i,param)
    local v = param or "ATR"
        
        if DS:C(i) == nil then
            return nil
        end
        
        if  v == "O" then
            return DS:O(i)
        elseif   v == "H" then
            return DS:H(i)
        elseif   v == "L" then
            return DS:L(i)
        elseif   v == "C" then
            return DS:C(i)
        elseif   v == "V" then
            return DS:V(i)
        elseif   v == "M" then
            return (DS:H(i) + DS:L(i))/2
        elseif   v == "T" then
            return (DS:H(i) + DS:L(i)+DS:C(i))/3
        elseif   v == "W" then
            return (DS:H(i) + DS:L(i)+2*DS:C(i))/4
        elseif   v == "ATR" then
            local previous = math.max(i-1, 1)
                
            if DS:C(i) == nil then
                previous = FindExistCandle(previous)
            end
            if previous == 0 then
                return nil
            end
        
            return math.max(math.abs(DS:H(i) - DS:L(i)), math.abs(DS:H(i) - DS:C(previous)), math.abs(DS:C(previous) - DS:L(i)))
        else
            return DS:C(i)
        end 
end

function round(num, idp)
    if idp and num then
    local mult = 10^(idp or 0)
    if num >= 0 then return math.floor(num * mult + 0.5) / mult
    else return math.ceil(num * mult - 0.5) / mult end
    else return num end
end

function findFirstEmptyCandle(DS)
    
    index = DS:Size()
    while index > 1 and DS:C(index) ~= nil do
        index = index - 1
    end

    return index
end

function FindExistCandle(I)

    local out = I
    while DS:C(out) == nil and out > 0 do
        out = out -1
    end	
    return out

end
