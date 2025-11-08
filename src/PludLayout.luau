local tween_service = game:GetService("TweenService")

export type Layout = {
	Padding: UDim2;
	Size: UDim2;
	ConstantUpdates: boolean;
	SmoothUpdates: boolean;
	TweenSize: boolean;
	UpdateTween: TweenInfo; -- only works with constant updates and smooth updates
	Linked: Frame;
	Whitelisted: {[Object]: {object: Instance, offset: UDim2, size_offset: UDim2, og_pos: UDim2, og_size: UDim2}};
	Blacklisted: {[Object]: boolean};
	Initialized: {[Object]: boolean};
}

local plud_layout = {}
plud_layout.__index =  plud_layout

function plud_layout.create_layout(grid_data: Layout)
	local self: Layout = setmetatable({
		whitelisted = {};
		initialized = {};
	}, plud_layout)

	for i, v in grid_data do
		self[i] = v
	end

	self.Linked.ChildAdded:Connect(function(child)
		print(`New child: {child}`)
		self:whitelist(child)
	end)

	self.Linked.ChildRemoved:Connect(function(child)
		print(`Lost child: {child}`)
		self:blacklist(child)
	end)

	for _, child in self.Linked:GetChildren() do
		self:whitelist(child)
	end

	return self
end

function plud_layout:update()
	local cleaned = {}
	if self.ConstantUpdates then
		for _, obj in self.whitelisted do
			if obj.object and obj.object.Parent then
				table.insert(cleaned, obj)
			end
		end
		self.whitelisted = cleaned
	end

	local corrected_padding = math.max(.001, self.Padding.X.Scale)
	local cols = math.floor((1 + corrected_padding) / (math.max(.001, self.Size.X.Scale) + corrected_padding))
	cols = math.max(1, cols)
	for i, obj_data in self.whitelisted do
		local obj = obj_data.object

		local col = (i-1) % cols
		local row = math.floor((i-1) / cols)

		local cell_w = self.Size.X.Scale
		local cell_h = self.Size.Y.Scale
		local pad_x = self.Padding.X.Scale
		local pad_y = self.Padding.Y.Scale

		local size = self.Size + obj_data.size_offset

		local pos = UDim2.new(
			col * (cell_w + pad_x),
			self.Padding.X.Offset + col * (self.Size.X.Offset + self.Padding.X.Offset),
			row * (cell_h + pad_y),
			self.Padding.Y.Offset + row * (self.Size.Y.Offset + self.Padding.Y.Offset)
		)
		local halfed_x = obj_data.og_size.X.Scale / 2
		local halfed_y = obj_data.og_size.Y.Scale / 2
		pos = (pos + obj_data.offset) + UDim2.new(halfed_x, 0, halfed_y, 0)

		if obj.Position == pos and obj.Size == size then continue end

		if self.SmoothUpdates and self.UpdateTween then
			local data = {Position = pos}
			if self.TweenSize then
				data.Size = size
			end
			tween_service:Create(obj, self.UpdateTween, data):Play()
			obj.Size = size
		else
			obj.Position = pos
			obj.Size = size
		end

		self.initialized[obj] = true
	end
end

function plud_layout:blacklist(obj: Object)
	if not obj then return end
	self.whitelisted[obj] = nil
	self.initialized[obj] = nil
end


function plud_layout:whitelist(obj: Object, p_offset, s_offset)
	p_offset = p_offset or UDim2.new(0, 0, 0, 0)
	s_offset = s_offset or UDim2.new(0, 0, 0, 0)
	if not obj then return end
	if obj:HasTag("Ignore") then return end

	local data = {
		object = obj;
		offset = p_offset;
		size_offset = s_offset;
		og_pos = obj.Position;
		og_size = obj.Size;
	}

	local slot_found = false
	for i = 1, #self.whitelisted do
		if self.whitelisted[i] == nil then
			self.whitelisted[i] = data
			slot_found = true
			break
		end
	end
	if not slot_found then
		table.insert(self.whitelisted, data)
	end
end

--[[
	Offsets the position or size of the object by the specified offset and size offset relative to its current position and size
]]
function plud_layout:offset(obj, offset, size_offset)
	for i, v in self.whitelisted do
		if v.object == obj then
			if offset ~= nil then
				v.offset = offset
			end
			if size_offset ~= nil then
				v.size_offset = size_offset
			end
		end
	end
end

--[[
	offset_type: "position" or "size", default is both
	Resets the offset to 0 of the specified type
]]
function plud_layout:remove_offset(obj, offset_type: string)
	for i, v in self.whitelisted do
		if v.object == obj then
			if offset_type == "position" then
				v.offset = UDim2.new(0, 0, 0, 0)
			elseif offset_type == "size" then
				v.size_offset = UDim2.new(0, 0, 0, 0)
			else
				v.offset = UDim2.new(0, 0, 0, 0)
				v.size_offset = UDim2.new(0, 0, 0, 0)
			end
		end
	end
end

return plud_layout
