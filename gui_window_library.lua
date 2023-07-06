

local user_input_service = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local run_service = game:GetService("RunService")
local local_player = game:GetService("Players").LocalPlayer
local mouse = local_player:GetMouse()
local http_service = game:GetService("HttpService")

local gui_window_library = {
	elements = {},
	theme_objects = {},
	connections = {},
	flags = {},
	themes = {
		Default = {
			main = Color3.fromRGB(37, 38, 38),
			second = Color3.fromRGB(36, 38, 38),
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

local success, response = pcall(function()
	icons = http_service:JSONDecode(game:HttpGetAsync("https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json")).icons
end)

if not success then
	warn("\nGUI Window Library - Failed to> load Feather Icons. Error code : " .. response .. "\n")
end	

local function get_icon(icon_name)
	if icons[icon_name] ~= nil then
		return icons[icon_name]
	else
		return nil
	end
end   

local gui_window = Instance.new("ScreenGui")
gui_window.Name = "gui_window"
if syn then
	syn.protect_gui(gui_window)
	gui_window.Parent = game.CoreGui
else
	gui_window.Parent = gethui() or game.CoreGui
end

if gethui then
	for _, interface in ipairs(gethui():GetChildren()) do
		if interface.Name == gui_window.Name and interface ~= gui_window then
			interface:Destroy()
		end
	end
else
	for _, interface in ipairs(game.CoreGui:GetChildren()) do
		if interface.Name == gui_window.Name and interface ~= gui_window then
			interface:Destroy()
		end
	end
end

function gui_window_library:is_running()
	if gethui then
		return gui_window.Parent == gethui()
	else
		return gui_window.Parent == game:GetService("CoreGui")
	end

end

local function add_connection(Signal, Function)
	if (not gui_window_library:is_running()) then
		return
	end
	local SignalConnect = Signal:Connect(Function)
	table.insert(gui_window_library.connections, SignalConnect)
	return SignalConnect
end

task.spawn(function()
	while (gui_window_library:is_running()) do
		wait()
	end

	for _, Connection in next, gui_window_library.connections do
		Connection:Disconnect()
	end
end)

local function make_draggable(drag_point, main)
	pcall(function()
		local dragging, drag_input, mouse_position, frame_position = false
		add_connection(drag_point.InputBegan, function(Input)
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
		add_connection(drag_point.InputChanged, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement then
				drag_input = Input
			end
		end)
		add_connection(user_input_service.InputChanged, function(Input)
			if Input == drag_input and dragging then
				local delta = Input.Position - mouse_position
				main.Position  = UDim2.new(frame_position.X.Scale,frame_position.X.Offset + delta.X, frame_position.Y.Scale, frame_position.Y.Offset + delta.Y)
			end
		end)
	end)
end    

local function create(Name, Properties, Children)
	local Object = Instance.new(Name)
	for i, v in next, Properties or {} do
		Object[i] = v
	end
	for i, v in next, Children or {} do
		v.Parent = Object
	end
	return Object
end

local function create_element(element_name, element_function)
	gui_window_library.elements[element_name] = function(...)
		return element_function(...)
	end
end

local function make_element(element_name, ...)
	local NewElement = gui_window_library.elements[element_name](...)
	return NewElement
end

local function set_props(Element, Props)
	table.foreach(Props, function(Property, Value)
		Element[Property] = Value
	end)
	return Element
end

local function set_children(Element, Children)
	table.foreach(Children, function(_, Child)
		Child.Parent = Element
	end)
	return Element
end

local function round(Number, Factor)
	local Result = math.floor(Number/Factor + (math.sign(Number) * 0.5)) * Factor
	if Result < 0 then Result = Result + Factor end
	return Result
end

local function return_property(Object)
	if Object:IsA("Frame") or Object:IsA("TextButton") then
		return "BackgroundColor3"
	end 
	if Object:IsA("ScrollingFrame") then
		return "ScrollBarImageColor3"
	end 
	if Object:IsA("UIStroke") then
		return "Color"
	end 
	if Object:IsA("TextLabel") or Object:IsA("TextBox") then
		return "TextColor3"
	end   
	if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
		return "ImageColor3"
	end   
end

local function add_theme_object(Object, Type)
	if not gui_window_library.theme_objects[Type] then
		gui_window_library.theme_objects[Type] = {}
	end    
	table.insert(gui_window_library.theme_objects[Type], Object)
	Object[return_property(Object)] = gui_window_library.themes[gui_window_library.selected_theme][Type]
	return Object
end    

local function set_theme()
	for Name, Type in pairs(gui_window_library.theme_objects) do
		for _, Object in pairs(Type) do
			Object[return_property(Object)] = gui_window_library.themes[gui_window_library.selected_theme][Name]
		end    
	end    
end

local function pack_color(Color)
	return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end    

local function unpack_color(Color)
	return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local function load_config(Config)
	local Data = http_service:JSONDecode(Config)
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
			warn("gui_window Library Config Loader - Could not find ", a ,b)
		end
	end)
end

local function save_config(Name)
	local Data = {}
	for i,v in pairs(gui_window_library.flags) do
		if v.Save then
			if v.Type == "Colorpicker" then
				Data[i] = pack_color(v.Value)
			else
				Data[i] = v.Value
			end
		end	
	end
	writefile(gui_window_library.folder .. "/" .. Name .. ".txt", tostring(http_service:JSONEncode(Data)))
end

local white_listed_mouse = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2,Enum.UserInputType.MouseButton3}
local black_listed_keys = {Enum.KeyCode.Unknown,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Left,Enum.KeyCode.Down,Enum.KeyCode.Right,Enum.KeyCode.Slash,Enum.KeyCode.Tab,Enum.KeyCode.Backspace,Enum.KeyCode.Escape}

local function check_key(Table, Key)
	for _, v in next, Table do
		if v == Key then
			return true
		end
	end
end

create_element("Corner", function(Scale, Offset)
	local Corner = create("UICorner", {
		CornerRadius = UDim.new(Scale or 0, Offset or 10)
	})
	return Corner
end)

create_element("Stroke", function(Color, Thickness)
	local Stroke = create("UIStroke", {
		Color = Color or Color3.fromRGB(255, 255, 255),
		Thickness = Thickness or 1
	})
	return Stroke
end)

create_element("List", function(Scale, Offset)
	local List = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(Scale or 0, Offset or 0)
	})
	return List
end)

create_element("Padding", function(Bottom, Left, Right, Top)
	local Padding = create("UIPadding", {
		PaddingBottom = UDim.new(0, Bottom or 4),
		PaddingLeft = UDim.new(0, Left or 4),
		PaddingRight = UDim.new(0, Right or 4),
		PaddingTop = UDim.new(0, Top or 4)
	})
	return Padding
end)

