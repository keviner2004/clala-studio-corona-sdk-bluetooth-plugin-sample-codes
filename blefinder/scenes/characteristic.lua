--template.lua
local composer = require( "composer" )
local LinearGroup = require("LinearGroup")
local navigationBar = require("myNavigationBar")
local widget = require("widget")
local bluetooth = require( "bluetooth" )
local bleutil = require("bleutil")
local scene = composer.newScene()
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

function scene:bluetooth(event)
    local eventType = event.type
    local eventPhase = event.phase    
    if eventType == "device" then
        local device = event.device
        if eventPhase == "didUpdateCharacteristic" then
            print("didUpdateCharacteristic", event.characteristic.uuid, event.characteristic.value)
            self:updateCharacteristicValueText(event.characteristic.value)
        elseif eventPhase == "didWriteCharacteristic" then
            print("didWriteCharacteristic", event.characteristic.uuid, event.characteristic.value)
        elseif eventPhase == "findDescriptors" then
            print("Found descriptors!!!!", #event.characteristic.descriptors)
            for i = 1, #event.characteristic.descriptors do
                print("Found descriptor ", event.characteristic.descriptors[i].uuid)
                self:pushDescriptor(event.characteristic.descriptors[i])
            end
            self:refreshDescriptorTable()
        end
    elseif eventType == "disconnect" then
        composer.gotoScene("scenes.devices")
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

function scene:pushDescriptor(descriptor)
    print("Push descriptor!!!!!!!!!!!!!!!!!!!!")
    local found = false
    for i = 1, #self.tabledata do
        local targetDescriptor = self.tabledata[i]
        if descriptor.uuid == targetDescriptor.uuid then
            found = true
            break
        end
    end
    if not found then
        self.tabledata[#self.tabledata+1] = descriptor
    end
end

function scene:createDescriptorCell(title, object)
    local cell = display.newGroup()
    cell.titleValueText = display.newText(cell, title, 0, 0, nil, 12)
    cell.titleValueText:setFillColor(0, 0, 0)
    cell.titleValueText.x = cell.titleValueText.width/2
    cell.titleValueText.y = cell.titleValueText.height/2
    cell.uuidValueText = display.newText(cell, object.uuid, 0, 0, nil, 12)
    cell.uuidValueText:setFillColor(0, 0, 0)
    cell.uuidValueText.x = cell.uuidValueText.width/2
    cell.uuidValueText.y = cell.titleValueText.y + (cell.titleValueText.height + cell.uuidValueText.height)/2
    cell.anchorX = 0.5
    cell.anchorY = 0.5
    cell.anchorChildren = true
    return cell
end

function scene:createDescriptorTable(w, h)
    -- The "onRowRender" function may go here (see example under "Inserting Rows", above)
    local function rowRender( event )
        local row = event.row
        local title = event.row.params.title
        row.descriptor = event.row.params.descriptor
        local cell = self:createDescriptorCell(title, row.descriptor)
        row.cell = cell
        row.cell.x = row.contentWidth / 2
        --row.cell.x = row.cell.width/2 + 15
        row.cell.y = row.contentHeight / 2
        row:insert(cell)
    end

    local function rowTouch(event)
        print("row touch: ", event.phase, event.row.identifier)
        if event.phase == "tap" then
            --go to the descriptor
            print("Go to descriptor ", event.row.descriptor.uuid, event.row.descriptor.value)
            composer.gotoScene("scenes.descriptor", {
                effect = "fromLeft",
                time = 400,
                params = {
                    descriptor = event.row.descriptor
                }
            })
        end
    end

    local tableView = widget.newTableView(
        {
            x = 0,
            y = 0,
            height = h,
            width = w,
            onRowRender = rowRender,
            onRowTouch = rowTouch
            --listener = scrollListener
        }
    )

    return tableView
end

function scene:refreshDescriptorTable()
    self.descriptorTable:deleteAllRows()
    for i = 1, #self.tabledata do
        print("Insert descriptor row~~~~~~~~~~~~~")
        local targetDescriptor = self.tabledata[i]
        self.descriptorTable:insertRow({
            id = targetDescriptor.uuid,
            rowHeight = display.contentHeight * 0.15, 
            params = {
                descriptor = targetDescriptor,
                cType = "descriptor",
                title = "Descriptor "..i
            }
        })
    end
end

function scene:createCharacteristicValueText()
    local text = display.newText({
        text = "MyValue",
        fontSize = 15
    })

    text.pTypes = {"hex", "string"}
    text.pType = text.pTypes[1]
    text:setFillColor(0)

    function text:setPresentation(pType)
        self.pType = pType
        self:setValue(self.value)
    end

    function text:setValue(value)
        self.value = value
        if self.pType == "string" then
            self.text = value
        elseif self.pType == "hex" then
            self.text = bleutil.stringToHex(value, 1, #value)
        end
    end

    function text:toggle()
        local total = #self.pTypes

        local idx = 0
        for i = 1, total do
            if self.pTypes[i] == self.pType then
                idx = i
                break
            end
        end
        if idx > 0 then
            idx = idx + 1
            if idx > total then
                idx = 1
            end
            self.pType = self.pTypes[idx]
            self:setValue(self.value)
        end
        return self.pType
    end

    return text
end

function scene:createCharacteristicBlock(w, h)
   local sceneGroup = self.view
   local group = LinearGroup.new({
        layout = LinearGroup.VERTICAL,
        gap = 20
    })
    
    local valueBox = LinearGroup.new({
        layout = LinearGroup.VERTICAL,
    })

    --value title
    local valueTitle = display.newText({
        text = "Value",
        fontSize = 15,
        font = native.systemFontBold
    })

    valueTitle:setFillColor(0, 0, 0)
    
    local characteristicValueText = self:createCharacteristicValueText()

    local valueTypeButton = widget.newButton({
        label = characteristicValueText.pType,
        x = 0,
        y = 0,
        onEvent = function (event)
            --change type
            if event.phase == "began" then
                characteristicValueText:toggle()
                event.target:setLabel(characteristicValueText.pType)
            end
        end
    })

    valueBox:insert(valueTitle)
    valueBox:insert(valueTypeButton)
    valueBox:insert(characteristicValueText)
    valueBox:resize()

    local writeDataBox = LinearGroup.new({
        layout = LinearGroup.VERTICAL
    })

    local writeField = widget.newTextField({
        x = 0, 
        y = 0,
        width = 180,
        height = 30,
        fontSize = 15
    })

    local writeFieldBox = LinearGroup.new({
        layout = LinearGroup.HORIZONTAL
    })

    local dataTypeButton = nil
    dataTypeButton = widget.newButton({
        label = self.intTypeData[1],
        x = 0,
        y = 0,
        width = 65,
        onEvent = function(event)
            if event.phase == "began" then
                print("Show the wheel!")
                self:showWheel(true, function(value)
                    dataTypeButton:setLabel(value)
                    self.dataType = value
                end)
            end
        end
    })

    local sendButton = widget.newButton({
        label = "Send",
        x = 0,
        y = 0,
        width = 65,
        onEvent = function (event)
            if event.phase == "ended" then
                self:writeValue()
            end
        end
    })

    local writeDataBoxTitle = display.newText({
        text = "Write Data",
        fontSize = 15,
        font = native.systemFontBold
    })
    writeDataBoxTitle:setFillColor(0)

    writeFieldBox:insert(dataTypeButton)
    writeFieldBox:insert(writeField)
    writeFieldBox:insert(sendButton)
    writeFieldBox:resize()

    writeDataBox:insert(writeDataBoxTitle)
    writeDataBox:insert(writeFieldBox)
    writeDataBox:resize()
    writeDataBox.x = 0
    writeDataBox.y = 0

    group:insert(valueBox)
    group:insert(writeDataBox)
    --input
    --group.anchorX = 0.5
    --group.anchorY = 0.5
    --group.anchorChildren = true
    group.characteristicValueText = characteristicValueText
    group.writeField = writeField
    group:resize()

    function group:update()

    end

    return group
end

function scene:updateCharacteristicValueType(pType)
    self.characteristicBlock.characteristicValueText:setPresentation(pType)
end

function scene:updateCharacteristicValueText(value)
    self.characteristicBlock.characteristicValueText:setValue(value)
end

function scene:writeValue()
    local value = tonumber(self.characteristicBlock.writeField.textField.text)
    if value then
        local numOfBytes = 0
        if self.dataType == "uint8" then
            numOfBytes = 1
        elseif self.dataType == "uint16" then
            numOfBytes = 2
        elseif self.dataType == "uint32" then
            numOfBytes = 3
        elseif self.dataType == "uint64" then
            numOfBytes = 4
        end
        print("Get text ", value, " and write", numOfBytes, "bytes")
        if numOfBytes > 0 then
            local data = bleutil.numberToBytes(value, numOfBytes)
            print("Try to send data: ", data, #data)
            if self.device and self.characteristic then
                print("send data to characteristic ", self.characteristic.uuid)
                self.device:writeValueForCharacteristic(data, numOfBytes, self.characteristic, 1)
            end
        end
    end
end

function scene:showWheel(show, onComplete)
    if show then
        local panelGroup = LinearGroup.new({
            layout = LinearGroup.VERTICAL
        })

        local sendButton = widget.newButton({
            x = 0,
            y = 0,
            width = 30,
            height = 50,
            label = "OK",
            onEvent = function(event)
                if event.phase == "began" then
                    print("Hide the wheel!")
                    local value = self:showWheel(false)
                    if onComplete then
                        onComplete(value)
                    end
                end
            end
        })

        --sendButton.anchorX = 0.5
        --sendButton.anchorY = 0.5
        --sendButton.anchorChildren = true

        local wheelTitle = display.newText({
            text = "Select a value type",
            fontSize = 15
        })
        wheelTitle:setFillColor(0)

        local columnData = 
        { 
            {
                align = "center",
                width = display.contentWidth,
                height = 35,
                labelPadding = 0,
                startIndex = 1,
                labels = self.intTypeData
            },
        }

        -- Create the widget
        self.pickerWheel = widget.newPickerWheel(
        {
            x = 0,
            y = 0,
            --top = display.contentHeight - 160,
            columns = columnData,
            style = "resizable",
            width = display.contentWidth,
            height = display.contentHeight,
            rowHeight = 50,
            fontSize = 14,
            --anchorX = 0.5,
            --anchorY = 0.5,
        }) 
        --self.pickerWheel.anchorX = 0
        --self.pickerWheel.anchorY = 0
        --self.pickerWheel.anchorChildren = true
        print("pickerWheel", self.pickerWheel.anchorY, self.pickerWheel.anchorX)
        panelGroup:insert(wheelTitle)
        panelGroup:insert(self.pickerWheel)
        panelGroup:insert(sendButton)
        panelGroup:resize()

        local panel = display.newGroup()

        local panelBackground = display.newRect(panel, 0, 0, display.contentWidth, display.contentHeight)
        --panelBackground.fill = {1,0,0}

        panel:insert(panelBackground)
        panel:insert(panelGroup)

        self.characteristicBlockOldX = self.characteristicBlock.writeField.x
        self.characteristicBlock.writeField.x = 9999
        self.wheelBox = panel
        self.view:insert(panel)
        panel.x = display.contentCenterX
        panel.y = display.contentCenterY
    else
        local value = self.pickerWheel:getValues()
        self.characteristicBlock.writeField.x = self.characteristicBlockOldX
        self.wheelBox:removeSelf()
        print("return value", value[1].value)
        return value[1].value
    end
end

function scene:unRegister()
    if self.device and self.characteristic then
        timer.performWithDelay(function()
            --self.device:setNotify(false, self.characteristic)
        end, 1)
    end
end

function scene:navigationBarLeftClick(event)
    if event.phase == "ended" then
        print("lClick, back to service")
        composer.gotoScene("scenes.services", {
            effect = "fromRight",
            time = 400,
            params = {
                keep = true,
                device = self.characteristic.service.device
            }
        })
    end
end

function scene:navigationBarRightClick(event)
    --print("rClick")
end
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

    local sceneGroup = self.view
    local container = LinearGroup.new({
        layout = LinearGroup.VERTICAL
    })
    local background = display.newRect(display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
    self.tabledata = {}
    -- Code here runs when the scene is first created but has not yet appeared on screen
    self.intTypeData = { "uint8", "uint16", "uint32", "uint64" }
    self.dataType = self.intTypeData[1]
    self.characteristicBlock = self:createCharacteristicBlock(display.contentWidth, display.contentHeight/2)
    self.descriptorTable = self:createDescriptorTable(display.contentWidth, display.contentHeight - self.characteristicBlock.height - navigationBar.height -15)

    local descriptorsTitle = display.newText({
        text = "Descriptors",
        font = native.systemFontBold,
        fontSize = 15
    })
    descriptorsTitle:setFillColor(0)
    container:insert(self.characteristicBlock)
    container:insert(descriptorsTitle)
    container:insert(self.descriptorTable)
    container:resize()

    container.x = display.contentWidth/2
    container.y = display.contentHeight/2 + navigationBar.height

    sceneGroup:insert(background)
    sceneGroup:insert(container)

end

-- show()
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        bluetooth:addEventListener("bluetooth", self)
        navigationBar:setTitle("Characteristic")
        navigationBar:showLeftButton(true)
        navigationBar:showRightButton(false)
        self.characteristicBlock.writeField.x = self.characteristicBlockOldX
        self.tabledata = {}
        self.descriptorTable:deleteAllRows()
        self.characteristic = event.params and event.params.characteristic
        if self.characteristic then
            self.device = self.characteristic.service.device
            print("Read value characteristic", self.characteristic.value)
            self.device:readValueForCharacteristic(self.characteristic)
            self.device:setNotify(true, self.characteristic)
            --discover descriptors
            self.characteristic.service.device:discoverDescriptors(self.characteristic)
            navigationBar:setTitle("Characteristic", self.characteristic.uuid)
        end
        self.title = event.params and event.params.title
        self.characteristicBlock:update()

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
        self.characteristicBlockOldX = self.characteristicBlock.writeField.x
        self.characteristicBlock.writeField.x = 9999
        self:unRegister()
        bluetooth:removeEventListener("bluetooth", self)
        navigationBar:removeEventListener("navigationBarLeftClick", self)
        navigationBar:removeEventListener("navigationBarRightClick", self)
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