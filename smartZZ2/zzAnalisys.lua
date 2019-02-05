-- nnh Glukk Inc. nick-h@yandex.ru

--Скрипт собирающий статистику по паттернам ABCD->E
--Строится по алгоритму Зиг-Заг
--Данные выводятся в файл


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

logging = false
g_previous_time = os.time() -- помещение в переменную времени сервера в формате HHMMSS 


-- Алгоритм: проверка размера волн и корректировка по следующим от- |
-- ношениям "Идеальных пропорций" ("Золотое сечение" версия 1):     |
-- (в терминах XABCD точки равны: A = X, B = A, C = B, D = B, E = D)|
--   №    (D-E)/(D-C)   "ЗС версия1" №  (E-D)/(C-D)   "ЗС версия1"  |
--   M1    2             1.618       W1  0.3334        0.3819       |
--   M2    0.5           0.5         W2  0.6667        0.618        |
--   M3    1.5           1.2720      W3  1.5           1.2720       |
--   M4    0.6667	     0.618       W4  0.5           0.5          |
--   M5    1.3334        1.2720      W5  2             1.618        |
--   M6    0.75          0.618       W6  0.25          0.25         |
--   M7    3             3.0000      W7  0.5           0.5          |
--   M8    0.3334        0.3819      W8  2             1.618        |
--   M9    2             1.618       W9  0.3334        0.3819       |
--   M10   0.5           0.5         W10 3             3.0000       |
--   M11   0.25          0.25        W11 0.75          0.618        |
--   M12   2             1.618       W12 1.3334        1.2720       |
--   M13   0.5           0.5         W13 0.6667        0.618        |
--   M14   1.5           1.2720      W14 1.5           1.2720       |
--   M15   0.6667        0.618       W15 0.5           0.5          |
--   M16   0.3334        0.3819      W16 2             1.618        |

NamePattern =
  {
   ERROR     = 2,
   NOPATTERN = 3,
   W15       = 8,
   W16       = 12,
   M8        = 64,
   M4        = 80,
   M3        = 112,
   W9        = 512,
   W13       = 640,
   W14       = 896,
   M13       = 4096,
   M12       = 5120,
   M7        = 7168,
   W4        = 32768,
   W5        = 40960,
   W10       = 57344,
   M11       = 262144,
   M10       = 327680,
   M5        = 393216,
   M6        = 458752,
   M16       = 2097152,
   M15       = 2621440,
   M14       = 3145728,
   M9        = 3670016,
   W1        = 16777216,
   W2        = 20971520,
   W3        = 25165824,
   W8        = 29360128,
   W6        = 134217728,
   W7        = 167772160,
   W11       = 201326592,
   W12       = 234881024,
   M1        = 536870912,
   M2        = 805306368
}

pattern = NamePattern.NOPATTERN
IsPointNotReal = false
oldPattern = pattern
patternName = 'NOPATTERN'

targetE = 0 -- точка Е
evE = 0 -- точка эволюции
mutE = 0 -- точка мутации

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
    Settings.deviation = 11
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

	local firstString = "Type;SEC;INTERVAL;Up/Down;ipA;ipB;ipC;ipD;ipD ABeqCD;ipE;"..
						"indCoG;valCoG;dA-Cog;dCog-D;"..
						"iAB;iBC;iCD;iAD;iDE;"..
						"pA;pB;pC;pD;pD_ABeqCD;real_E (pB);"..
						"pattern;target_E;%err_E;evolution_E;%err_ev_E;mutation_E (pC);%err_mut_E;"..
						"AB;BC;CD;AD;DE;BC/AB;CD/AB;BC/CD;DE/CD;rBC/AB;rCD/AB;rBC/CD;rDE/CD"

    resFile:write(firstString.."\n")
    resFile:flush()

    return resFile

end

function writeRes(Type)

    local sizeOfZZLevels = #ZZLevels
    if sizeOfZZLevels<4 then return end

    --for i=1,sizeOfZZLevels do
    --    myLog('i: '..tostring(i)..', val: '..tostring(ZZLevels[i]["val"])..', index: '..tostring(ZZLevels[i]["index"]))
    --end    

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

