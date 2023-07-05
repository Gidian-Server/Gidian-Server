local user_input_service = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local run_service = game:GetService("RunService")
local local_player = game:GetService("Players").LocalPlayer
local mouse_local = local_player:GetMouse()
local http_service = game:GetService("HttpService")
local gui_window_library = {
  elements = {},
  theme_objects = {},
  connections = {},
  flags = {},
  themes = {
    Default = {
      main = Color3.fromRGB(47, 51, 56),
      second = Color3.fromRGB(32, 32, 32),
      stroke = Color3.fromRGB(60, 60, 60),
      divider = Color3.fromRGB(60, 60, 60),
      text = Color3.fromRGB(240, 240, 240),
      text_dark = Color3.fromRGB(150, 150, 150)
    }
  },
  selected_theme = "Default",
  folder = nil,
  save_config = false
  
}
local icons = {}
local succes, response = pcall(function()
	icons = http_service:JSONDecode(game:HttpGetAsync("https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json")).icons
end)

if not succes then
  warn("\nGUI Window Libaray - Failed to load feather icons Error Code: " .. response .. "\n")
end

local function get_icon(icon_name)
  if icons[icon_name] ~= nil then
    return icons[icon_name]
  else
    return nil
  end
end

local gui_window = Instance.new("ScreenGui")
gui_window.Name = "GUI Window"

if syn then
  syn.protect_gui(gui_window)
  gui_window.Parent = game.CoreGui
else
  gui_window.Parent = gethui() or game.CoreGui
end

if gethui then
  for _, Interface in ipairs(gethui():GetChildren()) do
    if Interface.Name == gui_window.Name and Interface ~= gui_window then
    	  Interface:Destroy()
    	end
  end
else
  for _, Interface in ipairs(game.CoreGui:GetChildren()) do
									if Interface.Name == gui_window.Name and Interface ~= gui_window then
													Interface:Destroy()
									end
  end
end

function gui_window_library:is_runnig()
  if gethui then
    return gui_window.Parent == gethui()
				else
    return gui_window.Parent == game:GetService("CoreGui")
  end
end

local function add_connection(Signal, Function)
  if (not gui_window_library:is_runnig()) then
    return
  end
  local signal_connect = Signal:Connect(Function)
  table.insert(gui_window_library.connections, signal_connect)
  return signal_connect
end

task.spawn(function()
  while (gui_window_library:is_runnig()) do
    wait()
  end
  for _, Connection in next, gui_window_library.connections do
    Connection:Disconnect()
  end
end)

local function make_draggable(drag_point,main)
  pcall(function()
    local dargging, drag_input, mouse_position, frame_position = false
    add_connection(darg_point.InputBegan,function(Input)
      if Input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mouse_position = Input.Position
        frame_position = main.Position
        Input.Changed:Connect(function()
          if Input.UserInputState == Enum.UserInputState.End then
            dragging = false
          end
        end)
      end
  end)
    add_connection(darg_point.InputChanged, function(Input)
      if Input.UserInputType == Enum.UserInputType.MouseMovement then
        darg_input = Input
      end
    end)
    add_connection(user_input_service.InputChanged, function(Input)
      if Input == darg_input and dargging then
        local delta = Input.Position - mouse_position
        tween_service:Create(main,TweenInfo.new(0.05, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position  = UDim2.new(frame_position.X.Scale,frame_position.X.Offset + delta.X, frame_position.Y.Scale, frame_position.Y.Offset + delta.Y)}):Play()
        main.Position  = UDim2.new(frame_position.X.Scale,frame_position.X.Offset + delta.X, frame_position.Y.Scale, frame_position.Y.Offset + delta.Y)
      end
    end)
  end)
end

local function create(name,properties,children)
  local object = Instance.new(name)
  for i, v in next, properties or {} do
    object[i] = v
  end
  for i, v in next, children or {} do
    v.Parent = object
  end
  return object
end

local function create_element(element_name,element_function)
  gui_window_library.elements[element_name] = function(...)
    return element_function(...)
  end
end

