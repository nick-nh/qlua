Settings={
	Name = "*Murrey Levels",
	period=64,
	stepback = 0,
	showOldLevels = 0,
	usegap = 0,
	line={
			{
				Name = "[-2/8]",
				Type =TYPE_CANDLE,
				Width = 2,
				Color = RGB(255,0, 255)
			},
			{
				Name = "[-1/8]",
				Type =TYPE_CANDLE,
				Width = 2,
				Color = RGB(255,191, 191)
			},
			{
				Name = "[0/8] Ћкончательное сопротивление",
				Type =TYPE_CANDLE,
				Width = 2,
				Color = RGB(0,128, 255)
			},
			{
				Name = "[1/8] ‘лабый, место для остановки и разворота",
				Type =TYPE_CANDLE,
				Width = 2,
				Color = RGB(218,188, 18)
			},
			{
				Name = "[2/8] ‚ращение, разворот",
				Type =TYPE_CANDLE,
				Width = 2,
				Color = RGB(255,0, 128)
			},
			{
				Name = "[3/8] „но торгового диапазона",
				Type =TYPE_CANDLE,
				Width = 2,
				Color = RGB(120,220, 235)
			},
			{
				Name = "[4/8] ѓлавный уровень поддержки/сопротивления",
				Type =TYPE_CANDLE,
				Width = 2,
				Color = RGB(128,128, 128)--green
			},
			{
				Name = "[5/8] ‚ерх торгового диапазона",
				Type =TYPE_CANDLE,
				Width = 2,
				Color = RGB(120,220, 235)
			},
			{
				Name = "[6/8] ‚ращение, разворот",
				Type =TYPE_CANDLE,
				Width = 2,
				Color = RGB(255,0, 128)
			},
			{
				Name = "[7/8] ‘лабый, место для остановки и разворота",
				Type =TYPE_CANDLE,
				Width = 2,
				Color = RGB(218,188, 18)
			},
			{
				Name = "[8/8] Ћкончательное сопротивление",
				Type =TYPE_CANDLE,
				Width = 2,
				Color = RGB(0,128, 255)
			},
			{
				Name = "[+1/8]",
				Type =TYPE_CANDLE,
				Width = 2,
				Color = RGB(255,191, 191)
			},
			{
				Name = "[+2/8]",
				Type =TYPE_CANDLE,
				Width = 2,
				Color = RGB(255,0, 255)
			}
		}
}


function Init()
	myMurreyMath = MurreyMath()
	return #Settings.line
end

function OnCalculate(index)

	return myMurreyMath(index, Settings)

end

