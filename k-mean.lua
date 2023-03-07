-----------------------------------------------
--k-means clustering
-----------------------------------------------
local M = {}
M.LICENSE = {
    _VERSION     = 'k-mean lib 2023.03.05',
    _DESCRIPTION = 'k-mean lib',
    _AUTHOR      = 'nnh: nick-h@yandex.ru'
}

local math_floor = math.floor
local math_ceil  = math.ceil

--calc center of claster as median value
M.MEDIAN = false

--set round calc center of claster
--M.ROUND  = 2

-- vectors coordinat keys
--M.V_KEYS = {[1] = 'x', [2] = 'y'}

--vectors coordinat weights
M.V_WEIGHT = {}
--M.V_WEIGHT = {x = 1, y = 1}

---@param num number
---@param idp any
local function round(num, idp)
    if num then
        local mult = 10^(idp or 0)
        if num >= 0 then
            return math_floor(num * mult + 0.5) / mult
        else
            return math_ceil(num * mult - 0.5) / mult
        end
    else
        return num
    end
end

local v_clone = function(vector)
    local clone = {}
    for key, value in pairs(vector) do
        clone[key] = value
    end
    return clone
end

local Vector = {}
function Vector:new(v_data)
    self.__index = self
    if not M.V_KEYS then
        M.V_KEYS = {}
        for key in pairs(v_data) do
            M.V_KEYS[#M.V_KEYS+1] = key
        end
    end
    self.__tostring = function(instance)
        local rep = '|'
        for i = 1, #M.V_KEYS do
            rep = rep..M.V_KEYS[i]..' = '..tostring(instance[M.V_KEYS[i]])..'|'
        end
        return rep
    end
    return setmetatable(v_data, self)
end

local function VectorEq(v1,v2)
    for key, value in pairs(v1) do
        if v2[key] ~= value then return false end
    end
    return true
end

local Cluster = {}
function Cluster:new(v_data)
    self.__index = self
    if not M.V_KEYS then
        M.V_KEYS = {}
        for key in pairs(v_data) do
            M.V_KEYS[#M.V_KEYS+1] = key
        end
    end
    self.__tostring = function(instance)
        local rep = 'size: '..tostring(instance.size)..'; center |'
        for i = 1, #M.V_KEYS do
            rep = rep..M.V_KEYS[i]..' = '..tostring(instance.center[M.V_KEYS[i]])..'|'
        end
        return rep
    end
    return setmetatable({size = 0, vectors = {}, center = v_clone(v_data)}, self)
end

function ClusterAdd(c, v)
    table.insert(c.vectors, v)
    c.size = c.size + 1
end

function ClearCords(o)
    if o.size == 0 then
        return
    end
    o.vectors   = {}
    o.size      = 0
end

local function ClosestCluster(clusters, vector, k_len)
    local cur_indx    = 0
    local cur         = math.huge
    for i = 1, k_len do
        local dist = 0
        local diff
        for key in pairs(clusters[i].center) do
            diff    = clusters[i].center[key] - vector[key]
            dist    = dist + (M.V_WEIGHT[key] or 1)*diff*diff
        end
        if(dist < cur) then
            cur_indx  = i
            cur       = dist
        end
    end
    return cur_indx
end

local function SameCenter(centers, clasters, k_len)
    for i = 1 , k_len do
        if not VectorEq(centers[i], clasters[i].center) then
            return false
        end
    end
    return true
end

local function CalcClusterMean(c)
    local c_sum
    for key in pairs(c.center) do
        c_sum = 0
        for i = 1, c.size do
            c_sum = c_sum + c.vectors[i][key]
        end
        c.center[key] = c_sum/c.size
        if M.ROUND then c.center[key] = round(c.center[key], M.ROUND) end
    end
end

local function CalcClusterMedian(c)
    local k_val
    for key in pairs(c.center) do
        k_val = {}
        for i = 1, c.size do
            k_val[i] = c.vectors[i][key]
        end
        table.sort(k_val)
        c.center[key] = k_val[round(c.size/2)]
        if M.ROUND then c.center[key] = round(c.center[key], M.ROUND) end
    end
end

local function ClasterData(vectors, k, it_limit)

    local n         = #vectors
    if k >= n then return end

    it_limit        = it_limit or 1000
    local prev      = {}
    local centers   = {}
    local iterate   = 1
    local cache     = {}
    while #centers < k do
        local j = math.random(n)
        if not cache[j] then
            table.insert(prev, Cluster:new(vectors[j]))
            table.insert(centers, v_clone(vectors[j]))
            cache[j] = true
        end
    end

    local fAvg = M.MEDIAN and CalcClusterMedian or CalcClusterMean

    while true do

        if iterate >= it_limit then return prev, iterate end

        local j
        for i = 1, n do
            j = ClosestCluster(prev, vectors[i], k)
            ClusterAdd(prev[j], vectors[i])
        end

        for i = 1, k do
            fAvg(prev[i])
        end

        if SameCenter(centers, prev, k) == true then
            return prev, iterate
        end

        centers = {}
        for i = 1, k do
            table.insert(centers, v_clone(prev[i].center))
            ClearCords(prev[i])
        end
        iterate = iterate + 1
    end
end

M.Vector        = Vector
M.CloneVector   = v_clone
M.ClasterData   = ClasterData

return M