create_element("TFrame", function()
	local TFrame = create("Frame", {
		BackgroundTransparency = 1
	})
	return TFrame
end)

create_element("Frame", function(Color)
	local Frame = create("Frame", {
		BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0
	})
	return Frame
end)

create_element("RoundFrame", function(Color, Scale, Offset)
	local Frame = create("Frame", {
		BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0
	}, {
		create("UICorner", {
			CornerRadius = UDim.new(Scale, Offset)
		})
	})
	return Frame
end)

create_element("Button", function()
	local Button = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0
	})
	return Button
end)

create_element("ScrollFrame", function(Color, Width)
	local ScrollFrame = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		MidImage = "rbxassetid://7445543667",
		BottomImage = "rbxassetid://7445543667",
		TopImage = "rbxassetid://7445543667",
		ScrollBarImageColor3 = Color,
		BorderSizePixel = 0,
		ScrollBarThickness = Width,
		CanvasSize = UDim2.new(0, 0, 0, 0)
	})
	return ScrollFrame
end)

create_element("Image", function(ImageID)
	local ImageNew = create("ImageLabel", {
		Image = ImageID,
		BackgroundTransparency = 1
	})

	if get_icon(ImageID) ~= nil then
		ImageNew.Image = get_icon(ImageID)
	end	

	return ImageNew
end)

create_element("ImageButton", function(ImageID)
	local Image = create("ImageButton", {
		Image = ImageID,
		BackgroundTransparency = 1
	})
	return Image
end)

