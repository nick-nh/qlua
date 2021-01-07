function class(base, init)
  local c = {}
  if not init and type(base) == "function" then
    init = base
    base = nil
  elseif type(base) == "table" then
    for i, v in pairs(base) do
      c[i] = v
    end
    c._base = base
  end
  c.__index = c
  local mt = {}
  function mt.__call(class_tbl, ...)
    local obj = {}
    setmetatable(obj, c)
    if init then
      init(obj, ...)
    elseif base and base.init then
      base.init(obj, ...)
    end
    return obj
  end
  c.init = init
  function c:is_a(klass)
    local m = getmetatable(self)
    while m do
      if m == klass then
        return true
      end
      m = m._base
    end
    return false
  end
  setmetatable(c, mt)
  return c
end

-- ===========================================================================
-- Перегрузка ткласса аблицы
-- ===========================================================================

QTable ={}
QTable.__index = QTable

-- Создать и инициализировать экземпляр таблицы QTable
function QTable.new()
	local t_id = AllocTable()
	if t_id ~= nil then
		q_table = {}
		setmetatable(q_table, QTable)
		q_table.t_id=t_id
		q_table.caption = ""
		q_table.created = false
		q_table.curr_col=0
		-- таблица с описанием параметров столбцов
		q_table.columns={}
		return q_table
	else
		return nil
	end
end

function QTable:Show()
	-- отобразить в терминале окно с созданной таблицей
	CreateWindow(self.t_id)
	if self.caption ~="" then
		-- задать заголовок для окна
		SetWindowCaption(self.t_id, self.caption)
	end
	self.created = true
end
function QTable:IsClosed()
	-- если окно с таблицей закрыто, возвращает «true»
	return IsWindowClosed(self.t_id)
end

function QTable:delete()
	-- удалить таблицу
	DestroyTable(self.t_id)
end

function QTable:GetCaption()
	if IsWindowClosed(self.t_id) then
		return self.caption
	else
		-- возвращает строку, содержащую заголовок таблицы
		return GetWindowCaption(self.t_id)
	end
end

-- Задать заголовок таблицы
function QTable:SetCaption(s)
	self.caption = s
	if not IsWindowClosed(self.t_id) then
		res = SetWindowCaption(self.t_id, tostring(s))
	end
end

-- Добавить описание столбца <name> типа <c_type> в таблицу
-- <ff> – функция форматирования данных для отображения
function QTable:AddColumn(name, c_type, width, ff )
	local col_desc			= {}
	self.curr_col			= self.curr_col+1
	col_desc.c_type 		= c_type
	col_desc.format_function= ff
	col_desc.id 			= self.curr_col
	self.columns[name] 		= col_desc
	-- <name> используется в качестве заголовка таблицы
	AddColumn(self.t_id, self.curr_col, name, true, c_type, width)
end

function QTable:Clear()
	-- очистить таблицу
	Clear(self.t_id)
end

-- Установить значение в ячейке
--row - Номер строки (начинается с нуля)
function QTable:SetValue(row, col_name, data_view, data)

	local col_ind = col_name
	if type(col_name) == 'string' then col_ind = self.columns[col_name].id or nil end
	if col_ind == nil then
		return false
	end
	-- если для столбца задана функция форматирования, то она используется
	local ff
	if type(col_name) == 'string' then
		ff = self.columns[col_name].format_function
	end
	--myLog('data_view '..tostring(data_view)..', col_name '..tostring(col_name)..', col_ind '..tostring(col_ind)..', ff '..tostring(ff))
	if type(ff) == "function" then
		-- в качестве строкового представления используется
		-- результат выполнения функции форматирования
		SetCell(self.t_id, row, col_ind, ff(data), data or 0)
		return true
	else
		SetCell(self.t_id, row, col_ind, data_view or '', data or 0)
	end
end

function QTable:AddLine(key)
	-- добавляет в конец таблицы пустую строчку и возвращает ее номер
	return InsertRow(self.t_id, key or -1)
end

--ЕНС добавляет строку в указанную позицию
function QTable:InsertLine(key)
  -- добавляет в конец таблицы пустую строчку и возвращает ее номер
  return InsertRow(self.t_id, key)
end

--окрашивает строку или колонку
function QTable:SetColor(row, col, b_color, f_color, sel_b_color, sel_f_color)
  SetColor(self.t_id, row, col or QTABLE_NO_INDEX, b_color, f_color, sel_b_color, sel_f_color)
end

function QTable:GetSize()
	-- возвращает размер таблицы
	return GetTableSize(self.t_id)
end

-- Получить данные из ячейки по номеру строки и имени столбца
function QTable:GetValue(row, col_name)
	local t={}

	local col_ind = col_name
	if type(col_name) == 'string' then col_ind = self.columns[col_name].id or nil end
	if col_ind == nil then
		return false
	end

	t = GetCell(self.t_id, row, col_ind)
	return t
end

-- Подсветить ячейку
function QTable:Highlight(row, col_name, Color, defColor, delay)
	local t={}

	local col_ind = col_name
	if type(col_name) == 'string' then col_ind = self.columns[col_name].id or nil end
	if col_ind == nil then
		return false
	end

	Highlight(self.t_id, row, col_ind, Color, defColor, delay)
end
-- Задать координаты окна
function QTable:SetPosition(x, y, dx, dy)
	return SetWindowPos(self.t_id, x, y, dx, dy)
end

-- Функция возвращает координаты окна
function QTable:GetPosition()
	top, left, bottom, right = GetWindowRect(self.t_id)
	return top, left, right-left, bottom-top
end