function MurreyMath()
	
	local Buffer={}
	local cacheL = {}
	local cacheH = {}

	return function(ind, Fsettings)
		
		local index = ind
		local period = Fsettings.period or 64
		local stepback = Fsettings.stepback or 0
		local usegap = Fsettings.usegap or 0
		local showOldLevels = Fsettings.showOldLevels or 0
		
		local m = 0		
		local h = 0
		local fractal = 0
		local range = 0
		local sum = 0
		local mn = 0
		local mx = 0
		local octave = 0
		
		local indexshift = index - (period - 1)
		
		if index == 1 then
			 
			cacheL = {}
			cacheL[index] = 0			
			cacheH = {}
			cacheH[index] = 0			

			Buffer={}
			Buffer[index] = {}
			for nn = 1, 13 do
				Buffer[index][nn]=0
			end			
			 
			return nil
			
		end
 		
		cacheL[index] = cacheL[index-1] 
		cacheH[index] = cacheH[index-1] 

		Buffer[index] = {}
		for nn = 1, 13 do
			Buffer[index][nn] = Buffer[index-1][nn] 
		end
		
		if not CandleExist(index) then
			return nil
		end

		cacheH[index] = H(index)
        cacheL[index] = L(index)		

		if (index < (Size()-6) and showOldLevels == 0) or (index <= (period + stepback)) then 
			return nil 
		end
		
		for nn = 1, 13 do
			SetValue(Size()-6, nn, nil)
		end		

		--m = lowestLow(index,(period+stepback))
		--h = highestHigh(index,(period+stepback))
		m = math.min(unpack(cacheL,index-(period+stepback),index))
		h = math.max(unpack(cacheH,index-(period+stepback),index))

		fractal = DetermineFractal(h)
		range = h-m
		sum = math.floor(math.log(fractal/range)/math.log(2))
		octave=fractal*(math.pow(0.5,sum))
		
		mn = math.floor(m/octave)*octave
		mx = mn+(2*octave)		
		if (mn+octave) >= h then
			mx = mn+octave
		end
		
		-- calculating xx
		--x2
		local x2=0
		if ((m>=(3*(mx-mn)/16+mn)) and (h<=(9*(mx-mn)/16+mn))) then
			x2=mn+(mx-mn)/2
		end  
		--x1
		local x1=0
		if ((m>=(mn-(mx-mn)/8)) and (h<=(5*(mx-mn)/8+mn)) and (x2==0)) then
			x1=mn+(mx-mn)/2
		end  

		--x4
		local x4=0
		if ((m>=(mn+7*(mx-mn)/16)) and (h<=(13*(mx-mn)/16+mn))) then
			x4=mn+3*(mx-mn)/4
		end  

		--x5
		local x5=0
		if ((m>=(mn+3*(mx-mn)/8)) and (h<=(9*(mx-mn)/8+mn)) and (x4==0)) then
			x5=mx
		end  

		--x3
		local x3=0
		if ((m>=(mn+(mx-mn)/8)) and (h<=(7*(mx-mn)/8+mn)) and (x1==0) and (x2==0) and (x4==0) and (x5==0)) then
			x3=mn+3*(mx-mn)/4
		end  

		--x6
		local x6=0
		if (x1+x2+x3+x4+x5)==0 then
			x6=mx
		end  

		local finalH=x1+x2+x3+x4+x5+x6
		-- calculating yy
		--y1
		local y1=0
		if x1>0 then
			y1=mn
		end  

		--y2
		local y2=0
		if x2>0 then
			y2=mn+(mx-mn)/4
		end  

		--y3
		local y3=0
		if x3>0 then
			y3=mn+(mx-mn)/4
		end  

		--y4
		local y4=0
		if x4>0 then
			y4=mn+(mx-mn)/2
		end  

		--y5
		local y5=0
		if x5>0 then
			y5=mn+(mx-mn)/2
		end  

		--y6
		local y6=0
		if finalH>0 and (y1+y2+y3+y4+y5)==0 then
			y6=mn
		end  
		
		local finalL = y1+y2+y3+y4+y5+y6
		
		local dmml = (finalH-finalL)/8		
			
		Buffer[index][1]=(finalL-dmml*2) ---2/8
		for nn = 2, 13 do
			Buffer[index][nn]=Buffer[index][nn-1]+dmml
		end

		if usegap and Buffer[index-1][1]~=nil and Buffer[index][1] ~= Buffer[index-1][1] then
			return nil
		end
		
		return unpack(Buffer[index])
				
	end
end

function DetermineFractal(v)
  
   if v<=250000 and v>25000 then
      return 100000
   end
   if v<=25000 and v>2500 then
      return 10000
   end
   if v<=2500 and v>250 then
      return 1000
   end
   if v<=250 and v>25 then
      return 100
   end
   if v<=25 and v>12.5 then
      return 12.5
   end
   if v<=12.5 and v>6.25 then
      return 12.5
   end
   if v<=6.25 and v>3.125 then
      return 6.25
   end
   if v<=3.125 and v>1.5625 then
      return 3.125
   end
   if v<=1.5625 and v>0.390625 then
      return 1.5625
   end
   if v<=0.390625 and v>0 then
      return 0.1953125
   end
   
   return 0
   
 end

function round(num, idp)
	if idp and num then
	   local mult = 10^(idp or 0)
	   if num >= 0 then return math.floor(num * mult + 0.5) / mult
	   else return math.ceil(num * mult - 0.5) / mult end
	else return num end
end
  
function highestHigh(index, period)

	if index == 1 then
		return 0
	else

		local highestHigh = H(index)
		
		for i = math.max(index - period, 2), index, 1 do
			
			if H(i) > highestHigh then
				highestHigh = H(i)
			end
			
		end
	
		return highestHigh 
	
	end
end

function lowestLow(index, period)

	if index == 1 then
		return 0
	else

		local lowestLow = L(index)
		
		for i = math.max(index - period, 2), index, 1 do
						
			if L(i) < lowestLow then
				lowestLow = L(i)
			end
			
		end
	
		return lowestLow 
	
	end
end
