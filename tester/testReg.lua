RegSettings = {
    period    = 182,
    degree = 1, -- 1 -линейная, 2 - параболическая, - 3 степени
    shift = 0.618,
    kstd = 3, --отклонение сигма
    Size = 0
}

function initReg()
    calcAlgoValue = nil     --      Возвращаемая таблица
    calcChartResults = nil     --      Возвращаемая таблица
    ATR=nil
    calcATR = true
end

function iterateReg(iSec, cell)
    
    iterateSLTP = false

    local param1Min = 8
    local param1Max = 38
    local param1Step = 1

    local param2Min = 1
    local param2Max = 3
    local param2Step = 1
    
    local param3Min = 1
    local param3Max = 38
    local param3Step = 1

    local settingsTable = {}
    local allCount = 0

    for param1 = param1Min, param1Max, param1Step do
                
        for param2 = param2Min, param2Max, param2Step do    
            local calculatedShift = {}
            for param3 = param3Min, math.ceil(0.8*param1), param3Step do
            --for param3 = param3Min, param3Max, param3Step do
                allCount = allCount + 1
                
                settingsTable[allCount] = {
                    period    = param1,
                    degree = param2, -- 1 -линейная, 2 - параболическая, - 3 степени
                    shift = param3,
                    kstd = 3, --отклонение сигма
                    Size = Size,
                    endIndex = endIndex
                    }
            
                
            end
        end
    end

    iterateAlgorithm(iSec, cell, settingsTable)

end

function Reg(index, settings, DS)
 	        		
	local period = settings.period or 182
	local degree = settings.degree or 1
	local kstd = settings.kstd or 3
	local shift = settings.shift or 0.618
    
    local indexToCalc = 1000
    indexToCalc = settings.Size or indexToCalc
    local beginIndexToCalc = settings.beginIndexToCalc or math.max(1, settings.beginIndex - indexToCalc)
    local endIndexToCalc = settings.endIndex or DS:Size()

    if index == nil then index = 1 end

    period = math.min(period, DS:Size())
	
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
	
	p = period 
	nn = degree+1
 
    if index == beginIndexToCalc then
        myLog("Показатель Period "..tostring(period))
        myLog("Показатель degree "..tostring(degree))
        myLog("Показатель shift "..tostring(shift))
        myLog("--------------------------------------------------")
		
        calcAlgoValue = {}
        calcAlgoValue[index]= 0
        calcChartResults = {}
        calcChartResults[index]= {nil,nil}
        trend = {}
        trend[index] = 1
        ATR = {}
        ATR[index] = 0			
    
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
        
        return calcAlgoValue, nil, calcChartResults
    end
            
    calcAlgoValue[index] = calcAlgoValue[index-1]
    calcChartResults[index] = calcChartResults[index-1]
    trend[index] = trend[index-1]
    ATR[index] = ATR[index-1]

    if index<period then
        ATR[index] = 0
    elseif index==period then
        local sum=0
        for i = 1, period do
            sum = sum + dValue(i)
        end
        ATR[index]=sum / period
    elseif index>period then
        ATR[index]=(ATR[index-1] * (period-1) + dValue(index)) / period
    end

    if index <= beginIndexToCalc + (period + shift + 1) or index > endIndexToCalc then
        return calcAlgoValue, nil, calcChartResults
    end
	
	local typeVal = 'C'
	--- syx 
	for mi=1, nn do
		sum = 0
		for n=i0, i0+p do
			if DS:C(index+n-period) ~= nil then
				if mi==1 then
				   sum = sum + dValue(index+n-period,typeVal)
				else
				   sum = sum + dValue(index+n-period,typeVal)*math.pow(n,mi-1)
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
	   
	local n = p
	sum=0
	for kk=1, degree do
		sum = sum + x[kk+1]*math.pow(n,kk)
	end
	local regVal=x[1]+sum
		  
    calcAlgoValue[index] = round(regVal, 5)
    
    local isUpPinBar = DS:C(index)>DS:O(index) and (DS:H(index)-DS:C(index))/(DS:H(index) - DS:L(index))>=0.5 
    local isLowPinBar = DS:C(index)<DS:O(index) and (DS:C(index)-DS:L(index))/(DS:H(index) - DS:L(index))>=0.5 

    local isBuy = (not isUpPinBar and calcAlgoValue[index] > calcAlgoValue[index-shift] and calcAlgoValue[index-1] <= calcAlgoValue[index-shift-1]) 
    local isSell = (not isLowPinBar and calcAlgoValue[index] < calcAlgoValue[index-shift] and calcAlgoValue[index-1] >= calcAlgoValue[index-shift-1])
    
    if isBuy then
        trend[index] = 1
    end
    if isSell then
        trend[index] = -1
    end
    
    calcChartResults[index] = {calcAlgoValue[index], calcAlgoValue[index-shift-1]}

    return calcAlgoValue, trend, calcChartResults
	
end
