local widget = require("widget")
local screen = require("screen")
local navBar

local function handleLeftButton( event )
   if ( event.phase == "ended" ) then
      -- do stuff
   end
   event.name = "navigationBarLeftClick"
   navBar:dispatchEvent(event)
   return true
end
 
local function handleRightButton( event )
   if ( event.phase == "ended" ) then
      -- do stuff
   end
   event.name = "navigationBarRightClick"
   navBar:dispatchEvent(event)
   return true
end

local leftButton = {
   onEvent = handleLeftButton,
   --width = 60,
   --height = 34,
   label = "<-",
   labelColor = { default =  {1, 1, 1}, over = { 0.5, 0.5, 0.5} },
   font = "HelveticaNeue-Light",
   --defaultFile = "images/backbutton.png",
   --overFile = "images/backbutton_over.png"
}
 
local rightButton = {
   onEvent = handleRightButton,
   label = "->",
   labelColor = { default =  {1, 1, 1}, over = { 0.5, 0.5, 0.5} },
   font = "HelveticaNeue-Light",
   isBackButton = false
}

navBar = widget.newNavigationBar({
   title = "My App",
   backgroundColor = { 0.96, 0.62, 0.34 },
   --background = "images/topBarBgTest.png",
   titleColor = {1, 1, 1},
   font = "HelveticaNeue",
   leftButton = leftButton,
   rightButton = rightButton,
   includeStatusBar = false
})
print("move my navigation bar", screen.top, screen.left)

navBar.y = screen.top

return navBar