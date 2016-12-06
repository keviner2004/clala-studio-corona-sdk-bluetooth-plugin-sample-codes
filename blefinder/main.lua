require("newTextField")
require("navigationBar")
local widget = require("widget")
local composer = require("composer")

--display.setDefault( "background", 0, 0, 0 )
--local bluetooth = require("bluetooth")
display.setStatusBar(display.HiddenStatusBar)
composer.gotoScene("scenes.devices")
--composer.gotoScene("scenes.characteristic")
--composer.gotoScene("scenes.testListView")
--[[
local bit = require( "plugin.bit" )
local bleutil = require("bleutil")
local data = "  Ê#$%"
print(bleutil.stringToHex(data, 1, #data))
print(bit.tohex(data:byte(4), 2))  
--]]




