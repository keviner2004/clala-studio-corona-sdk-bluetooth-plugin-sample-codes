local widget = require( "widget" )
function widget.newTextField( options )
    local customOptions = options or {}
    local opt = {}
    opt.left = customOptions.left or 0
    opt.top = customOptions.top or 0
    opt.x = customOptions.x or 0
    opt.y = customOptions.y or 0
    opt.width = customOptions.width or (display.contentWidth * 0.75)
    opt.height = customOptions.height or 20
    opt.id = customOptions.id
    opt.listener = customOptions.listener or nil
    opt.text = customOptions.text or ""
    opt.inputType = customOptions.inputType or "default"
    opt.font = customOptions.font or native.systemFont
    opt.fontSize = customOptions.fontSize or opt.height * 0.2

    -- Vector options
    opt.strokeWidth = customOptions.strokeWidth or 2
    opt.cornerRadius = customOptions.cornerRadius or 0
    opt.strokeColor = customOptions.strokeColor or { 0, 0, 0 }
    opt.backgroundColor = customOptions.backgroundColor or { 1, 1, 1 }

    local field = display.newGroup()
     
    local background = display.newRoundedRect( 0, 0, opt.width, opt.height, opt.cornerRadius )
    background:setFillColor( unpack(opt.backgroundColor) )
    background.strokeWidth = opt.strokeWidth
    background.stroke = opt.strokeColor
    field:insert( background )
     
    if ( opt.x ) then
       field.x = opt.x
    elseif ( opt.left ) then
       field.x = opt.left + opt.width * 0.5
    end
    if ( opt.y ) then
       field.y = opt.y
    elseif ( opt.top ) then
       field.y = opt.top + opt.height * 0.5
    end
     
    -- Native UI element
    local tHeight = opt.height - opt.strokeWidth * 2
    if "Android" == system.getInfo("platformName") then
        --
        -- Older Android devices have extra "chrome" that needs to be compesnated for.
        --
        tHeight = tHeight + 10
    end
     
    field.textField = native.newTextField( 0, 0, opt.width - opt.cornerRadius, tHeight )
    field.textField.x = 0
    field.textField.y = 0
    field.textField.hasBackground = false
    field.textField.inputType = opt.inputType
    field.textField.text = opt.text
    print( opt.listener, type(opt.listener) )
    if ( opt.listener and type(opt.listener) == "function" ) then
       field.textField:addEventListener( "userInput", opt.listener )
    else
        local function onUserInput( event )
            -- Hide keyboard when the user clicks "Return" in this field
            if ( "submitted" == event.phase ) then
                native.setKeyboardFocus( nil )
            end
        end
        field.textField:addEventListener( "userInput", onUserInput )
    end
    field:insert(field.textField)
    local deviceScale = ( display.pixelWidth / display.contentWidth ) * 0.5
     
    field.textField.font = native.newFont( opt.font )
    field.textField.size = opt.fontSize * deviceScale

    function field:finalize( event )
       event.target.textField:removeSelf()
    end
    field:addEventListener( "finalize" ) 
     
    return field

end