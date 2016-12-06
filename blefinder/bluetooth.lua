local library = require "plugin.bluetooth"
--local EvtD = require "EventDispatcher"
local manager = {}
--local manager = EvtD()
local listenerBags = {}
local removeBags = {}
--local dispatcher = display.newGroup()

--local dispatcher = display.newRect(0,0, 100,100)

local function listener( event )
    --print( "!!Received event from Library plugin (" .. event.name .. "): ", event.type, event.phase )
    --manager:dispatchEvent(event)
    manager:dispatchEvent(event)
end

library.init( listener )

manager.dispatcher = dispatcher

function manager:fire(obj, event)
    if type(obj) == "table" then
        local f = obj[event.name]
        f(obj, event)
    elseif type(obj) == "function" then
        obj(event)
    end    
end

function manager:dispatchEvent(event)
    if self.dispatching then
        --print("Already dispatching, wait.......")
        return timer.performWithDelay(1, function()
            self:dispatchEvent(event)
        end)
    end
    self.dispatching = true
    local id = math.random(1000000)
    --print("~~~~ Dispatch event ~~~~~", id)
    --self.dispatcher:dispatchEvent(event)
    local listeners = listenerBags[event.name]
    local removeList = removeBags[event.name]
    if not listeners then
        self.dispatching = false
        return
    end

    --remove listener from remove bags
    if removeList then
        for obj, v in pairs(removeList) do
            listeners[obj] = nil
        end
    end
    --reset remove bags
    removeBags[event.name] = {}
    --dispatch event
    for obj, v in pairs(listeners) do
        self:fire(obj, event)
    end
    print("~~~~ Dispatch event done ~~~~~", id)
    self.dispatching = false
end

function manager:addEventListener(name, obj)
    --self.dispatcher:addEventListener(name, obj)
    if not listenerBags[name] then
        listenerBags[name] = {}
    end
    local listeners = listenerBags[name]
    listeners[obj] = true
end

function manager:removeEventListener(name, obj)
    if not removeBags[name] then
        removeBags[name] = {}
    end
    local removeList = removeBags[name]
    removeList[obj] = true
end

manager.discover = library.discover
manager.stopDiscover = library.stopDiscover
manager.connect = library.connect
manager.disconnect = library.disconnect

return manager