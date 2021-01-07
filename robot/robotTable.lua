--[[
  “аблица создаетс€ исход€ из состава колонок. «аголовки колонок - это имена колонок.
  ¬се пол€ создаютс€ в указанной строке и колонке.
  ≈сли у пол€ указаны различные строки дл€ заголовка и дл€ значени€, то занимаетс€ два пол€ таблицы.
  ≈сли строка заголовка = 0, то это пол€ с заголовком не создаетс€ (дл€ первой строки заголовки уже заданы)
  Ќо если заголовки указать как 1, 2, 3, 4... то дл€ наименовани€ полей надо создавать и заголовки 
]]

--operations with main table
table_settings = {}
table_settings.columns_width      = {}
table_settings.columns_type       = {}
table_settings.columns_visibility = {}
table_settings.fields             = {}
table_settings.edit_fields        = {}

--«аголовки колонок.
table_settings.columns = {"Price", "Pos" , "Profit", "SL", "TP", "Algo", "INTERVAL", "State"} -- пор€док вывода колонок.

-- ширина колонок
table_settings.columns_width['Price']     = 15
table_settings.columns_width['Pos']       = 15
table_settings.columns_width['Profit']    = 15
table_settings.columns_width['SL']        = 15
table_settings.columns_width['TP']        = 15
table_settings.columns_width['Algo']      = 17
table_settings.columns_width['INTERVAL']  = 18
table_settings.columns_width['State']     = 25

-- видимость колонок
table_settings.columns_visibility['Price']     = true
table_settings.columns_visibility['Pos']       = true
table_settings.columns_visibility['Profit']    = true
table_settings.columns_visibility['SL']        = true
table_settings.columns_visibility['TP']        = true
table_settings.columns_visibility['Algo']      = true
table_settings.columns_visibility['INTERVAL']  = true
table_settings.columns_visibility['State']     = true

-- типы колонок
table_settings.columns_type['Price']          = QTABLE_DOUBLE_TYPE
table_settings.columns_type['Pos']            = QTABLE_DOUBLE_TYPE
table_settings.columns_type['Profit']         = QTABLE_DOUBLE_TYPE
table_settings.columns_type['SL']             = QTABLE_DOUBLE_TYPE
table_settings.columns_type['TP']             = QTABLE_DOUBLE_TYPE
table_settings.columns_type['Algo']           = QTABLE_DOUBLE_TYPE
table_settings.columns_type['INTERVAL']       = QTABLE_DOUBLE_TYPE
table_settings.columns_type['State']          = QTABLE_DOUBLE_TYPE
table_settings.columns_type['Price']          = QTABLE_DOUBLE_TYPE
table_settings.columns_type['Pos']            = QTABLE_DOUBLE_TYPE
table_settings.columns_type['Profit']         = QTABLE_DOUBLE_TYPE
table_settings.columns_type['SL']             = QTABLE_DOUBLE_TYPE
table_settings.columns_type['TP']             = QTABLE_DOUBLE_TYPE
table_settings.columns_type['Algo']           = QTABLE_DOUBLE_TYPE
table_settings.columns_type['INTERVAL']       = QTABLE_DOUBLE_TYPE
table_settings.columns_type['State']          = QTABLE_DOUBLE_TYPE

