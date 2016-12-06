local widget = require( "widget" )
local LinearGroup = require("LinearGroup") 

function widget.newNavigationBar( options )
   local customOptions = options or {}
   local opt = {}
   opt.left = customOptions.left or nil
   opt.top = customOptions.top or nil
   opt.width = customOptions.width or display.contentWidth
   opt.height = customOptions.height or 50
   if ( customOptions.includeStatusBar == nil ) then
      opt.includeStatusBar = true  -- assume status bars for business apps
   else
      opt.includeStatusBar = customOptions.includeStatusBar
   end
 
   -- Determine the amount of space to adjust for the presense of a status bar
   local statusBarPad = 0
   if ( opt.includeStatusBar ) then
      statusBarPad = display.topStatusBarContentHeight
   end
 
   opt.x = customOptions.x or display.contentCenterX
   opt.y = customOptions.y or (opt.height + statusBarPad) * 0.5
   opt.id = customOptions.id
   opt.isTransluscent = customOptions.isTransluscent or true
   opt.background = customOptions.background
   opt.backgroundColor = customOptions.backgroundColor
   opt.title = customOptions.title or ""
   opt.subTitle = customOptions.subTitle or ""
   opt.titleColor = customOptions.titleColor or { 0, 0, 0 }
   opt.font = customOptions.font or native.systemFontBold
   opt.fontSize = customOptions.fontSize or 18
   opt.leftButton = customOptions.leftButton or nil
   opt.rightButton = customOptions.rightButton or nil
 
   -- If "left" and "top" parameters are passed, calculate the X and Y
   if ( opt.left ) then
      opt.x = opt.left + opt.width * 0.5
   end
   if ( opt.top ) then
      opt.y = opt.top + (opt.height + statusBarPad) * 0.5
   end

   local barContainer = display.newGroup()
   local background = display.newRect( barContainer, opt.x, opt.y, opt.width, opt.height + statusBarPad )
   print("background", background.width, background.height)
   if ( opt.background ) then
      background.fill = { type="image", filename=opt.background }
   elseif ( opt.backgroundColor ) then
      background.fill = opt.backgroundColor
   else
      background.fill = { 1, 1, 1 } 
   end
   
   local function createTitle(title, subTitle)
      local titleGroup = LinearGroup.new({
         layout = LinearGroup.VERTICAL
      })

      local title = display.newText( title or "Title", 0, 0, opt.font, opt.fontSize )
      title:setFillColor( unpack(opt.titleColor) )
      titleGroup:insert(title)

      if subTitle then
         local subTitle = display.newText( subTitle or "SubTitle", 0, 0, opt.font, opt.fontSize*0.5 )
         titleGroup:insert(subTitle)
         titleGroup.subTitle = subTitle
      end

      titleGroup.title = title
      titleGroup:resize()
      titleGroup.x = background.x
      titleGroup.y = background.y + statusBarPad * 0.5
      return titleGroup
   end

   barContainer.titleGroup = createTitle(opt.title, opt.subTitle)

   barContainer:insert( barContainer.titleGroup )

   local leftButton
   if ( opt.leftButton ) then
      if ( opt.leftButton.defaultFile ) then  -- construct an image button
         leftButton = widget.newButton({
            x = 0,
            y = 0,
            id = opt.leftButton.id,
            width = opt.leftButton.width,
            height = opt.leftButton.height,
            baseDir = opt.leftButton.baseDir,
            defaultFile = opt.leftButton.defaultFile,
            overFile = opt.leftButton.overFile,
            onEvent = opt.leftButton.onEvent
            })
      else  -- else, construct a text button
         leftButton = widget.newButton({
            x = 0,
            y = 0,
            id = opt.leftButton.id,
            label = opt.leftButton.label,
            onEvent = opt.leftButton.onEvent,
            font = opt.leftButton.font or opt.font,
            fontSize = opt.fontSize,
            labelColor = opt.leftButton.labelColor or { default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 } },
            labelAlign = "left",
            })
      end
      leftButton.x = 15 + leftButton.width * 0.5
      leftButton.y = barContainer.titleGroup.y
      barContainer:insert( leftButton )  -- insert button into container group
      print("dataf1", barContainer.width, barContainer.height)
   end
 
   local rightButton
   if ( opt.rightButton ) then
      if ( opt.rightButton.defaultFile ) then  -- construct an image button
         rightButton = widget.newButton({
            id = opt.rightButton.id,
            width = opt.rightButton.width,
            height = opt.rightButton.height,
            baseDir = opt.rightButton.baseDir,
            defaultFile = opt.rightButton.defaultFile,
            overFile = opt.rightButton.overFile,
            onEvent = opt.rightButton.onEvent
            })
      else  -- else, construct a text button
         rightButton = widget.newButton({
            id = opt.rightButton.id,
            label = opt.rightButton.label or "Default",
            onEvent = opt.rightButton.onEvent,
            font = opt.leftButton.font or opt.font,
            fontSize = opt.fontSize,
            labelColor = opt.rightButton.labelColor or { default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 } },
            labelAlign = "right",
            })
      end
      rightButton.x = background.width - rightButton.width * 0.5 - 15
      rightButton.y = barContainer.titleGroup.y
      barContainer:insert( rightButton )  -- insert button into container group
      print("dataf2", barContainer.width, barContainer.height)
   end

   barContainer.leftButton = leftButton
   barContainer.rightButton = rightButton

   print("display", display.contentWidth, display.contentHeight)
   print("dataf", barContainer.width, barContainer.height)

   function barContainer:setTitle(text1, text2)
      self.titleGroup:removeSelf()
      self.titleGroup = createTitle(text1, text2)
      self:insert(self.titleGroup)
   end

   function barContainer:showLeftButton(show)
      if show or show == nil then
         self.leftButton.alpha = 1
      else
         self.leftButton.alpha = 0
      end
   end

   function barContainer:showRightButton(show)
      if show or show == nil then
         self.rightButton.alpha = 1
      else
         self.rightButton.alpha = 0
      end
   end

   return barContainer

end