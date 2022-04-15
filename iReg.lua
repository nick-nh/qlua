--logfile=io.open("C:\\SBERBANK\\QUIK_SMS\\LuaIndicators\\qlua_log.txt", "w")

Settings =
	{
		Name = "*iReg",
		bars = 182,
		kstd1=1.0,
		kstd2=2.0,
		kstd3=3.0,
		kstd4=4.0,
		degree = 1, -- 1 linear, 2 parabolic, 3 third-power
		barsshift=0,
		showHistory=0,
		line=
			{
				{
					Name = "iReg",
					Color = RGB(0, 0, 255),
					Type = TYPE_LINE,
					Width = 1
				},
				{
					Name = "+iReg1",
					Color = RGB(0, 128, 0),
					Type = TYPE_LINE,
					Width = 1
				},
				{
					Name = "-iReg1",
					Color = RGB(192, 0, 0),
					Type = TYPE_DASHLINE,
					Width = 1
				},
				{
					Name = "+iReg2",
					Color = RGB(0, 128, 0),
					Type = TYPE_LINE,
					Width = 1
				},
				{
					Name = "-iReg2",
					Color = RGB(192, 0, 0),
					Type = TYPE_DASHLINE,
					Width = 1
				},
				{
					Name = "+iReg3",
					Color = RGB(0, 128, 0),
					Type = TYPE_LINE,
					Width = 1
				},
				{
					Name = "-iReg3",
					Color = RGB(192, 0, 0),
					Type = TYPE_DASHLINE,
					Width = 1
				},
				{
					Name = "+iReg4",
					Color = RGB(0, 128, 0),
					Type = TYPE_LINE,
					Width = 1
				},
				{
					Name = "-iReg4",
					Color = RGB(192, 0, 0),
					Type = TYPE_DASHLINE,
					Width = 1
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

    local fx_buffer={}
	local sx={}
	local calculated_buffer={}

	local out1 = nil
	local out2 = nil
	local out3 = nil
	local out4 = nil
	local out5 = nil
	local out6 = nil
	local out7 = nil
	local out8 = nil
	local out9 = nil
	local out10 = nil
	local out11 = nil
	local out12 = nil

	return function(ind, Fsettings)

		Fsettings	= (Fsettings or {})
		local index = ind
		local bars = Fsettings.bars or 182
		local kstd1 = Fsettings.kstd1 or 1
		local kstd2 = Fsettings.kstd2 or 2
		local kstd3 = Fsettings.kstd3 or 3
		local kstd4 = Fsettings.kstd4 or 4
		local barsshift = Fsettings.barsshift or 0
		local degree = Fsettings.degree or 1
		local showHistory = (Fsettings.showHistory or 0) == 1
		local index = ind


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

			out1 = nil
			out2 = nil
			out3 = nil
			out4 = nil
			out5 = nil
			out6 = nil
			out7 = nil
			out8 = nil
			out9 = nil
			out10 = nil

			fx_buffer = {}
			calculated_buffer = {}

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

		SetValue(index-bars-barsshift, 1, nil)
        SetValue(index-bars-barsshift, 2, nil)
        SetValue(index-bars-barsshift, 3, nil)
        SetValue(index-bars-barsshift, 4, nil)
        SetValue(index-bars-barsshift, 5, nil)
        SetValue(index-bars-barsshift, 6, nil)
        SetValue(index-bars-barsshift, 7, nil)
        SetValue(index-bars-barsshift, 8, nil)
        SetValue(index-bars-barsshift, 9, nil)

		if not CandleExist(index) or index <= bars then
			return nil
		end

        if index < (Size() - barsshift) and not showHistory then return nil end
		if index > (Size() - barsshift) then return nil end

		if calculated_buffer[index] ~= nil then
			return out1, out2, out3, out4, out5, out6, out7, out8, out9, out10, out11, out12
		end

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
		end

		--- Std
		sq=0.0
		for n=i0, i0+p do
			if CandleExist(index+n-bars) then
				sq = sq + math.pow(C(index+n-bars)-fx_buffer[n],2)
			end
		end

		sq = math.sqrt(sq/(p-1))

		if index == (Size() - barsshift) then
			for n=i0, i0+p do
				if kstd1 > 0 then
					SetValue(index+n-bars, 2, fx_buffer[n]+sq*kstd1)
					SetValue(index+n-bars, 3, fx_buffer[n]-sq*kstd1)
				end
				if kstd2 > 0 then
					SetValue(index+n-bars, 4, fx_buffer[n]+sq*kstd2)
					SetValue(index+n-bars, 5, fx_buffer[n]-sq*kstd2)
				end
				if kstd3 > 0 then
					SetValue(index+n-bars, 6, fx_buffer[n]+sq*kstd3)
					SetValue(index+n-bars, 7, fx_buffer[n]-sq*kstd3)
				end
				if kstd4 > 0 then
					SetValue(index+n-bars, 8, fx_buffer[n]+sq*kstd4)
					SetValue(index+n-bars, 9, fx_buffer[n]-sq*kstd4)
				end
			end
		end


		SetValue(index-bars, 1, nil)
        SetValue(index-bars, 2, nil)
        SetValue(index-bars, 3, nil)
        SetValue(index-bars, 4, nil)
        SetValue(index-bars, 5, nil)
        SetValue(index-bars, 6, nil)
        SetValue(index-bars, 7, nil)
        SetValue(index-bars, 8, nil)
        SetValue(index-bars, 9, nil)

		calculated_buffer[index] = true
		out1 = fx_buffer[bars]
		if kstd1 > 0 then
			out2 = fx_buffer[bars]+sq*kstd1
			out3 = fx_buffer[bars]-sq*kstd1
		end
		if kstd2 > 0 then
			out4 = fx_buffer[bars]+sq*kstd2
			out5 = fx_buffer[bars]-sq*kstd2
		end
		if kstd3 > 0 then
			out6 = fx_buffer[bars]+sq*kstd3
			out7 = fx_buffer[bars]-sq*kstd3
		end
		if kstd4 > 0 then
			out8 = fx_buffer[bars]+sq*kstd4
			out9 = fx_buffer[bars]-sq*kstd4
		end
		if showHistory then
			out10 = fx_buffer[bars]
			if kstd1 > 0 then
				out11 = fx_buffer[bars]+sq*kstd1
				out12 = fx_buffer[bars]-sq*kstd1
			end

		end

		return out1, out2, out3, out4, out5, out6, out7, out8, out9, out10, out11, out12

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

function WriteLog(text)

   logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n")
   logfile:flush()
   LASTLOGSTRING = text

end