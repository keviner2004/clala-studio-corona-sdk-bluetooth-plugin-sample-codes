--template.lua
local composer = require( "composer" )
local ListView = require( "ListView")
local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------




-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
    self.listView = ListView.new({
        width = display.contentWidth,
        height = display.contentHeight
    })
    sceneGroup:insert(self.listView)
    --self.listView.alpha = 0
    for i = 1, 11 do
        local obj = display.newGroup()
        local rect = display.newRect(obj, 0, 0, display.contentWidth - 50, 100)
        local text = display.newText({
            text = tostring(i)
        })
        obj:insert(text)
        rect.fill = {1, 0, 0}
        obj.num = i
        --obj.x = display.contentCenterX
        --obj.y = display.contentCenterY
        self.listView:insertRow(obj)
    end

    for i = 1, self.listView:getNumOfRows() do
        print("Row num is", self.listView:getRow(i).num)
    end

    self.listView:deleteRows({3, 4, 1})

end

function scene:listViewTouchRelease(event)
    print("touch at ", event.row.num)
end
-- show()
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        self.listView:addEventListener("listViewTouchRelease", self)
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen

    end
end


-- hide()
function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)

    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        self.listView:removeEventListener("listViewTouchRelease", self)
    end
end


-- destroy()
function scene:destroy( event )

    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene