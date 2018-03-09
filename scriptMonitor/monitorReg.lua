function initReg()
    calcAlgoValue = nil     --      Возвращаемая таблица
    fx_buffer = nil         --      Линия регрессии
    sql_buffer = nil    --      +Сигма
    sqh_buffer = nil    --      -Сигма
    sx = nil
end

function Reg(iSec, index, settings, DS)
 	        		
	local bars = settings.bars or 182
	local degree = settings.degree or 1
	local kstd = settings.kstd or 3
    
    if index == nil then index = DS:Size() end
	bars = math.min(bars, DS:Size())
	
	local p = 0
	local n = 0
	local f = 0
	local qq = 0
	local mm = 0
	local tt = 0
	local ii = 0
	local jj = 0
	local kk = 0
	local ll = 0
	local nn = 0
	local sq = 0
	local i0 = 0
	
	local mi = 0
 	local ai={{1,2,3,4}, {1,2,3,4}, {1,2,3,4}, {1,2,3,4}}		
	local b={}
	local x={}
	
	p = bars 
	nn = degree+1
 
    sql_buffer = {}
    sqh_buffer = {}
	sql_buffer[index]= 0
	sqh_buffer[index]= 0
        
	calcAlgoValue = {}
    calcAlgoValue[index]= 0
        
	fx_buffer = {}
    fx_buffer[index]= 0

	--- sx 
	sx={}
	sx[1] = p+1
		
	for mi=1, nn*2-2 do
		sum=0
		for n=i0, i0+p do
			sum = sum + math.pow(n,mi)
		end
		sx[mi+1]=sum
	end
           		 
	--- syx 
	for mi=1, nn do
		sum = 0
		for n=i0, i0+p do
			if DS:C(index+n-bars) ~= nil then
				if mi==1 then
				   sum = sum + DS:C(index+n-bars)
				else
				   sum = sum + DS:C(index+n-bars)*math.pow(n,mi-1)
				end
			end
		end
	    b[mi]=sum
	end
		 
	--- Matrix 
	for jj=1, nn do
		for ii=1, nn do
			kk=ii+jj-1
			ai[ii][jj]=sx[kk]
		end
	end
		 
	--- Gauss 
	for kk=1, nn-1 do
		ll=0
		mm=0
		for ii=kk, nn do
			if math.abs(ai[ii][kk])>mm then
				mm=math.abs(ai[ii][kk])
				ll=ii
			end
		end
			
		if ll==0 then
			return calcAlgoValue
		end
		if ll~=kk then

			for jj=1, nn do
				tt=ai[kk][jj]
				ai[kk][jj]=ai[ll][jj]
				ai[ll][jj]=tt
			end
			tt=b[kk]
			b[kk]=b[ll]
			b[ll]=tt
		end
		for ii=kk+1, nn do
			qq=ai[ii][kk]/ai[kk][kk]
			for jj=1, nn do
				if jj==kk then
					ai[ii][jj]=0
				else
					ai[ii][jj]=ai[ii][jj]-qq*ai[kk][jj]
				end
			end
			b[ii]=b[ii]-qq*b[kk]
		end
	end
	   
	 x[nn]=b[nn]/ai[nn][nn]
	   
	for ii=nn-1, 1, -1 do
		tt=0
		for jj=1, nn-ii do
			tt=tt+ai[ii][ii+jj]*x[ii+jj]
			x[ii]=(1/ai[ii][ii])*(b[ii]-tt)
		end
	end
	   
	---
	for n=i0, i0+p do
		sum=0
		for kk=1, degree do
			sum = sum + x[kk+1]*math.pow(n,kk)
		end
		fx_buffer[n]=x[1]+sum
        calcAlgoValue[index+n-bars] = round(fx_buffer[n], 5)
 	end
		 
	--- Std 
    sq=0.0
	for n=i0, i0+p do
		if DS:C(index+n-bars) ~= nil then
			sq = sq + math.pow(DS:C(index+n-bars)-fx_buffer[n],2)
		end
	end
	   
	sq = math.sqrt(sq/(p+1))*kstd

	for n=i0, i0+p do
		sqh_buffer[index+n-bars]=round(fx_buffer[n]+sq, 5)
		sql_buffer[index+n-bars]=round(fx_buffer[n]-sq, 5)
 	end        
    		
	return calcAlgoValue
	
end

