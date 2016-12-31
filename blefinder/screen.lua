local screen = {}

print(display.contentWidth, display.contentHeight, display.pixelWidth, display.pixelHeight)

local scaleW = display.pixelWidth / display.contentWidth
local scaleH = display.pixelHeight / display.contentHeight


if display.contentWidth * scaleH > display.pixelWidth then
    screen.top = 0
    screen.left = (display.contentWidth * scaleH - display.pixelWidth)/2/scaleH
else
    screen.top = (display.contentHeight * scaleW - display.pixelHeight)/2/scaleW
    screen.left = 0
end

print("Screen top, left ", screen.top, screen.left)

return screen

