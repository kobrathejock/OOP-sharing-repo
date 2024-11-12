rep = game:GetService("ReplicatedStorage")
localModules = rep:WaitForChild("modules")
weaponStats = require(localModules:WaitForChild("weaponStats")).stats

animatorModule = require(script.animator)
cameraModule = require(script.camera)
movementModule = require(script.movement)
weaponModule = require(script.weapon)
userInterfaceModule = require(script.userInterface)

local module = {}

module.init = function(char)
	local animator = animatorModule:init(char)
	cameraModule:init(char)
	movementModule:init(char)
	weaponModule:init(char)
	userInterfaceModule.init(char)
	
	local controller = {
		values = {
			currentWeapon = nil, -- refrences table within weapons
		},
		movement = {
			get = {
				values = {
					running = false,
					speedPercentage = 100,
					stance = "standing",
					lean = "",
				},
			},	
		},
		weapons = {
			
		},
		items = {
			
		}
	}
	
	-------------------------------[[Movement functions]]-----------------------------------------------
	local function setMovementFunctions()
		function controller.movement:lean(dir)
			movementModule.lean(nil, dir)
		end
		
		function controller.movement:setSpeed(ads)
			local maxSpeed = 100
			local speedPercentage = 100
			local speed = movementModule.walkSpeed

			if self.get:running() then--running
				maxSpeed = 100
				speed = movementModule.runSpeed
				
			elseif controller.values.currentWeapon and controller.values.currentWeapon.get:ads() and ads == true then--ads
				maxSpeed = movementModule.adsSpeed/movementModule.runSpeed*100
				speed = movementModule.adsSpeed
				
			elseif self.get:crouching() then--crouching
				maxSpeed = movementModule.crouchingSpeed/movementModule.runSpeed*100
				speedPercentage = self.get.values.speedPercentage
				speed = movementModule.crouchingSpeed
				
			else -- walking
				maxSpeed = 100
				speedPercentage = self.get.values.speedPercentage
			end
			
			if ads == true then--ads = true
				maxSpeed = movementModule.adsSpeed/movementModule.runSpeed*100
				speed = movementModule.adsSpeed
			end
			
			
			local hum = char:FindFirstChild("Humanoid")
			if not hum then
				warn("No humanoid for getJumping")
				return true
			end
			
			userInterfaceModule.walkSpeedPercentage(speedPercentage, maxSpeed)
			hum.WalkSpeed = speed*(speedPercentage/100)
		end
		
		function controller.movement:changeSpeed(percentage: number)
			if self.get:running() then--ignore speed changes when running
				return
			end
			
			self.get.values.speedPercentage = percentage
			self:setSpeed()
		end

		function controller.movement:crouch(bool: boolean)
			--if bool == nil then
			--	bool = not self.get:crouching()
			--end
			
			--if not bool then
			--	animator.body["crouchwalk"]:Stop()
			--	return
			--end
			
			--animator.body["crouchwalk"]:Play()
		end

		function controller.movement:run(bool: boolean)
			if bool == true then
				self:lean("middle")
				weaponModule.aim(char, false)
			elseif bool == false and self.get:running() == false then
				
			end
			
			self.get.values.running = bool
			movementModule.run(char, bool)
			self:setSpeed()
		end
		
		--Get functions
		function controller.movement.get:crouching()
			return false
		end 
		
		function controller.movement.get:walkSpeedPercentage()
			return self.values.speedPercentage
		end
		
		function controller.movement.get:running() -- return true/false
			local hum = char:FindFirstChild("Humanoid")
			if not hum then
				warn("No humanoid for getJumping")
				return true
			end

			return hum.WalkSpeed > movementModule.walkSpeed
		end

		function controller.movement.get:jumping() -- return true/false
			local hum = char:FindFirstChild("Humanoid")
			if not hum then
				warn("No humanoid for getJumping")
				return true
			end
			
			return hum.FloorMaterial == Enum.Material.Air
		end

		function controller.movement.get:Leaning() --return dir
			local rootJoint = char:FindFirstChild("RootJoint",true)
			if not rootJoint then
				warn("No rootJoint for getLeaning")
				return "middle"
			end
			
			local _, yOrientation, _ = rootJoint.C0:ToEulerAngles()
			return yOrientation == 0 and "middle" or yOrientation > 0 and "right" or "left"
		end
	end
	setMovementFunctions()
	
	-------------------------------[[Weapon functions]]-----------------------------------------------
	function controller:registerGun(weaponModel)
		local weapon = {
			get = {
				values = {
					firing = false,
					inBurst = false,
					reloading = false,
					adsing = false,
					checkingMag = false,
					ammo = weaponStats[weaponModel.Name].magCapacity,
					model = weaponModel,
					lastFired = 0,
					fireMode = weaponStats[weaponModel.Name].fireModes[1],-- semi/auto
				},
			},
		}
		
		function weapon:reload()
			local gun = self.get:gun()
			animator.vm[gun.Name]["reload"]:Play()
			local success = weaponModule:reload()
			self.get.values.reloading = true
			wait(2)
			self.get.values.reloading = false
			if success then
				self.get.values.ammo = weaponStats[gun.Name].magCapacity
			end
		end
		
		function weapon:fire(bool: boolean)
			if bool then
				if ( 
					self.get:reloading() == true or 
					self.get:ammo() < 1 or 
					self.get.values.inBurst == true 
				) then
					return
				end
			end
			
			local gun = self.get:gun()
			local commonFireFunc = function()
				self.get.values.ammo -= 1
				if animator.vm[self.get:gun().Name] and animator.vm[self.get:gun().Name]["fire"] then
					animator.vm[self.get:gun().Name]["fire"]:Play()
				else
					warn("problem finding fire animation for weapon: " .. self.get:gun().Name)
				end
				self.get.lastFired = tick()
				weaponModule.fire(gun)
				wait(60/weaponStats[gun.Name].rpm)
			end

			if bool == true then
				if self.get:fireMode() == "auto" then
					self.get.values.firing = true
					while self.get:firing() == true do
						if self.get:ammo() < 1 then
							break
						end
						commonFireFunc()
					end
				elseif self.get:fireMode() == "burst" then
					self.get.values.inBurst = true
					for i = 1,5 do
						commonFireFunc()
					end
					self.get.values.inBurst = false
				else
					if tick()-self.get:lastFireTime() < 60/weaponStats[gun.Name].rpm then
						print("to fast")
						return
					end
					commonFireFunc()
				end
			else
				self.get.values.firing = false
			end
		end
		
		function weapon:ads(bool: boolean)
			if bool then
				controller.movement:run(false)
			end
			
			weaponModule.aim(char, bool)
			controller.movement:setSpeed(bool)
		end
		
		function weapon:checkMag()
			weaponModule.checkMag(self.get:gun())
		end
		
		function weapon:changeFireMode(new)-- change available fire mode
			if new ~= nil then
				self.get.values.fireMode = new
				return
			end
			
			--get current number in available fire modes
			local gun = self.get:gun()
			local currentNumber = 1
			for i = 1,#weaponStats[gun.Name].fireModes do
				if weaponStats[gun.Name].fireModes[i] == self.get.values.fireMode then
					currentNumber = i
				end
			end
			
			-- add 1 to get next
			currentNumber = currentNumber+1
			
			-- if out of table, return to beginning
			if weaponStats[gun.Name].fireModes[currentNumber] == nil then
				currentNumber = 1
			end
			self.get.values.fireMode = weaponStats[gun.Name].fireModes[currentNumber]
		end
		
		function weapon:equip()
			
		end
		
		
		-- get functions
		function weapon.get:isBursting() -- return true/false
			if self == nil then error("fired with a dot instead of a colon") end
			return self.values.inBurst
		end
		function weapon.get:reloading() -- return true/false
			return self.values.reloading
		end
		function weapon.get:firing() -- return true/false
			return self.values.firing
		end
		function weapon.get:ads() -- return true/false
			local rootWeld = char:FindFirstChild("Head2Eyes",true)
			if not rootWeld then
				warn("no root weld for get ads")
				return false
			end
			
			return rootWeld.C0 == CFrame.new()
		end
		function weapon.get:checkingMag() -- return true/false
			return self.values.checkingMag
		end
		function weapon.get:fireMode(bool) -- return mode
			return self.values.fireMode
		end
		function weapon.get:ammo() -- return number
			return self.values.ammo
		end
		function weapon.get:gun() -- return model
			return self.values.model
		end
		function weapon.get:lastFireTime()
			return self.values.lastFired
		end
		
		table.insert(self.weapons, weapon)
		return weapon
	end
	
	function controller:setCurrentWeapon(weaponName)
		for _,v in ipairs(self.weapons) do
			if v.get:gun().Name == weaponName then
				self.values.currentWeapon = v
				if animator.vm[v.get:gun().Name] and animator.vm[v.get:gun().Name]["idle"] then
					animator.vm[v.get:gun().Name]["idle"]:Play()
				else
					warn("No idle animation here for: " .. v.get:gun().Name)
				end
				return true
			end
		end
		
		warn("setCurrentWeapon: "..weaponName.." failed.")
		return false
	end
	
	return controller
end

return module
