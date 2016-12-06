--devices.lua
local composer = require( "composer" )
local navigationBar = require( "myNavigationBar" )
local json = require("json")
local bluetooth = require( "bluetooth" )
local widget = require( "widget" )
local bleutil = require("bleutil")
local LinearGroup= require("LinearGroup")
local ListView = require("ListView")
local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

function scene:newDeviceCell(RSSI, device, advertisement)
    --local cell = display.newGroup()
    local cell = LinearGroup.new({
        layout = LinearGroup.VERTICAL,
        alignment = LinearGroup.Left
    })

    local statusBar = LinearGroup.new({
        layout = LinearGroup.HORIZONTAL
    })

    cell:insert(statusBar)

    cell.rssiLabelText = display.newText(cell, "RSSI:", 0, 0, nil, 12)
    cell.rssiLabelText:setFillColor(0, 0, 0)
    statusBar:insert(cell.rssiLabelText)

    cell.rssiValueText = display.newText(cell, "", 0, 0, nil, 12)
    cell.rssiValueText:setFillColor(1, 0, 0)
    statusBar:insert(cell.rssiValueText)

    local spacer = display.newRect(0, 0, 30, 1)
    statusBar:insert(spacer)

    cell.nameValueText = display.newText(cell, "", 0, 0, nil, 12)
    cell.nameValueText:setFillColor(0, 0, 0)
    statusBar:insert(cell.nameValueText)

    cell.uuidValueText = display.newText(cell, "", 0, 0, nil, 12)
    cell.uuidValueText:setFillColor(0, 0, 0)
    cell:insert(cell.uuidValueText)

    cell.advertiseLabelText = display.newText(cell, "Advertising Data:", 0, 0, native.systemFontBold, 12)
    cell.advertiseLabelText:setFillColor(0, 0, 0)
    cell:insert(cell.advertiseLabelText)

    cell.adLocalNameLabel = display.newText(cell, "Local name:", 0, 0, nil, 12)
    cell.adLocalNameLabel:setFillColor(0, 0, 0)
    cell:insert(cell.adLocalNameLabel)

    cell.adLocalNameValue = display.newText(cell, "", 0, 0, nil, 12)
    cell.adLocalNameValue:setFillColor(0, 0, 0)
    cell:insert(cell.adLocalNameValue)

    function cell:update(RSSI, device, advertisement)
        --update ui
        if advertisement.isConnectable ~= nil and not self.adConnectableLabel then
            self.adConnectableLabel = display.newText(self, "Connectable:", 0, 0, nil, 12)
            self.adConnectableLabel:setFillColor(0, 0, 0)
            self:insert(self.adConnectableLabel)        
            self.adConnectableValue = display.newText(self, "", 0, 0, nil, 12)
            self.adConnectableValue:setFillColor(0, 0, 0)
            self:insert(self.adConnectableValue)
        end

        if advertisement.serviceUuids and not self.serviceUuidsLabel then
            self.serviceUuidsLabel = display.newText(self, "Service UUIDs:", 0, 0, nil, 12)
            self.serviceUuidsLabel:setFillColor(0, 0, 0)
            self:insert(self.serviceUuidsLabel)        
            self.serviceUuidsValue = display.newText(self, "", 0, 0, nil, 12)
            self.serviceUuidsValue:setFillColor(0, 0, 0)
            self:insert(self.serviceUuidsValue)
        end

        if advertisement.manufacturerData and not self.manufacturerDataLabel then
            self.manufacturerDataLabel = display.newText(self, "Manufacturer Data", 0, 0, nil, 12)
            self.manufacturerDataLabel:setFillColor(0, 0, 0)
            self:insert(self.manufacturerDataLabel)
            self.manufacturerDataValue = display.newText(self, "", 0, 0, nil, 12)
            self.manufacturerDataValue:setFillColor(0, 0, 0)
            self:insert(self.manufacturerDataValue)
        end

        if advertisement.dataChannel and not self.adDataChannelLabel then
            self.adDataChannelLabel = display.newText(self, "Data channel:", 0, 0, nil, 12)
            self.adDataChannelLabel:setFillColor(0, 0, 0)
            self:insert(self.adDataChannelLabel)
            self.adDataChannelValue = display.newText(self, "", 0, 0, nil, 12)
            self.adDataChannelValue:setFillColor(0, 0, 0)
            self:insert(self.adDataChannelValue)
        end

        self.RSSI = RSSI
        self.device = device
        self.advertisement = advertisement
        self.identifier = device.identifier
        self.rssiValueText.text = RSSI
        self.uuidValueText.text = device.identifier
        self.nameValueText.text = device.name or "Unknow"

        if self.advertisement then
            self.adLocalNameValue.text = advertisement.localName or "Unknow"
            if advertisement.dataChannel then
                self.adDataChannelValue.text = advertisement.dataChannel or ""
            end

            if advertisement.isConnectable ~= nil then
                local isConnectableValue = ""
                isConnectableValue = tostring(advertisement.isConnectable)
                self.adConnectableValue.text = isConnectableValue  
            end
            
            if advertisement.serviceUuids then
                self.serviceUuidsValue.text = json.prettify(advertisement.serviceUuids)
            end

            if self.manufacturerDataValue and advertisement.manufacturerData then
                self.manufacturerDataValue.text = json.prettify(bleutil.parseManufacturerData(advertisement.manufacturerData))
            end
        end

        self:resizeAll()
    end

    cell:update(RSSI, device, advertisement)

    return cell
end

