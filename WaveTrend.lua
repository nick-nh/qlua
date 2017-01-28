
Settings = 
{
	Name = "*WaveTrend",
	ChannelLength = 7,
	AverageLength = 30,
	line=
	{
		{
			Name = "wt1",
			Color = RGB(0, 128, 0),
			Type = TYPE_LINE,
			Width = 2
		}
	,
		{
			Name = "wt2",
			Color = RGB(128, 0, 0),
			Type = TYPE_POINT,
			Width = 2
		}
	,
		{
			Name = "wt1-wt2",
			Color = RGB(150, 150, 150),
			Type = TYPE_HISTOGRAM,
			Width = 2
		}
	,	
		{
			Name = "53",
			Color = RGB(230, 240, 8),
			Type = TYPE_LINE,
			Width = 1
		}
	,	
		{
			Name = "-53",
			Color = RGB(230, 240, 8),
			Type = TYPE_LINE,
			Width = 1
		}
	,	
		{
			Name = "60",
			Color = RGB(80, 170, 255),
			Type = TYPE_LINE,
			Width = 1
		}
	,	
		{
			Name = "-60",
			Color = RGB(80, 170, 255),
			Type = TYPE_LINE,
			Width = 1
		}
	}
}

----------------------------------------------------------

function WaveTrend()
	
	local esa={}
	local d={}
	local wt1={}
	local wt2={}
	
	local SMA=fSMA()
	
	return function(ind, _c, _a)
		local index = ind
		local n1 = _c
		local n2 = _a
		
		local ci = 0		
		local k = 2/(n1+1)
		local kk = 2/(n2+1)
		
		if index == 1 then
			esa = {}
			d={}
			wt1={}
			wt2={}
			
			esa[index]=0
			d[index]=0
			wt1[index]=0
			wt2[index]=0
			return nil, nil, nil, 53, -53, 60, -60
		end
		
		ap = (H(index) + L(index) + C(index))/3
		
		
		esa[index] = k*ap+(1-k)*esa[index-1]
		d[index] = k*math.abs(ap - esa[index])+(1-k)*d[index-1]
		ci = (ap - esa[index]) / (0.015 * d[index])
		wt1[index] = kk*ci+(1-kk)*wt1[index-1]
		
		wt2[index] = SMA(index, 4, wt1)
		
		return wt1[index], wt2[index], wt1[index] - wt2[index], 53, -53, 60, -60
				
	end
end
	----------------------------

function Init()
	myWaveTrend = WaveTrend()
	return #Settings.line
end

function OnCalculate(index)

	return myWaveTrend(index, Settings.ChannelLength, Settings.AverageLength)
end

function fSMA()
		
	return function (Index, Period, bb)
		
		local Out = 0
		   
		   if Index >= Period then
			  local sum = 0
			  for i = Index-Period+1, Index do
				 sum = sum + bb[i]
			  end
			  Out = sum/Period
		   end
		   
		return Out
	end
end