local function make_element(element_name,...)
  local new_element = gui_window_library.elements[element_name](...)
  return new_element
end

local function set_props(element,props)
  table.foreach(props, function(property, value)
    element[property] = value
  end)
  return element
end

local function set_children(element,children)
  table.foreach(children, function(_, child)
    child.Parent = element
  end)
  return element
end

local function round(number, factor)
  local result = math.floor(number/factor + (math.sign(number) * 0.5)) * factor
  if result < 0 then
    result = result + factor
  end
  return result
end

local function return_property(object)
  if object:IsA("Frame") or object:IsA("TextButton") then
    return "BackgroundColor3"
  end
  if object:IsA("ScrollingFrame") then
    return "ScrollBarImageColor3"
  end
  if object:IsA("UIStroke") then
    return "Color"
  end
  if object:IsA("TextLabel") or object:IsA("TextBox") then
    return "TextColor3"
  end
  if object:IsA("ImageLabel") or object:IsA("ImageButton") then
    return "ImageColor3"
  end
end

local function add_theme_object(object, type)
  if not gui_window_library.theme_objects[type] then
    gui_window_library.theme_objects[type] = {}
  end
  table.insert(gui_window_library.theme_objects[type],object)
  object[return_property[object]] = gui_window_library.themes[gui_window_library.selected_theme][type]
  return object
end

local function set_theme()
  for name, type in pairs(gui_window_library.theme_objects) do
    for _, object in paits(type) do
      object[return_property(object)] = gui_window_library.themes[gui_window_library.selected_theme][name]
    end
  end
end

local function pack_color(color)
  return {R = color.R * 255, G = color.G * 255, B = color.B * 255}
end

local function unpack_color(color)
  return Color3.fromRGB(color.R, color.G, color.B)
end

local function load_config(config)
  local data = http_service:JSONDecode(config)
  table.foreach(Data, function(a,b)
    if gui_window_library.flags[a] then
      spawn(function()
        if gui_window_library.flags[a].Type == "Colorpicker" then
          gui_window_library.flags[a]:Set(unpack_color(b))
        else
          gui_window_library.flags[a]:Set(b)
        end
      end)
    else
      warn("GUI Window Library Config Loader - Cloud not find ",a,b)
    end
  end)
end

local function save_config(name)
  local data = {}
  for i,v in pairs(gui_window_library.flags) do
    if v.Save then
      if v.Type == "Colorpicker" then
        data[i] = pack_color(v.Value)
      else
        data[i] = v.Value
      end
    end
  end
  writefile(gui_window_library.folder .. "/" .. name .. ".txt", tostring(http_service:JSONEncode(data)))
end

local white_listed_mouse = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2,Enum.UserInputType.MouseButton3}
local black_listed_keys = {Enum.KeyCode.Unknown,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Left,Enum.KeyCode.Down,Enum.KeyCode.Right,Enum.KeyCode.Slash,Enum.KeyCode.Tab,Enum.KeyCode.Backspace,Enum.KeyCode.Escape}

local function check_key(table,key)
  for _, v in next, table do
    if v == key then
      return true
    end
  end
end

create_element("corner", function(scale, offset)
  local corner = create("UICorner",{
    CornerRadius = UDim.new(scale or 0, offset or 10)
  })
  return corner
end)

create_element("stroke", function(color, thickness)
  local stroke = create("UIStroke", {
    Color = color or Color3.fromRGB(255, 255, 255),
    Thickness = thickness or 1
  })
  return stroke
end)

create_element("list", function(scale, offset)
  local list = create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(scale or 0, offset or 0)
  })
  return list
end)

create_element("padding", function(bottom, left, right, top)
  local padding = create("UIPadding", {
    PaddingBottom = UDim.new(0, bottom or 4),
    PaddingLeft = UDim.new(0, left or 4),
    PaddingRight = UDim.new(0, right or 4),
    PaddingTop = UDim.new(0, top or 4)
  })
  return padding
end)

create_element("tframe", function()
  local tframe = create("Frame", {
    BackgroundTransparency = 1
  })
  return tframe
end)

