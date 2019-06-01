--logfile=io.open(getWorkingFolder().."\\LuaIndicators\\rangeHV.txt", "w")

min_price_step = 0

Settings=
{
    Name                    = "*rangeFlatHV",
    period                  = 60,
    flat_bars               = 27,
    kstd                    = 1.5,
    ratioFactor             = 0.3,
    sqFactor                = 2,
    bars                    = 1000,
    clasters                = 100,
    showMaxVol              = 0,
    showVWAP                = 0,
    showEMAVWAP             = 1,
    emaPeriod               = 12,
    line =
    {       
        {
            Name = "maxVol",
            Color = RGB(127, 127, 127),
            Type = TYPET_BAR, --TYPE_DASHDOT,
            Width = 3
        },
        {
            Name = "VWAP",
            Color = RGB(64, 64, 64),
            Type = TYPET_LINE, --TYPE_DASHDOT,
            Width = 1
        },
        {
            Name = "EMAVWAP",
            Color = RGB(64, 64, 64),
            Type = TYPET_LINE, --TYPE_DASHDOT,
            Width = 1
        },
        {
            Name = "rangeVWAPMax",
            Color = RGB(89, 213, 107),
            Type = TYPET_BAR,
            Width = 2
        },
        {
            Name = "rangeVWAPMin",
            Color = RGB(251,82,0),
            Type = TYPET_BAR,
            Width = 2
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
        scale = getSecurityInfo(DSInfo.class_code, DSInfo.sec_code).scale
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
        if previous ==0 then
            return 0
        end
    
        return math.max(math.abs(H(i) - L(i)), math.abs(H(i) - C(previous)), math.abs(C(previous) - L(i)))
    else
        return C(i)
    end 
end

function rangeBar()
    
    local maxPrice          = {}
    local VWAP              = {}    

    local sx                = {}
    local prevRangeStart    = {}
    local rangeStart        = {}
    local lastRange         = {}

    local Close             = {}
    local Open              = {}
    local High              = {}
    local Low               = {}
    local CC                = {}
    local calculated_buffer = {}
    local calcAlgoValue     = {}
    local trend             = {}

    local EMA               = {}    
    local vEMA              = {}    
    
    local outMaxRange       = 0
    local outMinRange       = 0      


    return function(ind, Fsettings, ds)
    
        local Fsettings=(Fsettings or {})
        
        local index         = ind
        local periodHV      = Fsettings.period or 59
        local flat_bars     = Fsettings.flat_bars or 27
        local kstd          = Fsettings.kstd or 1
        local ratioFactor   = Fsettings.ratioFactor or 3
        local sqFactor      = Fsettings.sqFactor or 3
                
        local bars          = Fsettings.bars or 1000
        local clasters      = Fsettings.clasters or 50
        
        if bars == 0 then bars = Size()-100 end
                
        local showMaxVol            = Fsettings.showMaxVol or 0
        local showVWAP              = Fsettings.showVWAP or 0
        local showEMAVWAP           = Fsettings.showEMAVWAP or 0
        local emaPeriod             = Fsettings.emaPeriod or period
        
        local kvEMA = 2/(emaPeriod+1)
        
        local MAX = 0
        local MAXV = 0
        local MIN = 0
        local jj = 0
        local kk = 0
                
        local outMaxPrice = nil         
        local outVWAP = nil         

        local degree = 1
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
        
        p = flat_bars 
        nn = degree+1
        local maxRange          = 0
        local minRange          = 0      
    

        if index == 1 then
            maxPrice = {}
            maxPrice[index] = 0 

            VWAP = {}
            VWAP[index] = 0 

            Close = {}
            Close[index] = 0
            Open = {}
            Open[index] = 0
            High = {}
            High[index] = 0
            Low = {}
            Low[index] = 0
            
            calculated_buffer = {}
            trend = {}
            trend[index] = 1            
            calcAlgoValue = {}
            calcAlgoValue[index] = C(index)         
            
            
            if showEMAVWAP == 1 then
                vEMA = {}
                vEMA[index] = C(index)          
            end

            maxRange            = 0
            minRange            = 0      
            rangeStart = {}
            rangeStart[index] = nil         
            prevRangeStart = {}
            prevRangeStart[index] = nil     
            
            calculated_buffer = {}
            
            lastRange = {}
            lastRange[index] = {0, 0}
            
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
            
            maxPrice[index]         = maxPrice[index-1] 
            VWAP[index]       = VWAP[index-1] 

            High[index]             = High[index-1] 
            Low[index]              = Low[index-1] 
            Close[index]            = Close[index-1] 
            calcAlgoValue[index]    = calcAlgoValue[index-1] 
            trend[index]            = trend[index-1] 

            if showEMAVWAP == 1 then
                vEMA[index] = vEMA[index-1] 
            end

            rangeStart[index] = rangeStart[index-1] 
            prevRangeStart[index] = prevRangeStart[index-1] 
            lastRange[index] = lastRange[index-1] 

        end
        
        if not CandleExist(index) then
            return nil
        end

        local beginIndex = math.max(Size() - bars, periodHV, emaPeriod)
        
        if index == beginIndex then
            maxPrice[index] = C(index)      
            VWAP[index] = C(index)
            
            calcAlgoValue[index] = C(index)         

            if showEMAVWAP == 1 then
                vEMA[index] = C(index)
            end
        end

        Close[index] = C(index)         
        Open[index]  = O(index)         
        High[index]  = H(index)         
        Low[index]   = L(index)         

        if index < beginIndex - flat_bars then
            return nil
        end

        if showMaxVol == 1 then
            outMaxPrice = maxPrice[index]
        end
        if showVWAP == 1 then 
            outVWAP = VWAP[index]
        end
        if showEMAVWAP == 1 then
            outEMAVWAP = vEMA[index]
        end         
        
        if calculated_buffer[index]~=nil then
            return outMaxPrice, outVWAP, outEMAVWAP, outMaxRange, outMinRange
        end
                
        local previous = index-periodHV     

        local _p = index - previous

        if C(previous) == nil then
            previous = FindExistCandle(previous)
        end
        
        MAX = High[math.max(previous+1, 1)]
        MIN = Low[math.max(previous+1, 1)]      
        for i=math.max(previous+1, 1)+1,index do
            MAX = math.max(High[i], MAX)
            MIN = math.min(Low[i], MIN)
        end 

        for i = 1, clasters do CC[i]={0, i/clasters*(MAX-MIN)+MIN} end
        
        local numProf = 0
        local avgVol = 0

        VWAP[index] = 0
        local allVolume = 0

        for i = 0, _p-1 do
            if C(index-i) ~= nil then
                jj=math.floor( (H(index-i)-MIN)/(MAX-MIN)*(clasters-1))+1
                kk=math.floor( (L(index-i)-MIN)/(MAX-MIN)*(clasters-1))+1
                for k=1,(jj-kk) do
                    if CC[kk+k-1][1] == 0 then numProf = numProf + 1 end
                    CC[kk+k-1][1]=CC[kk+k-1][1]+V(index-i)/(jj-kk)
                    VWAP[index] = VWAP[index] + CC[kk+k-1][2]*V(index-i)/(jj-kk)
                    avgVol = avgVol + V(index-i)/(jj-kk)
                    allVolume = allVolume + V(index-i)/(jj-kk)
                end
            end
        end

        VWAP[index] = VWAP[index]/allVolume
        

        if showEMAVWAP == 1 then
            vEMA[index]=round(kvEMA*VWAP[index]+(1-kvEMA)*vEMA[index-1], 5)
        end
        
        if numProf > 0 then
            avgVol = round(avgVol/numProf, 5)
        else 
            avgVol = 0
        end
        
        for i = 1, clasters do 
            MAXV = math.max(MAXV, CC[i][1]) 
            if MAXV == CC[i][1] then
                maxPrice[index]=CC[i][2]
            end
        end

        -- range max price
        previous = rangeStart[index] or index-flat_bars
            
        if not CandleExist(previous) then
            previous = FindExistCandle(previous)
        end
                    
        local maxRange = maxPrice[math.max(previous, 1)]
        local minRange = maxPrice[math.max(previous, 1)]      
        --WriteLog('index: '..tostring(index)..', previous: '..tostring(previous)..', maxPrice prev: '..tostring(maxPrice[math.max(previous, 1)])..', maxPrice: '..tostring(maxPrice[index]))
        for i=math.max(previous, 1)+1,index-1 do
            maxRange = math.max(maxPrice[i], maxRange)
            minRange = math.min(maxPrice[i], minRange)
        end 

        --WriteLog('index: '..tostring(index)..', rangeStart: '..tostring(rangeStart[index])..', maxRange: '..tostring(maxRange)..', minRange: '..tostring(minRange))

        if index < beginIndex then
            return nil
        end

        local fx_buffer={}
        
        --- syx 
        for mi = 1, nn do
            sum = 0
            for n=0, p do
                if CandleExist(index+n-flat_bars) then
                    if mi==1 then
                        sum = sum + maxPrice[index+n-flat_bars]
                    else
                        sum = sum + maxPrice[index+n-flat_bars]*math.pow(n,mi-1)
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

        -- Std 
        sq=0.0
        for n = 1, p do
            if CandleExist(index+n-flat_bars) then
                sq = sq + math.pow(maxPrice[index+n-flat_bars]-fx_buffer[n],2)
            end
        end
        
        sq = math.sqrt(sq/(p-1))*kstd

        local deltaRatio = math.abs(fx_buffer[#fx_buffer]-fx_buffer[1])*100/fx_buffer[1]
        --WriteLog('fx_buffer: '..tostring(fx_buffer[#fx_buffer])..', fx_buffer[1]: '..tostring(fx_buffer[1])..', deltaRatio: '..tostring(deltaRatio)..', sq: '..tostring(sq))

        if  deltaRatio < ratioFactor and math.abs(maxRange-minRange) < sqFactor*sq
        then

            --WriteLog('deltaRatio < ratioFactor:  '..tostring(deltaRatio < ratioFactor))
            if rangeStart[index] == nil then
                if prevRangeStart[index]~=nil then
                    if previous - prevRangeStart[index] < flat_bars then
                        previous = prevRangeStart[index]
                        maxRange = maxPrice[math.max(previous, 1)]
                        minRange = maxPrice[math.max(previous, 1)]      
                        for i=math.max(previous, 1)+1,index-1 do
                            maxRange = math.max(maxPrice[i], maxRange)
                            minRange = math.min(maxPrice[i], minRange)
                        end 
                    end
                end
                rangeStart[index] = previous
            end

            lastRange[index] = {maxRange, minRange}
            for i=rangeStart[index],index do
                SetValue(i, 4, maxRange)                
                SetValue(i, 5, minRange)                
            end

        else
            if rangeStart[index] ~=nil then
                prevRangeStart[index] = rangeStart[index]    
            end
            rangeStart[index]   = nil
            outMaxRange         = nil
            outMinRange         = nil
        end

        -- range max price
                
        calculated_buffer[index] = maxPrice[index]
        if showMaxVol == 1 then
            outMaxPrice = maxPrice[index]
        end
        if showVWAP == 1 then 
            outVWAP = VWAP[index]
        end
        if showEMAVWAP == 1 then
            outEMAVWAP = vEMA[index]
        end         
                
        return outMaxPrice, outVWAP, outEMAVWAP, outMaxRange, outMinRange
        
    end
end

function WriteLog(text)

   logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n");
   logfile:flush();
   LASTLOGSTRING = text;

end

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