--ѕерва€ срока заполн€етс€ автоматически из строки заголовков
-- ” команд строка заголовка и строка значени€ совпадают
table_settings.fields['Price']          = {caption = '',              caption_line = 0, caption_col = 1, val_line = 1, val_col = 1, base_color = nil}
table_settings.fields['Pos']            = {caption = '',              caption_line = 0, caption_col = 2, val_line = 1, val_col = 2, base_color = nil}
table_settings.fields['Profit']         = {caption = '',              caption_line = 0, caption_col = 3, val_line = 1, val_col = 3, base_color = nil}
table_settings.fields['SL']             = {caption = '',              caption_line = 0, caption_col = 4, val_line = 1, val_col = 4, base_color = nil}
table_settings.fields['TP']             = {caption = '',              caption_line = 0, caption_col = 5, val_line = 1, val_col = 5, base_color = nil}
table_settings.fields['Algo']           = {caption = '',              caption_line = 0, caption_col = 6, val_line = 1, val_col = 6, base_color = nil}
table_settings.fields['INTERVAL']       = {caption = '',              caption_line = 0, caption_col = 7, val_line = 1, val_col = 7, base_color = nil}
table_settings.fields['State']          = {caption = '',              caption_line = 0, caption_col = 8, val_line = 1, val_col = 8, base_color = nil}
table_settings.fields['START']          = {caption = 'START',         caption_line = 2, caption_col = 1, val_line = 2, val_col = 1, base_color = RGB(165,227,128)}
table_settings.fields['QTY']            = {caption = '',              caption_line = 2, caption_col = 2, val_line = 2, val_col = 2, base_color = nil}
table_settings.fields['SELL']           = {caption = 'SELL',          caption_line = 2, caption_col = 3, val_line = 2, val_col = 3, base_color = RGB(255,168,164)}
table_settings.fields['BUY']            = {caption = 'BUY',           caption_line = 2, caption_col = 4, val_line = 2, val_col = 4, base_color = RGB(165,227,128)}
table_settings.fields['REVERSE']        = {caption = 'REVERSE',       caption_line = 2, caption_col = 5, val_line = 2, val_col = 5, base_color = RGB(200,200,200)}
table_settings.fields['CLOSE_ALL']      = {caption = 'CLOSE ALL',     caption_line = 2, caption_col = 6, val_line = 2, val_col = 6, base_color = RGB(255,168,164)}
table_settings.fields['KILL_ALL_SL']    = {caption = 'KILL ALL SL',   caption_line = 2, caption_col = 7, val_line = 2, val_col = 7, base_color = RGB(255,168,164)}
table_settings.fields['SET_SL_TP']      = {caption = 'SET SL/TP',     caption_line = 2, caption_col = 8, val_line = 2, val_col = 8, base_color = RGB(168,255,168)}
table_settings.fields['OPTIMIZE']       = {caption = 'OPTIMIZE',      caption_line = 3, caption_col = 7, val_line = 3, val_col = 7, base_color = nil}
table_settings.fields['ALL_PROFIT']     = {caption = '',              caption_line = 3, caption_col = 8, val_line = 3, val_col = 8, base_color = nil}
table_settings.fields['testSizeBars']   = {caption = 'testSizeBars',  caption_line = 4, caption_col = 5, val_line = 5, val_col = 5, base_color = nil}
table_settings.fields['ChartId']        = {caption = 'ChartId',       caption_line = 4, caption_col = 6, val_line = 5, val_col = 6, base_color = nil}
table_settings.fields['STOP_LOSS']      = {caption = 'SL',            caption_line = 4, caption_col = 7, val_line = 5, val_col = 7, base_color = nil}
table_settings.fields['TAKE_PROFIT']    = {caption = 'TP',            caption_line = 4, caption_col = 8, val_line = 5, val_col = 8, base_color = nil}

-- возможность редактировани€ колонок
table_settings.edit_fields['INTERVAL']        = true
table_settings.edit_fields['QTY']             = true
table_settings.edit_fields['testSizeBars']    = true
table_settings.edit_fields['ChartId']         = true
table_settings.edit_fields['STOP_LOSS']       = true
table_settings.edit_fields['TAKE_PROFIT']     = true


--—оздание объекта основной таблицы
MainTable = class(function(acc)
end)

--»нициализаци€
function MainTable:Init()
  self.t = nil --ID of table
end
 
--ќчистка таблицы
function MainTable:clearTable()

  for row = self.t:GetSize(), 1, -1 do
    DeleteRow(self.t.t_id, row)
  end  
  
end


--//TODO —делать вывод в одно поле заголовка, если задана одна колонка и строка дл€ заголовка и значени€

-- SHOW MAIN TABLE

