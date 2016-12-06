local widget = require("widget")
local LinearGroup = require("LinearGroup")
local ListView = {}

ListView.new = function(options)
    if not options then
        options = {}
    end

    -- ScrollView listener
    local function scrollListener( event )

        local phase = event.phase
        if ( phase == "began" ) then
            --print( "Scroll view was touched" )
        elseif ( phase == "moved" ) then 
            --print( "Scroll view was moved" )
            event.target.needDispatchTouchEvent = false
            if event.target.touchRect then
                event.target.touchRect.fill = {1}
            end
        elseif ( phase == "ended" ) then 
            --print( "Scroll view was released" )
            if event.target.needDispatchTouchEvent then
                event.target:dispatchEvent({
                    name = "listViewTouchRelease",
                    row = event.target.touchedRow
                })
            end
            if event.target.touchRect then
                event.target.touchRect.fill = {1}
            end
        end

        -- In the event a scroll limit is reached...
        if ( event.limitReached ) then
            if ( event.direction == "up" ) then 
                --print( "Reached bottom limit" )
            elseif ( event.direction == "down" ) then 
                --print( "Reached top limit" )
            elseif ( event.direction == "left" ) then 
                --print( "Reached right limit" )
            elseif ( event.direction == "right" ) then 
                --print( "Reached left limit" )
            end
        end

        return false
    end

    options.listener = scrollListener

    local container = widget.newScrollView(options)
    container.view = LinearGroup.new({
        layout = LinearGroup.VERTICAL
    })
    container:insert(container.view)

    function container:insertRow(obj)
        local cell = LinearGroup.new({
            layout = LinearGroup.VERTICAL
        })
        local content = display.newGroup()

        local line = display.newRect(0, 0, self.width - 4, 1)
        line.fill = {0.7}

        local hitRect = display.newRect(0, 0, self.width, obj.height+50)
        hitRect.alpha = 0
   
        local touchRect = display.newRect(0, 0, self.width, obj.height+50)

        hitRect:addEventListener("touch", function(event)
            event.name = "listViewTouchPress"
            event.row = obj
            self:dispatchEvent(event)
            self.needDispatchTouchEvent = true
            self.touchedRow = obj
            self.touchRect = touchRect
            self.touchRect.fill = {0.5}
            --return true
        end)

        hitRect.isHitTestable = true

        content:insert(touchRect)
        content:insert(obj)
        content:insert(hitRect)

        cell:insert(content)
        cell:insert(line)

        cell.content = content
        cell.row = obj

        cell:resize()
        self.view:insert(cell)
        self.view:resize()
        self:resize()
    end

    function container:getRows()
        return self.view
    end

    function container:getNumOfRows()
        return self.view.numChildren
    end

    function container:deleteRow(idx)
        self.view:remove(idx)
    end

    function container:deleteRows(idxes)
        for i = 1, #idxes do
            local idx = idxes[i]
            self:deleteRow(idx)
            for j = i, #idxes do
                if idxes[j] > idx then
                    idxes[j] = idxes[j] - 1
                end
            end
        end
        self.view:resize()
        self:resize()
    end

    function container:deleteAllRows()
        for i = 1, self.view.numChildren do
            self.view[1]:removeSelf()
        end
    end

    function container:getRow(idx)
        return self.view[idx].row
    end

    function container:resize()
        print("Resize list view", self.width, self.height, self.view.height)
        self.view.x = self.width/2
        self.view.y = self.view.height/2
        self:setScrollHeight(self.view.height)
    end

    return container
end

return ListView