function scene:bluetooth( event )
    local eventPhase = event.phase
    local deviceTable = self.deviceTable
    if event.type == "discovery" then
        local numOfRows = self.deviceTable:getNumOfRows()
        if eventPhase == "found" then
            if deviceTable.deleting then
                print("deleting, skip")
                return
            end
            --reload 
            --deviceTable:reloadData()
            local newDevice = event.device
            local advertisementData = event.advertisement
            local RSSI = event.RSSI

            if advertisementData.manufacturerData then
                local mData = bleutil.parseManufacturerData(advertisementData.manufacturerData)
            end

            local needAddToList = 0

            self.deviceList[#self.deviceList + 1] = newDevice
            --print("**********Compare********** rows", numOfRows)
            for i = 1, numOfRows do
                local targetRow = deviceTable:getRow(i)
                if not targetRow then
                    --do nothing
                    --print("**********Compare**********: no target row", i)
                    return
                end
                local targetId = targetRow.identifier
                --print("**********Compare**********: id", targetId)
                if newDevice:getIdentifier() == targetId then
                    needAddToList = i
                    break
                end
            end
            --print("Need insert to list", needAddToList)
            if needAddToList == 0 then
                -- add to list
                local cell = self:newDeviceCell(RSSI, newDevice, advertisementData)
                --print("Insert to row")
                deviceTable:insertRow(cell)
            else
                --update the device
                deviceTable:getRow(needAddToList):update(RSSI, newDevice, advertisementData)
            end
            
        elseif eventPhase == "started" then
            self.deviceList = {}

        elseif eventPhase == "finished" then
            --local numOfRows = deviceTable:getNumOfRows()
            local removeList = {}
            for i = 1, numOfRows do
                local targetRow = deviceTable:getRow(i)
                --print("Check row i ", targetRow, numOfRows)
                
                if not targetRow then
                    --do nothing
                    return
                end
                local targetId = targetRow.identifier
                --print("~~~~Check ", targetId, "is still exists")
                local found = 0
                for j = 1, #self.deviceList do
                    --print("~~~~Compare to deviceList[j]:getIdentifier()", self.deviceList[j]:getIdentifier())
                    if self.deviceList[j]:getIdentifier() == targetId then
                        found = j
                        break
                    end
                end
                if found == 0 then
                    removeList[#removeList+1] = i
                end
            end
            if #removeList > 0 then
                deviceTable.deleting = true
                local deleteTime = 100
                deviceTable:deleteRows( removeList, { slideLeftTransitionTime=deleteTime, slideUpTransitionTime=deleteTime } )
                timer.performWithDelay(deleteTime, function()
                    deviceTable.deleting = false
                end)
                --deviceTable:deleteRows( removeList )
            end
        end
    end
end

function scene:listViewTouchRelease( event )
    print("Device states ", event.row.device.identifier, event.row.device.state)
    --library.connect(event.row.identifier)
    self:stopScan()
    composer.gotoScene("scenes.services", {
        params = {
            device = event.row.device
        }
    })
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()

function scene:create( event )

    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
    self.scanTimeout = 3200

    -- The "onRowRender" function may go here (see example under "Inserting Rows", above)
    local function rowRender( event )
        --print("on row render", event.name)
        -- Get reference to the row group
        local row = event.row
        local rowWidth = row.contentWidth
        local rowHeight = row.contentHeight
        row.cell = row.params.cell
        row:insert(row.cell)
        row.identifier = row.params.identifier
        row.device = row.params.device
        row.advertisement = row.params.advertisementData
        row.cell.x = rowWidth / 2
        row.cell.y = rowHeight / 2
    end

    local function rowTouch(event)
        --print("row touch: ", event.phase, event.row.identifier)
        if event.phase == "release" then
            --print("connect to ", event.row.device.identifier, event.row.device.state)
            --library.connect(event.row.identifier)
            if event.row.device.state == "disconnected" and event.row.advertisement.isConnectable then
                self:stopScan()
                composer.gotoScene("scenes.services", {
                    params = {
                        device = event.row.device
                    }
                })

            else
                print("Non connectable device")
            end
        end
    end

    --[[
    local tableView = widget.newTableView(
        {
            height = display.contentHeight - navigationBar.height,
            width = display.contentWidth,
            onRowRender = rowRender,
            onRowTouch = rowTouch
        }
    )
    --]]

    local tableView = ListView.new({
        height = display.contentHeight - navigationBar.height,
        width = display.contentWidth,
    })

    tableView.x = display.contentCenterX
    tableView.y = tableView.height/ 2 + navigationBar.height

    print("?????", tableView.y - tableView.height/ 2)

    sceneGroup:insert(tableView)
    self.deviceTable = tableView
end

function scene:reset()
    self.deviceList = {}
    self.deviceTable:deleteAllRows()
end

-- show()
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        self:reset()
        self.deviceList = {}
        bluetooth.discover(self.scanTimeout)
        self.discoverTimer = timer.performWithDelay(
            self.scanTimeout + 1000,
            function()
                bluetooth.discover(self.scanTimeout)
            end,
            -1
        )
        print("Listen bluetooth event!!")
        bluetooth:addEventListener("bluetooth", self)
        self.deviceTable:addEventListener("listViewTouchRelease", self)
        navigationBar:setTitle("Devices")
        navigationBar:showLeftButton(false)
        navigationBar:showRightButton(false)
        --navigationBar.alpha = 0
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
    end
end

function scene:stopScan()
    print("Stop scan from lua...")
    timer.cancel(self.discoverTimer)
    bluetooth.stopDiscover()
end

-- hide()
function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
        -- Code here runs immediately after the scene goes entirely off screen
        print("Remove event listener~!!")
        bluetooth:removeEventListener("bluetooth", self)
        self.deviceTable:removeEventListener("listViewTouchRelease", self)
        self:stopScan()
    elseif ( phase == "did" ) then

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