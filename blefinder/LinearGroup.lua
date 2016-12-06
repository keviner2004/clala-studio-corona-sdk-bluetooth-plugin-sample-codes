local Group = {}

Group.HORIZONTAL = "horizontal"
Group.VERTICAL = "vertical"
Group.Left = "left"
Group.Center = "center"
Group.Right = "right"

Group.new = function(options)
  local group = display.newGroup()
  group.gap = options and options.gap or 0
  group.layout = options and options.layout or Group.HORIZONTAL
  group.alignment = options and options.alignment or Group.Center
  group.__resizable = true

  --[[
  group.oriInsert = group.insert
  function group:insert(index, child, resetTransform)
    self:oriInsert(index, child, resetTransform)
  end
  --]]

  function group:resize()
    local lt = 0
    local wh = "width"
    local wh2 = "height"
    local xy = ""
    local xy2 = ""
    local al = 0
    if self.layout == Group.HORIZONTAL then
      wh = "width"
      wh2 = "height"
      xy = "x"
      xy2 = "y"
    else
      wh = "height"
      wh2 = "width"
      xy = "y"
      xy2 = "x"
    end
    for i = 1, self.numChildren do
      lt = lt + self[i][wh]
    end

    if self.layout == Group.VERTICAL and self.alignment == Group.Left then
      print("detect alignment")
      for i = 1, self.numChildren do
        if self[i].width > al then
          al = self[i].width
        end
      end
    end

    lt = lt + (self.numChildren - 1) * self.gap
    lt = -lt/2
    for i = 1, self.numChildren do
      if i == 1 then
        self[i][xy] = lt + self[i][wh]/2
      else
        self[i][xy] = self[i-1][xy] + self[i-1][wh]/2 + self[i][wh]/2 + self.gap
      end
      if al > 0 then        
        self[i][xy2] = (self[i][wh2]-al)/2
      end
    end
  end

  function group:resizeAll()
    print("reszize All")
    for i = 1, self.numChildren do
      if self[i].__resizable then
        print("Found sizable container")
        self[i]:resizeAll()
      end
    end
    self:resize()
  end

  return group
end

return Group