--logfile=io.open("C:\\SBERBANK\\QUIK_SMS\\LuaIndicators\\qlua_log.txt", "w")

Settings = 
	{
		Name = "*iReg",
		bars = 182,
		kstd=2,
		degree = 3, -- 1 linear, 2 parabolic, 3 third-power 
		barsshift=0,
		showHistory=0,
		line=
			{
				{
					Name = "iReg",
					Color = RGB(0, 0, 255),
					Type = TYPE_LINE,
					Width = 2
				},
				{
					Name = "+iReg",
					Color = RGB(0, 128, 0),
					Type = TYPE_LINE,
					Width = 2
				},
				{
					Name = "-iReg",
					Color = RGB(192, 0, 0),
					Type = TYPE_DASHLINE,
					Width = 2
				},
				{
					Name = "iRegHist",
					Color = RGB(0, 0, 255),
					Type = TYPE_DASH,
					Width = 1
				},
				{
					Name = "+iRegHist",
					Color = RGB(0, 128, 0),
					Type = TYPE_DASH,
					Width = 1
				},
				{
					Name = "-iRegHist",
					Color = RGB(192, 0, 0),
					Type = TYPE_DASH,
					Width = 1
				}
			}
	}

----------------------------------------------------------
----------------------------------------------------------
----------------------------------------------------------
function Reg()
            
	local sql_buffer={}
    local sqh_buffer={}
    local fx_buffer={}
	local sx={}
	local calculated_buffer={}
	        
 	return function(ind, Fsettings)
		
		local Fsettings=(Fsettings or {})
		local index = ind
		local bars = Fsettings.bars or 182
		local kstd = Fsettings.kstd or 2
		local barsshift = Fsettings.barsshift or 0
		local degree = Fsettings.degree or 1
		local showHistory = Fsettings.showHistory or 0
		local index = ind

		local out1 = nil
		local out2 = nil
		local out3 = nil
		local out4 = nil
		local out5 = nil
		local out6 = nil
		
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
			calculated_buffer = {}
			
			sql_buffer[index]= 0
			sqh_buffer[index]= 0
			fx_buffer[index]= 0

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
			
			return nil
		end
				
		sql_buffer[index] = sql_buffer[index-1]	
		sqh_buffer[index] = sqh_buffer[index-1]	
		fx_buffer[index] = fx_buffer[index-1]
 		
		out1 = fx_buffer[bars]
		out2 = sqh_buffer[bars]
		out3 = sql_buffer[bars]

		SetValue(index-bars-barsshift, 1, nil)
        SetValue(index-bars-barsshift, 2, nil)
        SetValue(index-bars-barsshift, 3, nil)
       
		if not CandleExist(index) or index <= bars then
			return nil
		end

        if index < (Size() - barsshift) and showHistory == 0 then return nil end
		if index > (Size() - barsshift) then return nil end
        if calculated_buffer[index] ~= nil then return nil end		
		 
		--- syx 
		for mi=1, nn do
			sum = 0
			for n=i0, i0+p do
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
		for n=i0, i0+p do
			sum=0
			for kk=1, degree do
				sum = sum + x[kk+1]*math.pow(n,kk)
			end
			fx_buffer[n]=x[1]+sum
			if index == (Size() - barsshift) then
				SetValue(index+n-bars, 1, fx_buffer[n])
			end
			if n == i0+p and showHistory == 1 then
				out4 = fx_buffer[n]
			end
		end
			 
		--- Std 
		sq=0.0
		for n=i0, i0+p do
			if CandleExist(index+n-bars) then
				sq = sq + math.pow(C(index+n-bars)-fx_buffer[n],2)
			end
		end
		   
		sq = math.sqrt(sq/(p-1))*kstd

		for n=i0, i0+p do
			sqh_buffer[n]=fx_buffer[n]+sq
			sql_buffer[n]=fx_buffer[n]-sq
			if index == (Size() - barsshift) then
				SetValue(index+n-bars, 2, sqh_buffer[n])
	            SetValue(index+n-bars, 3, sql_buffer[n])
			end
			if n == i0+p and showHistory == 1 then
				out5 = sqh_buffer[n]
				out6 = sql_buffer[n]
			end
		end
						
		SetValue(index-bars, 1, nil)
        SetValue(index-bars, 2, nil)
        SetValue(index-bars, 3, nil)
		
		calculated_buffer[index] = true
		out1 = fx_buffer[bars]
		out2 = sqh_buffer[bars]
		out3 = sql_buffer[bars]
		
		return out1, out2, out3, out4, out5, out6 
	
	end
	
end
----------------------------    ----------------------------    ----------------------------
----------------------------    ----------------------------    ----------------------------
----------------------------    ----------------------------    ----------------------------
function FindExistCandle(I)

	local out = I
	
	while not CandleExist(out) and out > 0 do
		out = out -1
	end	
	
	return out
 
end

 function Init()
	myfunc = Reg()
	return #Settings.line
 end
 
function OnCalculate(index)
	
	--WriteLog ("OnCalc() ".."CandleExist("..index.."): "..tostring(CandleExist(index)))

	if Settings.degree > 3 then
		return nil
	end
	
	return myfunc(index, Settings)
 end
 
 -- РџРѕР»СЊР·РѕРІР°С‚РµР»СЊcРєРёРµ С„СѓРЅРєС†РёРё
function WriteLog(text)

   logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n")
   logfile:flush()
   LASTLOGSTRING = text

end
