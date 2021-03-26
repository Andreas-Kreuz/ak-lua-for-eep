if AkDebugLoad then print("Loading ak.io.jsonEncode ...") end
--
-- jsonEncode.lua
-- Simplified and fast version omitting any checks

local json = { _version = "1.0.0" }

-- local alias names increase performance
local type, tostring, pairs, ipairs, next, table_concat --, table_insert
    = type, tostring, pairs, ipairs, next, table.concat --, table.insert

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local encode -- forward declaration

local result = {}

-- append entry
local function cat(str)
-- table_insert(result, str)    -- same speed
    result[#result + 1] = str    -- as this command
end

-- replace last entry
local function rep(str)
    result[#result] = str
end

local function encodeTable(tab)
    if tab[1] ~= nil then
        -- Encode array
        cat( "[" )
        for _, value in ipairs(tab) do
            encode(value)
            cat( "," )
        end
        rep( "]" ) -- replace last colon
        return

    elseif next(tab) ~= nil then
        -- Encode object
         cat( "{" )
        for key, value in pairs(tab) do
            --encode(key)
            --cat( ":" )
            --encode(value)
            -- It's faster to skip the last level of recursion
            if     type(value) == "string" then
                cat( string.format('"%s":"%s"', key, value) )

            elseif type(value) == "number" then -- Differentiate between integer and float
                cat( string.format(( value == math.floor(value) and '"%s":%d' or '"%s":%.3f' ), key, value) )
            else
                cat( string.format('"%s":', key) )
                encode(value)
            end
            cat( "," )
        end
        rep( "}" ) -- replace last colon
        return

    else
        -- Encode empty table
        cat( "[]" )
        return
    end
end

local function encodeString(str)
    cat( '"' .. str .. '"' )
end

local function encodeNumber(num)
    cat( tostring(num) )
end

local function encodeBoolean(bool)
    cat( tostring(bool) )
end

local function encodeNil(_)
    cat( "null" )
end

local type_func_map = {
    [ "table"   ] = encodeTable,
    [ "string"  ] = encodeString,
    [ "number"  ] = encodeNumber,
    [ "boolean" ] = encodeBoolean,
    [ "nil"     ] = encodeNil,
}

encode = function(value)
    local t = type(value)
    local f = type_func_map[t]
    if f then
        return f(value)
    end
    error("unexpected type '" .. t .. "'")
end

function json.encode(value)
    result = {}

local t0 = os.clock()

    encode(value) -- this is the slow part

local t1 = os.clock()

    local jsonString = table_concat(result)    -- this is very fast

local t2 = os.clock()
print(string.format("json.Encode: concat %d lines into %d characters, encode in %.3f sec, concat in %.3f sec",
    #result, #jsonString, t1-t0, t2-t1
))

    return jsonString
end

return json
