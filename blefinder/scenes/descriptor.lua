--template.lua
local LinearGroup = require("LinearGroup")
local navigationBar = require("myNavigationBar")
local composer = require( "composer" )
local bluetooth = require( "bluetooth" )
local bleutil = require( "bleutil" )
local widget = require("widget")
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
        if eventPhase == "didUpdateDescriptor" then
            print("didUpdateDescriptor", event.descriptor.uuid, event.descriptor.value)
            self:updateDescriptorValueText(event.descriptor.value)
        elseif eventPhase == "didWriteDescriptor" then
            print("didWriteDescriptor", event.descriptor.uuid, event.descriptor.value)
        end
    elseif eventType == "disconnect" then
        composer.gotoScene("scenes.devices")
    end
end

function scene:navigationBarLeftClick(event)
    if event.phase == "ended" then
        print("lClick, back to characteristic")
        composer.gotoScene("scenes.characteristic", {
            effect = "fromRight",
            time = 400,
            params = {
                keep = true,
                characteristic = self.descriptor.characteristic
            }
        })
    end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )
    local sceneGroup = self.view
    self.intTypeData = { "uint8", "uint16", "uint32", "uint64" }
    -- Code here runs when the scene is first created but has not yet appeared on screen
    self.descriptorBlock = self:createDescriptorBlock(display.contentWidth, display.contentHeight/2)
    local background = display.newRect(display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)

    self.descriptorBlock.x = display.contentWidth/2
    self.descriptorBlock.y = display.contentHeight/2
    self.dataType = self.intTypeData[1]
    sceneGroup:insert(background)
    sceneGroup:insert(self.descriptorBlock)
end


function scene:updateDescriptorValueText(value)
    self.descriptorBlock.descriptorValueText:setValue(value)
end

function scene:createDescriptorValueText()
    local text = display.newText({
        text = "",
        fontSize = 15
    })

    text.value = ""

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

function scene:writeValue()
    local value = tonumber(self.descriptorBlock.writeField.textField.text)
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
            if self.device and self.descriptor then
                print("send data to descriptor ", self.descriptor.uuid)
                self.device:writeValueForDescriptor(data, numOfBytes, self.descriptor)
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

        self.descriptorBlockOldX = self.descriptorBlock.writeField.x
        self.descriptorBlock.writeField.x = 9999
        self.wheelBox = panel
        self.view:insert(panel)
        panel.x = display.contentCenterX
        panel.y = display.contentCenterY
    else
        local value = self.pickerWheel:getValues()
        self.descriptorBlock.writeField.x = self.descriptorBlockOldX
        self.wheelBox:removeSelf()
        print("return value", value[1].value)
        return value[1].value
    end
end

function scene:createDescriptorBlock(w, h)
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
    
    local descriptorValueText = self:createDescriptorValueText()

    local valueTypeButton = widget.newButton({
        label = descriptorValueText.pType,
        x = 0,
        y = 0,
        onEvent = function (event)
            --change type
            if event.phase == "began" then
                descriptorValueText:toggle()
                event.target:setLabel(descriptorValueText.pType)
            end
        end
    })

    valueBox:insert(valueTitle)
    valueBox:insert(valueTypeButton)
    valueBox:insert(descriptorValueText)
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
    group.descriptorValueText = descriptorValueText
    group.writeField = writeField
    group:resize()

    function group:update()

    end

    return group
end

-- show()
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        if self.descriptorBlockOldX then
            self.descriptorBlock.writeField.x = self.descriptorBlockOldX
        end
        
        self.descriptor = event.params and event.params.descriptor

        if self.descriptor then
            self.device = self.descriptor.characteristic.service.device
            print("readValueForDescriptor")
            self.device:readValueForDescriptor(self.descriptor)
            navigationBar:setTitle("descriptor", self.descriptor.uuid)
        end

        bluetooth:addEventListener("bluetooth", self)

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
        self.descriptorBlockOldX = self.descriptorBlock.writeField.x
        self.descriptorBlock.writeField.x = 9999
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