local util = {}
local bit = require( "plugin.bit" )

util.toUint16 = function (data, start)
    return data:byte(start) + bit.lshift(data:byte(start+1), 8)
end

util.numberToBytes = function(number, num)
    local bytes = ""
    local mask = 0xff
    for i = 1, num do
        local c = string.char(bit.band(number, mask))
        print("get c", c)
        bytes = c..bytes
        number = bit.rshift(number, 8)
    end
    
    return bytes
end

util.stringToHex = function(data, s, e)
    local id = ""
    for i = s, e do
        id = id .. bit.tohex(data:byte(i), 2)
    end
    return id
end

util.parseManufacturerData = function(data)
    local manufacturerData
    if #data == 25 then
        --local manufacturerType = util.toUint16(string.sub(data, 2, 2)..string.sub(data, 1, 1), 1)
        local manufacturerType = util.toUint16(data, 1)
        local indicator = data:byte(3)
        local dataLength = data:byte(4)
        print("ManufacturerData Data dataLength is ", dataLength)
        local major = util.toUint16(string.sub(data, 21, 21)..string.sub(data, 22, 22), 1)
        local minor = util.toUint16(string.sub(data, 23, 23)..string.sub(data, 24, 24), 1)
        local txPower = data:byte(25)
        if txPower > 127 then
            txPower = -(bit.band(bit.bnot(txPower), 0xff)+1)
        end
        local uuid = util.stringToHex(data, 5, 20)

        manufacturerData = {
            manufacturerType = manufacturerType,
            indicator = indicator,
            dataLength = dataLength,
            major = major,
            minor = minor,
            txPower = txPower,
            uuid = uuid,
        }
    else
        manufacturerData = {
            raw = util.stringToHex(data, 1, #data)
        }
    end
    return manufacturerData
end

return util