--show main table on screen
function MainTable:showTable()
  self.t:Show()  
end

--show main table on screen
function MainTable:closeTable()
  if self.t == nil then return end
  self.t:delete()  
end

function MainTable:col_width(col_name)
  
	if table_settings.columns_width[col_name] ~= nil then
		return table_settings.columns_width[col_name]
	else
		return 15
	end

end

function MainTable:col_vis(col_name)
  
  if table_settings.columns_visibility[col_name]==true then
	  return self:col_width(col_name)
  end
  return 0
end

--creates main table
function MainTable:createTable(caption)

  -- create instance of table
  local t = QTable.new()
  if not t then
    message("error!", 3)
    return
  else
    --message("table with id = " ..t.t_id .. " created", 1)
  end

  --—оздаем колонки на основании описани€ строки колонок
  for i=1,#table_settings.columns do
    local key = table_settings.columns[i]
    t:AddColumn(key, table_settings.columns_type[key] or QTABLE_DOUBLE_TYPE, self:col_vis(key))  
  end

  t:SetCaption(caption)
  
  return t
  
end

function MainTable:createOwnTable(caption)
  self.t = self:createTable(caption)
  self.max_fields_row     = 0
  self.mutable_colums     = {} 
  self.added_algo_fields  = {} 
end

function MainTable:fillTable()

  --«аполн€ем элементы таблицы интерфейса
  for key, field in pairs(table_settings.fields) do
    local t_size = (self.t:GetSize())
    while t_size < field.caption_line or t_size < field.val_line do
      self.t:AddLine()
      t_size = (self.t:GetSize())
    end
    if field.caption_line > 0 then
      self.t:SetValue(field.caption_line, field.caption_col, field.caption, 0)
      self.t:SetColor(field.caption_line, field.caption_col, field.base_color or RGB(255,255,255), RGB(0,0,0), field.base_color or RGB(255,255,255), RGB(0,0,0))
    end
    if table_settings.edit_fields[key] then
      self.mutable_colums[tonumber(tostring(field.val_line)..tostring(field.val_col))] = true
    end
  end

  self.max_fields_row = (self.t:GetSize())
  
end

