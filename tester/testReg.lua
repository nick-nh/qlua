RegSettings = {
    period    = 182,
    degree = 1, -- 1 -линейная, 2 - параболическая, - 3 степени
    shift = 0.618,
    kstd = 3, --отклонение сигма
    periodATR = 0,
    kATR = 0,
    Size = 0
}

function initReg()
    Reg = nil         --      Линия регрессии
    Trigger = nil
    sx = nil
    calcAlgoValue = nil     --      Возвращаемая таблица
    calcChartResults = nil     --      Возвращаемая таблица
    ATR=nil
    calcATR = true
end

function iterateReg(iSec, cell)

    local param1Min = 8
    local param1Max = 38
    local param1Step = 1

    local param2Min = 1
    local param2Max = 3
    local param2Step = 1

    local param3Min = 1
    local param3Max = 10
    local param3Step = 1

    local param4Min   = 10
    local param4Max   = 10
    local param4Step  = 1

    local param5Min   = 0.6
    local param5Max   = 0.6
    local param5Step  = 0.05

    if fixedstop then
        param4Min   = 10
        param4Max   = 10
        param4Step  = 1

        param5Min   = 0.6
        param5Max   = 0.6
        param5Step  = 0.05
    end

    local settingsTable = {}
    local allCount = 0

    for param1 = param1Min, param1Max, param1Step do

        --_param2Min = math.max(math.ceil(param1+1), param2Min)
        --for param2 = _param2Min, param2Max, param2Step do
        for param2 = param2Min, param2Max, param2Step do

            --for param3 = param3Min, math.ceil(0.8*param1), param3Step do
            for param3 = param3Min, param3Max, param3Step do
                for param4 = param4Min, param4Max, param4Step do
                    for param5 = param5Min, param5Max, param5Step do
                        allCount = allCount + 1
                        settingsTable[allCount] = {
                            period    = param1,
                            degree = param2, -- 1 -линейная, 2 - параболическая, - 3 степени
                            shift = param3,
                            kstd = 3, --отклонение сигма
                            periodATR = param4,
                            kATR = param5,
                            Size = Size
                            }
                    end
                end
            end
        end
    end

    iterateAlgorithm(iSec, cell, settingsTable)

end

function Reg(index, settings, DS)

	local period = settings.period or 182
	local degree = settings.degree or 1
	local kstd = settings.kstd or 3
	local shift = settings.shift or 1

    local periodATR = settings.periodATR or 10
    kATR = settings.kATR or 0.65

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

    if index == beginIndexToCalc or index == 1 then
        --myLog("Показатель Period "..tostring(period))
        --myLog("Показатель degree "..tostring(degree))
        --myLog("Показатель shift "..tostring(shift))
        --myLog("--------------------------------------------------")

        --- sx
        sx={}
        sx[1] = p+1

        for mi=1, nn*2-2 do
            local sum=0
            for n=i0, i0+p do
                sum = sum + math.pow(n,mi)
            end
            sx[mi+1] = sum
        end


        Reg = {}
        Reg[index]= 0
        Trigger = {}
        Trigger[index]= 0

        ATR = {}
        ATR[index] = 0
        trend = {}
        trend[index] = 1
        calcAlgoValue = {}
        calcAlgoValue[index] = 0
        calcChartResults = {}
        calcChartResults[index] = {}

        return calcAlgoValue, trend, calcChartResults
    end

    Reg[index] = Reg[index-1]
    Trigger[index] = Trigger[index-1]

    calcAlgoValue[index] = calcAlgoValue[index-1]
    calcChartResults[index] = calcChartResults[index-1]
    trend[index] = trend[index-1]
    ATR[index] = ATR[index-1]

    if index<(periodATR+beginIndexToCalc) then
        ATR[index] = 0
    elseif index==(periodATR+beginIndexToCalc) then
        local sum=0
        for i = 1, periodATR do
            sum = sum + dValue(i)
        end
        ATR[index]=sum / periodATR
    elseif index>(periodATR+beginIndexToCalc) then
        ATR[index]=(ATR[index-1] * (periodATR-1) + dValue(index)) / periodATR
        --ATR[index] = kawg*dValue(index)+(1-kawg)*ATR[index-1]
    end

    if index <= beginIndexToCalc + (math.max(period, periodATR) + shift + 1) or index > endIndexToCalc then
        return calcAlgoValue, trend, calcChartResults
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

	---
	--for n=i0, i0+p do
		local n = p
		sum=0
		for kk=1, degree do
			sum = sum + x[kk+1]*math.pow(n,kk)
		end
		--fx_buffer[n]=x[1]+sum
		Reg[index]=round(x[1]+sum, 5)
 	--end

	--- Std
    --sq=0.0
	--for n=i0, i0+p do
	--	if dValue(index+n-period,typeVal) ~= nil then
	--		sq = sq + math.pow(dValue(index+n-period,typeVal)-fx_buffer[n],2)
	--	end
	--end
	--
	--sq = math.sqrt(sq/(p-1))*kstd
    --
	--for n=i0, i0+p do
	--	sqh_buffer[index+n-period]=round(fx_buffer[n]+sq, 5)
	--	sql_buffer[index+n-period]=round(fx_buffer[n]-sq, 5)
 	--end

    Trigger[index] = 2.0*Reg[index]-(Reg[index-shift] or 0)

    local isUpPinBar = DS:C(index)>DS:O(index) and (DS:H(index)-DS:C(index))/(DS:H(index) - DS:L(index))>=0.5
    local isLowPinBar = DS:C(index)<DS:O(index) and (DS:C(index)-DS:L(index))/(DS:H(index) - DS:L(index))>=0.5

    local isBuy  = trend[index] <= 0 and Reg[index] > Reg[index-1] and Trigger[index] > Reg[index]
    local isSell = trend[index] >= 0 and Reg[index] < Reg[index-1] and Trigger[index] < Reg[index]

    if isBuy then
        trend[index] = 1
    end
    if isSell then
        trend[index] = -1
    end

    calcAlgoValue[index] = DS:C(index)
    calcChartResults[index] = {Reg[index], Trigger[index]}
    --calcChartResults[index] = {calcAlgoValue[index], TEMA[index-shift]}

    --myLog("index "..tostring(index)..", calcChartResults1 "..tostring(calcChartResults[index][1])..", calcChartResults2 "..tostring(calcChartResults[index][2]))

    return calcAlgoValue, trend, calcChartResults

end

local newIndex = #ALGORITHMS['names']+1

ALGORITHMS['names'][newIndex]               = "Reg"
ALGORITHMS['initParams'][newIndex]          = initReg
ALGORITHMS['initAlgorithms'][newIndex]      = initReg
ALGORITHMS['itetareAlgorithms'][newIndex]   = iterateReg
ALGORITHMS['calcAlgorithms'][newIndex]      = Reg
ALGORITHMS['tradeAlgorithms'][newIndex]     = simpleTrade
ALGORITHMS['settings'][newIndex]            = RegSettings
