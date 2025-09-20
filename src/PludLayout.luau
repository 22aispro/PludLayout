local tween_service = game:GetService("TweenService")

export type Layout = {
	Padding: UDim2;
	Size: UDim2;
	ConstantUpdates: boolean;
	SmoothUpdates: boolean;
	UpdateTween: TweenInfo; -- only works with constant updates and smooth updates || fonctionne uniquement avec des mises à jour constantes et des mises à jour fluides || Solo funciona con actualizaciones constantes y actualizaciones fluidas.
	Linked: Frame;
}

local plud_layout = {}
plud_layout.__index =  plud_layout

function plud_layout.create_layout(grid_data: Layout)
	local self: Layout = setmetatable({
		blacklisted = {};
		affected_objs = {};
		initialized = {};
	}, plud_layout)
	
	for i, v in grid_data do
		self[i] = v
	end
	
	self.Linked.ChildAdded:Connect(function(child)
		--print(`New child: {child}`)
		self:whitelist(child)
	end)
	
	self.Linked.ChildRemoved:Connect(function(child)
		--print(`Lost child: {child}`)
		self:blacklist(child)
	end)
	
	return self
end

function plud_layout:update()
	local cleaned = {}
	if self.ConstantUpdates then
		for _, obj in self.affected_objs do
			if obj and obj.Parent and not table.find(self.blacklisted, obj) then
				table.insert(cleaned, obj)
			end
		end
		self.affected_objs = cleaned
	end

	local cols = math.floor((1 + self.Padding.X.Scale) / (self.Size.X.Scale + self.Padding.X.Scale))
	cols = math.max(1, cols)
	for i, obj in self.affected_objs do
		if table.find(self.blacklisted, obj) then continue end
		
		local col = (i-1) % cols
		local row = math.floor((i-1) / cols)

		local cell_w = self.Size.X.Scale
		local cell_h = self.Size.Y.Scale
		local pad_x = self.Padding.X.Scale
		local pad_y = self.Padding.Y.Scale

		local pos = UDim2.new(
			col * (cell_w + pad_x),
			self.Padding.X.Offset + col * (self.Size.X.Offset + self.Padding.X.Offset),
			row * (cell_h + pad_y),
			self.Padding.Y.Offset + row * (self.Size.Y.Offset + self.Padding.Y.Offset)
		)
		if obj.Position == obj then continue end
		
		if self.SmoothUpdates and self.UpdateTween then
			tween_service:Create(obj, self.UpdateTween, {Position = pos}):Play()
			obj.Size = self.Size
		else
			obj.Position = pos
			obj.Size = self.Size
		end

		self.initialized[obj] = true
	end
end

function plud_layout:blacklist(obj: Object)
	if not obj then return end
	table.insert(self.blacklisted, obj)
	
	for i = 1, #self.affected_objs do
		if self.affected_objs[i] == obj then
			self.affected_objs[i] = nil
			break
		end
	end

	if table.find(self.initialized, obj) then
		self.initialized[obj] = false
	end
end


function plud_layout:whitelist(obj: Object)
	if not obj then return end
	if table.find(self.blacklisted, obj) then
		table.remove(self.blacklisted, table.find(self.blacklisted, obj))
	end
	
	local slot_found = false
	for i = 1, #self.affected_objs do
		if self.affected_objs[i] == nil then
			self.affected_objs[i] = obj
			slot_found = true
			break
		end
	end
	if not slot_found then
		table.insert(self.affected_objs, obj)
	end
end

return plud_layout
