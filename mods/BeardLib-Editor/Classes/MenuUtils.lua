DummyItem = DummyItem or class()
function DummyItem:init(name, v)
	self.name = name
	self.value = v
end
function DummyItem:Value()
	return self.value
end
function DummyItem:SetValue(v)
	self.value = v
end

MenuUtils = MenuUtils or class()
function MenuUtils:init(this, menu)
	menu = menu or this._menu
	function this:Divider(name, opt)
	    opt = opt or {}
	    return menu:Divider(table.merge({
	        name = name,
	        text = name,
	        color = menu.marker_highlight_color,
	    }, opt))
	end

	function this:Group(name, opt)
	    opt = opt or {}
	    return menu:ItemsGroup(table.merge({
	        name = name,
	        text = string.pretty2(name),
	    }, opt))
	end	

	function this:DivGroup(name, opt)
	    opt = opt or {}
	    opt.use_as_menu = true
	    opt.offset = {8, 4}
	    opt.text = opt.text or string.pretty2(name)
	    local div = self:Divider(name.."Div", opt)
		return self:Group(name, opt), div
	end

	function this:CloseButton()
		self:Button("Close", callback(menu.menu, menu.menu, "disable"))
	end

	function this:Button(name, callback, opt)
	    opt = opt or {}
	    return menu:Button(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        callback = callback,
	    }, opt))
	end

	function this:SmallButton(name, callback, parent, opt)    
	    opt = opt or {}
	    return menu:Button(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        callback = callback,
	        size_by_text = true,
	        position = "CenterRight",
	        align = "center",
	        override_parent = parent,
	    }, opt))
	end

	function this:ComboBox(name, callback, items, value, opt)
	    opt = opt or {}
	    return menu:ComboBox(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        items = items,
	        callback = callback,
	    }, opt))
	end

	function this:TextBox(name, callback, value, opt)
	    opt = opt or {}
	    return menu:TextBox(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        callback = callback,
	        value = value
	    }, opt))
	end

	function this:Slider(name, callback, value, opt)
	    opt = opt or {}
	    return menu:Slider(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        callback = callback,
	    }, opt))
	end

	function this:NumberBox(name, callback, value, opt)
	    opt = opt or {}
	    return menu:NumberBox(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        callback = callback,
	    }, opt))
	end

	function this:Toggle(name, callback, value, opt)
	    opt = opt or {}
	    return menu:Toggle(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        callback = callback,
	    }, opt))
	end

	function this:SetAxisControls(pos, rot, name)
		name = name or ""
	    for i, control in pairs(self._axis_controls) do
	        if alive(self[name..control]) then
	            self[name..control]:SetValue(i < 4 and pos[control] or rot[control](rot))
	        end
	    end
	end

	function this:SetShapeControls(shape, name)
		name = name or ""
	    for _, control in pairs(self._shape_controls) do
	        if alive(self[name..control]) then
	            self[name..control]:SetValue(shape and shape[control] or 0)
	        end
	    end
	end

	function this:SetAxisControlsEnabled(enabled, name)
		name = name or ""
	    for _, control in pairs(self._axis_controls) do
	        if alive(self[name..control]) then
	            self[name..control]:SetEnabled(enabled)
	        end
	    end
	end

	function this:AxisControlsPosition(name)
		name = name or ""
	    return Vector3(self[name.."x"].value, self[name.."y"].value, self[name.."z"].value)
	end

	function this:AxisControlsRotation(name)
		name = name or ""
	    return Rotation(self[name.."yaw"].value, self[name.."pitch"].value, self[name.."roll"].value)
	end

	function this:SetShapeControlsEnabled(enabled, name)
		name = name or ""
	    for _, control in pairs(self._shape_controls) do
	        if alive(self[name..control]) then
	            self[name..control]:SetEnabled(enabled)
	        end
	    end
	end

	function this:AxisControls(callback, opt, name, pos, rot)
		name = name or ""
	    opt = opt or {}
	    opt.align_method = "grid"
	    opt.use_as_menu = true
	    opt.color = false
	    local translation
	    local rotation
	    if not opt.no_pos then
	    	self:Divider("Translate"..name, opt)
			translation = self:Group("TranslateGroup", opt)
	    end
	    if not opt.no_rot then
	    	self:Divider("Rotate"..name, opt)
	    	rotation = self:Group("RotateGroup", opt)
	    end
	    opt.w = translation.w / 3
	    opt.offset = 0
	    opt.control_slice = 1.75
	    for i, control in pairs(self._axis_controls) do
	    	opt.group = i < 4 and translation or rotation
	    	if alive(opt.group) then
	        	self[name..control] = self:NumberBox(control, callback, 0, opt)
	        end
	    end
	   	if pos and rot then
	   		self:SetAxisControls(pos, rot, name)
	   	end
	end

	function this:ShapeControls(callback, opt, name, shape, no_radius)
		name = name or ""
	    opt = opt or {}
	    opt.floats = 0
	    opt.align_method = "grid"
	    opt.use_as_menu = true
	    opt.color = false
	    self:Divider("Shape", opt)
	    local shapegroup = self:Group("ShapeGroup", opt)
	    opt.w = shapegroup.w / 2
	    opt.offset = 0
	    opt.group = shapegroup
	    for i, control in pairs(self._shape_controls) do
	    	if not no_radius or control ~= "radius" then
				self[control..name] = self:NumberBox(control, callback, 0, opt)
	    	end    
	    end
	    if shape then
	    	self:SetShapeControls(shape)
	    end
	end	

	function this:PathItem(name, callback, value, typ, opt, loaded, filterout)
		opt = opt or {}
		opt.control_slice = opt.control_slice or 1.5
		opt.callback = opt.callback or callback
	    local t = self:TextBox(name, nil, value, opt)
	    opt.text = "Browse for " .. tostring(typ).."s"
		opt.offset = {t.offset[1] * 4, t.offset[2]}
		opt.callback = nil
	    local btn = self:Button("SelectPath"..name, function()
	       BeardLibEditor.managers.ListDialog:Show({
		        list = BeardLibEditor.Utils:GetEntries(typ, loaded, filterout),
		        callback = function(path) t:SetValue(path, true) end
		    })
	    end, opt)
	    t.SetEnabled = function(this, enabled)
	    	TextBox.SetEnabled(this, enabled)
	    	btn:SetEnabled(enabled)
	    end
	    return t
	end

	function this:ColorEnvItem(name, opt)
		local col = DummyItem:new(name, Vector3(1,1,1))
		local btn = self:Button("SetColor"..name, function()
			local vc = col:Value()
			BeardLibEditor.managers.ColorDialog:Show({color = Color(vc.x, vc.y, vc.z), callback = function(color)
		    	col:SetValue(Vector3(color.red, color.green, color.blue))
		    end})
		end, opt)
		return col
	end

	function this:ClearItems(lbl)
		menu:ClearItems(lbl)
	end	

	function this:GetItem(name)
		return menu:GetItem(name)
	end
end