function toExcelNum(number) return string.gsub(tostring(number),'[\.]+', ',') end

function writePattern(Type, i)

    local ipA 	= ZZLevels[i+0]["index"]
    local ipB 	= ZZLevels[i+1]["index"]
    local ipC 	= ZZLevels[i+2]["index"]
    local ipD 	= ZZLevels[i+3]["index"]
    local ipE 	= ZZLevels[i+4]["index"]
	
    local pA  	= ZZLevels[i+0]["val"]
    local pB  	= ZZLevels[i+1]["val"]
    local pC  	= ZZLevels[i+2]["val"]
    local pD  	= ZZLevels[i+3]["val"]
    local pE  	= ZZLevels[i+4]["val"]
	
    local iAB 	= ZZLevels[i+1]["index"] - ZZLevels[i+0]["index"]
    local iBC 	= ZZLevels[i+2]["index"] - ZZLevels[i+1]["index"]
    local iCD 	= ZZLevels[i+3]["index"] - ZZLevels[i+2]["index"]
    local iAD 	= ZZLevels[i+3]["index"] - ZZLevels[i+0]["index"]
    local iDE 	= ZZLevels[i+4]["index"] - ZZLevels[i+3]["index"]

    local AB    = round(math.abs(ZZLevels[i+1]["val"] - ZZLevels[i+0]["val"]), SCALE)
    local BC    = round(math.abs(ZZLevels[i+2]["val"] - ZZLevels[i+1]["val"]), SCALE)
    local CD    = round(math.abs(ZZLevels[i+3]["val"] - ZZLevels[i+2]["val"]), SCALE)
    local AD    = round(math.abs(ZZLevels[i+3]["val"] - ZZLevels[i+0]["val"]), SCALE)
    local absDE = round(math.abs(ZZLevels[i+4]["val"] - ZZLevels[i+3]["val"]), SCALE)
    local DE    = round(ZZLevels[i+4]["val"] - ZZLevels[i+3]["val"], SCALE)

    local ipD_ABeqCD  	= ZZLevels[i+2]["index"]+iAB
    local pD_ABeqCD  	= round(ZZLevels[i+2]["val"]+(ZZLevels[i+1]["val"] - ZZLevels[i+0]["val"]), SCALE)
	local indCoG 		= math.floor((ipA+ipD)/2)
	local valCoG 		= math.floor((pA+pD)/2)
	local dACog  		= indCoG - ipA
	local dCogD	 		= ipD - indCoG

    -- Prediction
    targetE = 0
    evE = nil
    mutE = nil   

    local pDE = pD + DE/2
    getPattern(pA, pB, pC, pD, pDE)
    if targetE ~= 0 then
        CalcPrognozPoint(pA,pB,pC,pD,targetE)        
        if targetE == pDE then targetE = 0 end
    end

    targetE = round(targetE or 0, SCALE)
    err_targetE = targetE == 0 and 0 or round(math.abs(targetE - pE)*100/absDE, 2)
    evE     = round(evE or 0, SCALE)
    err_evE = evE == 0 and 0 or round(math.abs(evE - pE)*100/absDE, 2)
    mutE    = round(mutE or 0, SCALE)
    local next_pB = ZZLevels[i+5] == nil and 0 or ZZLevels[i+5]["val"]
    err_mutE = (next_pB == 0 or mutE == 0) and 0 or round(math.abs(mutE - next_pB)*100/(round(math.abs(ZZLevels[i+5]["val"] - ZZLevels[i+4]["val"]), SCALE)), 2)

    local BCtoAB    = round(BC/AB, 3)
    local CDtoAB    = round(CD/AB, 3)
    local BCtoCD    = round(BC/CD, 3)
    local DEtoCD    = round(DE/CD, 3)
    local rBCtoAB   = round(math.floor(100*BC/AB/roundStep)*roundStep, 3)
    local rCDtoAB   = round(math.floor(100*CD/AB/roundStep)*roundStep, 3)
    local rBCtoCD   = round(math.floor(100*BC/CD/roundStep)*roundStep, 3)
    local roundFunc = DE>=0 and math.floor or math.ceil
    local rDEtoCD   = round(roundFunc(100*DE/CD/roundStep)*roundStep, 3)

    local stringLine = Type..';'..SEC_CODE..';'..INTERVAL..';'..(pA>pD and 'Down' or 'Up')..';'..
    toExcelNum(ipA)..';'..toExcelNum(ipB)..';'..toExcelNum(ipC)..';'..toExcelNum(ipD)..';'..toExcelNum(ipD_ABeqCD)..';'..toExcelNum(ipE)..';'..
    toExcelNum(indCoG)..';'..toExcelNum(valCoG)..';'..toExcelNum(dACog)..';'..toExcelNum(dCogD)..';'..
    toExcelNum(iAB)..';'..toExcelNum(iBC)..';'..toExcelNum(iCD)..';'..toExcelNum(iAD)..';'..toExcelNum(iDE)..';'..
    toExcelNum(pA)..';'..toExcelNum(pB)..';'..toExcelNum(pC)..';'..toExcelNum(pD)..';'..toExcelNum(pD_ABeqCD)..';'..toExcelNum(pE)..';'..
    patternName..';'..toExcelNum(targetE)..';'..toExcelNum(err_targetE)..';'..toExcelNum(evE)..';'..toExcelNum(err_evE)..';'..toExcelNum(mutE)..';'..toExcelNum(err_mutE)..';'..
    toExcelNum(AB)..';'..toExcelNum(BC)..';'..toExcelNum(CD)..';'..toExcelNum(AD)..';'..toExcelNum(DE)..';'..
    toExcelNum(BCtoAB)..';'..toExcelNum(CDtoAB)..';'..toExcelNum(BCtoCD)..';'..toExcelNum(DEtoCD)..';'..
    toExcelNum(rBCtoAB)..';'..toExcelNum(rCDtoAB)..';'..toExcelNum(rBCtoCD)..';'..toExcelNum(rDEtoCD)

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

