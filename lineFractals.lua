--nnh Glukk Inc.
--modifide fractals

--logfile=io.open(getWorkingFolder().."\\LuaIndicators\\qlua_log.txt", "w")

lines = 50

Settings = {
Name = "*line Fractals", 
Period = 29,
line = {{
		Name = "FRACTALS - Down", 
		Type = TYPE_TRIANGLE_DOWN, 
		Color = RGB(255, 0, 0)
		},
		{
		Name = "FRACTALS - Up", 
		Type = TYPE_TRIANGLE_UP, 
		Color = RGB(0, 255, 0)
		}
		}
}

 -- Пользовательcкие функции
function myLog(text)

	logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n");
	logfile:flush();
	LASTLOGSTRING = text;
 
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

function Init() 
	func = FRACTALS()

	--добавляем линии
	for i = 1, lines do
		Settings.line[i+2] = {Color = RGB(0, 128, 255), Type = TYPET_BAR, Width = 1} --upLines
	end
	for i = lines+1, 2*lines do
		Settings.line[i+2] = {Color = RGB(255, 64, 0), Type = TYPET_BAR, Width = 1} --downLines
	end

	return #Settings.line
end

function OnCalculate(Index) 
	return func(Index, Settings)
end

function FRACTALS() --Fractals ("FRACTALS")
	
	local H_tmp={}
	local L_tmp={}

	--стеки линий
	local upLines = {}
	local downLines = {}
	local countUpLines = 0
	local countDownLines = 0

	return function (I, Fsettings, ds)

		local Fsettings=(Fsettings or {})
		local P = (Fsettings.Period or 5)

		P = math.floor(P/2)*2+1
		H_tmp[I]=Value(I,"High",ds)
		L_tmp[I]=Value(I,"Low",ds)

		if I == 1 then
			upLines = {}
			downLines = {}
			countUpLines = 0
			countDownLines = 0
			return nil
		end

		local high = Value(I,"High",ds)
		local low = Value(I,"Low",ds)
		--myLog("T("..tostring(I).."); "..isnil(toYYYYMMDDHHMMSS(T(I)))..' high '..tostring(high)..' low '..tostring(low))

		if I>=P then
			local S = I-P+1+math.floor(P/2)
			local val_h=math.max(unpack(H_tmp,I-P+1,I)) 
			local val_l=math.min(unpack(L_tmp,I-P+1,I))
			local L = Value(S,"Low",ds)
			local H = Value(S,"High",ds)
			if (val_h == H) and (val_h >0) 
				and (val_l == L) and (val_l > 0) then
					if ds then return S,S else
						SetValue(S, 1, val_l)
						SetValue(S, 2, val_h)
					end
			else
				if (val_h == H) and (val_h >0) then
					if ds then return S,nil else
						SetValue(S, 1, nil)
						SetValue(S, 2, val_h)
						countUpLines = countUpLines + 1
						if countUpLines > 50 then countUpLines = 1 end
						for i=S,I do
							SetValue(i, 2+countUpLines, val_h)
						end
						--myLog('-------- add up index '..tostring(S)..' val '..tostring(val_h)..' line '..tostring(countUpLines))
						upLines[countUpLines] = val_h
					end
				end
				if (val_l == L) and (val_l > 0) then
					if ds then return nil,S else
						SetValue(S, 1, val_l)
						SetValue(S, 2, nil)
						countDownLines = countDownLines + 1
						if countDownLines > 50 then countDownLines = 1 end
						for i=S,I do
							SetValue(i, 2+lines+countDownLines, val_l)
						end
						--myLog('-------- add down index '..tostring(S)..' val '..tostring(val_l)..' line '..tostring(countDownLines))
						downLines[countDownLines] = val_l
					end
				end
			end
			
		end
		
		--вывод линий
		local i=1
		while i<=lines do
			--myLog('up i '..tostring(i)..' val '..tostring(upLines[i]))
			if upLines[i]~=nil then
				SetValue(I-1, 2+i, upLines[i])
				if high>upLines[i] then
					--myLog('cleen up i '..tostring(i))
					upLines[i] = nil
					
					--компрессия стека, если произошел прорыв линии
					for j=i,lines-1 do
						upLines[j] = upLines[j+1]
						upLines[j+1] = nil
					end
					countUpLines = countUpLines-1
					i = i-1
				end
			end
			i = i+1
		end
		
		i=1
		while i<=lines do
			--myLog('down i '..tostring(i)..' val '..tostring(downLines[i]))
			if downLines[i]~=nil then
				SetValue(I-1, 2+lines+i, downLines[i])
				if low<downLines[i] then
					--myLog('cleen down i '..tostring(i))
					downLines[i] = nil

					--компрессия стека, если произошел прорыв линии
					for j=i,lines-1 do
						downLines[j] = downLines[j+1]
						downLines[j+1] = nil
					end
					countDownLines = countDownLines-1
					i = i-1
				end
			end
			i = i+1
		end
		
		--myLog('--------------------------------------')
		--myLog(' ')

		return nil,nil

	end
end

function Value(I,VType,ds) 
local Out = nil
VType=(VType and string.upper(string.sub(VType,1,1))) or "A"
	if VType == "O" then		--Open
		Out = (O and O(I)) or (ds and ds:O(I))
	elseif VType == "H" then 	--High
		Out = (H and H(I)) or (ds and ds:H(I))
	elseif VType == "L" then	--Low
		Out = (L and L(I)) or (ds and ds:L(I))
	elseif VType == "C" then	--Close
		Out = (C and C(I)) or (ds and ds:C(I))
	elseif VType == "V" then	--Volume
		Out = (V and V(I)) or (ds and ds:V(I)) 
	elseif VType == "M" then	--Median
		Out = ((Value(I,"H",ds) + Value(I,"L",ds)) / 2)
	elseif VType == "T" then	--Typical
		Out = ((Value(I,"M",ds) * 2 + Value(I,"C",ds))/3)
	elseif VType == "W" then	--Weighted
		Out = ((Value(I,"T",ds) * 3 + Value(I,"O",ds))/4) 
	elseif VType == "D" then	--Difference
		Out = (Value(I,"H",ds) - Value(I,"L",ds))
	elseif VType == "A" then	--Any
		if ds then Out = ds[I] end
	end
return Out
end
