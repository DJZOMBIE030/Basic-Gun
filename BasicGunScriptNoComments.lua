--Variables
local player = game.Players.LocalPlayer
local character = script.Parent
local hrp = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local mouse = {
	ScreenPos = Vector2.new(),
	Hit = Vector3.new(),
	Target = nil
}
local camera = workspace.CurrentCamera
local npc = game.ReplicatedStorage:WaitForChild("Dummy")

local screenGui
local maxAmmo = 60
local shooting = false
local reloading = false
local interupt = false
local debugMode = false

--Folders
local bulletsFolder
if workspace:FindFirstChild("Bullets") then
	bulletsFolder = workspace:FindFirstChild("Bullets")
else
	bulletsFolder = Instance.new("Folder", workspace)
	bulletsFolder.Name = "Bullets"
end

local npcFolder
if workspace:FindFirstChild("NPCs") then
	npcFolder = workspace:FindFirstChild("NPCs")
else
	npcFolder = Instance.new("Folder", workspace)
	npcFolder.Name = "NPCs"
end

--Services
local debris = game:GetService("Debris")
local userInputService = game:GetService("UserInputService")

--Functions
--Create A Part
local function CreatePart(parent, size, material, canCollide, anchored, transparency, name, cframe)
	local part = Instance.new("Part", parent)
	part.Size = size
	part.Material = material
	part.CanCollide = canCollide
	part.Anchored = anchored
	part.Transparency = transparency
	part.Name = name
	part.CFrame = cframe
	
	return part
end

--Part For DebugMode
local rayPart
if not workspace:FindFirstChild("Ray") then
	rayPart = CreatePart(workspace, Vector3.new(0.1, 0.1, 10), Enum.Material.SmoothPlastic, false, true, 1, "Ray", CFrame.new())
else
	rayPart = workspace:FindFirstChild("Ray")

	if rayPart.Transparency ~= 1 then
		debugMode = true
	end
end

--Create A Weld
local function CreateWeld(parent, part1)
	local weld = Instance.new("WeldConstraint", parent)
	weld.Part0 = parent
	weld.Part1 = part1
end

--Create An IntValue
local function CreateIntValue(parent, value, name)
	local intValue = Instance.new("IntValue", parent)
	intValue.Value = value
	intValue.Name = name
	
	return intValue
end

--Create A Sound
local function CreateSound(parent, id, volume, timePosition, pitch, playOnRemove)
	local sound = Instance.new("Sound", parent)
	sound.SoundId = "rbxassetid://"..id
	sound.Volume = volume
	sound.TimePosition = timePosition
	
	local pitchShift = Instance.new("PitchShiftSoundEffect", sound)
	pitchShift.Octave = pitch
	
	if playOnRemove then
		sound.PlayOnRemove = playOnRemove
		sound:Destroy()
	else
		sound:Play()
		task.wait(sound.TimeLength - timePosition)
		sound:Destroy()
	end
end

--Create A Light
local function CreateLight(parent, brightness, color, range, shadows)
	local light = Instance.new("PointLight", parent)
	light.Color = color
	light.Range = range
	light.Shadows = shadows
	
	debris:AddItem(light, 0.1)
end

--Update All Relevant Mouse Information
local function UpdateMouse(mousePos)
	local length = 5000
	local rayPartLength = 500
	local offset = 10
	local unitRay = camera:ViewportPointToRay(mousePos.X, mousePos.Y + 58)

	--Raycast
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {character, rayPart, bulletsFolder}
	local raycast = workspace:Raycast(unitRay.Origin, unitRay.Direction * length, raycastParams)

	mouse.ScreenPos = mousePos
	if raycast then
		mouse.Hit = raycast.Position
		mouse.Target = raycast.Instance

		if debugMode then
			rayPart.Color = Color3.fromRGB(0, 255, 0)
		end
	else
		mouse.Hit = unitRay.Direction * math.pow(2, 16)
		mouse.Target = nil

		if debugMode then
			rayPart.Color = Color3.fromRGB(255, 0, 0)
		end
	end
	
	if debugMode then
		rayPart.Size = Vector3.new(0.1, 0.1, rayPartLength)
		rayPart.CFrame = CFrame.new(unitRay.Origin + (unitRay.Direction * ((rayPart.Size.Z + offset)/2)), unitRay.Origin + unitRay.Direction)
	end
