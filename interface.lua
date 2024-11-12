uis = game:GetService("UserInputService")
controllerModule = require(script.controller)
rs = game:GetService("RunService")

local module = {}

module.init = function(char)
	-- Get char if not provided
	if rs:IsClient() then
		char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
	elseif char == nil then
		warn("Character is nil")
		return
	end
	
	-- initialize controller
	local controller = controllerModule.init(char)
	controller:registerGun(char:WaitForChild("viewModel"):WaitForChild("M4A1")) -- Registering a gun returns and puts it in the weapns section of controller
	local success = controller:setCurrentWeapon("M4A1")
	
	-- local variables
	local hum = char:WaitForChild("Humanoid")
	
	-------------------------------Input Began-------------------------------
	uis.InputBegan:Connect(function(input, gameProcessed)
		local equipedItem = controller.values.currentWeapon
		if equipedItem == nil then return end
		
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.R then
				equipedItem:reload()
			elseif input.KeyCode == Enum.KeyCode.E then
				controller.movement:lean("right")
			elseif input.KeyCode == Enum.KeyCode.Q then
				controller.movement:lean("left")
			elseif input.KeyCode == Enum.KeyCode.C then
				controller.movement:crouch()
			elseif input.KeyCode == Enum.KeyCode.LeftShift then
				controller.movement:run(true)
			elseif input.KeyCode == Enum.KeyCode.B then
				equipedItem:changeFireMode()
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			equipedItem:fire(true)
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			equipedItem:ads(true)
		end
	end)
	
	-------------------------------Input Ended-------------------------------
	uis.InputEnded:Connect(function(input, gameProcessed)
		local equipedItem = controller.values.currentWeapon
		if equipedItem == nil then return end
		
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.LeftShift then
				--controller.movement:run(false)--remove once inertia is added
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			equipedItem:fire(false)
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			equipedItem:ads(false)
		end
	end)
	
	-------------------------------Input Changed-------------------------------
	uis.InputChanged:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local speed = math.clamp(controller.movement.get:walkSpeedPercentage() + input.Position.Z*5,20,100)
			controller.movement:changeSpeed(speed)
		end
	end)
	
	-------------------------------Move Direction-------------------------------
	hum:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if hum.MoveDirection == Vector3.new() then
			controller.movement:run(false)
		end
	end)
end

return module