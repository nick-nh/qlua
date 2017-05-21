
Settings={}
Settings.period = 150
Settings.shift = 150
Settings.Name = "xHV"

---------------------------------------------------------------------------------------
function FFF()
	local CC={}
	local LL={}
	local VV={}	
	
	return function(ind,  _p,_N, _s)

		local index = ind
		local MAX = 0
		local MAXV = 0
		local MIN = 0
		local RR = 0
		local jj = 0
		local kk = 0
				
		if index == 1 then
			VV={}
			CC={}
			LL={}
	------------------
			VV[index]=V(index)
			CC[1]=0
			return nil
		end
	------------------------------		
		if not CandleExist(index) then
			return nil
		end
		
		VV[index]=V(index)
		
		for j = 1, _N do
			SetValue(index-_s-1, j, nil)
			SetValue(index-_s, j, nil)
		end
			
		if index < Size() then return nil end
			
		MAX = H(index)
		MIN = L(index)
			
		for i = 0, _p-1 do	
			if CandleExist(index-i) then
				MAX=math.max(MAX,H(index-i))
				MIN=math.min(MIN,L(index-i))
			end
		end
			----------------------------------------
		for i = 1, _N do CC[i]=0 end

		for i = 0, _p-1 do
			if CandleExist(index-i) then
				jj=math.floor( (H(index-i)-MIN)/(MAX-MIN)*(_N-1))+1
				kk=math.floor( (L(index-i)-MIN)/(MAX-MIN)*(_N-1))+1
				 for k=1,(jj-kk) do
					CC[kk+k-1]=CC[kk+k-1]+V(index-i)/(jj-kk)
				 end
			end
		end
			--------------------
		MAXV = 0
		for i = 1, _N do MAXV=math.max(MAXV,CC[i])end

		for i = 1, _N do
			CC[i]=math.floor(CC[i]/MAXV*50)
		end
			---------------------
		for i = 1, _N do
			LL[i]= i/_N*(MAX-MIN)+MIN
			if CC[i]==0 then LL[i]=nil end
		end
			
		for i = 1, _s do
			for j = 1, _N do
				if CC[j]>i then
					SetValue(index-_s+i, j, LL[j])
				else
					SetValue(index-_s+i, j, nil)
				end
			end
		end
		
		--for i = 51, 75 do
		--	for j = 1, _N do
		--		SetValue(index-75+i, j, nil)
		--	end
		--end
				

		--return unpack(LL)
		return nil
	end
end
---------------------------------------------------------------------------------------

function Init()
	Settings.line = {}
	for i = 1, 100 do
		Settings.line[i] = {}
		Settings.line[i] = {Color = RGB(255, 192, 0), Type = TYPE_LINE, Width = 2}
	end
	
	myFFF = FFF()
	return 100
end
function OnCalculate(index)
	return myFFF(index, Settings.period, 100, Settings.shift)
end