-- Prediction
function getPattern(pA, pB, pC, pD, pE)
	
	--- Первичный сброс флага
	IsPointNotReal = false;
	--- Сохраняем старый паттерн
	oldPattern = pattern;
 
	if (pB>pA and pA>pD and pD>pC and pC>pE)	then
		pattern = NamePattern.M1;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M1'
		return(pattern);
	end
	--- M2
	if (pB>pA and pA>pD and pD>pE and pE>pC) then
		pattern = NamePattern.M2;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M2'
		return(pattern);
	end
	--- M3
	if (pB>pD and pD>pA and pA>pC and pC>pE) then
		pattern = NamePattern.M3;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M3'
		return(pattern);
	end
	--- M4
	if (pB>pD and pD>pA and pA>pE and pE>pC) then
		pattern = NamePattern.M4;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M4'
		return(pattern);
	end
	--- M5
	if (pD>pB and pB>pA and pA>pC and pC>pE) then
		pattern = NamePattern.M5;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M5'
		return(pattern);
	end
	--- M6
	if (pD>pB and pB>pA and pA>pE and pE>pC) then
		pattern = NamePattern.M6;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M6'
		return(pattern);
	end
	--- M7
	if (pB>pD and pD>pC and pC>pA and pA>pE) then
		pattern = NamePattern.M7;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M7'
		return(pattern);
	end
	--- M8
	if (pB>pD and pD>pE and pE>pA and pA>pC) then
		pattern = NamePattern.M8;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M8'
		return(pattern);
	end
	--- M9
	if (pD>pB and pB>pC and pC>pA and pA>pE) then
		pattern = NamePattern.M9;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M9'
		return(pattern);
	end
	--- M10
	if (pD>pB and pB>pE and pE>pA and pA>pC) then
		pattern = NamePattern.M10;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M10'
		return(pattern);
	end
	--- M11
	if (pD>pE and pE>pB and pB>pA and pA>pC) then
		pattern = NamePattern.M11;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M11'
		return(pattern);
	end
	--- M12
	if (pB>pD and pD>pC and pC>pE and pE>pA) then
		pattern = NamePattern.M12;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M12'
		return(pattern);
	end
	--- M13
	if (pB>pD and pD>pE and pE>pC and pC>pA) then
		pattern = NamePattern.M13;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M13'
		return(pattern);
	end
	--- M14
	if (pD>pB and pB>pC and pC>pE and pE>pA) then
		pattern = NamePattern.M14;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M14'
		return(pattern);
	end
	--- M15
	if (pD>pB and pB>pE and pE>pC and pC>pA) then
		pattern = NamePattern.M15;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M15'
		return(pattern);
	end
	--- M16
	if (pD>pE and pE>pB and pB>pC and pC>pA) then
		pattern = NamePattern.M16;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M16'
		return(pattern);
	end
	--- W1
	if (pA>pC and pC>pB and pB>pE and pE>pD) then
		pattern = NamePattern.W1;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
        patternName = 'M17'
		return(pattern);	
	end
	--- W2
	if (pA>pC and pC>pE and pE>pB and pB>pD) then
		pattern = NamePattern.W2;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
        patternName = 'W2'
		return(pattern);	
	end
	--- W3
	if (pA>pE and pE>pC and pC>pB and pB>pD) then
		pattern = NamePattern.W3;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
        patternName = 'W3'
		return(pattern);	
	end
	--- W4
	if (pA>pC and pC>pE and pE>pD and pD>pB) then
		pattern = NamePattern.W4;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
        patternName = 'W4'
		return(pattern);	
	end
	--- W5
	if (pA>pE and pE>pC and pC>pD and pD>pB) then
		pattern = NamePattern.W5;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
        patternName = 'W5'
		return(pattern);	
	end
	--- W6
	if (pC>pA and pA>pB and pB>pE and pE>pD) then
		pattern = NamePattern.W6;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
        patternName = 'W6'
		return(pattern);	
	end
	--- W7
	if (pC>pA and pA>pE and pE>pB and pB>pD) then
		pattern = NamePattern.W7;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
        patternName = 'W7'
		return(pattern);	
	end
	--- W8
	if (pE>pA and pA>pC and pC>pB and pB>pD) then
		pattern = NamePattern.W8;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
        patternName = 'W8'
		return(pattern);	
	end
	--- W9
	if (pC>pA and pA>pE and pE>pD and pD>pB) then
		pattern = NamePattern.W9;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
        patternName = 'W9'
		return(pattern);	
	end
	--- W10
	if (pE>pA and pA>pC and pC>pD and pD>pB) then
		pattern = NamePattern.W10;
        patternName = 'W10'
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- W11
	if (pC>pE and pE>pA and pA>pB and pB>pD) then
		pattern = NamePattern.W11;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W11'
		return(pattern);
	end
	--- W12
	if (pE>pC and pC>pA and pA>pB and pB>pD) then
		pattern = NamePattern.W12;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W12'
		return(pattern);
	end
	--- W13
	if (pC>pE and pE>pA and pA>pD and pD>pB) then
		pattern = NamePattern.W13;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W13'
		return(pattern);
	end
	--- W14
	if (pE>pC and pC>pA and pA>pD and pD>pB) then
		pattern = NamePattern.W14;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W14'
		return(pattern);
	end
	--- W15
	if (pC>pE and pE>pD and pD>pA and pA>pB) then
		pattern = NamePattern.W15;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W15'
		return(pattern);
	end
	--- W16
	if (pE>pC and pC>pD and pD>pA and pA>pB) then
		pattern = NamePattern.W16;
        AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W16'
		return(pattern);
	end
	
	--- NOPATTERN
    pattern = NamePattern.NOPATTERN;
    patternName = 'NOPATTERN'
	return(pattern);
	
