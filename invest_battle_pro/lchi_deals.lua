local is_dark = _G.isDarkTheme()
local log_file  = io.open(_G.getScriptPath()..'\\lchi.log', 'w')

-- Lua implementation of PHP scandir function
---@param directory string
local function ScanDir(directory)
    if type(directory) ~= 'string' then  error(("bad argument directory (string expected, got %s)"):format(type(directory)),2) end

    local i, t, popen = 0, {}, io.popen
    for filename in popen('dir "'..directory..'" /b'):lines() do
        i = i + 1
        t[i] = filename
    end
    return t
end

function main()
 
    local iif = function( cond, ifTrue, ifFalse )
 
        if( cond ) then return ifTrue; end
        return ifFalse;
    end;
	local function trim(s)
		return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
	end
    local trades = {};
    local charts = {};
 
	local files = ScanDir(getScriptPath()..'//deals//')
	
    for i=1,#files do
        local file_name = files[i]
        if file_name:find('csv') then
			log_file:write('find deals file '..tostring(file_name)..'\n')
			for line in io.lines( getScriptPath() .. "//deals//"..file_name ) do
		 
				local t = {};	 
				for w in string.gmatch( line, "([^;]+)" ) do		 
					table.insert( t, trim(w) );
				end		 
				local trade =
				{
					timestamp = t[1],
					ticker = t[2],
					chart_id = ((t[2]:match('%a%a%a%d')) and t[2]:sub(1,2) or t[2]),
					lots = tonumber( t[ 3 ] ),
					price = tonumber( t[ 4 ] ),
					date = string.gsub( string.match( t[ 1 ], "(%d+-%d+-%d+)" ), "-", "" ),
					time = string.gsub( string.match( t[ 1 ], "(%d+:%d+:%d+)" ), ":", "" )
				};
				charts[trade.ticker] = charts[trade.ticker] or {}			
				charts[trade.ticker].deals = (charts[trade.ticker].deals or 0) + 1;	 
				charts[trade.ticker].chart_id = trade.chart_id;	 
				table.insert( trades, trade );    
			end
        end
    end
 
 
	log_file:write('---------------------------------------------------\n')	
   for code, val in pairs(charts) do
		log_file:write('code:  '..tostring(code)..', chart_id:  '..tostring(val.chart_id)..', deals: '..tostring(val.deals)..'\n')	
        DelAllLabels(val.chart_id);
    end
 
	local image_path = getScriptPath() .. "//images//"

    for _, t in pairs( trades ) do
 
        local label = {};
        label.TEXT = '';
        label.YVALUE = t.price;
        label.DATE = t.date;
        label.TIME = t.time;
        label.R = iif( t.lots > 0, 0, 255 );
        label.G = iif( t.lots > 0, 255, 0 );
        label.B = 0;
        label.FONT_FACE_NAME = "Arial";
        label.FONT_HEIGHT = 10;
		label.ALIGNMENT = t.lots > 0 and 'BOTTOM' or 'TOP'
        label.HINT = t.timestamp..' '..(t.lots > 0 and 'BUY ' or 'SELL ')..tostring(math.abs(t.lots)) .. " | " .. tostring(t.price);
		label.IMAGE_PATH = image_path..(t.lots > 0 and 'buy' or 'sell')..(is_dark and '_dark' or '')..'.bmp'
		label.TRANSPARENT_BACKGROUND = 1
 
        local labelId = AddLabel( t.chart_id, label );
    end
end