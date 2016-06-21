Widget = Widget or class()
function Widget:init(parent, name)
	self._parent = parent
	self._widget = World:spawn_unit(Idstring("core/units/" .. name .. "/" .. name), Vector3())
	self._widget:set_enabled(false)
	self._x_pen = Draw:pen("no_z", "red")
	self._y_pen = Draw:pen("no_z", "green")
	self._z_pen = Draw:pen("no_z", "blue")
	self._yellow_pen = Draw:pen("no_z", "yellow")
end
function Widget:widget()
	return self._widget
end
function Widget:set_enabled(enabled)
	self._widget:set_enabled(enabled)
end
function Widget:toggle()
	self._widget:set_enabled(false)
	self._widget:set_enabled(true)
end
function Widget:enabled()
	return self._widget:enabled()
end
function Widget:set_position(pos)
	self._widget:set_position(pos)
	self:refresh()
end
function Widget:set_rotation(rot)
	self._widget:set_rotation(rot)
	self:refresh()
end
function Widget:refresh()
	local objects = self._widget:get_objects_by_type(Idstring("model"))
	for _, object in pairs(objects) do
		object:set_visibility(not object:visibility())
		object:set_visibility(not object:visibility())
	end
	local num = self._widget:num_bodies()
	for i = 0, num - 1 do
		local unit_body = self._widget:body(i)
		unit_body:set_enabled(not unit_body:enabled())
		unit_body:set_enabled(not unit_body:enabled())
	end
end
function Widget:update()
end
function Widget:calculate()
end
function Widget:reset_values()
end
MoveWidget = MoveWidget or class(Widget)
function MoveWidget:init(parent)
	self.super.init(self, parent, "move_widget")
	self._draw_axis = {}
	self._move_widget_axis = {}
	self._move_widget_offset = Vector3()
	self._widget:set_visible(false)
	self._unit_start_positions = {}
	self._move_widget_offsets = {}
end
function MoveWidget:reset_values()
 	self._move_widget_axis = {}
	self._draw_axis = {}
	self._move_widget_offset = Vector3()
end
function MoveWidget:update(t, dt)
	local u_pos = self._widget:position()
	local u_rot = self._widget:rotation()
	self._x_pen:arrow(u_pos + u_rot:x() * 10, u_pos + u_rot:x() * 100, 0.25)
	self._y_pen:arrow(u_pos + u_rot:y() * 10, u_pos + u_rot:y() * 100, 0.25)
	self._z_pen:arrow(u_pos + u_rot:z() * 10, u_pos + u_rot:z() * 100, 0.25)
	local ps = 40
	local pr = 1
	Application:draw_cylinder(u_pos + u_rot:z() * ps, u_pos + (u_rot:z() + u_rot:y()) * ps, pr, 0, 0, 1)
	Application:draw_cylinder(u_pos + u_rot:y() * ps, u_pos + (u_rot:z() + u_rot:y()) * ps, pr, 0, 1, 0)
	Application:draw_cylinder(u_pos + u_rot:z() * ps, u_pos + (u_rot:z() + u_rot:x()) * ps, pr, 0, 0, 1)
	Application:draw_cylinder(u_pos + u_rot:x() * ps, u_pos + (u_rot:z() + u_rot:x()) * ps, pr, 1, 0, 0)
	Application:draw_cylinder(u_pos + u_rot:y() * ps, u_pos + (u_rot:y() + u_rot:x()) * ps, pr, 0, 1, 0)
	Application:draw_cylinder(u_pos + u_rot:x() * ps, u_pos + (u_rot:y() + u_rot:x()) * ps, pr, 1, 0, 0)
	local draw_axis = clone(self._draw_axis)
	if #draw_axis == 0 then
		local from = self._parent:get_cursor_look_point(0)
		local to = self._parent:get_cursor_look_point(100000)
		local ray = World:raycast("ray", from, to, "ray_type", "widget", "target_unit", self._widget)
		if ray and ray.body then
			local axis = self._parent._widget_bodies[ray.body:name():t()]
			table.insert(draw_axis, axis)
			if axis == "xy" or axis == "xz" then
				table.insert(draw_axis, "x")
			end
			if axis == "xy" or axis == "yz" then
				table.insert(draw_axis, "y")
			end
			if axis == "xz" or axis == "yz" then
				table.insert(draw_axis, "z")
			end
		end
	end
	for _, axis in ipairs(draw_axis) do
		if axis == "xy" then
			self._yellow_pen:cylinder(u_pos + u_rot:y() * ps, u_pos + (u_rot:y() + u_rot:x()) * ps, pr)
			self._yellow_pen:cylinder(u_pos + u_rot:x() * ps, u_pos + (u_rot:y() + u_rot:x()) * ps, pr)
		elseif axis == "xz" then
			self._yellow_pen:cylinder(u_pos + u_rot:z() * ps, u_pos + (u_rot:z() + u_rot:x()) * ps, pr)
			self._yellow_pen:cylinder(u_pos + u_rot:x() * ps, u_pos + (u_rot:z() + u_rot:x()) * ps, pr)
		elseif axis == "yz" then
			self._yellow_pen:cylinder(u_pos + u_rot:z() * ps, u_pos + (u_rot:z() + u_rot:y()) * ps, pr)
			self._yellow_pen:cylinder(u_pos + u_rot:y() * ps, u_pos + (u_rot:z() + u_rot:y()) * ps, pr)
		else
			self._yellow_pen:arrow(u_pos + u_rot[axis](u_rot) * 10, u_pos + u_rot[axis](u_rot) * 100, 0.25)
		end
	end
