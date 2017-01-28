
Settings = 
{
	Name = "*THV Coral",
	period = 30,
	koef = 1,
	line=
	{
		{
			Name = "g_ibuf_92",
			Color = RGB(255, 255, 2),
			Type = TYPE_POINT,
			Width = 2
		},
		{
			Name = "g_ibuf_96",
			Color = RGB(0, 255, 0),
			Type = TYPE_POINT,
			Width = 2
		}
	,
		{
			Name = "g_ibuf_100",
			Color = RGB(255, 0, 0),
			Type = TYPE_POINT,
			Width = 2
		}
	}
}

----------------------------------------------------------
function cached_THV()
	
	local g_ibuf_92={}
	local g_ibuf_96={}
	local g_ibuf_100={}
	local g_ibuf_104={}
	local gda_108={}
	local gda_112={}
	local gda_116={}
	local gda_120={}
	local gda_124={}
	local gda_128={}
	
	return function(ind, _p, _k)
		local period = _p
		local index = ind
		local koef = _k

		local ild_0
		local ld_8

		local gd_188 = koef * koef
		local gd_196 = 0
		local gd_196 = gd_188 * koef
		local gd_132 = -gd_196
		local gd_140 = 3.0 * (gd_188 + gd_196)
		local gd_148 = -3.0 * (2.0 * gd_188 + koef + gd_196)
		local gd_156 = 3.0 * koef + 1.0 + gd_196 + 3.0 * gd_188
		local gd_164 = period
		if gd_164 < 1.0 then gd_164 = 1 end
		gd_164 = (gd_164 - 1.0) / 2.0 + 1.0
		local gd_172 = 2 / (gd_164 + 1.0)
		local gd_180 = 1 - gd_172
		
		if index == 1 then
			g_ibuf_92={}
			g_ibuf_96={}
			g_ibuf_100={}
			g_ibuf_104={}
			gda_108={}
			gda_112={}
			gda_116={}
			gda_120={}
			gda_124={}
			gda_128={}
			
			g_ibuf_92[index]=0
			g_ibuf_96[index]=0
			g_ibuf_100[index]=0
			g_ibuf_104[index]=0
			gda_108[index]=0
			gda_112[index]=0
			gda_116[index]=0
			gda_120[index]=0
			gda_124[index]=0
			gda_128[index]=0
			
			return nil,nil,nil
		end
		  
			
		  gda_108[index] = gd_172 * C(index) + gd_180 * (gda_108[index - 1])
		  gda_112[index] = gd_172 * (gda_108[index]) + gd_180 * (gda_112[index - 1])
		  gda_116[index] = gd_172 * (gda_112[index]) + gd_180 * (gda_116[index - 1])
		  gda_120[index] = gd_172 * (gda_116[index]) + gd_180 * (gda_120[index - 1])
		  gda_124[index] = gd_172 * (gda_120[index]) + gd_180 * (gda_124[index - 1])
		  gda_128[index] = gd_172 * (gda_124[index]) + gd_180 * (gda_128[index - 1])
		  g_ibuf_104[index] = gd_132 * (gda_128[index]) + gd_140 * (gda_124[index]) + gd_148 * (gda_120[index]) + gd_156 * (gda_116[index])
		  ld_0 = g_ibuf_104[index]
		  ld_8 = g_ibuf_104[index-1]
		  g_ibuf_92[index] = ld_0
		  g_ibuf_96[index] = ld_0
		  g_ibuf_100[index] = ld_0
		  
		  if ld_8 > ld_0 then 
			g_ibuf_96[index] = nil 
		  else 
			if ld_8 < ld_0 then 
				g_ibuf_100[index] = nil 
			else 
				g_ibuf_92[index] = nil 
			end
		  end
	     
	return g_ibuf_92[index], g_ibuf_96[index], g_ibuf_100[index]	
	
	end	
	
end
----------------------------

function Init()
	
	myTHV = cached_THV()
	return 3
end

function OnCalculate(index)
	return myTHV(index, Settings.period, Settings.koef)
end

