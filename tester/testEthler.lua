CyberCycleSettings = {
    alpha    = 0.07,
    cycletype = 1,
    shift = 1,
    Size = 0,
    fixedstop = 0,
    SLSec = 0,
    TPSec = 0
}

--- Алгоритм
function initCyberCycle()
    ATR = nil
    trend=nil
    calcAlgoValue = nil     --      Возвращаемая таблица
    calcChartResults = nil     --      Возвращаемая таблица

    sx          =nil
    Reg         =nil
    Close       =nil
    Price       =nil
    Smooth      =nil
    Cycle       =nil
    it          =nil
    Trigger     =nil
    CyclePeriod =nil
    InstPeriod  =nil
    Q1          =nil
    I1          =nil
    DeltaPhase  =nil
end

function iterateCyberCycle(iSec, cell)

    iterateSLTP = false

    param1Min = 0.01
    param1Max = 0.13
    param1Step = 0.005

    param2Min = 1
    param2Max = 2
    param2Step = 1

    param3Min = 1
    param3Max = 10
    param3Step = 1

    local settingsTable = {}
    local allCount = 0

    for param1 = param1Min, param1Max, param1Step do
        for param2 = param2Min, param2Max, param2Step do
            for param3 = param3Min, param3Max, param3Step do
                allCount = allCount + 1

                    settingsTable[allCount] = {
                        alpha    = param1,
                        cycletype    = param2,
                        shift    = param3
                    }
                end
        end
    end

    iterateAlgorithm(iSec, cell, settingsTable)

end

