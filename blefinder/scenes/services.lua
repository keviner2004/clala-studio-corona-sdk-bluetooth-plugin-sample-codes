--template.lua
local composer = require( "composer" )
local navigationBar = require( "myNavigationBar" )
local widget = require("widget")
local bluetooth = require( "bluetooth" )
local json = require("json")
local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------


function scene:bluetooth( event )
    print("Service scene got the bluetooth event")
    local eventType = event.type
    local eventPhase = event.phase
    if eventType == "connect" then
        local device = event.device
        print("discover the service")
        device:discoverServices()
    elseif eventType == "disconnect" then
        self:back()
    elseif eventType == "device" then
        local device = event.device
        if eventPhase == "findServices" then
            local services = device.services
            for i = 1, #services do
                self:pushService(services[i])
                device:discoverCharacteristics(nil, services[i])
            end
            self:refresh()
        elseif eventPhase == "findCharacteristics" then
            local service = event.service      
            local characteristics = service.characteristics     
            for i = 1, #characteristics do
                self:pushCharacteristic(characteristics[i])
            end
            self:refresh()
        end

    end
end

function scene:back()
    self.backToDevices = true
    composer.gotoScene("scenes.devices", {
        effect = "fromRight",
        time = 400,
        params = {

        }
    })
end

function scene:navigationBarLeftClick(event)
    if event.phase == "ended" then
        print("lClick, back to device")
        if self.device and self.characteristic then
            self.device:setNotify(false, self.characteristic)
        end
        self:back()
    end
end

function scene:navigationBarRightClick(event)
    print("rClick")
    if event.phase == "ended" then

    end
end

function scene:pushService(service)
    print("Push service!!!!!!!!!!!!!!!!!!!!")
    local found = false
    for i = 1, #self.tabledata do
        local targetService = self.tabledata[i].service
        if service.uuid == targetService.uuid then
            found = true
            break
        end
    end
    if not found then
        self.tabledata[#self.tabledata+1] = {
            service = service,
            characteristics = {

            }
        }
    end
end