function signalReg(i, cell, settings, DS, signal)
    
    --tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value) or 0
	local testvalue = GetCell(t_id, i, tableIndex["Текущая цена"]).value
	local scale = getSecurityInfo(CLASS_CODE, SEC_CODE).scale
	--local price_step = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value) or 0
    local signaltestvalue1 = calcAlgoValue[DS:Size()-1] or 0
    local signaltestvalue2 = calcAlgoValue[DS:Size()-2] or 0
	local testZone = settings.testZone or 4
	local index = DS:Size()
	
	local plusSigma = sqh_buffer[index]
	local minusSigma = sql_buffer[index]
	local testSigmaZone = round((plusSigma - minusSigma)*testZone/100, 5)
	local deltaSigma = (plusSigma - minusSigma)/2
	local maxSigmaZone = plusSigma - testSigmaZone
	local minSigmaZone = minusSigma + testSigmaZone

    if calcAlgoValue[DS:Size()] == nil or DS:Size() == 0 then return end
    local calcVal = round(calcAlgoValue[DS:Size()] or 0, scale)
    if INTERVALS["visible"][cell] then
        local colorGradation = math.floor((math.abs(testvalue - calcVal)/deltaSigma)*(255-200))
        local Color = RGB(255, 255, 255)
        if calcVal>=testvalue then
            Color = RGB(math.max(255 - 0.5*colorGradation, 255), 255 - 3*colorGradation, 255 - 3*colorGradation) -- оттенки красного
		elseif calcVal<testvalue then
            Color = RGB(255 - 3*colorGradation, math.max(255 - 0.7*colorGradation, 255), 255 - 3.4*colorGradation) --оттенки зеленого
		elseif calcVal>maxSigmaZone or calcVal<minSigmaZone  then
            Color = RGB(200, 200, 255) --голубой
        end

        SetCell(t_id, i, tableIndex[cell], tostring(calcVal), calcVal)
        cellSetColor(i, tableIndex[cell], Color, RGB(0,0,0))
    end

    if signal then
		local isMessage = SEC_CODES['isMessage'][i]
		local isPlaySound = SEC_CODES['isPlaySound'][i]
		local mes0 = tostring(SEC_CODES['names'][i]).." timescale "..INTERVALS["names"][cell]
		local mes = ""
		
		if signaltestvalue1 < DS:C(DS:Size()-1) and signaltestvalue2 > DS:C(DS:Size()-2) then
			mes = mes0..": Сигнал Buy"
			myLog(mes)
			--myLog("Значение алгоритма -1 "..tostring(signaltestvalue1).." Закрытие свечи-1 "..DS:C(DS:Size()-1))
			--myLog("Значение алгоритма -2 "..tostring(signaltestvalue2).." Закрытие свечи-2 "..DS:C(DS:Size()-2))
			if isMessage == 1 then message(mes) end
			if isPlaySound == 1 then PaySoundFile(soundFileName) end
		end
		if signaltestvalue1 > DS:C(DS:Size()-1) and signaltestvalue2 < DS:C(DS:Size()-2) then
			mes = mes0..": Сигнал Sell"
			myLog(mes)
			--myLog("Значение алгоритма -1 "..tostring(signaltestvalue1).." Закрытие свечи-1 "..DS:C(DS:Size()-1))
			--myLog("Значение алгоритма -2 "..tostring(signaltestvalue2).." Закрытие свечи-2 "..DS:C(DS:Size()-2))
			if isMessage == 1 then message(mes) end
			if isPlaySound == 1 then PaySoundFile(soundFileName) end
		end
		
		if testvalue > maxSigmaZone and DS:C(DS:Size()-1) < maxSigmaZone then
			mes = mes0..": Цена приблизилась к верхней зоне +"..tostring(settings.kstd).." сигма "..tostring(maxSigmaZone)
			myLog(mes)
			if isMessage == 1 then message(mes) end
			if isPlaySound == 1 then PaySoundFile(soundFileName) end
		end
	if testvalue < minSigmaZone and DS:C(DS:Size()-1) > minSigmaZone then
			mes = mes0..": Цена приблизилась к нижней зоне -"..tostring(settings.kstd).." сигма "..tostring(minSigmaZone)
			myLog(mes)
			if isMessage == 1 then message(mes) end
			if isPlaySound == 1 then PaySoundFile(soundFileName) end
		end
		if testvalue < maxSigmaZone and DS:C(DS:Size()-1) > maxSigmaZone then
			mes = mes0..": Цена оттолкнулась от верхней зоны +"..tostring(settings.kstd).." сигма "..tostring(maxSigmaZone)
			myLog(mes)
			if isMessage == 1 then message(mes) end
			if isPlaySound == 1 then PaySoundFile(soundFileName) end
		end
	if testvalue > minSigmaZone and DS:C(DS:Size()-1) < minSigmaZone then
			mes = mes0..": Цена оттолкнулась от нижней зоны -"..tostring(settings.kstd).." сигма "..tostring(minSigmaZone)
			myLog(mes)
			if isMessage == 1 then message(mes) end
			if isPlaySound == 1 then PaySoundFile(soundFileName) end
		end
    end

end