function CyberCycle(index, Fsettings)

    local alpha = Fsettings.alpha or 0.03
    local alpha1 = Fsettings.alpha or 0.03
    local cycletype = Fsettings.cycletype or 2
	local shift = Fsettings.shift or 3
    local periodATR = 18
    local ATRfactor = 0.2

    local reg_period = 64
    local reg_degree = 1

    local indexToCalc = 1000
    indexToCalc = Fsettings.indexToCalc or indexToCalc
    local beginIndexToCalc = Fsettings.beginIndexToCalc or math.max(1, DS:Size() - indexToCalc)

    if index == nil then index = 1 end

    if index == beginIndexToCalc or index == 1 then

        --if ROBOT_STATE ~= 'РЕОПТИМИЗАЦИЯ' then
        --    myLog("--------------------------------------------------")
        --    myLog("Показатель Period "..tostring(period))
        --    myLog("Показатель shift "..tostring(shift))
        --    myLog("--------------------------------------------------")
        --end

        Close={}
        Price={}
        Smooth={}
        Cycle={}
        it={}
        Trigger={}
        CyclePeriod={}
        InstPeriod={}
        Q1={}
        I1={}
        DeltaPhase={}

        Close[index] = DS:C(index)
        Price[index] = (DS:H(index) + DS:L(index))/2
        Smooth[index]=0
        Cycle[index]=0
        it[index]=0
        Trigger[index]=0
        CyclePeriod[index]=0
        InstPeriod[index]=0
        Q1[index]=0
        I1[index]=0
        DeltaPhase[index]=0

        Reg = {}
        Reg[index] = DS:C(index)
        sx={}
        sx[1] = reg_period+1
        local nn = reg_degree+1

        for mi=1, nn*2-2 do
            sum=0
            for n=1, reg_period do
                sum = sum + math.pow(n,mi)
            end
            sx[mi+1]=sum
        end

        ATR = {}
        ATR[index] = 0
        trend = {}
        trend[index] = 1
        calcAlgoValue = {}
        calcAlgoValue[index] = 0

        calcChartResults = {}
        calcChartResults[index]= {nil,nil}

        return calcAlgoValue
    end

    Close[index]        = Close[index-1]
    Price[index]        = Price[index-1]
    Smooth[index]       = Smooth[index-1]
    Cycle[index]        = Cycle[index-1]
    it[index]           = it[index-1]
    Trigger[index]      = Trigger[index-1]
    CyclePeriod[index]  = CyclePeriod[index-1]
    InstPeriod[index]   = InstPeriod[index-1]
    Q1[index]           = Q1[index-1]
    I1[index]           = I1[index-1]
    DeltaPhase[index]   = DeltaPhase[index-1]
    Reg[index]          = Reg[index-1]

    ATR[index] = ATR[index-1]
    calcAlgoValue[index] = calcAlgoValue[index-1]
    trend[index] = trend[index-1]
    calcChartResults[index] = calcChartResults[index-1]

    if DS:C(index) == nil then
        return calcAlgoValue, trend, calcChartResults
    end

    --Close[index] = DS:C(index)
    --Price[index] = (DS:H(index) + DS:L(index))/2
    Price[index] = dValue(index, 'T')

    if index<periodATR then
        ATR[index] = 0
    elseif index==periodATR then
        local sum=0
        for i = 1, periodATR do
            sum = sum + dValue(i)
        end
        ATR[index]=sum / periodATR
    elseif index>periodATR then
        ATR[index]=(ATR[index-1] * (periodATR-1) + dValue(index)) / periodATR
    end

    if index <= beginIndexToCalc + 4 then
        Cycle[index]=0
        it[index]=0
        Trigger[index]=0
        CyclePeriod[index]=0
        InstPeriod[index]=0
        Q1[index]=0
        I1[index]=0
        DeltaPhase[index]=0
        return calcAlgoValue, trend, calcChartResults
    end

    if DS:C(index) ~= nil then

		Cycle[index]=(Price[index]-2.0*Price[index - 1]+Price[index - 2])/4.0

		if cycletype == 1 then

			Smooth[index] = (Price[index]+2*Price[index - 1]+2*Price[index - 2]+Price[index - 3])/6.0

			if index < beginIndexToCalc + 7 then
				it[index]=0
				Trigger[index]=0
				CyclePeriod[index]=0
				InstPeriod[index]=0
				Q1[index]=0
				I1[index]=0
				DeltaPhase[index]=0
				return calcAlgoValue, trend, calcChartResults
			end

			Cycle[index]=(1.0-0.5*alpha) *(1.0-0.5*alpha) *(Smooth[index]-2.0*Smooth[index - 1]+Smooth[index - 2])
							+2.0*(1.0-alpha)*Cycle[index - 1]-(1.0-alpha)*(1.0-alpha)*Cycle[index - 2]


            --myLog("index "..tostring(index)..", Cycle "..tostring(Cycle[index])..", InstPeriod "..tostring(InstPeriod[index]))
            Q1[index] = (0.0962*Cycle[index]+0.5769*Cycle[index-2]-0.5769*Cycle[index-4]-0.0962*Cycle[index-6])*(0.5+0.08*(InstPeriod[index-1] or 0))
			I1[index] = Cycle[index-3]

			if Q1[index]~=0.0 and Q1[index-1]~=0.0 then
				DeltaPhase[index] = (I1[index]/Q1[index]-I1[index-1]/Q1[index-1])/(1.0+I1[index]*I1[index-1]/(Q1[index]*Q1[index-1]))
			else DeltaPhase[index] = 0
			end
			if DeltaPhase[index] < 0.1 then
				DeltaPhase[index] = 0.1
			end
			if DeltaPhase[index] > 0.9 then
				DeltaPhase[index] = 0.9
			end

			MedianDelta = Median(DeltaPhase[index],DeltaPhase[index-1], Median(DeltaPhase[index-2], DeltaPhase[index-3], DeltaPhase[index-4]))

			if MedianDelta == 0.0 then
				DC = 15.0
			else
				DC = 6.28318/MedianDelta + 0.5
			end

			InstPeriod[index] = 0.33 * DC + 0.67 * (InstPeriod[index-1] or 0)
			CyclePeriod[index] = 0.15 * InstPeriod[index] + 0.85 * CyclePeriod[index-1]

			alpha1 = 2.0/(CyclePeriod[index]+1.0)
		end

		it[index]=(alpha1-((alpha1*alpha1)/4.0))*Price[index]+0.5*alpha1*alpha1*Price[index-1]-(alpha1-0.75*alpha1*alpha1)*Price[index-2]+
			2*(1-alpha1)*(it[index-1] or Cycle[index])-(1-alpha1)*(1-alpha1)*(it[index-2] or Cycle[index])

        Trigger[index] = 2.0*it[index]-(it[index-shift] or 0)

        --local reg_price = regArr(Close, reg_degree, index, reg_period)
        --Reg[index] = reg_price[#reg_price]
        --local is_reg_up   = reg_price[#reg_price] > reg_price[1]
        --local is_reg_down = reg_price[#reg_price] < reg_price[1]

        local isUpPinBar = DS:C(index)>DS:O(index) and (DS:H(index)-DS:C(index))/(DS:H(index) - DS:L(index))>=0.5
        local isLowPinBar = DS:C(index)<DS:O(index) and (DS:C(index)-DS:L(index))/(DS:H(index) - DS:L(index))>=0.5
        local isUpOutsideBar = not isUpPinBar and DS:C(index)>DS:O(index) and DS:C(index)>=DS:C(index-1) and DS:O(index)<=DS:O(index-1)
        local isLowOutsideBar = not isLowPinBar and DS:C(index)<DS:O(index) and DS:C(index)<=DS:C(index-1) and DS:O(index)>=DS:O(index-1)

        --local isBuy  = trend[index] <= 0 and Trigger[index] > it[index] and Trigger[index] > Trigger[index-1] and it[index] > it[index-1]
        --local isSell = trend[index] >= 0 and Trigger[index] < it[index] and Trigger[index] < Trigger[index-1] and it[index] < it[index-1]
        --local isBuy  = trend[index] <= 0 and Trigger[index] > Trigger[index-1] and it[index] > it[index-1]
        --local isSell = trend[index] >= 0 and Trigger[index] < Trigger[index-1] and it[index] < it[index-1]
        --local isBuy  = trend[index] <= 0 and it[index] > it[index-1] and Trigger[index] > it[index]
        --local isSell = trend[index] >= 0 and it[index] < it[index-1] and Trigger[index] < it[index]

        --local isBuy  = trend[index] <= 0 and it[index] > it[index-1] and Trigger[index] > it[index] and DS:O(index) > it[index]
        --local isSell = trend[index] >= 0 and it[index] < it[index-1] and Trigger[index] < it[index] and DS:O(index) < it[index]
        --local isBuy  = trend[index] <= 0 and it[index] > it[index-1] and it[index] > Trigger[index] and DS:O(index) > it[index]
        --local isSell = trend[index] >= 0 and it[index] < it[index-1] and it[index] < Trigger[index] and DS:O(index) < it[index]

        --local isBuy  = trend[index] <= 0 and it[index] > it[index-1] and Trigger[index] > it[index] and DS:O(index) > Trigger[index]
        --local isSell = trend[index] >= 0 and it[index] < it[index-1] and Trigger[index] < it[index] and DS:O(index) < Trigger[index]
        local isBuy  = trend[index] <= 0 and it[index] > it[index-1] and Trigger[index] > it[index] and DS:O(index) > it[index]
        local isSell = trend[index] >= 0 and it[index] < it[index-1] and Trigger[index] < it[index] and DS:O(index) < it[index]
        --local isBuy  = trend[index] <= 0 and Trigger[index] > Trigger[index-1] and Trigger[index] > it[index] and DS:O(index) > Trigger[index]
        --local isSell = trend[index] >= 0 and Trigger[index] < Trigger[index-1] and Trigger[index] < it[index] and DS:O(index) < Trigger[index]

        if isBuy then
            trend[index] = 1
        end
        if isSell then
            trend[index] = -1
        end
        --if trend[index] == 1 and (Trigger[index] - DS:O(index)) > ATRfactor*ATR[index] then
        --    trend[index] = 0
        --end
        --if trend[index] == -1 and (DS:O(index) - Trigger[index]) > ATRfactor*ATR[index] then
        --    trend[index] = 0
        --end

        calcAlgoValue[index] = DS:O(index)
    end

    calcChartResults[index] = {Trigger[index], it[index]}

    return calcAlgoValue, trend, calcChartResults

end

function regArr(arr, degree, index, bars)

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

    local mi = 0
    local ai={{1,2,3,4}, {1,2,3,4}, {1,2,3,4}, {1,2,3,4}}
    local b={}
    local x={}

    nn = degree+1

    local fx_buffer = {}
    fx_buffer[1]= 0

    ----- sx
    --sx={}
    --sx[1] = bars+1
    --
    --for mi=1, nn*2-2 do
    --    sum=0
    --    for n=1, bars do
    --        sum = sum + math.pow(n,mi)
    --    end
    --    sx[mi+1]=sum
    --end

    --- syx
    for mi=1, nn do
        sum = 0
		for n=0, bars do
			if arr[index+n-bars] ~= nil then
                if mi==1 then
                   sum = sum + arr[index+n-bars]
                else
                   sum = sum + arr[index+n-bars]*math.pow(n,mi-1)
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
            return calcAlgoValue[index]
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

	for n=1, bars do
        sum=0
        for kk=1, degree do
            sum = sum + x[kk+1]*math.pow(n,kk)
        end
        fx_buffer[n]=x[1]+sum
    end

    return fx_buffer

end

local newIndex = #ALGORITHMS['names']+1

ALGORITHMS['names'][newIndex]               = "CyberCycle"
ALGORITHMS['initParams'][newIndex]          = initCyberCycle
ALGORITHMS['initAlgorithms'][newIndex]      = initCyberCycle
ALGORITHMS['itetareAlgorithms'][newIndex]   = iterateCyberCycle
ALGORITHMS['calcAlgorithms'][newIndex]      = CyberCycle
ALGORITHMS['tradeAlgorithms'][newIndex]     = simpleTrade
ALGORITHMS['settings'][newIndex]            = CyberCycleSettings
