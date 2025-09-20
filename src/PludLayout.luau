local tween_service = game:GetService("TweenService")

export type Layout = {
    Padding: UDim2;
    Size: UDim2;
    ConstantUpdates: boolean;
    SmoothUpdates: boolean;
    UpdateTween: TweenInfo;
    Linked: Frame;
    blacklisted: {[GuiObject]: true};
    affected_objs: {GuiObject};
}

local plud_layout = {}
plud_layout.__index =  plud_layout

function plud_layout.create_layout(grid_data: Layout)
	local self: Layout = setmetatable({
		blacklisted = {};
		affected_objs = {};
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
	
	return self
end

function plud_layout:update()
	if not self.ConstantUpdates then return end
	
	local cleaned = {}
	for _, obj in self.affected_objs do
		if obj and obj.Parent and not self.blacklisted[obj] then
			table.insert(cleaned, obj)
		end
	end
	self.affected_objs = cleaned
	
	local cols = math.max(1, math.floor(1 / math.max(0.001, self.Size.X.Scale)))
	local x, y = 0, 0
	
	for i, obj in self.affected_objs do
		local col = (i-1) % cols
		local row = math.floor((i-1) / cols)
		
		local cellW = self.Size.X.Scale
		local cellH = self.Size.Y.Scale
		local padX = self.Padding.X.Scale
		local padY = self.Padding.Y.Scale

		local pos = UDim2.new(
			(col * (cellW + padX)),
			self.Padding.X.Offset + (col * (self.Size.X.Offset + self.Padding.X.Offset)),
			(row * (cellH + padY)),
			self.Padding.Y.Offset + (row * (self.Size.Y.Offset + self.Padding.Y.Offset))
		)
		if obj.Position == pos then continue end
		
		if self.SmoothUpdates and self.UpdateTween then
			tween_service:Create(obj, self.UpdateTween, {Position = pos}):Play()
			obj.Size = self.Size
		else
			obj.Position = pos
			obj.Size = self.Size
		end
	end
end

function plud_layout:blacklist(obj: GuiObject)
	if not obj then return end
	self.blacklisted[obj] = true
end

function plud_layout:whitelist(obj: GuiObject)
    if not obj then return end
    self.blacklisted[obj] = nil 
    if not table.find(self.affected_objs, obj) then
        table.insert(self.affected_objs, obj)
    end
end

return plud_layout