--¬ывод переменных алгоритма в таблицу
function MainTable:setTableAlgoParams(settingsAlgo, preset)

  for i=1,#self.added_algo_fields do
    self.t:SetValue(self.added_algo_fields[i][1], self.added_algo_fields[i][2], '', 0)
    self.t:SetColor(self.added_algo_fields[i][1], self.added_algo_fields[i][2], RGB(255,255,255), RGB(0,0,0), RGB(255,255,255), RGB(0,0,0))
  end

  local rows = (self.t:GetSize())
  if rows > self.max_fields_row then
    while rows > self.max_fields_row do
      self:DeleteLine(rows)
      rows = (self.t:GetSize())
    end        
  end
  
  self.added_algo_fields = {}

  for par, field in pairs(preset.fields) do
    local t_size = (self.t:GetSize())
    while t_size < field.caption_line or t_size < field.val_line do
      self.t:AddLine()
      t_size = (self.t:GetSize())
    end
    if field.caption_line > 0 then
      self.t:SetValue(field.caption_line, field.caption_col, field.caption, 0)
      self.t:SetColor(field.caption_line, field.caption_col, field.base_color or RGB(255,255,255), RGB(0,0,0), field.base_color or RGB(255,255,255), RGB(0,0,0))
      self.added_algo_fields[#self.added_algo_fields+1] = {field.caption_line, field.caption_col}
    end
    if field.val_line > 0 and settingsAlgo[par]~= nil then
      self.t:SetValue(field.val_line, field.val_col, tostring(settingsAlgo[par]), settingsAlgo[par])
      self.added_algo_fields[#self.added_algo_fields+1] = {field.val_line,field.val_col}
    end
    if preset.edit_fields[par] then
      self.mutable_colums[tonumber(tostring(field.val_line)..tostring(field.val_col))] = true
    end
  end

  rows = (self.t:GetSize())
  self.t:SetPosition(980, 120, 730, 27*rows) -- «адает положение и размеры окна таблицы

end

--„тение значений из таблицы в переменные алгоритма
function MainTable:readTableAlgoParams(preset)
  
  for par, field in pairs(preset.fields) do
    if isBoolSettings[par]==nil then
      Settings[par]  = self.t:GetValue(field.val_line, field.val_col).value
    else
      Settings[par]  = self.t:GetValue(field.val_line, field.val_col).value == 1
    end
    --≈сли в настройках алгоритма есть переопределенна€ глобальна€ переменна€, 
    --то записываем ее заначение в глобальную пееменную
    if Settings[par]~=nil and globalSettings[par]~=nil then
        globalSettings[par] = Settings[par]
        assert(loadstring(par..'= '..tostring(Settings[par])))()
    end
  end

end

function MainTable:is_it_editField(interface_line, interface_col)
	return self.mutable_colums[tonumber(tostring(interface_line)..tostring(interface_col))]~=nil
end

function MainTable:SetValue(field, value_view, value)
  if self.t == nil then return end
  if table_settings.fields[field]==nil then return end
  self.t:SetValue(table_settings.fields[field].val_line, table_settings.fields[field].val_col, value_view or '', value or 0)  
end

function MainTable:SetCaption(field, value_view, value)
  if self.t == nil then return end
  if table_settings.fields[field]==nil then return end
  self.t:SetValue(table_settings.fields[field].caption_line, table_settings.fields[field].caption_col, value_view or '', value or 0)  
end

function MainTable:GetValue(field, key)
  if self.t == nil then return end
  if table_settings.fields[field]==nil then return end
  key = key or (table_settings.columns_type[table_settings.columns[table_settings.fields[field].val_col]] == QTABLE_STRING_TYPE and 'image' or 'value')
  return self.t:GetValue(table_settings.fields[field].val_line, table_settings.fields[field].val_col)[key] 
end

function MainTable:GetCaption(field)
  if self.t == nil then return '' end
  if table_settings.fields[field]==nil then return end
  return self.t:GetValue(table_settings.fields[field].caption_line, table_settings.fields[field].caption_col)['image'] 
end

function MainTable:GetColValue(line, col, key)
  if type(line)~='number' then error('line must be number', 2) end
  if table_settings.columns[col]==nil or line > self.t:GetSize() then return nil end
  key = key or (table_settings.columns_type[table_settings.columns[col]] == QTABLE_STRING_TYPE and 'image' or 'value')
  return self.t:GetValue(line, col)[key] 
end

function MainTable:GetColType(col)
  if table_settings.columns[col]==nil then return nil end
  return table_settings.columns_type[table_settings.columns[col]]
end

function MainTable:SetColValue(line, col, value_view, value)
  if type(line)~='number' then error('line must be number', 2) end
  if table_settings.columns[col]==nil or line > self.t:GetSize() then return end
  self.t:SetValue(line, col, value_view or '', value or 0)  
end

function MainTable:is_it_Field(field, line, col)
  return table_settings.fields[field]~=nil and table_settings.fields[field].val_line == line and table_settings.fields[field].val_col == col
end

function MainTable:GetField(field)
  return table_settings.fields[field]
end

function MainTable:GetFieldName(line, col)
  for k,v in pairs(table_settings.fields) do
    if v.caption_line == line and v.caption_col == col then
      return k
    elseif v.val_line == line and v.val_col == col then
        return k    
    end
  end
end

function MainTable:SetColor(field, b_color, f_color, sel_b_color, sel_f_color, all_line)
  if self.t == nil then return end
  if table_settings.fields[field]==nil then return end
  self.t:SetColor(table_settings.fields[field].val_line, not all_line and table_settings.fields[field].val_col or QTABLE_NO_INDEX, b_color, f_color, sel_b_color, sel_f_color)
end

function MainTable:DeleteLine(line)
    if self.t == nil then return end
    DeleteRow(self.t.t_id, line)
end