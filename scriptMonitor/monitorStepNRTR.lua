smax1 = {}
smin1 = {}
trend = {}

function initstepNRTR()
    calcAlgoValue=nil
    smax1=nil
    smin1=nil
    trend=nil
end

function stepNRTR(ind, settings, DS)

    local Length = settings.Length or 29            -- perios        
    local Kv = settings.Kv or 1                     -- miltiply
    local StepSize = settings.StepSize or 0         -- fox stepSize
    local Percentage = settings.Percentage or 0
    local Switch = settings.Switch or 1             --1 - HighLow, 2 - CloseClose
    local Size = settings.Size or 1000 

    local ratio=Percentage/100.0*SEC_PRICE_STEP
    local smax0 = 0
    local smin0 = 0
    
    if ind == nil then ind = DS:Size() end
    
    Size = math.min(Size, DS:Size()) - 2

    calcAlgoValue = {}
    calcAlgoValue[ind] = 0			
    smax1 = {}
    smin1 = {}
    trend = {}
    smax1[ind-Size-1] = 0
    smin1[ind-Size-1] = 0
    trend[ind-Size-1] = 1


    for index = ind-Size, DS:Size() do    
        calcAlgoValue[index] = calcAlgoValue[index-1] 
        smax1[index] = smax1[index-1] 
        smin1[index] = smin1[index-1] 
        trend[index] = trend[index-1] 
        
        if DS:C(index) ~= nil then        
            local Step=StepSizeCalc(Length,Kv,StepSize,Switch,index)
            if Step == 0 then Step = 1 end
            
            local SizeP=Step*SEC_PRICE_STEP
            local Size2P=2*SizeP
            
            
            local result		
            local previous = index-1
            
            if DS:C(index) == nil then
                previous = FindExistCandle(previous)
            end
            
            if Switch == 1 then     
                smax0=DS:L(previous)+Size2P
                smin0=DS:H(previous)-Size2P    
            else   
                smax0=DS:C(previous)+Size2P
                smin0=DS:C(previous)-Size2P
            end
            
            if DS:C(index)>smax1[index] then trend[index] = 1 end
            if DS:C(index)<smin1[index] then trend[index]= -1 end

            if trend[index]>0 then
                if smin0<smin1[index] then smin0=smin1[index] end
                result=smin0+SizeP
            else
                if smax0>smax1[index] then smax0=smax1[index] end
                result=smax0-SizeP
            end
                
            smax1[index] = smax0
            smin1[index] = smin0
            
            if trend[index]>0 then
                calcAlgoValue[index]=(result+ratio/Step)-Step*SEC_PRICE_STEP
            end
            if trend[index]<0 then
                calcAlgoValue[index]=(result+ratio/Step)+Step*SEC_PRICE_STEP		
            end	
        end
    end	
            
    return calcAlgoValue 
    
end

function StepSizeCalc(Len, Km, Size, Switch, index)

    local result

    if Size == 0 then
        
        local Range=0.0
        local ATRmax=-1000000
        local ATRmin=1000000

        for iii=1, Len do	
            if DS:C(index-iii) ~= nil then				
                if Switch == 1 then     
                    Range=DS:H(index-iii)-DS:L(index-iii)
                else   
                    Range=math.abs(DS:O(index-iii)-DS:C(index-iii))
                end
                if Range>ATRmax then ATRmax=Range end
                if Range<ATRmin then ATRmin=Range end
            end
        end
        result = round(0.5*Km*(ATRmax+ATRmin)/SEC_PRICE_STEP, nil)
        
    else result=Km*Size
    end

    return result
end