create_element("Label", function(Text, TextSize, Transparency)
	local Label = create("TextLabel", {
		Text = Text or "",
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextTransparency = Transparency or 0,
		TextSize = TextSize or 15,
		Font = Enum.Font.Gotham,
		RichText = true,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	return Label
end)

local notification_holder = set_props(set_children(make_element("TFrame"), {
	set_props(make_element("List"), {
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

function gui_window_library:make_notification(notification_config)
	spawn(function()
		notification_config.name = notification_config.name or "Notification"
		notification_config.content = notification_config.content or "Test"
		notification_config.image = notification_config.image or "rbxassetid://4384403532"
		notification_config.time = notification_config.time or 15

		local notification_parent = set_props(make_element("TFrame"), {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = notification_holder
		})

		local notification_frame = set_children(set_props(make_element("RoundFrame", Color3.fromRGB(25, 25, 25), 0, 10), {
			Parent = notification_parent, 
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(1, -55, 0, 0),
			BackgroundTransparency = 0,
			AutomaticSize = Enum.AutomaticSize.Y
		}), {
			make_element("Stroke", Color3.fromRGB(93, 93, 93), 1.2),
			make_element("Padding", 12, 12, 12, 12),
			set_props(make_element("Image", notification_config.image), {
				Size = UDim2.new(0, 20, 0, 20),
				ImageColor3 = Color3.fromRGB(240, 240, 240),
				Name = "Icon"
			}),
			set_props(make_element("Label", notification_config.name, 15), {
				Size = UDim2.new(1, -30, 0, 20),
				Position = UDim2.new(0, 30, 0, 0),
				Font = Enum.Font.GothamBold,
				Name = "Title"
			}),
			set_props(make_element("Label", notification_config.content, 14), {
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 0, 25),
				Font = Enum.Font.GothamSemibold,
				Name = "Content",
				AutomaticSize = Enum.AutomaticSize.Y,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				TextWrapped = true
			})
		})

		tween_service:Create(notification_frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 0, 0, 0)}):Play()

		wait(notification_config.time - 0.88)
		tween_service:Create(notification_frame.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
		tween_service:Create(notification_frame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.6}):Play()
		wait(0.3)
		tween_service:Create(notification_frame.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0.9}):Play()
		tween_service:Create(notification_frame.Title, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play()
		tween_service:Create(notification_frame.Content, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.5}):Play()
		wait(0.05)

		notification_frame:TweenPosition(UDim2.new(1, 20, 0, 0),'In','Quint',0.8,true)
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
					name = "GUI Window Configuration",
					content = "Auto loaded Configuration For The Game : " .. game.GameId .. ".",
					time = 5
				})
			end
		end)		
	end	
end	

function gui_window_library:make_window(window_config)
	local first_tab = true
	local minimized = false
	local ui_hidden = false
	window_config = window_config or {}
	window_config.title = window_config.title or "GUI Window Library"
	window_config.config_folder = window_config.config_folder or window_config.title
	window_config.save_config = window_config.save_config or false
	window_config.hide_premium = window_config.hide_premium or false
	window_config.intro_enabled = window_config.intro_enabled or false
	
	window_config.intro_text = window_config.intro_text or "GUI Window Library"
	window_config.close_call_back = window_config.close_call_back or function() end
	window_config.show_icon = window_config.show_icon or false
	window_config.Icon = window_config.Icon or "rbxassetid://8834748103"
	window_config.IntroIcon = window_config.IntroIcon or "rbxassetid://8834748103"
	gui_window_library.folder = window_config.config_folder
	gui_window_library.save_config = window_config.save_config

	if window_config.save_config then
		if not isfolder(window_config.config_folder) then
			makefolder(window_config.config_folder)
		end	
	end

	local tab_holder = add_theme_object(set_children(set_props(make_element("ScrollFrame", Color3.fromRGB(255, 255, 255), 4), {
		Size = UDim2.new(1, 0, 1, -50)
	}), {
		make_element("List"),
		make_element("Padding", 8, 0, 0, 8)
	}), "divider")

	add_connection(tab_holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		tab_holder.CanvasSize = UDim2.new(0, 0, 0, tab_holder.UIListLayout.AbsoluteContentSize.Y + 16)
	end)

	local close_button = set_children(set_props(make_element("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundTransparency = 1
	}), {
		add_theme_object(set_props(make_element("Image", "rbxassetid://7072725342"), {
			Position = UDim2.new(0, 9, 0, 6),
			Size = UDim2.new(0, 18, 0, 18)
		}), "text")
	})

	local minimize_button = set_children(set_props(make_element("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1
	}), {
		add_theme_object(set_props(make_element("Image", "rbxassetid://7072719338"), {
			Position = UDim2.new(0, 9, 0, 6),
			Size = UDim2.new(0, 18, 0, 18),
			Name = "Ico"
		}), "text")
	})

	local drag_point = set_props(make_element("TFrame"), {
		Size = UDim2.new(1, 0, 0, 50)
	})

	local window_stuff = add_theme_object(set_children(set_props(make_element("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), {
		Size = UDim2.new(0, 150, 1, -50),
		Position = UDim2.new(0, 0, 0, 50)
	}), {
		add_theme_object(set_props(make_element("Frame"), {
			Size = UDim2.new(1, 0, 0, 10),
			Position = UDim2.new(0, 0, 0, 0)
		}), "second"), 
		add_theme_object(set_props(make_element("Frame"), {
			Size = UDim2.new(0, 10, 1, 0),
			Position = UDim2.new(1, -10, 0, 0)
		}), "second"), 
		add_theme_object(set_props(make_element("Frame"), {
			Size = UDim2.new(0, 1, 1, 0),
			Position = UDim2.new(1, -1, 0, 0)
		}), "stroke"), 
		tab_holder
		
	}), "second")

	local window_title = add_theme_object(set_props(make_element("Label", window_config.title, 14), {
		Size = UDim2.new(1, -30, 2, 0),
		Position = UDim2.new(0, 25, 0, -24),
		Font = Enum.Font.GothamBlack,
		TextSize = 20
	}), "text")

	local window_top_bar_line = add_theme_object(set_props(make_element("Frame"), {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1)
	}), "stroke")

	local main_window = add_theme_object(set_children(set_props(make_element("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), {
		Parent = gui_window,
		Position = UDim2.new(0.5, -307, 0.5, -172),
		Size = UDim2.new(0, 615, 0, 344),
		ClipsDescendants = true
	}), {
		
		set_children(set_props(make_element("TFrame"), {
			Size = UDim2.new(1, 0, 0, 50),
			Name = "TopBar"
		}), {
			window_title,
			window_top_bar_line,
			add_theme_object(set_children(set_props(make_element("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 7), {
				Size = UDim2.new(0, 70, 0, 30),
				Position = UDim2.new(1, -90, 0, 10)
			}), {
				add_theme_object(make_element("Stroke"), "stroke"),
				add_theme_object(set_props(make_element("Frame"), {
					Size = UDim2.new(0, 1, 1, 0),
					Position = UDim2.new(0.5, 0, 0, 0)
				}), "stroke"), 
				close_button,
				minimize_button
			}), "second"), 
		}),
		drag_point,
		window_stuff
	}), "main")

	if window_config.show_icon then
		window_title.Position = UDim2.new(0, 50, 0, -24)
		local window_icon = set_props(make_element("Image", window_config.Icon), {
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.new(0, 25, 0, 15)
		})
		window_icon.Parent = main_window.TopBar
	end	

	make_draggable(drag_point, main_window)

	add_connection(close_button.MouseButton1Up, function()
		main_window.Visible = false
		ui_hidden = true
		gui_window_library:make_notification({
			name = "GUI Window Interface Hidden",
			content = "Tap RightShift To Reopen The Interface",
			time = 5
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
			tween_service:Create(main_window, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 615, 0, 344)}):Play()
			minimize_button.Ico.Image = "rbxassetid://7072719338"
			wait(.02)
			main_window.ClipsDescendants = false
			window_stuff.Visible = true
			window_top_bar_line.Visible = true
		else
			main_window.ClipsDescendants = true
			window_top_bar_line.Visible = false
			minimize_button.Ico.Image = "rbxassetid://7072720870"

			tween_service:Create(main_window, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, window_title.TextBounds.X + 140, 0, 50)}):Play()
			wait(0.1)
			window_stuff.Visible = false	
		end
		minimized = not minimized    
	end)

	local function load_sequence()
		main_window.Visible = false
		local load_sequene_logo = set_props(make_element("Image", window_config.IntroIcon), {
			Parent = gui_window,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.4, 0),
			Size = UDim2.new(0, 28, 0, 28),
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			ImageTransparency = 1
		})

		local load_sequene_text = set_props(make_element("Label", window_config.intro_text, 14), {
			Parent = gui_window,
			Size = UDim2.new(1, 0, 1, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 19, 0.5, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = Enum.Font.GothamBold,
			TextTransparency = 1
		})

		tween_service:Create(load_sequene_logo, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
		wait(0.8)
		tween_service:Create(load_sequene_logo, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -(load_sequene_text.TextBounds.X/2), 0.5, 0)}):Play()
		wait(0.3)
		tween_service:Create(load_sequene_text, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
		wait(2)
		tween_service:Create(load_sequene_text, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
		main_window.Visible = true
		load_sequene_logo:Destroy()
		load_sequene_text:Destroy()
	end 

	if window_config.intro_enabled then
		load_sequence()
	end	

	local tab_function = {}
	function tab_function:make_tab(tab_config)
		tab_config = tab_config or {}
		tab_config.name = tab_config.name or "Tab"
		tab_config.icon = tab_config.icon or ""
		tab_config.premium_only = tab_config.premium_only or false

		local tab_frame = set_children(set_props(make_element("Button"), {
			Size = UDim2.new(1, 0, 0, 30),
			Parent = tab_holder
		}), {
			add_theme_object(set_props(make_element("Image", tab_config.icon), {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0, 18, 0, 18),
				Position = UDim2.new(0, 10, 0.5, 0),
				ImageTransparency = 0.4,
				Name = "Ico"
			}), "text"),
			add_theme_object(set_props(make_element("Label", tab_config.name, 14), {
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

		local container = add_theme_object(set_children(set_props(make_element("ScrollFrame", Color3.fromRGB(255, 255, 255), 5), {
			Size = UDim2.new(1, -150, 1, -50),
			Position = UDim2.new(0, 150, 0, 50),
			Parent = main_window,
			Visible = false,
			Name = "ItemContainer"
		}), {
			make_element("List", 0, 6),
			make_element("Padding", 15, 10, 10, 15)
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
			for _, Tab in next, tab_holder:GetChildren() do
				if Tab:IsA("TextButton") then
					Tab.Title.Font = Enum.Font.GothamSemibold
					tween_service:Create(Tab.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0.4}):Play()
					tween_service:Create(Tab.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
				end    
			end
			for _, item_container in next, main_window:GetChildren() do
				if item_container.Name == "ItemContainer" then
					item_container.Visible = false
				end    
			end  
			tween_service:Create(tab_frame.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
			tween_service:Create(tab_frame.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
			tab_frame.Title.Font = Enum.Font.GothamBlack
			container.Visible = true   
		end)

		local function get_elements(item_parent)
			local element_function = {}
			function element_function:add_label(Text)
				local label_frame = add_theme_object(set_children(set_props(make_element("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 0.7,
					Parent = item_parent
				}), {
					add_theme_object(set_props(make_element("Label", Text, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "text"),
					add_theme_object(make_element("Stroke"), "stroke")
				}), "second")

				local label_function = {}
				function label_function:set(to_change)
					label_frame.Content.Text = to_change
				end
				return label_function
			end
			function element_function:add_paragraph(Text, Content)
				Text = Text or "text"
				Content = Content or "Content"

				local paragraph_frame = add_theme_object(set_children(set_props(make_element("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 0.7,
					Parent = item_parent
				}), {
					add_theme_object(set_props(make_element("Label", Text, 15), {
						Size = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 10),
						Font = Enum.Font.GothamBold,
						Name = "Title"
					}), "text"),
					add_theme_object(set_props(make_element("Label", "", 13), {
						Size = UDim2.new(1, -24, 0, 0),
						Position = UDim2.new(0, 12, 0, 26),
						Font = Enum.Font.GothamSemibold,
						Name = "Content",
						TextWrapped = true
					}), "text_dark"),
					add_theme_object(make_element("Stroke"), "stroke")
				}), "second")

				add_connection(paragraph_frame.Content:GetPropertyChangedSignal("Text"), function()
					paragraph_frame.Content.Size = UDim2.new(1, -24, 0, paragraph_frame.Content.TextBounds.Y)
					paragraph_frame.Size = UDim2.new(1, 0, 0, paragraph_frame.Content.TextBounds.Y + 35)
				end)

				paragraph_frame.Content.Text = Content

				local paragraph_function = {}
				function paragraph_function:set(to_change)
					paragraph_frame.Content.Text = to_change
				end
				return paragraph_function
			end    
			function element_function:add_button(button_config)
				button_config = button_config or {}
				button_config.name = button_config.name or "Button"
				button_config.call_back = button_config.call_back or function() end
				button_config.icon = button_config.icon or "rbxassetid://3944703587"

				local Button = {}

				local Click = set_props(make_element("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local button_frame = add_theme_object(set_children(set_props(make_element("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size = UDim2.new(1, 0, 0, 33),
					Parent = item_parent
				}), {
					add_theme_object(set_props(make_element("Label", button_config.name, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "text"),
					add_theme_object(set_props(make_element("Image", button_config.icon), {
						Size = UDim2.new(0, 20, 0, 20),
						Position = UDim2.new(1, -30, 0, 7),
					}), "text_dark"),
					add_theme_object(make_element("Stroke"), "stroke"),
					Click
				}), "second")

				add_connection(Click.MouseEnter, function()
					tween_service:Create(button_frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(gui_window_library.themes[gui_window_library.selected_theme].second.R * 255 + 3, gui_window_library.themes[gui_window_library.selected_theme].second.G * 255 + 3, gui_window_library.themes[gui_window_library.selected_theme].second.B * 255 + 3)}):Play()
				end)

				add_connection(Click.MouseLeave, function()
					tween_service:Create(button_frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = gui_window_library.themes[gui_window_library.selected_theme].second}):Play()
				end)

				add_connection(Click.MouseButton1Up, function()
					tween_service:Create(button_frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(gui_window_library.themes[gui_window_library.selected_theme].second.R * 255 + 3, gui_window_library.themes[gui_window_library.selected_theme].second.G * 255 + 3, gui_window_library.themes[gui_window_library.selected_theme].second.B * 255 + 3)}):Play()
					spawn(function()
						button_config.call_back()
					end)
				end)

				add_connection(Click.MouseButton1Down, function()
					tween_service:Create(button_frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(gui_window_library.themes[gui_window_library.selected_theme].second.R * 255 + 6, gui_window_library.themes[gui_window_library.selected_theme].second.G * 255 + 6, gui_window_library.themes[gui_window_library.selected_theme].second.B * 255 + 6)}):Play()
				end)

				function button:set(button_text)
					button_frame.Content.Text = button_text
				end	

				return Button
			end    
			function element_function:add_toggle(toggle_config)
				toggle_config = toggle_config or {}
				toggle_config.name  = toggle_config.name  or "Toggle"
				toggle_config.default = toggle_config.default or false
				toggle_config.call_back = toggle_config.call_back or function() end
				toggle_config.color = toggle_config.color or Color3.fromRGB(9, 99, 195)
				toggle_config.flag = toggle_config.flag or nil
				toggle_config.save = toggle_config.save or false

				local toggle = {value = toggle_config.default, save = toggle_config.save}

				local Click = set_props(make_element("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local toggle_box = set_children(set_props(make_element("RoundFrame", toggle_config.color, 0, 4), {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, -24, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5)
				}), {
					set_props(make_element("Stroke"), {
						Color = toggle_config.color,
						Name = "Stroke",
						Transparency = 0.5
					}),
					set_props(make_element("Image", "rbxassetid://3944680095"), {
						Size = UDim2.new(0, 20, 0, 20),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						ImageColor3 = Color3.fromRGB(255, 255, 255),
						Name = "Ico"
					}),
				})

				local toggle_frame = add_theme_object(set_children(set_props(make_element("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = item_parent
				}), {
					add_theme_object(set_props(make_element("Label", toggle_config.name , 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "text"),
					add_theme_object(make_element("Stroke"), "stroke"),
					toggle_box,
					Click
				}), "second")

				function toggle:set(Value)
					toggle.value = Value
					tween_service:Create(toggle_box, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = toggle.value and toggle_config.color or gui_window_library.themes.Default.divider}):Play()
					tween_service:Create(toggle_box.Stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Color = toggle.value and toggle_config.color or gui_window_library.themes.Default.Stroke}):Play()
					tween_service:Create(toggle_box.Ico, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = toggle.value and 0 or 1, Size = toggle.value and UDim2.new(0, 20, 0, 20) or UDim2.new(0, 8, 0, 8)}):Play()
					toggle_config.call_back(toggle.value)
				end    

				toggle:set(toggle.value)

				add_connection(Click.MouseEnter, function()
					tween_service:Create(toggle_frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(gui_window_library.themes[gui_window_library.selected_theme].second.R * 255 + 3, gui_window_library.themes[gui_window_library.selected_theme].second.G * 255 + 3, gui_window_library.themes[gui_window_library.selected_theme].second.B * 255 + 3)}):Play()
				end)

				add_connection(Click.MouseLeave, function()
					tween_service:Create(toggle_frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = gui_window_library.themes[gui_window_library.selected_theme].second}):Play()
				end)

				add_connection(Click.MouseButton1Up, function()
					tween_service:Create(toggle_frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(gui_window_library.themes[gui_window_library.selected_theme].second.R * 255 + 3, gui_window_library.themes[gui_window_library.selected_theme].second.G * 255 + 3, gui_window_library.themes[gui_window_library.selected_theme].second.B * 255 + 3)}):Play()
					save_config(game.GameId)
					toggle:set(not toggle.value)
				end)

				add_connection(Click.MouseButton1Down, function()
					tween_service:Create(toggle_frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(gui_window_library.themes[gui_window_library.selected_theme].second.R * 255 + 6, gui_window_library.themes[gui_window_library.selected_theme].second.G * 255 + 6, gui_window_library.themes[gui_window_library.selected_theme].second.B * 255 + 6)}):Play()
				end)

				if toggle_config.flag then
					gui_window_library.flags[toggle_config.flag] = toggle
				end	
				return toggle
			end  
			function element_function:AddSlider(SliderConfig)
				SliderConfig = SliderConfig or {}
				SliderConfig.Name = SliderConfig.Name or "Slider"
				SliderConfig.Min = SliderConfig.Min or 0
				SliderConfig.Max = SliderConfig.Max or 100
				SliderConfig.Increment = SliderConfig.Increment or 1
				SliderConfig.Default = SliderConfig.Default or 50
				SliderConfig.Callback = SliderConfig.Callback or function() end
				SliderConfig.ValueName = SliderConfig.ValueName or ""
				SliderConfig.Color = SliderConfig.Color or Color3.fromRGB(9, 149, 98)
				SliderConfig.Flag = SliderConfig.Flag or nil
				SliderConfig.Save = SliderConfig.Save or false

				local Slider = {Value = SliderConfig.Default, Save = SliderConfig.Save}
				local dragging = false

				local SliderDrag = set_children(set_props(make_element("RoundFrame", SliderConfig.Color, 0, 5), {
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundTransparency = 0.3,
					ClipsDescendants = true
				}), {
					add_theme_object(set_props(make_element("Label", "value", 13), {
						Size = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 6),
						Font = Enum.Font.GothamBold,
						Name = "Value",
						TextTransparency = 0
					}), "text")
				})

				local SliderBar = set_children(set_props(make_element("RoundFrame", SliderConfig.Color, 0, 5), {
					Size = UDim2.new(1, -24, 0, 26),
					Position = UDim2.new(0, 12, 0, 30),
					BackgroundTransparency = 0.9
				}), {
					set_props(make_element("Stroke"), {
						Color = SliderConfig.Color
					}),
					add_theme_object(set_props(make_element("Label", "value", 13), {
						Size = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 6),
						Font = Enum.Font.GothamBold,
						Name = "Value",
						TextTransparency = 0.8
					}), "text"),
					SliderDrag
				})

				local SliderFrame = add_theme_object(set_children(set_props(make_element("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
					Size = UDim2.new(1, 0, 0, 65),
					Parent = item_parent
				}), {
					add_theme_object(set_props(make_element("Label", SliderConfig.Name, 15), {
						Size = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 10),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "text"),
					add_theme_object(make_element("Stroke"), "stroke"),
					SliderBar
				}), "second")

				SliderBar.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then 
						dragging = true 
					end 
				end)
				SliderBar.InputEnded:Connect(function(Input) 
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then 
						dragging = false 
					end 
				end)

				user_input_service.InputChanged:Connect(function(Input)
					if dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then 
						local SizeScale = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
						Slider:Set(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale)) 
						save_config(game.GameId)
					end
				end)

				function Slider:Set(Value)
					self.Value = math.clamp(round(Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
					tween_service:Create(SliderDrag,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{Size = UDim2.fromScale((self.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min), 1)}):Play()
					SliderBar.Value.Text = tostring(self.Value) .. " " .. SliderConfig.ValueName
					SliderDrag.Value.Text = tostring(self.Value) .. " " .. SliderConfig.ValueName
					SliderConfig.Callback(self.Value)
				end      

				Slider:Set(Slider.Value)
				if SliderConfig.Flag then				
					gui_window_library.flags[SliderConfig.Flag] = Slider
				end
				return Slider
			end  
			function element_function:AddDropdown(DropdownConfig)
				DropdownConfig = DropdownConfig or {}
				DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
				DropdownConfig.Options = DropdownConfig.Options or {}
				DropdownConfig.Default = DropdownConfig.Default or ""
				DropdownConfig.Callback = DropdownConfig.Callback or function() end
				DropdownConfig.Flag = DropdownConfig.Flag or nil
				DropdownConfig.Save = DropdownConfig.Save or false

				local Dropdown = {Value = DropdownConfig.Default, Options = DropdownConfig.Options, Buttons = {}, Toggled = false, Type = "Dropdown", Save = DropdownConfig.Save}
				local MaxElements = 5

				if not table.find(Dropdown.Options, Dropdown.Value) then
					Dropdown.Value = "..."
				end

				local DropdownList = make_element("List")

				local Dropdowncontainer = add_theme_object(set_props(set_children(make_element("ScrollFrame", Color3.fromRGB(40, 40, 40), 4), {
					DropdownList
				}), {
					Parent = item_parent,
					Position = UDim2.new(0, 0, 0, 38),
					Size = UDim2.new(1, 0, 1, -38),
					ClipsDescendants = true
				}), "divider")

				local Click = set_props(make_element("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local DropdownFrame = add_theme_object(set_children(set_props(make_element("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = item_parent,
					ClipsDescendants = true
				}), {
					Dropdowncontainer,
					set_props(set_children(make_element("TFrame"), {
						add_theme_object(set_props(make_element("Label", DropdownConfig.Name, 15), {
							Size = UDim2.new(1, -12, 1, 0),
							Position = UDim2.new(0, 12, 0, 0),
							Font = Enum.Font.GothamBold,
							Name = "Content"
						}), "text"),
						add_theme_object(set_props(make_element("Image", "rbxassetid://7072706796"), {
							Size = UDim2.new(0, 20, 0, 20),
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(1, -30, 0.5, 0),
							ImageColor3 = Color3.fromRGB(240, 240, 240),
							Name = "Ico"
						}), "text_dark"),
						add_theme_object(set_props(make_element("Label", "Selected", 13), {
							Size = UDim2.new(1, -40, 1, 0),
							Font = Enum.Font.Gotham,
							Name = "Selected",
							TextXAlignment = Enum.TextXAlignment.Right
						}), "text_dark"),
						add_theme_object(set_props(make_element("Frame"), {
							Size = UDim2.new(1, 0, 0, 1),
							Position = UDim2.new(0, 0, 1, -1),
							Name = "Line",
							Visible = false
						}), "stroke"), 
						Click
					}), {
						Size = UDim2.new(1, 0, 0, 38),
						ClipsDescendants = true,
						Name = "F"
					}),
					add_theme_object(make_element("Stroke"), "stroke"),
					make_element("Corner")
				}), "second")

				add_connection(DropdownList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
					Dropdowncontainer.CanvasSize = UDim2.new(0, 0, 0, DropdownList.AbsoluteContentSize.Y)
				end)  

				local function AddOptions(Options)
					for _, Option in pairs(Options) do
						local OptionBtn = add_theme_object(set_props(set_children(make_element("Button", Color3.fromRGB(40, 40, 40)), {
							make_element("Corner", 0, 6),
							add_theme_object(set_props(make_element("Label", Option, 13, 0.4), {
								Position = UDim2.new(0, 8, 0, 0),
								Size = UDim2.new(1, -8, 1, 0),
								Name = "Title"
							}), "text")
						}), {
							Parent = Dropdowncontainer,
							Size = UDim2.new(1, 0, 0, 28),
							BackgroundTransparency = 1,
							ClipsDescendants = true
						}), "divider")

						add_connection(OptionBtn.MouseButton1Click, function()
							Dropdown:Set(Option)
							save_config(game.GameId)
						end)

						Dropdown.Buttons[Option] = OptionBtn
					end
				end	

				function Dropdown:Refresh(Options, Delete)
					if Delete then
						for _,v in pairs(Dropdown.Buttons) do
							v:Destroy()
						end    
						table.clear(Dropdown.Options)
						table.clear(Dropdown.Buttons)
					end
					Dropdown.Options = Options
					AddOptions(Dropdown.Options)
				end  

				function Dropdown:Set(Value)
					if not table.find(Dropdown.Options, Value) then
						Dropdown.Value = "..."
						DropdownFrame.F.Selected.Text = Dropdown.Value
						for _, v in pairs(Dropdown.Buttons) do
							tween_service:Create(v,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{BackgroundTransparency = 1}):Play()
							tween_service:Create(v.Title,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{TextTransparency = 0.4}):Play()
						end	
						return
					end

					Dropdown.Value = Value
					DropdownFrame.F.Selected.Text = Dropdown.Value

					for _, v in pairs(Dropdown.Buttons) do
						tween_service:Create(v,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{BackgroundTransparency = 1}):Play()
						tween_service:Create(v.Title,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{TextTransparency = 0.4}):Play()
					end	
					tween_service:Create(Dropdown.Buttons[Value],TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{BackgroundTransparency = 0}):Play()
					tween_service:Create(Dropdown.Buttons[Value].Title,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{TextTransparency = 0}):Play()
					return DropdownConfig.Callback(Dropdown.Value)
				end

				add_connection(Click.MouseButton1Click, function()
					Dropdown.Toggled = not Dropdown.Toggled
					DropdownFrame.F.Line.Visible = Dropdown.Toggled
					tween_service:Create(DropdownFrame.F.Ico,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{Rotation = Dropdown.Toggled and 180 or 0}):Play()
					if #Dropdown.Options > MaxElements then
						tween_service:Create(DropdownFrame,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{Size = Dropdown.Toggled and UDim2.new(1, 0, 0, 38 + (MaxElements * 28)) or UDim2.new(1, 0, 0, 38)}):Play()
					else
						tween_service:Create(DropdownFrame,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{Size = Dropdown.Toggled and UDim2.new(1, 0, 0, DropdownList.AbsoluteContentSize.Y + 38) or UDim2.new(1, 0, 0, 38)}):Play()
					end
				end)

				Dropdown:Refresh(Dropdown.Options, false)
				Dropdown:Set(Dropdown.Value)
				if DropdownConfig.Flag then				
					gui_window_library.flags[DropdownConfig.Flag] = Dropdown
				end
				return Dropdown
			end
			function element_function:AddBind(BindConfig)
				BindConfig.Name = BindConfig.Name or "Bind"
				BindConfig.Default = BindConfig.Default or Enum.KeyCode.Unknown
				BindConfig.Hold = BindConfig.Hold or false
				BindConfig.Callback = BindConfig.Callback or function() end
				BindConfig.Flag = BindConfig.Flag or nil
				BindConfig.Save = BindConfig.Save or false

				local Bind = {Value, Binding = false, Type = "Bind", Save = BindConfig.Save}
				local Holding = false

				local Click = set_props(make_element("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local BindBox = add_theme_object(set_children(set_props(make_element("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5)
				}), {
					add_theme_object(make_element("Stroke"), "stroke"),
					add_theme_object(set_props(make_element("Label", BindConfig.Name, 14), {
						Size = UDim2.new(1, 0, 1, 0),
						Font = Enum.Font.GothamBold,
						TextXAlignment = Enum.TextXAlignment.Center,
						Name = "Value"
					}), "text")
				}), "main")

				local BindFrame = add_theme_object(set_children(set_props(make_element("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = item_parent
				}), {
					add_theme_object(set_props(make_element("Label", BindConfig.Name, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "text"),
					add_theme_object(make_element("Stroke"), "stroke"),
					BindBox,
					Click
				}), "second")

				add_connection(BindBox.Value:GetPropertyChangedSignal("Text"), function()
					--BindBox.Size = UDim2.new(0, BindBox.Value.TextBounds.X + 16, 0, 24)
					tween_service:Create(BindBox, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, BindBox.Value.TextBounds.X + 16, 0, 24)}):Play()
				end)

				add_connection(Click.InputEnded, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						if Bind.Binding then return end
						Bind.Binding = true
						BindBox.Value.Text = ""
					end
				end)

				add_connection(user_input_service.InputBegan, function(Input)
					if user_input_service:GetFocusedTextBox() then return end
					if (Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value) and not Bind.Binding then
						if BindConfig.Hold then
							Holding = true
							BindConfig.Callback(Holding)
						else
							BindConfig.Callback()
						end
					elseif Bind.Binding then
						local Key
						pcall(function()
							if not check_key(black_listed_keys, Input.KeyCode) then
								Key = Input.KeyCode
							end
						end)
						pcall(function()
							if check_key(white_listed_mouse, Input.UserInputType) and not Key then
								Key = Input.UserInputType
							end
						end)
						Key = Key or Bind.Value
						Bind:Set(Key)
						save_config(game.GameId)
					end
				end)

				add_connection(user_input_service.InputEnded, function(Input)
					if Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value then
						if BindConfig.Hold and Holding then
							Holding = false
							BindConfig.Callback(Holding)
						end
					end
				end)

				add_connection(Click.MouseEnter, function()
					tween_service:Create(BindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(gui_window_library.themes[gui_window_library.selected_theme].second.R * 255 + 3, gui_window_library.themes[gui_window_library.selected_theme].second.G * 255 + 3, gui_window_library.themes[gui_window_library.selected_theme].second.B * 255 + 3)}):Play()
				end)

				add_connection(Click.MouseLeave, function()
					tween_service:Create(BindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = gui_window_library.themes[gui_window_library.selected_theme].second}):Play()
				end)

				add_connection(Click.MouseButton1Up, function()
					tween_service:Create(BindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(gui_window_library.themes[gui_window_library.selected_theme].second.R * 255 + 3, gui_window_library.themes[gui_window_library.selected_theme].second.G * 255 + 3, gui_window_library.themes[gui_window_library.selected_theme].second.B * 255 + 3)}):Play()
				end)

				add_connection(Click.MouseButton1Down, function()
					tween_service:Create(BindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(gui_window_library.themes[gui_window_library.selected_theme].second.R * 255 + 6, gui_window_library.themes[gui_window_library.selected_theme].second.G * 255 + 6, gui_window_library.themes[gui_window_library.selected_theme].second.B * 255 + 6)}):Play()
				end)

				function Bind:Set(Key)
					Bind.Binding = false
					Bind.Value = Key or Bind.Value
					Bind.Value = Bind.Value.Name or Bind.Value
					BindBox.Value.Text = Bind.Value
				end

				Bind:Set(BindConfig.Default)
				if BindConfig.Flag then				
					gui_window_library.flags[BindConfig.Flag] = Bind
				end
				return Bind
			end  
			function element_function:AddTextbox(TextboxConfig)
				TextboxConfig = TextboxConfig or {}
				TextboxConfig.Name = TextboxConfig.Name or "Textbox"
				TextboxConfig.Default = TextboxConfig.Default or ""
				TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
				TextboxConfig.Callback = TextboxConfig.Callback or function() end

				local Click = set_props(make_element("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local TextboxActual = add_theme_object(Create("TextBox", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					PlaceholderColor3 = Color3.fromRGB(210,210,210),
					PlaceholderText = "Input",
					Font = Enum.Font.GothamSemibold,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextSize = 14,
					ClearTextOnFocus = false
				}), "text")

				local Textcontainer = add_theme_object(set_children(set_props(make_element("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5)
				}), {
					add_theme_object(make_element("Stroke"), "stroke"),
					TextboxActual
				}), "main")


				local TextboxFrame = add_theme_object(set_children(set_props(make_element("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = item_parent
				}), {
					add_theme_object(set_props(make_element("Label", TextboxConfig.Name, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "text"),
					add_theme_object(make_element("Stroke"), "stroke"),
					Textcontainer,
					Click
				}), "second")

				add_connection(TextboxActual:GetPropertyChangedSignal("Text"), function()
					tween_service:Create(Textcontainer, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, TextboxActual.TextBounds.X + 16, 0, 24)}):Play()
				end)

				add_connection(TextboxActual.FocusLost, function()
					TextboxConfig.Callback(TextboxActual.Text)
					if TextboxConfig.TextDisappear then
						TextboxActual.Text = ""
					end	
				end)

				TextboxActual.Text = TextboxConfig.Default

				add_connection(Click.MouseEnter, function()
					tween_service:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(gui_window_library.themes[gui_window_library.selected_theme].second.R * 255 + 3, gui_window_library.themes[gui_window_library.selected_theme].second.G * 255 + 3, gui_window_library.themes[gui_window_library.selected_theme].second.B * 255 + 3)}):Play()
				end)

				add_connection(Click.MouseLeave, function()
					tween_service:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = gui_window_library.themes[gui_window_library.selected_theme].second}):Play()
				end)

				add_connection(Click.MouseButton1Up, function()
					tween_service:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(gui_window_library.themes[gui_window_library.selected_theme].second.R * 255 + 3, gui_window_library.themes[gui_window_library.selected_theme].second.G * 255 + 3, gui_window_library.themes[gui_window_library.selected_theme].second.B * 255 + 3)}):Play()
					TextboxActual:CaptureFocus()
				end)

				add_connection(Click.MouseButton1Down, function()
					tween_service:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(gui_window_library.themes[gui_window_library.selected_theme].second.R * 255 + 6, gui_window_library.themes[gui_window_library.selected_theme].second.G * 255 + 6, gui_window_library.themes[gui_window_library.selected_theme].second.B * 255 + 6)}):Play()
				end)
			end 
			function element_function:AddColorpicker(ColorpickerConfig)
				ColorpickerConfig = ColorpickerConfig or {}
				ColorpickerConfig.Name = ColorpickerConfig.Name or "Colorpicker"
				ColorpickerConfig.Default = ColorpickerConfig.Default or Color3.fromRGB(255,255,255)
				ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
				ColorpickerConfig.Flag = ColorpickerConfig.Flag or nil
				ColorpickerConfig.Save = ColorpickerConfig.Save or false

				local ColorH, ColorS, ColorV = 1, 1, 1
				local Colorpicker = {Value = ColorpickerConfig.Default, Toggled = false, Type = "Colorpicker", Save = ColorpickerConfig.Save}

				local ColorSelection = Create("ImageLabel", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(select(3, Color3.toHSV(Colorpicker.Value))),
					ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=4805639000"
				})

				local HueSelection = Create("ImageLabel", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(0.5, 0, 1 - select(1, Color3.toHSV(Colorpicker.Value))),
					ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=4805639000"
				})

				local Color = Create("ImageLabel", {
					Size = UDim2.new(1, -25, 1, 0),
					Visible = false,
					Image = "rbxassetid://4155801252"
				}, {
					Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
					ColorSelection
				})

				local Hue = Create("Frame", {
					Size = UDim2.new(0, 20, 1, 0),
					Position = UDim2.new(1, -20, 0, 0),
					Visible = false
				}, {
					Create("UIGradient", {Rotation = 270, Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)), ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234, 255, 0)), ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21, 255, 0)), ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 17, 255)), ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 251)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4))},}),
					Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
					HueSelection
				})

				local Colorpickercontainer = Create("Frame", {
					Position = UDim2.new(0, 0, 0, 32),
					Size = UDim2.new(1, 0, 1, -32),
					BackgroundTransparency = 1,
					ClipsDescendants = true
				}, {
					Hue,
					Color,
					Create("UIPadding", {
						PaddingLeft = UDim.new(0, 35),
						PaddingRight = UDim.new(0, 35),
						PaddingBottom = UDim.new(0, 10),
						PaddingTop = UDim.new(0, 17)
					})
				})

				local Click = set_props(make_element("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local ColorpickerBox = add_theme_object(set_children(set_props(make_element("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5)
				}), {
					add_theme_object(make_element("Stroke"), "stroke")
				}), "main")

				local ColorpickerFrame = add_theme_object(set_children(set_props(make_element("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = item_parent
				}), {
					set_props(set_children(make_element("TFrame"), {
						add_theme_object(set_props(make_element("Label", ColorpickerConfig.Name, 15), {
							Size = UDim2.new(1, -12, 1, 0),
							Position = UDim2.new(0, 12, 0, 0),
							Font = Enum.Font.GothamBold,
							Name = "Content"
						}), "text"),
						ColorpickerBox,
						Click,
						add_theme_object(set_props(make_element("Frame"), {
							Size = UDim2.new(1, 0, 0, 1),
							Position = UDim2.new(0, 0, 1, -1),
							Name = "Line",
							Visible = false
						}), "stroke"), 
					}), {
						Size = UDim2.new(1, 0, 0, 38),
						ClipsDescendants = true,
						Name = "F"
					}),
					Colorpickercontainer,
					add_theme_object(make_element("Stroke"), "stroke"),
				}), "second")

				add_connection(Click.MouseButton1Click, function()
					Colorpicker.Toggled = not Colorpicker.Toggled
					tween_service:Create(ColorpickerFrame,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{Size = Colorpicker.Toggled and UDim2.new(1, 0, 0, 148) or UDim2.new(1, 0, 0, 38)}):Play()
					Color.Visible = Colorpicker.Toggled
					Hue.Visible = Colorpicker.Toggled
					ColorpickerFrame.F.Line.Visible = Colorpicker.Toggled
				end)

				local function UpdateColorPicker()
					ColorpickerBox.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
					Color.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
					Colorpicker:Set(ColorpickerBox.BackgroundColor3)
					ColorpickerConfig.Callback(ColorpickerBox.BackgroundColor3)
					save_config(game.GameId)
				end

				ColorH = 1 - (math.clamp(HueSelection.AbsolutePosition.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)
				ColorS = (math.clamp(ColorSelection.AbsolutePosition.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
				ColorV = 1 - (math.clamp(ColorSelection.AbsolutePosition.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)

				add_connection(Color.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if ColorInput then
							ColorInput:Disconnect()
						end
						ColorInput = add_connection(run_service.RenderStepped, function()
							local ColorX = (math.clamp(Mouse.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
							local ColorY = (math.clamp(Mouse.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)
							ColorSelection.Position = UDim2.new(ColorX, 0, ColorY, 0)
							ColorS = ColorX
							ColorV = 1 - ColorY
							UpdateColorPicker()
						end)
					end
				end)

				add_connection(Color.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if ColorInput then
							ColorInput:Disconnect()
						end
					end
				end)

				add_connection(Hue.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if HueInput then
							HueInput:Disconnect()
						end;

						HueInput = add_connection(run_service.RenderStepped, function()
							local HueY = (math.clamp(Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)

							HueSelection.Position = UDim2.new(0.5, 0, HueY, 0)
							ColorH = 1 - HueY

							UpdateColorPicker()
						end)
					end
				end)

				add_connection(Hue.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if HueInput then
							HueInput:Disconnect()
						end
					end
				end)

				function Colorpicker:Set(Value)
					Colorpicker.Value = Value
					ColorpickerBox.BackgroundColor3 = Colorpicker.Value
					ColorpickerConfig.Callback(Colorpicker.Value)
				end

				Colorpicker:Set(Colorpicker.Value)
				if ColorpickerConfig.Flag then				
					gui_window_library.flags[ColorpickerConfig.Flag] = Colorpicker
				end
				return Colorpicker
			end  
			return element_function   
		end	

		local element_function = {}

		function element_function:AddSection(SectionConfig)
			SectionConfig.Name = SectionConfig.Name or "Section"

			local SectionFrame = set_children(set_props(make_element("TFrame"), {
				Size = UDim2.new(1, 0, 0, 26),
				Parent = container
			}), {
				add_theme_object(set_props(make_element("Label", SectionConfig.Name, 14), {
					Size = UDim2.new(1, -12, 0, 16),
					Position = UDim2.new(0, 0, 0, 3),
					Font = Enum.Font.GothamSemibold
				}), "text_dark"),
				set_children(set_props(make_element("TFrame"), {
					AnchorPoint = Vector2.new(0, 0),
					Size = UDim2.new(1, 0, 1, -24),
					Position = UDim2.new(0, 0, 0, 23),
					Name = "Holder"
				}), {
					make_element("List", 0, 6)
				}),
			})

			add_connection(SectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
				SectionFrame.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y + 31)
				SectionFrame.Holder.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
			end)

			local SectionFunction = {}
			for i, v in next, get_elements(SectionFrame.Holder) do
				SectionFunction[i] = v 
			end
			return SectionFunction
		end	

		for i, v in next, get_elements(container) do
			element_function[i] = v 
		end

		if tab_config.premium_only then
			for i, v in next, element_function do
				element_function[i] = function() end
			end    
			container:FindFirstChild("UIListLayout"):Destroy()
			container:FindFirstChild("UIPadding"):Destroy()
			set_children(set_props(make_element("TFrame"), {
				Size = UDim2.new(1, 0, 1, 0),
				Parent = item_parent
			}), {
				add_theme_object(set_props(make_element("Image", "rbxassetid://3610239960"), {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(0, 15, 0, 15),
					ImageTransparency = 0.4
				}), "text"),
				add_theme_object(set_props(make_element("Label", "Unauthorised Access", 14), {
					Size = UDim2.new(1, -38, 0, 14),
					Position = UDim2.new(0, 38, 0, 18),
					TextTransparency = 0.4
				}), "text"),
				add_theme_object(set_props(make_element("Image", "rbxassetid://4483345875"), {
					Size = UDim2.new(0, 56, 0, 56),
					Position = UDim2.new(0, 84, 0, 110),
				}), "text"),
				add_theme_object(set_props(make_element("Label", "Premium Features", 14), {
					Size = UDim2.new(1, -150, 0, 14),
					Position = UDim2.new(0, 150, 0, 112),
					Font = Enum.Font.GothamBold
				}), "text"),
				add_theme_object(set_props(make_element("Label", "This part of the script is locked to Sirius Premium users. Purchase Premium in the Discord server (discord.gg/sirius)", 12), {
					Size = UDim2.new(1, -200, 0, 14),
					Position = UDim2.new(0, 150, 0, 138),
					TextWrapped = true,
					TextTransparency = 0.4
				}), "text")
			})
		end
		return element_function   
	end  
	
	return tab_function
end   

function gui_window_library:Destroy()
	gui_window:Destroy()
end

return gui_window_library