end

function AnalysisPointE(pA,pB,pC,pD,pE)

	--- Контрольный сброс флага
	IsPointNotReal = false;
	--WriteLog ("Pattern "..tostring(pattern))

	 --- 1. Если паттерн определен то можно анализировать/корректировать значение E
	if ((pattern ~= NamePattern.NOPATTERN) and (pattern ~= NamePattern.ERROR))
	  then
	   if (pattern == NamePattern.M1)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.618)
			then
			 pE = round(pD - 1.618 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M2)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.5)
			then
			 pE = round(pD - 0.5 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M3)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.2720)
			then
			 pE = round(pD - 1.2720 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M4)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.618)
			then
			 pE = round(pD - 0.618 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M5)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.2720)
			then
			 pE = round(pD - 1.2720 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M6)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.618)
			then
			 pE = round(pD - 0.618 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M7)
		 then
		  if (((pD-pE)/(pD-pC)) < 3.0000)
			then
			 pE = round(pD - 3.0000 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M8)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.3819)
			then
			 pE = round(pD - 0.3819 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M9)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.618)
			then
			 pE = round(pD - 1.618 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M10)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.5)
			then
			 pE = round(pD - 0.5 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M11)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.25)
			then
			 pE = round(pD - 0.25 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M12)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.618)
			then
			 pE = round(pD - 1.618 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M13)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.5)
			then
			 pE = round(pD - 0.5 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M14)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.2720)
			then
			 pE = round(pD - 1.2720 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M15)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.618)
			then
			 pE = round(pD - 0.618 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M16)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.3819)
			then
			 pE = round(pD - 0.3819 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W1)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.3819)
			then
			 pE = round(0.3819 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W2)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.618)
			then
			 pE = round(0.618 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W3)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.2720)
			then
			 pE = round(1.2720 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W4)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.5)
			then
			 pE = round(0.5 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W5)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.618)
			then
			 pE = round(1.618 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W6)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.25)
			then
			 pE = round(0.25 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W7)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.5)
			then
			 pE = round(0.5 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W8)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.618)
			then
			 pE = round(1.618 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W9)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.3819)
			then
			 pE = round(0.3819 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W10)
		 then
		  if (((pE-pD)/(pC-pD)) < 3.0000)
			then
			 pE = round(3.0000 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W11)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.618)
			then
			 pE = round(0.618 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W12)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.2720)
			then
			 pE = round(1.2720 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W13)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.618)
			then
			 pE = round(0.618 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	  if (pattern == NamePattern.W14)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.2720)
			then
			 pE = round(1.2720 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W15)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.5)
			then
			 pE = round(0.5 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W16)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.618)
			then
			 pE = round(1.618 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	  end
 
	targetE = pE

end

function CalcPrognozPoint(pA,pB,pC,pD,pE)

	if (pattern == NamePattern.ERROR)
	  then
	--+------------------------------------------------------------+
	--| ПАТТЕРН: ERROR                                             |
	--| Точка "эволюции"=> НЕТ = 0                                 |
	--| Точка "мутации" => НЕТ = 0                                 |
	--+------------------------------------------------------------+
	  evE = nil 
	  mutE = nil
	  ----- level_1:
	  --CalcPrognozLevel1();
	  return;
   end


	----- ПРОВЕРКА НАЛИЧИЯ ТЕКУЩЕГО ПАТТЕРНА
	if (pattern == NamePattern.NOPATTERN)
	  then
	   evE = nil 
	   mutE = nil            -- НЕТ ПРОГНОЗА
	   --CalcPrognozLevel1();
	   return;                                         -- НЕТ ПАТТЕРНА - ВЫХОД
	end 

	--+---------------------------------------------------------------+
	--| РАСЧЕТ ТОЧЕК ПРОГНОЗА                                         |
	--+---------------------------------------------------------------+
	  
	   if pattern == NamePattern.M1 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M1 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> нет= 0                                  |
	   --| Точка "мутации" => W1 = 0.3819 * (pD-pE)+pE               |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = round(0.3819 * (pD-pE)+pE,SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M2 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M2 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M1 = D - 1.618 * (pD-pC)                |
	   --| Точка "мутации" => W4 = 0.5 * (pD-pE)+pE                  |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 1.618 * (pD-pC),SCALE);
		 
		 -----
		 mutE = round(0.5 * (pD-pE)+pE,SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M3 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M3 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> нет= 0                                  |
	   --| Точка "мутации" => W1 = 0.3819 * (pD-pE)+pE               |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = round(0.3819 * (pD-pE)+pE,SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M4 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M4 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M3 = D - 1.272 * (pD-pC)                |
	   --| Точка "мутации" => W4 = 0.5 * (pD-pE)+pE                  |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 1.272 * (pD-pC),SCALE);
		         
		 -----
		 mutE = round(0.5 * (pD-pE)+pE,SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M5 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M5 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> нет = 0                                 |
	   --| Точка "мутации" => W6  = 0.25 * (pD-pE)+pE                |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = round(0.25 * (pD-pE)+pE,SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M6 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M6 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M5 = D - 1.272 * (pD-pC)                |
	   --| Точка "мутации" => W9 = 0.3819 * (pD-pE)+pE               |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 1.272 * (pD-pC),SCALE);
		         
		 -----
		 mutE = round(0.3819 * (pD-pE)+pE,SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M7 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M7 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> нет = 0                                 |
	   --| Точка "мутации" => W1  = 0.3819 * (pD-pE)+pE              |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = round(0.3819 * (pD-pE)+pE,SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M8 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M8 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M4 = D - 0.618 * (pD-pC)                |
	   --| Точка "мутации" => W4 = 0.5 * (pD-pE)+pE                  |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 0.618 * (pD-pC),SCALE);
		         
		 -----
		 mutE = round(0.5 * (pD-pE)+pE,SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M9 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M9 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> нет = 0                                 |
	   --| Точка "мутации" => W6  = 0.25 * (pD-pE)+pE                |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = round(0.25 * (pD-pE)+pE,SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M10 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M10 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M6 = D - 0.618 * (pD-pC)                |
	   --| Точка "мутации" => W9 = 0.3819 * (pD-pE)+pE               |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 0.618 * (pD-pC),SCALE);
		 
		 -----
		 mutE = round(0.3819 * (pD-pE)+pE,SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M11 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M11 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M10 = D - 0.5 * (pD-pC)                 |
	   --| Точка "мутации" => W15 = 0.5 * (pD-pE)+pE                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 0.5 * (pD-pC),SCALE);
		 
		 -----
		 mutE = round(0.5 * (pD-pE)+pE,SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M12 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M12 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M7 = D - 3.0000 * (pD-pC)               |
	   --| Точка "мутации" => W1 = 0.3819 * (pD-pE)+pE               |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 3.0000 * (pD-pC),SCALE);
		 
		 -----
		 mutE = round(0.3819 * (pD-pE)+pE,SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M13 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M13 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M12 = D - 1.618 * (pD-pC)               |
	   --| Точка "мутации" => W4  = 0.5 * (pD-pE)+pE                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 1.618 * (pD-pC),SCALE);
		 
		 -----
		 mutE = round(0.5 * (pD-pE)+pE,SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M14 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M14 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M9 = D - 1.618 * (pD-pC)                |
	   --| Точка "мутации" => W6 = 0.25 * (pD-pE)+pE                 |
	   --+------------------------------------------------------------+
		 evE = round(pD - 1.618 * (pD-pC),SCALE);
		 
		 -----
		 mutE = round(0.25 * (pD-pE)+pE,SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M15 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M15 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M14 = D - 1.272 * (pD-pC)               |
	   --| Точка "мутации" => W9  = 0.3819 * (pD-pE)+pE              |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pC-(pC-pA)/1.618,SCALE);
		 
		 -----
		 mutE = round(pE+(pB-pE)/1.618,SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M16 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M16 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M15 = D - 0.618 * (pD-pC)               |
	   --| Точка "мутации" => W15 = 0.5 * (pD-pE)+pE                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 0.618 * (pD-pC),SCALE);
		         
		 -----
		 mutE = round(0.5 * (pD-pE)+pE,SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W1 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W1 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W2  = 0.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M2  = E - 0.5 * (pE-pD)                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(0.618 * (pC-pD)+pD,SCALE);
		         
		 -----
		 mutE = round(pE-0.5 * (pE-pD),SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W2 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W2 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W3  = 1.272 * (pC-pD)+pD               |
	   --| Точка "мутации" => M8  = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(1.272 * (pC-pD)+pD,SCALE);
		         
		 -----
		 mutE = round(pE-0.3819 * (pE-pD),SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W3 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W3 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W8  = 1.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M11 = E - 0.25 * (pE-pD)                |
	   --+------------------------------------------------------------+
		 evE = round(1.618 * (pC-pD)+pD,SCALE);
		         
		 -----
		 mutE = round(pE-0.25 * (pE-pD),SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W4 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W4 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W5  = 1.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M13 = E - 0.5 * (pE-pD)                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(1.618 * (pC-pD)+pD,SCALE);
		         
		 -----
		 mutE = round(pE-0.5 * (pE-pD),SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W5 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W5 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W10 = 3.0000 * (pC-pD)+pD              |
	   --| Точка "мутации" => M16 = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 evE = round(3.0000 * (pC-pD)+pD,SCALE);
		         
		 -----
		 mutE = round(pE-0.3819 * (pE-pD),SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W6 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W6 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W7 = 0.5 * (pC-pD)+pD                  |
	   --| Точка "мутации" => M2 = E - 0.5 * (pE-pD)                  |
	   --+------------------------------------------------------------+
		 evE = round(0.5 * (pC-pD)+pD,SCALE);
		         
		 -----
		 mutE = round(pE-0.5 * (pE-pD),SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W7 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W7 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W11 = 0.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M8  = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 evE = round(0.618 * (pC-pD)+pD,SCALE);
		         
		 -----
		 mutE = round(pE-0.3819 * (pE-pD),SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W8 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W8 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> НЕТ = 0                                 |
	   --| Точка "мутации" => M11 = E - 0.25 * (pE-pD)                |
	   --+------------------------------------------------------------+
		 evE = nil        
		 -----
		 mutE = round(pE-0.25 * (pE-pD),SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W9 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W9 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W13 = 0.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M13 = E - 0.5 * (pE-pD)                 |
	   --+------------------------------------------------------------+
		 evE = round(0.618 * (pC-pD)+pD,SCALE);
		         
		 -----
		 mutE = round(pE-0.5 * (pE-pD),SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W10 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W10 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> НЕТ = 0                                 |
	   --| Точка "мутации" => M16 = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 evE = nil   
		 -----
		 mutE = round(pE-0.3819 * (pE-pD),SCALE);
		         
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W11 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W11 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W12 = 1.272 * (pC-pD)+pD               |
	   --| Точка "мутации" => M8  = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 evE = round(1.272 * (pC-pD)+pD,SCALE);
		         
		 -----
		 mutE = round(pE-0.3819 * (pE-pD),SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W12 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W12 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> НЕТ = 0                                 |
	   --| Точка "мутации" => M11 = E - 0.25 * (pE-pD)                |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = round(pE-0.25 * (pE-pD),SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W13 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W13 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W14 = 1.272 * (pC-pD)+pD               |
	   --| Точка "мутации" => M13 = E - 0.5 * (pE-pD)                 |
	   --+------------------------------------------------------------+
	   
	   ----- level_0:
	   evE = round(1.272 * (pC-pD)+pD,SCALE);
	   
	   -----
	   mutE = round(pE-0.5 * (pE-pD),SCALE);
	   
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W14 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W14 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> НЕТ = 0                                 |
	   --| Точка "мутации" => M16 = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil    
		 -----
		 mutE = round(pE-0.3819 * (pE-pD),SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W15 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W15 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W16 = 1.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M13 = E - 0.5 * (pE-pD)                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(1.618 * (pC-pD)+pD,SCALE);
		         
		 -----
		 mutE = round(pE-0.5 * (pE-pD),SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W16 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W16 +                                             |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> НЕТ = 0                                 |
	   --| Точка "мутации" => M16 = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil        
		 -----
		 mutE = round(pE-0.3819 * (pE-pD),SCALE);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	 
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