end
function MoveWidget:calculate(unit, widget_rot)
	local result_pos = self:calc_move_widget_pos(unit, unit:rotation())
	result_pos = result_pos + self._move_widget_offsets[unit:editor_id()]
	return result_pos
end
function MoveWidget:calc_move_widget_pos(unit, widget_rot)
	local result_pos = Vector3()
	if #self._move_widget_axis == 2 then
		local p1 = self._parent:get_cursor_look_point(0)
		local p2 = self._parent:get_cursor_look_point(100)
		local axis1 = widget_rot[self._move_widget_axis[1]](widget_rot)
		local axis2 = widget_rot[self._move_widget_axis[2]](widget_rot)
		local normal = axis1:cross(axis2)
		local d = self._unit_start_positions[unit:editor_id()]:dot(normal)
		--if p2 - p1:dot(normal) ~= 0 then --No idea how to fix :/
		--	local t = (d - p1:dot(normal)) / p2 - p1:dot(normal)
			--result_pos = (p2 - p1) * t
		--end
	else
		local axis1 = self._move_widget_axis[1]
		local from = self._parent:get_cursor_look_point(0)
		local to = self._parent:get_cursor_look_point(100)
		local w_s_pos = --[[self._unit_start_positions[unit:editor_id()] + ]] widget_rot[axis1](widget_rot) * -100
		local w_e_pos = --[[self._unit_start_positions[unit:editor_id()] +  ]] widget_rot[axis1](widget_rot) * 100
		local mid_line_pos = math.line_intersection(w_s_pos, w_e_pos, from, to)
		local dot1_v = mid_line_pos - w_s_pos
		local dot2_v = w_e_pos - w_s_pos
		local dot = dot2_v:normalized():dot(dot1_v)
		local line_pos = w_s_pos + dot2_v:normalized() * dot
		result_pos = line_pos -- - self._unit_start_positions[unit:editor_id()]
	end
	result_pos = result_pos:rotate_with(widget_rot:inverse())
	local grid_size = self._parent:grid_size()
	result_pos = result_pos:with_x(math.round(result_pos.x / grid_size) * grid_size)
	result_pos = result_pos:with_y(math.round(result_pos.y / grid_size) * grid_size)
	result_pos = result_pos:with_z(math.round(result_pos.z / grid_size) * grid_size)
	result_pos = result_pos:rotate_with(widget_rot)
	return result_pos -- + self._unit_start_positions[unit:editor_id()]
end
function MoveWidget:add_move_widget_axis(axis)
	if axis == "x" then
		table.insert(self._move_widget_axis, "x")
		table.insert(self._draw_axis, "x")
	elseif axis == "y" then
		table.insert(self._move_widget_axis, "y")
		table.insert(self._draw_axis, "y")
	elseif axis == "z" then
		table.insert(self._move_widget_axis, "z")
		table.insert(self._draw_axis, "z")
	elseif axis == "xy" then
		table.insert(self._move_widget_axis, "x")
		table.insert(self._move_widget_axis, "y")
		table.insert(self._draw_axis, "x")
		table.insert(self._draw_axis, "y")
		--table.insert(self._draw_axis, "xy")
	elseif axis == "xz" then
		table.insert(self._move_widget_axis, "x")
		table.insert(self._move_widget_axis, "z")
		table.insert(self._draw_axis, "x")
		table.insert(self._draw_axis, "z")
		--table.insert(self._draw_axis, "xz")
	elseif axis == "yz" then
		table.insert(self._move_widget_axis, "y")
		table.insert(self._move_widget_axis, "z")
		table.insert(self._draw_axis, "y")
		table.insert(self._draw_axis, "z")
		--table.insert(self._draw_axis, "yz")
	end
	return table
