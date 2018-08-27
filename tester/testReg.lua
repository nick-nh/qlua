RegSettings = {
    bars    = 182,
    degree = 1, -- 1 -линейная, 2 - параболическая, - 3 степени
    kstd = 3 --отклонение сигма
}

function initReg()
    calcAlgoValue = nil     --      Возвращаемая таблица
    fx_buffer = nil         --      Линия регрессии
    sql_buffer = nil    --      +Сигма
    sqh_buffer = nil    --      -Сигма
    sx = nil
end

function iterateReg(iSec, cell)
    
    Clear(tres_id)

    myLog("================================================")
    myLog("Sec code "..SEC_CODES['sec_codes'][iSec])

    --local settings = ALGORITHMS["settings"][cell]
    local Size = GetCell(t_id, lineTask, 2).value or SEC_CODES['Size'][iSec]
    --resultsTable = {}
    clearResultsTable(iSec, cell)
    local resultsTable = CreateResTable(iSec)    
    local count = #resultsTable
    local settingTable = ALGORITHMS['settings'][cell]

    myLog("Interval "..ALGORITHMS['names'][cell])
    myLog("================================================")
    
    local param1Min = 4
    local param1Max = 128
    local param1Step = 1
    
    local ChartId = SEC_CODES['ChartId'][iSec]
    if ChartId ~= nil then
        DelAllLabels(ChartId);
    end
   
    maxProfitIndex = 0
    maxProfit = nil
    maxProfitDeals = nil
    maxProfitAlgoResults = nil

    local localCount = 0
    local done = 0

    DS = DataSource(iSec)
    beginIndex = DS:Size()-Size
    endIndex = DS:Size()

    local allCount = ((param1Max-param1Min + param1Step)/param1Step)

    for _Period = param1Min, param1Max, param1Step do
                
        count = count + 1
        localCount = localCount + 1
        done = round(localCount*100/allCount, 0)
        SetCell(t_id, lineTask, 4, tostring(done).."%", done)

        allProfit = 0
        shortProfit = 0
        longProfit = 0
        lastDealPrice = 0
        dealsCount = 0
        dealsLongCount = 0
        dealsShortCount = 0
        profitDealsLongCount = 0
        profitDealsShortCount = 0
        ratioProfitDeals = 0
        initalAssets = 0
                
        settingsTask = {
            bars    = _Period,
            degree = 1, -- 1 -линейная, 2 - параболическая, - 3 степени
            kstd = 3, --отклонение сигма
            Size = Size
        }
        
        calculateAlgorithm(iSec, cell)
        local profitRatio, avg, sigma, maxDrawDown, sharpe, AHPR, ZCount = calculateSigma(deals)

        --myLog("--------------------------------------------------")
        --myLog("Прибыль по лонгам "..tostring(longProfit))
        --myLog("Прибыль по шортам "..tostring(shortProfit))
        --myLog("Прибыль всего "..tostring(allProfit))
        --myLog("================================================")
        
        dealsLP = tostring(dealsLongCount).."/"..tostring(profitDealsLongCount)
        dealsSP = tostring(dealsShortCount).."/"..tostring(profitDealsShortCount)
        if dealsLongCount + dealsShortCount > 0 then
            ratioProfitDeals = round((profitDealsLongCount + profitDealsShortCount)*100/(dealsLongCount + dealsShortCount), 2)
        end
        
        resultsTable[count] = {iSec, cell, allProfit, profitRatio, longProfit, shortProfit, dealsLP, dealsSP, ratioProfitDeals, avg, sigma, maxDrawDown, sharpe, AHPR, ZCount, settingsTask}

        if maxProfit == nil or maxProfit<allProfit then
            maxProfit = allProfit
            maxProfitIndex = count
            maxProfitDeals = deals
            maxProfitAlgoResults = algoResults
            SetCell(t_id, lineTask, 5, tostring(allProfit), allProfit)
            SetCell(t_id, lineTask, 6, tostring(profitRatio), profitRatio)
            SetCell(t_id, lineTask, 7, tostring(longProfit), longProfit)
            SetCell(t_id, lineTask, 8, tostring(shortProfit), shortProfit)
            SetCell(t_id, lineTask, 9, tostring(dealsLP), 0)
            SetCell(t_id, lineTask, 10, tostring(dealsSP), 0)
            SetCell(t_id, lineTask, 11, tostring(ratioProfitDeals), ratioProfitDeals)
            SetCell(t_id, lineTask, 12, tostring(avg), avg)
            SetCell(t_id, lineTask, 13, tostring(sigma), sigma)
            SetCell(t_id, lineTask, 14, tostring(maxDrawDown), maxDrawDown)
            SetCell(t_id, lineTask, 15, tostring(sharpe), sharpe)
            SetCell(t_id, lineTask, 16, tostring(AHPR), AHPR)
            SetCell(t_id, lineTask, 17, tostring(ZCount), ZCount)
        end
    
    end
       
    SetCell(t_id, lineTask, 4, "100%", 100)
 
    openResults(resultsTable, settingTable)

    if ChartId ~= nil then
        addDeals(maxProfitDeals, ChartId, DS)
        stv.UseNameSpace(ChartId)
        stv.SetVar('algoResults', maxProfitAlgoResults)
    end

end

function Reg(index, settings, DS)
 	        		
	local bars = settings.bars or 182
	local degree = settings.degree or 1
	local kstd = settings.kstd or 3
    
    if index == nil then index = 1 end

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
 
    if index == 1 then
        sql_buffer = {}
        sqh_buffer = {}
        fx_buffer = {}
        
        sql_buffer[index]= 0
        sqh_buffer[index]= 0
        fx_buffer[index]= 0
        
        calcAlgoValue = {}
        calcAlgoValue[index]= 0
        trend = {}
        trend[index] = 1
    
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
        
        return calcAlgoValue
    end
            
    sql_buffer[index] = sql_buffer[index-1]	
    sqh_buffer[index] = sqh_buffer[index-1]	
    --fx_buffer[index] = fx_buffer[index-1]
    calcAlgoValue[index] = calcAlgoValue[index-1]
    trend[index] = trend[index-1]
    
    if index <= (bars + 1) then
        return calcAlgoValue
    end
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
 	end
		 
	--- Std 
    sq=0.0
	for n=i0, i0+p do
		if DS:C(index+n-bars) ~= nil then
			sq = sq + math.pow(DS:C(index+n-bars)-fx_buffer[n],2)
		end
	end
	   
	sq = math.sqrt(sq/(p-1))*kstd

	for n=i0, i0+p do
		sqh_buffer[index+n-bars]=round(fx_buffer[n]+sq, 5)
		sql_buffer[index+n-bars]=round(fx_buffer[n]-sq, 5)
 	end        
    		
    calcAlgoValue[index] = round(fx_buffer[p], 5)
    if calcAlgoValue[index] < DS:C(index) and calcAlgoValue[index-1] >= DS:C(index-1) then
        trend[index] = 1
    end
    if calcAlgoValue[index] > DS:C(index) and calcAlgoValue[index-1] <= DS:C(index-1) then
        trend[index] = -1
    end

	return calcAlgoValue, trend
	
end