create_element("frame", function(color)
  local frame = create("Frame", {
    BackgroundColor3 = color or Color3.fromRGB(255, 255, 255),
    BorderSizePixel = 0
  })
  return frame
end)

create_element("round_frame", function(color, scale, offset)
  local frame = create("Frame", {
    BackgroundColor3 = color or Color3.fromRGB(255, 255, 255),
    BorderSizePixel = 0
  }, {
    create("UICorner", {
      CornerRadius = UDim.new(scale, offset)
    })
  })
  return frame
end)

create_element("button", function()
  local button = create("TextButton", {
    Text = "",
    AutoButtonColor = false,
    BackgroundTransparency = 1,
    BorderSizePixel = 0
  })
	return button
end)

create_element("scroll_frame", function(color, width)
  local scroll_frame = create("ScrollingFrame", {
    BackgroundTransparency = 1,
    MidImage = "rbxassetid://7445543667",
    BottomImage = "rbxassetid://7445543667",
    TopImage = "rbxassetid://7445543667",
    ScrollBarImageColor3 = color,
    BorderSizePixel = 0,
    ScrollBarThickness = width,
    CanvasSize = UDim2.new(0, 0, 0, 0)
  })
  return scroll_frame
end)

create_element("image", function(image_id)
  local image_new = create("ImageLabel", {
    Image = image_id,
    BackgroundTransparency = 1
  })
  if get_icon(image_id) ~= nil then
    image_new.Image = get_icon(image_id)
  end	
  return image_new
end)

create_element("image_button", function(image_id)
  local image = Create("ImageButton", {
    Image = image_id,
    BackgroundTransparency = 1
  })
  return image
end)

create_element("label", function(text, text_size, transparency)
  local label = create("TextLabel", {
    Text = text or "",
    TextColor3 = Color3.fromRGB(240, 240, 240),
    TextTransparency = transparency or 0,
    TextSize = text_size or 15,
    Font = Enum.Font.Gotham,
    RichText = true,
    BackgroundTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Left
  })
  return label
end)

local notification_holder = set_props(set_children(make_element("tframe"),{
  set_props(make_element("list"),{
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0, 5)
  })
}), {
  Position = UDim2.new(1, -25, 1, -25),
  Size = UDim2.new(0, 300, 1, -25),
  AnchorPoint = Vector2.new(1, 1),
  Parent = gui_window
})

function gui_window_library:make_notification(notifaction_config)
  spawn(function()
    notification_config.Name = notification_config.Name or "Notification"
    notification_config.Content = notification_config.Content or "Test"
    notification_config.Image = notification_config.Image or "rbxassetid://4384403532"
    notification_config.Time = notification_config.Time or 10
    local notification_parent = set_props(make_element("tframe"), {
      Size = UDim2.new(1, 0, 0, 0),
      AutomaticSize = Enum.AutomaticSize.Y,
      Parent = notification_holder
    })
    local notification_frame = set_children(set_props(make_element("round_frame",Color3.fromRGB(25, 25, 25), 0, 10),
    {
      Parent = notification_parent,
      Size = UDim2.new(1, 0, 0, 0),
      Position = UDim2.new(1, -55, 0, 0),
      BackgroundTransparency = 0,
      AutomaticSize = Enum.AutomaticSize.Y
    }),{
      make_element("stroke", Color3.fromRGB(93, 93, 93), 1.2),
      make_element("padding",12, 12, 12, 12),
      set_props(make_element("image",notification_config.Image),{
        Size = UDim2.new(0, 20, 0, 20),
        ImageColor3 = Color3.fromRGB(240, 240, 240),
        Name = "Icon"
      }),
      set_props(make_element("lable",notification_config.Name,15),{
        Size = UDim2.new(1, -30, 0, 20),
        Position = UDim2.new(0, 30, 0, 0),
        Font = Enum.Font.GothamBold,
        Name = "Title"
      }),
      set_props(make_element("lable",notification_config.Content,14),{
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 25),
        Font = Enum.Font.GothamSemibold,
        Name = "Content",
        AutomaticSize = Enum.AutomaticSize.Y,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextWrapped = true
      })
    })
    tween_service:Create(notification_frame.Icon,
    TweenInfo.new(0.5, Enum.EasingStyle.Quint),
    {ImageTransparency = 1}):Play()
    tween_service:Create(notification_frame,
    TweenInfo.new(0.8, Enum.EasingStyle.Quint),
    {BackgroundTransparency = 0.6}):Play()
    wait(0.3)
    tween_service:Create(notification_frame.UIStroke,
    TweenInfo.new(0.6, Enum.EasingStyle.Quint),
    {Transparency = 0.9}):Play()
    tween_service:Create(notification_frame.Title,
    TweenInfo.new(0.6, Enum.EasingStyle.Quint),
    {TextTransparency = 0.4}):Play()
    tween_service:Create(notification_frame.Content,
    TweenInfo.new(0.6, Enum.EasingStyle.Quint), 
    {TextTransparency = 0.5}):Play()
    wait(0.05)
    notification_frame:TweenPosition(UDim2.new(1, 20, 0, 0),'In','GUI Window',0.8,true)
    wait(1.35)
    notification_frame:Destroy()
  end)
