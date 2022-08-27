isTrade                         = false


manualDelOrders                 = {}        --таблица с удаленнымми вручную ордерами
deletedOrders                   = {}        --таблица с удаленнымми ордерами
checkedOrders                   = {}        --таблица с проверенными исполненными ордерами

FILTER_ROBOTS_POSTFIX           = true
ROBOT_NUMBER                    = ROBOT_NUMBER or 1
trans_id                        = os.time() + ROBOT_NUMBER*10000 -- Задает начальный номер ID транзакций
DEAL_COUNTER                    = 1

WAIT_FOR_EXECUTION              = 10        -- ожидать появления записей в таблицах по торговым операциям


--Поиск ордера в таблице заявок по order_num
function findOrder(Sec, ord, order_num)
    function myFind(C,S,F,B,N)
        return C == Sec.CLASS_CODE and S == Sec.SEC_CODE and N == order_num
    end
    if order_num == nil then return nil end
    ord = ord or "orders"
    local orders = SearchItems(ord, 0, getNumberOf(ord)-1, myFind, "class_code,sec_code,flags,brokerref,order_num")
    if (orders ~= nil) and (#orders > 0) then
        local order = getItem(ord, orders[#orders])
        if order ~= nil and type(order) == "table" then
            order.index = orders[#orders]
            --myLog(NAME_OF_STRATEGY..' findOrder Найдена заявка по '..order.sec_code..' number: '..tostring(order.order_num)..' order.index: '..tostring(order.index)..' qty: '..tostring(order.qty))
            return order
        end
    end
    return nil
end

------------------------------------
-- Управление позицией

--Поиск ордера в таблице заявок по trans_id
function FindTransIdOrder(Sec, ord, trans_id)
    function myFind(C,S,T,L,B,A)
        return C == Sec.CLASS_CODE and S == Sec.SEC_CODE and T == trans_id and (A == Sec.ACCOUNT or Sec.ACCOUNT == '') and (L:find(Sec.CLIENT_CODE)~=nil or Sec.CLIENT_CODE == '') and (not FILTER_ROBOTS_POSTFIX or (ROBOT_POSTFIX == '' or B:find(ROBOT_POSTFIX)~=nil))
    end
    ord = ord or "orders"
    local orders = SearchItems(ord, 0, getNumberOf(ord)-1, myFind, "class_code,sec_code,trans_id,client_code,brokerref,account")
    if (orders ~= nil) and (#orders > 0) then
        local order = getItem(ord, orders[#orders])
        if order ~= nil and type(order) == "table" then
            order.index = orders[#orders]
            return order
        end
    end
    return nil
end

-- Выставляет лимитную заявку
-- price,      -- Цена заявки
-- Type - операция ('BUY', 'SELL') -- текущее направление позиции которую надо открыть
-- qty         -- Количество
function SetOrder(Sec, price, Type, qty, dont_wait)

    if qty<0 then qty = -qty end

    local operation = Type == 'BUY' and 'B' or 'S'

    local transClientCode = Sec.transClientCode or getROBOT_CLIENT_CODE(Sec, DEAL_COUNTER)

    -- Выставляет заявку
    -- Получает ID для следующей транзакции
    trans_id = os.time() + ROBOT_NUMBER*10000
    -- Заполняет структуру для отправки транзакции
    local TR = {}
    TR['TRANS_ID']       = tostring(trans_id)     -- Номер транзакции
    TR['ACCOUNT']        = Sec.ACCOUNT            -- Код счета
    TR['CLASSCODE']      = Sec.CLASS_CODE         -- Код класса
    TR['SECCODE']        = Sec.SEC_CODE           -- Код инструмента
    TR['CLIENT_CODE']    = transClientCode        -- Комментарий к транзакции, который будет виден в транзакциях, заявках и сделках
    TR['ACTION']         = 'NEW_ORDER'            -- Тип транзакции ('NEW_ORDER' - новая заявка)
    TR['TYPE']           = 'L'                    -- Тип ('L' - лимитированная, 'M' - рыночная)
    TR['OPERATION']      = operation              -- Операция ('B' - buy, или 'S' - sell)
    TR['PRICE']          = format_to_scale(GetCorrectPrice(Sec, price), Sec.SCALE) -- Цена
    TR['QUANTITY']       = tostring(qty)          -- Количество
    TR["COMMENT"]        = NAME_OF_STRATEGY

    myLog(NAME_OF_STRATEGY..' Установка ордера trans_id: '..tostring(trans_id)..', позиция '..Type..' qty '..tostring(qty)..', по цене: '..tostring(price)..', transClientCode: '..tostring(transClientCode))

    local prev_table_count = getNumberOf('orders')-1

    -- Отправляет транзакцию
    local res = sendTransaction(TR)
    -- Если при отправке транзакции возникла ошибка
    if res ~= '' then
       local mes = 'Ошибка выставления лимитной заявки: '..tostring(res)
       myLog(NAME_OF_STRATEGY..' '..mes)
       myLog(NAME_OF_STRATEGY..' TR: '..tostring(TR))
       return nil, mes
    end

    if dont_wait then
        return trans_id
    end

    myLog(NAME_OF_STRATEGY..' SetOrder Find order TR: '..tostring(TR))

    local curTime = os.time()
    while isRun and os.time()-curTime < WAIT_FOR_EXECUTION do
        -- Перебирает еще не обработанные строки таблицы
        local last_index = getNumberOf('orders')-1
        if prev_table_count + 1 <= last_index then
           for i = prev_table_count + 1, last_index do
              -- Получает строку таблицы
              local table_line = getItem('orders', i)
              if table_line~=nil and table_line.trans_id == trans_id and table_line.sec_code == Sec.SEC_CODE and
                 (table_line.account == Sec.ACCOUNT or Sec.ACCOUNT == '') and
                 (table_line.client_code:find(Sec.CLIENT_CODE)~=nil or Sec.CLIENT_CODE == '') and
                 (not FILTER_ROBOTS_POSTFIX or ROBOT_POSTFIX == '' or table_line.brokerref:find(ROBOT_POSTFIX)~=nil)
              then
                 table_line.index = i
                 return table_line
              end
           end
        end
        sleep(100)
    end

    local mes = 'Возникла неизвестная ошибка при выставлении лимитной заявки по транзакции: '..tostring(trans_id)..', '..tostring(res)
    myLog(NAME_OF_STRATEGY..' '..mes)
    return nil, mes

end

function GetBestBidOffer(Sec, Type)
    --Берем лучшую цену из стакана
    if Type == 'SELL' then
        return tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, 'offer').param_value or 0)
    else
        return tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, 'bid').param_value or 0)
    end
end

-- Возвращает корректную цену для рыночной заявки закрытия позиции по текущему инструменту (принимает 'SELL',или 'BUY' и уровень цены)
-- Фунция возвращает цену в обратном направлении от Типа.
-- Если передано BUY, то функция вернет цену для закрытия позиции
-- Если надо наоборот набрать позицию, то необходимо передавать тип, обратный набираемой позиции
 function GetPriceForMarketOrder(Sec, Type, level_price)

     -- Пытается получить максимально возможную цену для инструмента
     local PriceMax = tonumber(getParamEx(Sec.CLASS_CODE,  Sec.SEC_CODE, 'PRICEMAX').param_value)
     -- Пытается получить минимально возможную цену для инструмента
     local PriceMin = tonumber(getParamEx(Sec.CLASS_CODE,  Sec.SEC_CODE, 'PRICEMIN').param_value)

     --Берем лучшую цену из стакана
     if (level_price or 0) == 0 then
        level_price = GetBestBidOffer(Sec, Type)
     end

     -- Получает цену последней сделки, если не задано
     level_price = (level_price or 0) == 0 and  GetLastPrice(Sec, level_price, T[Sec.SEC_CODE].INTERVAL, true) or level_price

     myLog(NAME_OF_STRATEGY..' GetPriceForMarketOrder level_price: '..tostring(level_price))

     local market_offset = T[Sec.SEC_CODE].MARKET_PRICE_OFFSET or 100

     if Type == 'SELL' then
         -- по цене, завышенной на 200 мин. шагов цены
         local price = level_price + market_offset*Sec.SEC_PRICE_STEP
         if level_price == 0 or (PriceMax ~= nil and PriceMax ~= 0 and price > PriceMax) then
            price = PriceMax-1*Sec.SEC_PRICE_STEP
         end
         return price
     else
         -- по цене, заниженной на 200 мин. шагов цены
         local price = level_price - market_offset*Sec.SEC_PRICE_STEP
         if level_price == 0 or (PriceMin ~= nil and PriceMin ~= 0 and price < PriceMin) then
            price = PriceMin+1*Sec.SEC_PRICE_STEP
         end
         return price
     end

end

--Получение префикса для выставления заявок
function getROBOT_CLIENT_CODE(Sec, counter)
    local postfix = ROBOT_POSTFIX
    if Sec.CLASS_CODE == 'QJSIM' or Sec.CLASS_CODE == 'TQBR' or Sec.CLASS_CODE == 'TQOB' then
        postfix = '/'..ROBOT_POSTFIX --Строка комментаия в заявках, сделках
    end
    return Sec.CLIENT_CODE..postfix..(counter==nil and '' or tostring(counter))
end