end
function MoveWidget:set_move_widget_offset(unit)
	self._unit_start_positions[unit:editor_id()] = unit:position()
	self._move_widget_offsets[unit:editor_id()] = unit:position() - self:calc_move_widget_pos(unit, unit:rotation())
end
RotationWidget = RotationWidget or class(Widget)
function RotationWidget:init(parent)
	self.super.init(self, parent, "rotation_widget")
	self._rotate_widget_axis = nil
	self._rotate_widget_unit_rotations = {}
end
function RotationWidget:reset_values()
	self._rotate_widget_axis = nil
end
function RotationWidget:set_rotate_widget_axis(axis)
	self._rotate_widget_axis = axis
end
function RotationWidget:set_rotate_widget_start_screen_position(pos)
	self._rotate_widget_start_screen_position = pos
end
function RotationWidget:set_rotate_widget_unit_rot(unit)
	self._rotate_widget_unit_rotations[unit:editor_id()] = unit:rotation() 
end
function RotationWidget:set_world_dir(ray_pos)
	self._world_dir = ray_pos - self._widget:position()
end
function RotationWidget:update(t, dt)
	local u_pos = self._widget:position()
	local u_rot = self._widget:rotation()
	self._x_pen:torus(u_pos, 75, 2.5, u_rot:x())
	self._y_pen:torus(u_pos, 75, 2.5, u_rot:y())
	self._z_pen:torus(u_pos, 75, 2.5, u_rot:z())
	local axis = self._rotate_widget_axis
	if not axis then
		local from = self._parent:get_cursor_look_point(0)
		local to = self._parent:get_cursor_look_point(100000)
		local ray = World:raycast("ray", from, to, "ray_type", "widget", "target_unit", self._widget)
		if ray and ray.body then
			axis = self._parent._widget_bodies[ray.body:name():t()]
		end
	end
	if axis then
		self._yellow_pen:torus(u_pos, 75, 2.5, u_rot[axis](u_rot))
	end
end
function RotationWidget:calculate(unit, widget_rot)
	self._parent:world_to_screen(unit:position())
	local world_click_pos = self._widget:position() + self._world_dir
	local distance_vector = self._rotate_widget_start_screen_position - self._parent:cursor_pos()
	local real_click_screen_pos = self._parent:world_to_screen(world_click_pos)
	real_click_screen_pos = real_click_screen_pos:with_z(real_click_screen_pos.z / 1000)
	local real_widget_screen_pos = self._parent:world_to_screen(self._widget:position())
	real_widget_screen_pos = real_widget_screen_pos:with_z(real_widget_screen_pos.z / 1000)
	local real_screen_dir = real_click_screen_pos - real_widget_screen_pos:normalized()
	local real_widget_axis_pos = self._parent:world_to_screen(self._widget:position() + widget_rot[self._rotate_widget_axis](widget_rot) * 100)
	real_widget_axis_pos = real_widget_axis_pos:with_z(real_widget_axis_pos.z / 1000)
	local real_widget_screen_dir = real_widget_axis_pos - real_widget_screen_pos:normalized()
	local real_cross_dir = real_screen_dir:cross(real_widget_screen_dir)
	real_cross_dir = real_cross_dir:with_z(0):normalized()
	local world_to_1 = self._parent:screen_to_world(real_click_screen_pos + real_cross_dir * 3)
	local world_to_2 = self._parent:screen_to_world(real_click_screen_pos + real_cross_dir * -3)
	Application:draw_line(world_click_pos, world_to_1, 1, 1, 0)
	Application:draw_line(world_click_pos, world_to_2, 1, 1, 0)
	local amount = real_cross_dir:dot(distance_vector:normalized())
	local distance = distance_vector:length() * amount * 360
	local snap_rot = self._parent:snap_rotation()
	local rot = math.round(distance / snap_rot) * snap_rot
	local result_rot = Rotation(Rotation()[self._rotate_widget_axis](Rotation()), rot)
	--if self._layer:local_rot() then
		result_rot = Rotation(self._rotate_widget_unit_rotations[unit:editor_id()][self._rotate_widget_axis](self._rotate_widget_unit_rotations[unit:editor_id()]), rot)
	--end
	result_rot = result_rot * self._rotate_widget_unit_rotations[unit:editor_id()]
	Application:draw_rotation(unit:position(), result_rot)
	return result_rot
end