end

function gui_window_library:init()
  if gui_window_library.save_config then
    pcall(function()
      if isfile(gui_window_library.folder .. "/" .. game.GameId .. ".txt") then
        load_config(readfile(gui_window_library.folder .. "/" .. game.GameId .. ".txt"))
        gui_window_library:make_notification({
          Name = "configuration",
          Content = "Auto load configuration for the game " .. game.GameId .. ".",
          Time = 4
        })
      end
    end)
  end
end

function gui_window_library:make_window(window_config)
  local first_tab = true
  local minimized = false
  local loaded = false
  local ui_hidden = false
  window_config = window_config or {}
  window_config.title = window_config.title or "GUI Window"
  window_config.config_folder = window_config.config_folder or window_config.title
  window_config.save_config = window_config.save_config or false
  window_config.hide_premium = window_config.hide_premium or false
  
  if window_config.intro_enable == nil then
    window_config.intro_enabld = true
  end
  window_config.intro_text = window_config.intro_text or "GUI Window Library"
  window_config.close_call_back = window_config.close_call_back or function()
  end
  window_config.show_icon = window_config.show_icon or false
  window_config.icon = window_config.icon or "rbxassetid://8834748103"
  window_config.intro_icon = window_config.intro_icon or "rbxassetid://8834748103"
  gui_window_library.folder = window_config.config_folder
  gui_window_library.save_config = window_config.save_config
  
  if window_config.save_config then
    if not isfolder(window_config.config_folder) then
      makefolder(window_config.config_folder)
    end
  end
  local tab_holder = add_theme_object(set_children(set_props(make_element("scroll_frame",Color3.fromRGB(255, 255, 255), 4),{
    Size = UDim2.new(1, 0, 1, -50)
  }),{
    make_element("list"),
    make_element("padding",8,0,0,8)
  }),"divider")
  add_connection(tab_holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"),function()
    tab_holder.CanvasSize = UDim2.new(0, 0, 0, tab_holder.UIListLayout.AbsoluteContentSize.Y + 16)
  end)
  local close_button = set_children(set_props(make_element("button"),{
    Size = UDim2.new(0.5, 0, 1, 0),
    Position = UDim2.new(0.5, 0, 0, 0),
    BackgroundTransparency = 1
  }),{
    add_theme_object(set_props(make_element("image","rbxassetid://7072725342"),{
      Position = UDim2.new(0, 9, 0, 6),
      Size = UDim2.new(0, 18, 0, 18)
    }), "text")
  })
  local minimize_button = set_children(set_props(make_element("button"),{
    Size = UDim2.new(0.5, 0, 1, 0),
    BackgroundTransparency = 1
  }),{
    add_theme_object(set_props(make_element("image", "rbxassetid://7072719338"),{
      Position = UDim2.new(0, 9, 0, 6),
      Size = UDim2.new(0, 18, 0, 18),
      Name = "Ico"
    }), "text")
  })
  local darg_point = set_props(make_element("tframe"),{
    Size = UDim2.new(1, 0, 0, 50)
  })
  local window_stuff = add_theme_object(set_children(set_props(make_element("round_frame",Color3.fromRGB(255, 255, 255), 0, 10),{
    Size = UDim2.new(0, 150, 1, -50),
    Position = UDim2.new(0, 0, 0, 50)
  }),{
    add_theme_object(set_props(make_element("frame"),{
      Size = UDim2.new(1, 0, 0, 10),
      Position = UDim2.new(0, 0, 0, 0)
    }), "second"),
    add_theme_object(set_props(make_element("frame"),{
      Size = UDim2.new(0, 10, 1, 0),
      Position = UDim2.new(1, -10, 0, 0)
    }), "second"),
    add_theme_object(set_props(make_element("frame"),{
      Size = UDim2.new(0, 1, 1, 0),
      Position = UDim2.new(1, -1, 0, 0)
    }), "stroke"),
    tab_holder,set_children(set_props(make_element("tframe"),{
      Size = UDim2.new(1, 0, 0, 50),
      Position = UDim2.new(0, 0, 1, -50)
    }),{
      add_theme_object(set_props(make_element("frame"),{
        Size = UDim2.new(1, 0, 0, 1)
      }), "stroke"),
      add_theme_object(set_children(set_props(make_element("frame"),{
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(0, 10, 0.5, 0)
      }),{
        set_props(make_element("image","https://www.roblox.com/headshot-thumbnail/image?userId="..local_player.UserId.."&width=420&height=420&format=png"),{
          Size = UDim2.new(1, 0, 1, 0)
        }),
        add_theme_object(set_props(make_element("image","rbxassetid://4031889928"),{
          Size = UDim2.new(1, 0, 1, 0),
        }), "second"),
        make_element("corner",1)
      }), "divider"),
      set_children(set_props(make_element("tframe"),{
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(0, 10, 0.5, 0)
      }),{
        add_theme_object(make_element("stroke"),"stroke"),
        make_element("corner",1)
      }),
      add_theme_object(set_props(make_element("label",local_player.DisplayName,window_config.hide_premium and 14 or 13),{
        Size = UDim2.new(1, -60, 0, 13),
        Position = WindowConfig.HidePremium and UDim2.new(0, 50, 0, 19) or UDim2.new(0, 50, 0, 12),
        Font = Enum.Font.GothamBold,
        ClipsDescendants = true
      }), "text"),
      add_theme_object(set_props(make_element("label","",12),{
        Size = UDim2.new(1, -60, 0, 12),
        Position = UDim2.new(0, 50, 1, -25),
        Visible = not WindowConfig.HidePremium
      }), "text_dark")
    }),
  }) "second")
  local window_title = add_theme_object(set_props(make_element("label",window_config.title,14),{
    Size = UDim2.new(1, -30, 2, 0),
    Position = UDim2.new(0, 25, 0, -24),
    Font = Enum.Font.GothamBlack,
    TextSize = 20
  }), "text")
  local window_top_bar_line = add_theme_object(set_props(make_element("frame"),{
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 1, -1)
  }), "stroke")
  local main_window = add_theme_object(set_children(set_props(make_element("round_frame",Color3.fromRGB(255, 255, 255), 0, 10),{
    Parent = gui_window,
    Position = UDim2.new(0.5, -307, 0.5, -172),
    Size = UDim2.new(0, 615, 0, 344),
    ClipsDescendants = true
  }),{
    set_children(set_props(make_element("tframe"),{
      Size = UDim2.new(1, 0, 0, 50),
      Name = "TopBar"
    }),{
      window_title,
      window_top_bar_line,
      add_theme_object(set_children(set_props(make_element("round_frame",Color3.fromRGB(255, 255, 255), 0, 7),{
        Size = UDim2.new(0, 70, 0, 30),
        Position = UDim2.new(1, -90, 0, 10)
      }),{
        add_theme_object(make_element("stroke"), "stroke"),
        add_theme_object(set_props(make_element("frame"),{
          Size = UDim2.new(0, 1, 1, 0),
          Position = UDim2.new(0.5, 0, 0, 0)
        }), "stroke"),
        close_button,
        minimize_button
      }), "second"),
    }),
    darg_point,
    window_stuff
  }),"main")
  if window_config.show_icon then
    window_title.Position = UDim2.new(0, 50, 0, -24)
    local window_icon = set_props(make_element("Image",window_config.icon),{
      Size = UDim2.new(0, 20, 0, 20),
      Position = UDim2.new(0, 25, 0, 15)
    })
    window_icon.Parent = main_window.TopBar
  end
  make_draggable(darg_point,main_window)
  add_connection(close_button.MouseButton1Up,function()
    main_window.Visible = false
    ui_hidden = true
    gui_window_library:make_notification({
      Name = "GUI Window Library Interface Hidden",
      Content = "Tap RightShift To Reopen The GUI Window Interface",
      Time = 4
    })
    window_config.close_call_back()
  end)
  add_connection(user_input_service.InputBegan, function(Input)
    if Input.KeyCode == Enum.KeyCode.RightShift and ui_hidden then
      main_window.Visible = true
    end
  end)
  add_connection(minimize_button.MouseButton1Up, function()
    if minimized then
      tween_service:Create(main_window,
      TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
      {Size = UDim2.new(0, 615, 0, 344)}):Play()
      minimize_button.Ico.Image = "rbxassetid://7072719338"
      wait(0.3)
      main_window.ClipsDescendants = false
      window_stuff.Visible = true
      window_top_bar_line.Visible = true
    else
      main_window.ClipsDescendants = true
      window_top_bar_line.Visible = false
      minimize_button.Ico.Image = "rbxassetid://7072720870"
      tween_service:Create(main_window, 
      TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), 
      {Size = UDim2.new(0, window_title.TextBounds.X + 140, 0, 50)}):Play()
      wait(0.1)
      window_stuff.Visible = false
    end
    minimized = not minimized
  end)
  local function load_sequence()
    main_window.Visible = false
    local load_sequence_logo = set_props(make_element("image",window_config.intro_icon),{
      Parent = gui_window,
      AnchorPoint = Vector2.new(0.5, 0.5),
      Position = UDim2.new(0.5, 0, 0.4, 0),
      Size = UDim2.new(0, 28, 0, 28),
      ImageColor3 = Color3.fromRGB(255, 255, 255),
      ImageTransparency = 1
    })
    local load_sequence_text = set_props(make_element("label",window_config.intro_text,14),{
      Parent = gui_window,
      Size = UDim2.new(1, 0, 1, 0),
      AnchorPoint = Vector2.new(0.5, 0.5),
      Position = UDim2.new(0.5, 19, 0.5, 0),
      TextXAlignment = Enum.TextXAlignment.Center,
      Font = Enum.Font.GothamBold,
      TextTransparency = 1
    })
    tween_service:Create(load_sequence_logo, 
    TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
    {ImageTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
    wait(0.5)
    tween_service:Create(load_sequence_logo, 
    TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
    {Position = UDim2.new(0.5, -(load_sequence_text.TextBounds.X/2), 0.5, 0)}):Play()
    wait(0.3)
    tween_service:Create(load_sequence_text, 
    TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    {TextTransparency = 0}):Play()
    wait(1.3)
    tween_service:Create(load_sequence_text, 
    TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
    {TextTransparency = 1}):Play()
    main_window.Visible = true
    load_sequence_logo:Destroy()
    load_sequence_text:Destroy()
  end
  
  if window_config.intro_enabld then
    load_sequence()
  end
  
  local tab_function = {}
  function tab_function:make_tab(tab_config)
    tab_config = tab_config or {}
    tab_config.name = tab_config.name or "Tab"
    tab_config.icon = tab_config.icon or ""
    tab_config.premium_only = tab_config.premium_only or false
    local tab_frame = set_children(set_props(make_element("button"),{
      Size = UDim2.new(1, 0, 0, 30),
      Parent = tab_holder
    }),{
      add_theme_object(set_props(make_element("image",tab_config.icon),{
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 10, 0.5, 0),
        ImageTransparency = 0.4,
        Name = "Ico"
      }), "text"),
      add_theme_object(set_props(make_element("label",tab_config.name,14),{
        Size = UDim2.new(1, -35, 1, 0),
        Position = UDim2.new(0, 35, 0, 0),
        Font = Enum.Font.GothamSemibold,
        TextTransparency = 0.4,
        Name = "Title"
      }), "text")
    })
    if get_icon(tab_config.icon) ~= nil then
      tab_frame.Ico.Image = get_icon(tab_config.icon)
    end
    local container = add_theme_object(set_children(set_props(make_element("scroll_frame", Color3.fromRGB(255, 255, 255), 5),{
      Size = UDim2.new(1, -150, 1, -50),
      Position = UDim2.new(0, 150, 0, 50),
      Parent = main_window,
      Visible = false,
      Name = "ItemContainer"
    }),{
      make_element("list",0,6),
      make_element("padding",15, 10, 10, 15)
    }), "divider")
    add_connection(container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
      container.CanvasSize = UDim2.new(0, 0, 0, container.UIListLayout.AbsoluteContentSize.Y + 30)
    end)
    if first_tab then
      first_tab = false
      tab_frame.Ico.ImageTransparency = 0
      tab_frame.Title.TextTransparency = 0
      tab_frame.Title.Font = Enum.Font.GothamBlack
      container.Visible = true
    end
    add_connection(tab_frame.MouseButton1Click, function()
      for _, tab in next, tab_holder:GetChildren() do
        if tab:IsA("TextButton") then
          tab.Title.Font = Enum.Font.GothamSemibold
          tween_service:Create(tab.Ico, 
          TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), 
          {ImageTransparency = 0.4}):Play()
          tween_service:Create(tab.Title, 
          TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
          {TextTransparency = 0.4}):Play()
        end
      end
      for _, item_container in next, main_window:GetChildren() do
        if item_container.Name == "ItemContainer" then
          item_container.Visible = false
        end
      end
      tween_service:Create(tab_frame.Ico, 
      TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), 
      {ImageTransparency = 0}):Play()
      tween_service:Create(tab_frame.Title, 
      TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), 
      {TextTransparency = 0}):Play()
      tab_frame.Title.Font = Enum.Font.GothamBlack
      container.Visible = true   
    end)
    local function get_elements(item_parent)
      local element_function = {}
      function element_function:add_label(text)
        local label_frame = add_theme_object(set_children(set_props(make_element("round_frame",Color3.fromRGB(255, 255, 255), 0, 5),{
          Size = UDim2.new(1, 0, 0, 30),
          BackgroundTransparency = 0.7,
          Parent = item_parent
        }),{
          add_theme_object(set_props(make_element("label",text,14),{
            Size = UDim2.new(1, -12, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            Font = Enum.Font.GothamBold,
            Name = "Content"
          }), "text"),
          add_theme_object(make_element("stroke"),"stroke")
        }),
        "second")
        local lable_function = {}
        function lable_function:set(to_change)
          lable_function.Content.Text = to_change
        end
        return lable_function
      end
      function element_function:add_paragraph(text,content)
        text = text or "Text"
        content = content or "Content"
        local paragraph_frame = add_theme_object(set_children(set_props(make_element("round_frame",Color3.fromRGB(255, 255, 255), 0, 5),{
          Size = UDim2.new(1, 0, 0, 30),
          BackgroundTransparency = 0.7,
          Parent = item_parent
        }),{
          add_theme_object(set_props(make_element("label",text,15),{
            Size = UDim2.new(1, -12, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            Font = Enum.Font.GothamBold,
            Name = "Content"
          }), "text"),
          add_theme_object(make_element("stroke"), "stroke")
        }), "second")
        
      end
    end
  end
end


function gui_window_library:destroy()
  gui_window_library:Destroy()
end

return gui_window_library