end

--Create A Bullet
local function CreateBullet(parent, barrel)
	local part = CreatePart(parent, Vector3.new(0.2, 0.2, 3), Enum.Material.Neon, false, false, 0, "Bullet", CFrame.new(barrel.Position, mouse.Hit))
	
	local att = Instance.new("Attachment", part)
	att.Name = "Attachment0"
	
	local velocity = Instance.new("LinearVelocity", part)
	velocity.Attachment0 = att
	velocity.MaxForce = 10000000
	velocity.VectorVelocity = part.CFrame.LookVector * 500
	
	CreateSound(character.Head, 799968774, 0.5, 0, math.random(95, 110)/100, true)
	CreateLight(barrel, 5, Color3.fromRGB(255, 201, 39), 5, false)
	
	debris:AddItem(part, 10)
	
	--When A Bullet Hits Something With Collision And Is Visible, Delete It (Give Damage If Humanoid Is Found)
	part.Touched:Connect(function(touched)
		if touched.Parent then
			if touched:IsA("BasePart") and touched.Transparency ~= 1 and (touched.CanCollide == true or touched.Parent:FindFirstChildWhichIsA("Humanoid")) then
				if touched.Parent.Name ~= player.Name then
					if touched.Parent:FindFirstChildWhichIsA("Humanoid") and touched.Parent:FindFirstChildWhichIsA("Humanoid").Health > 0 then
						local tHumanoid = touched.Parent:FindFirstChildWhichIsA("Humanoid")
						local multiplier = {
							Head = 1.15,
							Torso = 1,
							["Left Arm"] = 0.9,
							["Left Leg"] = 0.9,
							["Right Arm"] = 0.9,
							["Right Leg"] = 0.9
						}
						
						if multiplier[touched.Name] then
							tHumanoid:TakeDamage(10 * multiplier[touched.Name])
						end
						
						if tHumanoid.Health <= 0 then
							if tHumanoid.Parent:FindFirstChild("HumanoidRootPart") then
								tHumanoid.Parent:FindFirstChild("HumanoidRootPart"):Destroy()
							end
							
							debris:AddItem(touched.Parent, 10)
						end
					end
					
					if not touched.Anchored then
						touched.AssemblyLinearVelocity += velocity.VectorVelocity * 0.025
					end
					
					part:Destroy()
				end
			end
		end
	end)
end

--UI
local function MakeUI()
	local screenGUI = Instance.new("ScreenGui", player.PlayerGui)

	local frame = Instance.new("Frame", screenGUI)
	frame.Size = UDim2.new(0, 250, 0, 100)
	frame.Position = UDim2.new(1, -frame.Size.X.Offset, 1, -frame.Size.Y.Offset)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.75

	local ammoCounter = Instance.new("TextLabel", frame)
	ammoCounter.Size = UDim2.new(1, 0, 1, 0)
	ammoCounter.TextScaled = true
	ammoCounter.TextColor3 = Color3.fromRGB(255, 255, 255)
	
	return screenGUI
end

--Change The Ammo Counter Text Lable
local function ChangeAmmoCounter(mag)
	if mag then
		screenGui.Frame.TextLabel.Text = mag.Ammo.Value.."/"..maxAmmo
	else
		screenGui.Frame.TextLabel.Text = "0/"..maxAmmo
	end
end

--Equiping The Gun
character.ChildAdded:Connect(function(child)
	if child:IsA("Tool") and child.Name == "Gun" then
		local handle = child:WaitForChild("Handle")
		local mag = handle:FindFirstChild("Mag")
		
		screenGui = MakeUI()
		
		ChangeAmmoCounter(mag)
	end
end)