function scene:pushCharacteristic(characteristic)
    print("Push Characteristic!!!!!!!!!!!!!!!!!!!!")
    local service = characteristic.service
    for i = 1, #self.tabledata do
        local targetService = self.tabledata[i].service
        if service.uuid == targetService.uuid then
            local found = false
            local characteristics = self.tabledata[i].characteristics
            for j = 1, #characteristics do
                local targetCha = characteristics[j]
                if targetCha.uuid == characteristic.uuid then
                    found = true
                    break
                end
            end
            if not found then
                characteristics[#characteristics+1] = characteristic
            end
            break
        end
    end
end

function scene:refresh()
    self.tableView:deleteAllRows()
    for i = 1, #self.tabledata do
        --print("Insert service row~~~~~~~~~~~~~")
        local targetService = self.tabledata[i].service
        local characteristics = self.tabledata[i].characteristics
        self.tableView:insertRow({
            id = targetService.uuid,
            rowHeight = display.contentHeight * 0.15, 
            params = {
                service = targetService,
                cType = "service",
                title = "Service "..i
            }
        })
        for j = 1, #characteristics do
            local targetCha = characteristics[j]
            self.tableView:insertRow({
                id = targetCha.uuid,
                rowHeight = display.contentHeight * 0.15, 
                params = {
                    characteristic = targetCha,
                    cType = "characteristic",
                    title = "Characteristic "..j
                }
            })
        end
    end
end

function scene:createServiceCell(title, service)
    local cell = display.newGroup()
    cell.titleValueText = display.newText(cell, title, 0, 0, nil, 12)
    cell.titleValueText:setFillColor(0, 0, 0)
    cell.titleValueText.x = cell.titleValueText.width/2
    cell.titleValueText.y = cell.titleValueText.height/2
    cell.uuidValueText = display.newText(cell, service.uuid, 0, 0, nil, 12)
    cell.uuidValueText:setFillColor(0, 0, 0)
    cell.uuidValueText.x = cell.uuidValueText.width/2
    cell.uuidValueText.y = cell.titleValueText.y + (cell.titleValueText.height + cell.uuidValueText.height)/2
    cell.anchorX = 0.5
    cell.anchorY = 0.5
    cell.anchorChildren = true
    return cell
end

function scene:createCharacteristicCell(title, characteristic)
    local cell = display.newGroup()
    cell.titleValueText = display.newText(cell, title, 0, 0, nil, 12)
    cell.titleValueText:setFillColor(0, 0, 0)
    cell.titleValueText.x = cell.titleValueText.width/2
    cell.titleValueText.y = cell.titleValueText.height/2
    cell.uuidValueText = display.newText(cell, characteristic.uuid, 0, 0, nil, 12)
    cell.uuidValueText:setFillColor(0, 0, 0)
    cell.uuidValueText.x = cell.uuidValueText.width/2
    cell.uuidValueText.y = cell.titleValueText.y + (cell.titleValueText.height + cell.uuidValueText.height)/2
    cell.anchorX = 0.5
    cell.anchorY = 0.5
    cell.anchorChildren = true
    return cell
end

function scene:reset()
    if self.tabledata then
        self.tabledata = {}
    end
    if self.tableView then
        self.tableView:deleteAllRows()
    end
end

function scene:createTableView()
    -- The "onRowRender" function may go here (see example under "Inserting Rows", above)
    local sceneGroup = self.view
    local function rowRender( event )
        print("on row render", event.name)
        local row = event.row
        local rowWidth = row.contentWidth
        local rowHeight = row.contentHeight
        local title = row.params.title
        row.cType = row.params.cType
        -- Get reference to the row group
        
        if row.params.cType == "service" then 
            row.service = row.params.service
            row.cell = self:createServiceCell(title, row.service)
        else
            row.characteristic = row.params.characteristic
            row.cell = self:createCharacteristicCell(title, row.characteristic)
        end

        row:insert(row.cell)        
        
        row.cell.x = row.cell.width/2 + 15
        row.cell.y = rowHeight / 2
    end

    local function rowTouch(event)
        local row = event.row
        print("row touch: ", event.phase, event.row.identifier)
        if event.phase == "tap" then
            --go to the characteristic
            if row.cType == "characteristic" then
                print("Check the detail of characteristic ", row.characteristic.uuid)
                composer.gotoScene("scenes.characteristic", {
                    effect = "fromLeft",
                    time = 400,
                    params = {
                        characteristic = row.characteristic
                    }
                })
            end
        end

    end

    local tableView = widget.newTableView(
        {
            height = display.contentHeight - navigationBar.height,
            width = display.contentWidth,
            onRowRender = rowRender,
            onRowTouch = rowTouch
            --listener = scrollListener
        }
    )

    tableView.x = display.contentCenterX
    tableView.y = tableView.height / 2 + navigationBar.height + navigationBar.y
    sceneGroup:insert(tableView)   
    self.tableView = tableView
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
    self.tabledata = {}
    self:createTableView()
end


-- show()
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase
    local keep = event.params and event.params.keep

    if ( phase == "will" ) then
        self.backToDevices = false
        if not keep then
            self:reset()
        end
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        bluetooth:addEventListener("bluetooth", self)
        local device = event.params and event.params.device
        if device then
            print("device.state:", device.state)
            if device.state == "disconnected" then
                self:reset()
                bluetooth.connect(device)
            else
                device:discoverServices()
            end
            self.device = device
        end

        navigationBar:setTitle("Services")
        navigationBar:showLeftButton(true)
        navigationBar:showRightButton(false)
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        navigationBar:addEventListener("navigationBarLeftClick", self)
        navigationBar:addEventListener("navigationBarRightClick", self)
    end
end


-- hide()
function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
        bluetooth:removeEventListener("bluetooth", self)
        navigationBar:removeEventListener("navigationBarLeftClick", self)
        navigationBar:removeEventListener("navigationBarRightClick", self)
        if self.backToDevices then
            bluetooth.disconnect(self.device)
        end
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen

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