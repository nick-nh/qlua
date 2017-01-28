
Settings = 
{
	Name = "*Ehlers Instantaneous Trend",
	alpha = 0.07,
	cycletype = 1, -- 0 - simle, 1 - adaptive
	line=
	{
		{
			Name = "Trend",
			Color = RGB(0, 128, 0),
			Type = TYPE_LINE,
			Width = 2
		}
	,
		{
			Name = "Trigger",
			Color = RGB(255, 0, 0),
			Type = TYPE_LINE,
			Width = 2
		}
	}
}

----------------------------------------------------------
function CyberCycle()
	
	local Price={}
	local Smooth={}
	local Cycle={}
	local it={}
	local Trigger={}
	local CyclePeriod={}
	local InstPeriod={}
	local Q1={}
	local I1={}
	local DeltaPhase={}
	
	--local SMA=fSMA()
	
	return function(ind, _a, _t)
		
		local index = ind
		local alpha = _a
		local alpha1 = _a
		local cycletype = _t
				
		local DC, MedianDelta
		
		if index == 1 then
			Price = {}
			Smooth={}
			Cycle={}
			it={}
			Trigger={}
			CyclePeriod={}
			InstPeriod={}
			Q1={}
			I1={}
			DeltaPhase={}
			
			Price[index] = (H(index) + L(index))/2
			Smooth[index]=0
			Cycle[index]=0
			it[index]=0
			Trigger[index]=0
			CyclePeriod[index]=0
			InstPeriod[index]=0
			Q1[index]=0
			I1[index]=0
			DeltaPhase[index]=0
			return nil, nil
		end
		
		Price[index] = (H(index) + L(index))/2
		
		if index < 4 then
			Cycle[index]=0
			it[index]=0
			CyclePeriod[index]=0
			InstPeriod[index]=0
			Q1[index]=0
			I1[index]=0
			DeltaPhase[index]=0
			return nil, nil
		end       
		
		Cycle[index]=(Price[index]-2.0*Price[index - 1]+Price[index - 2])/4.0
		
		if cycletype == 1 then
							
			Smooth[index] = (Price[index]+2*Price[index - 1]+2*Price[index - 2]+Price[index - 3])/6.0
			
			if index < 7 then
				it[index]=0
				CyclePeriod[index]=0
				InstPeriod[index]=0
				Q1[index]=0
				I1[index]=0
				DeltaPhase[index]=0
				return nil, nil
			end
						
			Cycle[index]=(1.0-0.5*alpha) *(1.0-0.5*alpha) *(Smooth[index]-2.0*Smooth[index - 1]+Smooth[index - 2])
							+2.0*(1.0-alpha)*Cycle[index - 1]-(1.0-alpha)*(1.0-alpha)*Cycle[index - 2]			   
					
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
		
		lag = 2.0*it[index]-(it[index-2] or 0)

		
		return lag, it[index]
	end
end


function Init()
	myCyberCycle = CyberCycle()
	return #Settings.line
end

function OnCalculate(index)

	return myCyberCycle(index, Settings.alpha, Settings.cycletype)
end

function Median(x, y, z)     
   return (x+y+z) - math.min(x,math.min(y,z)) - math.max(x,math.max(y,z)) 
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