--Unequiping The Gun
character.ChildRemoved:Connect(function(child)
	if child:IsA("Tool") and child.Name == "Gun" then
		screenGui:Destroy()
		shooting = false
		
		if reloading then
			interupt = true
		end
	end
end)

--Keybinds
--Input Began
userInputService.InputBegan:Connect(function(input)
	--Shooting The Gun
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		UpdateMouse(input.Position)
		
		if character:FindFirstChild("Gun") then
			local gun = character:FindFirstChild("Gun")
			local handle = gun.Handle

			if handle:FindFirstChild("Mag") then
				local barrel = handle:FindFirstChild("Barrel")
				local mag = handle:FindFirstChild("Mag")
				local ammo = mag.Ammo

				if ammo.Value > 0 and reloading == false and humanoid.Health > 0 then
					shooting = true
				end

				while shooting and humanoid.Health > 0 do
					UpdateMouse(userInputService:GetMouseLocation() + Vector2.new(0, -58))
					CreateBullet(bulletsFolder, barrel)
					ammo.Value -= 1

					ChangeAmmoCounter(mag)

					if ammo.Value == 0 then
						shooting = false
					end

					task.wait(0.03)
				end
			end
		end
	end
	
	--Spawning NPC
	if input.KeyCode == Enum.KeyCode.F then
		if character.HumanoidRootPart.CFrame:ToObjectSpace(CFrame.new(mouse.Hit)).Position.Magnitude <= 100 then
			local clone = npc:Clone()
			clone.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit + Vector3.new(0, 3, 0), character.HumanoidRootPart.Position)
			clone.Parent = npcFolder
		end
	end
	
	--Reloading
	if input.KeyCode == Enum.KeyCode.R then
		if character:FindFirstChild("Gun") and reloading == false then
			local gun = character:FindFirstChild("Gun")
			local handle = gun.Handle
			local main = handle.Main
			local mag = handle:FindFirstChild("Mag")
			
			reloading = true
			
			if mag then
				mag:FindFirstChild("WeldConstraint"):Destroy()
				mag.Parent = workspace
				mag.CanCollide = true
				mag.AssemblyLinearVelocity += -mag.CFrame.RightVector * 10
				mag.AssemblyAngularVelocity += mag.CFrame.LookVector * 10
				debris:AddItem(mag, 5)
				CreateSound(character.Head, 799968994, 1, 0.5, 1, false)
			else
				CreateSound(character.Head, 799968994, 1, 2.433/2, 1, false)
			end
			
			if reloading == true then
				if interupt == false then
					--Making New Mag
					mag = CreatePart(handle, Vector3.new(0.5, 0.9, 0.25), Enum.Material.SmoothPlastic, false, false, 0, "Mag", main.CFrame * CFrame.new(-0.5, -0.7, 0))
					
					CreateWeld(mag, main)
					
					local ammo = CreateIntValue(mag, maxAmmo, "Ammo")
					ChangeAmmoCounter(mag)
				else
					interupt = false
				end
			end
			
			reloading = false
		end
	end
	
	--DebugMode
	if input.KeyCode == Enum.KeyCode.P then
		if debugMode then
			rayPart.Transparency = 1
		else
			rayPart.Transparency = 0.25
		end
		
		debugMode = not debugMode
	end
end)

--Input Changed
userInputService.InputChanged:Connect(function(input)
	--Getting All Relevant Mouse Information When The Mouse Moves
	if input.UserInputType == Enum.UserInputType.MouseMovement and shooting == false then
		UpdateMouse(input.Position)
	end
end)

--Input Ended
userInputService.InputEnded:Connect(function(input)
	--Stop Shooting The Gun
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		UpdateMouse(input.Position)
		
		if shooting then
			shooting = false
		end
	end
end)
