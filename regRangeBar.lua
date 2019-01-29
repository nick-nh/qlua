-- nick-h@yandex.ru
-- Glukk Inc ©
-- индикатор, выводящий диапазоны проторговки

--logfile=io.open(getWorkingFolder().."\\LuaIndicators\\regRangeBar.txt", "w")

min_price_step = 0

Settings=
{
	Name = "*regRangeBar",
    bars = 27,
    ratioFactor = 0.7,
    kstd = 1.8,
	line =
	{		
		{
			Name = "upRange",
			Color = RGB(89, 213, 107),
			Type = TYPET_BAR, --TYPE_DASHDOT,
			Width = 2
		},
		{
			Name = "downRange",
			Color = RGB(251,82,0),
			Type = TYPET_BAR,
			Width = 2
		},
		{
			Name = "signal",
			Color = RGB(128,64,64),
			Type = TYPE_POINT,
			Width = 3
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
	end
	return myFunc(index, Settings)
		
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
	
	local upRange={}
	local dwnRange={}
	local cacheL={}
	local cacheH={}
    local cacheC={}
	local sx={}
	local calculated_buffer={}
    local prevRangeStart = {}
    local rangeStart = {}
    local lastRange = {}
    local lastSignal = {}
		
	return function(ind, Fsettings, ds)
	
		local Fsettings=(Fsettings or {})
		
		local index = ind
		local bars = Fsettings.bars or 64
		local ratioFactor = Fsettings.ratioFactor or 3
		local kstd = Fsettings.kstd or 1
        local degree = 1
        		
		local out1 = nil
        local out2 = nil
        local out3 = nil
        
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
		
		local mi = 0
 		local ai={{1,2,3,4}, {1,2,3,4}, {1,2,3,4}, {1,2,3,4}}		
		local b={}
		local x={}

        local index = ind-1
		index = math.max(index, 1)
		
		p = bars 
		nn = degree+1
		
		if index == 1 then
        
            upRange = {}
			upRange[index] = 0
			dwnRange = {}
			dwnRange[index] = 0
            cacheL = {}
            cacheL[index] = 0			
            cacheH = {}
            cacheH[index] = 0			
            cacheC = {}
            cacheC[index] = 0			
            rangeStart = {}
            rangeStart[index] = nil			
            prevRangeStart = {}
            prevRangeStart[index] = nil		
            
            calculated_buffer = {}
            
            lastRange = {}
            lastRange[index] = {0, 0}
            lastSignal = {}
            lastSignal[index] = {index, 0, nil}
            
			--- sx 
			sx={}
			sx[1] = p+1
			
			for mi=1, nn*2-2 do
				sum=0
				for n=1, p do
					sum = sum + math.pow(n,mi)
				end
			    sx[mi+1]=sum
			end
           
            return nil
		end
		
        if calculated_buffer[index] == nil then
            upRange[index] = upRange[index-1] 
            dwnRange[index] = dwnRange[index-1] 
            cacheL[index] = cacheL[index-1] 
            cacheH[index] = cacheH[index-1] 
            cacheC[index] = cacheC[index-1] 
            rangeStart[index] = rangeStart[index-1] 
            prevRangeStart[index] = prevRangeStart[index-1] 
            lastRange[index] = lastRange[index-1] 
            lastSignal[index] = lastSignal[index-1] 
        end
            
		if not CandleExist(index) then
			return nil
		end
		if index <= Size()-500 then
			return nil
		end

        cacheH[index] = H(index)
        cacheL[index] = L(index)
        cacheC[index] = C(index)
		
        if calculated_buffer[index] == nil then
            
            --WriteLog ("---------------------------------")
            --WriteLog ("OnCalc() ".."CandleExist("..index.."): "..tostring(CandleExist(index)).."; T("..index.."); "..isnil(toYYYYMMDDHHMMSS(T(index))," - "))
            --WriteLog ("C(index) "..tostring(C(index)).." H(index) "..tostring(H(index)).." L(index) "..tostring(L(index)))
            
            previous = rangeStart[index] or index-bars
            
            if not CandleExist(previous) then
                previous = FindExistCandle(previous)
            end
                        
            local maxC = cacheC[math.max(previous, 1)]
            local minC = cacheC[math.max(previous, 1)]      
            for i=math.max(previous, 1)+1,index-1 do
                maxC = math.max(cacheC[i], maxC)
                minC = math.min(cacheC[i], minC)
            end 

            local fx_buffer={}
            
            --- syx 
            for mi = 1, nn do
                sum = 0
                for n=0, p do
                    if CandleExist(index+n-bars) then
                        if mi==1 then
                            sum = sum + C(index+n-bars)
                        else
                            sum = sum + C(index+n-bars)*math.pow(n,mi-1)
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
                    return nil
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
            for n = 1, p do
                sum=0
                for kk=1, degree do
                    sum = sum + x[kk+1]*math.pow(n,kk)
                end
                fx_buffer[n]=x[1]+sum
            end

            calculated_buffer[index] = true

            -- Std 
            sq=0.0
            for n = 1, p do
                if CandleExist(index+n-bars) then
                    sq = sq + math.pow(C(index+n-bars)-fx_buffer[n],2)
                end
            end
            
            sq = math.sqrt(sq/(p-1))*kstd

            lastSignal[index][3] = nil				                

            local deltaRatio = math.abs(fx_buffer[#fx_buffer]-fx_buffer[1])*100/fx_buffer[1]

            if deltaRatio < ratioFactor and fx_buffer[#fx_buffer] < maxC and fx_buffer[#fx_buffer] > minC and math.abs(maxC-minC) < 2*sq then

                if rangeStart[index] == nil then
                    if prevRangeStart[index]~=nil then
                        if previous - prevRangeStart[index] < bars then
                            if lastSignal[index][1] > previous and lastSignal[index][2]~=0 then
                                SetValue(lastSignal[index][1], 3, nil)
                                lastSignal[lastSignal[index][1]][3] = nil				                
                            end
                            previous = prevRangeStart[index]
                            maxC = cacheC[math.max(previous, 1)]
                            minC = cacheC[math.max(previous, 1)]      
                            for i=math.max(previous, 1)+1,index-1 do
                                maxC = math.max(cacheC[i], maxC)
                                minC = math.min(cacheC[i], minC)
                            end 
                        end
                    end
                    rangeStart[index] = previous
                end

                out1 = maxC
                out2 = minC
                lastRange[index] = {out1, out2}
                for i=rangeStart[index],index do
                    SetValue(i, 1, out1)				
                    SetValue(i, 2, out2)				
                end

                lastSignal[index] = {index, 0, nil}
            else
                if rangeStart[index] ~=nil then
                    prevRangeStart[index] = rangeStart[index]    
                end
                rangeStart[index] = nil
            end

            if lastRange[index]~=nil then
                if (cacheC[index-1] > lastRange[index][1] and cacheC[index-2] <= lastRange[index][1] and lastSignal[index][2]~=1) then
                    lastSignal[index] = {index, 1, O(index)}
                    SetValue(lastSignal[index][1], 3, lastSignal[index][3])				                
                end
                if (cacheC[index-1] < lastRange[index][2] and cacheC[index-2] >= lastRange[index][2] and lastSignal[index][2]~=-1) then
                    lastSignal[index] = {index, -1, O(index)}
                    SetValue(lastSignal[index][1], 3, lastSignal[index][3])				                
                end
            end
            
        end
       
		return nil
		
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
