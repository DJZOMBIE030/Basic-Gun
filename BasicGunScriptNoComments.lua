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
local bulletsFolder = workspace:FindFirstChild("Bullets")

if not bulletsFolder then
	bulletsFolder = Instance.new("Folder")
	bulletsFolder.Name = "Bullets"
	bulletsFolder.Parent = workspace
end

local npcFolder = workspace:FindFirstChild("NPCs")

if not npcFolder then
	npcFolder = Instance.new("Folder")
	npcFolder.Name = "NPCs"
	npcFolder.Parent = workspace
end

--Services
local debris = game:GetService("Debris")
local userInputService = game:GetService("UserInputService")

--Functions
--Checking If The Player Is Alive
local function IsAlive()
	return humanoid.Health > 0
end

--Checking If The Passed Instance Is The Gun
local function IsGun(instance)
	return instance:IsA("Tool") and instance.Name == "Gun"
end

--Create A Part
local function CreatePart(parent, size, material, canCollide, anchored, transparency, name, cframe)
	local part = Instance.new("Part")
	part.Size = size
	part.Material = material
	part.CanCollide = canCollide
	part.Anchored = anchored
	part.Transparency = transparency
	part.Name = name
	part.CFrame = cframe
	part.Parent = parent

	return part
end

--Part For DebugMode
local rayPart = workspace:FindFirstChild("Ray")

if rayPart then
	debugMode = rayPart.Transparency ~= 1
else
	rayPart = CreatePart(workspace, Vector3.new(0.1, 0.1, 10), Enum.Material.SmoothPlastic, false, true, 1, "Ray", CFrame.new())
end

--Create A Weld
local function CreateWeld(parent, part1)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = parent
	weld.Part1 = part1
	weld.Parent = parent
end

--Create An IntValue
local function CreateIntValue(parent, value, name)
	local intValue = Instance.new("IntValue")
	intValue.Value = value
	intValue.Name = name
	intValue.Parent = parent

	return intValue
end

--Create A Sound
local function CreateSound(parent, id, volume, timePosition, pitch, playOnRemove)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://"..id
	sound.Volume = volume
	sound.TimePosition = timePosition
	sound.Parent = parent

	local pitchShift = Instance.new("PitchShiftSoundEffect")
	pitchShift.Octave = pitch
	pitchShift.Parent = sound

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
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Shadows = shadows
	light.Parent = parent

	debris:AddItem(light, 0.1)
end

--Update rayPart
local function UpdateRay(unitRay, offset, hit)
	local rayPartLength = 500

	if hit then
		rayPart.Color = Color3.fromRGB(0, 255, 0)
	else
		rayPart.Color = Color3.fromRGB(255, 0, 0)
	end

	rayPart.Size = Vector3.new(0.1, 0.1, rayPartLength)
	rayPart.CFrame = CFrame.new(unitRay.Origin + (unitRay.Direction * ((rayPart.Size.Z + offset)/2)), unitRay.Origin + unitRay.Direction)
end

--Update All Relevant Mouse Information
local function UpdateMouse(mousePos)
	local length = 5000
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
	else
		mouse.Hit = unitRay.Direction * math.pow(2, 16)
		mouse.Target = nil
	end

	if debugMode then
		UpdateRay(unitRay, offset, raycast ~= nil)
	end
end

--Create A Bullet
local function CreateBullet(parent, barrel) --A function to create a bullet.
	local part = CreatePart(parent, Vector3.new(0.2, 0.2, 3), Enum.Material.Neon, false, false, 0, "Bullet", CFrame.new(barrel.Position, mouse.Hit))

	local att = Instance.new("Attachment")
	att.Name = "Attachment0"
	att.Parent = part

	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = att
	velocity.MaxForce = 10000000
	velocity.VectorVelocity = part.CFrame.LookVector * 500
	velocity.Parent = part

	CreateSound(character.Head, 799968774, 0.5, 0, math.random(95, 110)/100, true)
	CreateLight(barrel, 5, Color3.fromRGB(255, 201, 39), 5, false)

	debris:AddItem(part, 10)

	--When A Bullet Hits Something With Collision And Is Visible, Delete It (Give Damage If Humanoid Is Found)
	part.Touched:Connect(function(touched)
		if not (touched.Parent and touched.Parent.Name ~= player.Name) then
			return
		end

		if not (touched:IsA("BasePart") and touched.Transparency ~= 1 and (touched.CanCollide == true or touched.Parent:FindFirstChildWhichIsA("Humanoid"))) then
			return
		end

		if not touched.Anchored then
			touched.AssemblyLinearVelocity += velocity.VectorVelocity * 0.025
		end

		part:Destroy()

		if not touched.Parent:FindFirstChildWhichIsA("Humanoid") or touched.Parent:FindFirstChildWhichIsA("Humanoid").Health <= 0 then
			return
		end

		local tHumanoid = touched.Parent:FindFirstChildWhichIsA("Humanoid")
		local tHRP = tHumanoid.Parent:FindFirstChild("HumanoidRootPart")
		local baseDamage = 10
		local multiplier = {
			Head = 1.5,
			Torso = 1,
			["Left Arm"] = 0.9,
			["Left Leg"] = 0.9,
			["Right Arm"] = 0.9,
			["Right Leg"] = 0.9
		}

		if multiplier[touched.Name] then
			tHumanoid:TakeDamage(baseDamage * multiplier[touched.Name])
		end

		if tHumanoid.Health > 0 then
			return
		end

		if tHRP then
			tHRP:Destroy()
		end

		debris:AddItem(touched.Parent, 10)
	end)
end

--UI
local function MakeUI()
	local screenGUI = Instance.new("ScreenGui")
	screenGUI.Parent = player.PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 250, 0, 100)
	frame.Position = UDim2.new(1, -frame.Size.X.Offset, 1, -frame.Size.Y.Offset)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.75
	frame.Parent = screenGUI

	local ammoCounter = Instance.new("TextLabel")
	ammoCounter.Size = UDim2.new(1, 0, 1, 0)
	ammoCounter.TextScaled = true
	ammoCounter.TextColor3 = Color3.fromRGB(255, 255, 255)
	ammoCounter.Parent = frame

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

--Shoot The Gun
local function FireGun()
	if not IsAlive() then
		return
	end

	local gun = character:FindFirstChild("Gun")

	if not gun then
		return
	end

	local handle = gun.Handle
	local barrel = handle.Barrel
	local mag = handle:FindFirstChild("Mag")

	if not mag then
		return
	end

	local ammo = mag.Ammo

	if ammo.Value > 0 and reloading == false then
		shooting = true
	end

	while shooting and IsAlive() do
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

--Reload The Gun
local function ReloadGun()
	if not IsAlive() then
		return
	end

	local gun = character:FindFirstChild("Gun")

	if not gun or reloading then
		return
	end

	local handle = gun.Handle
	local main = handle.Main
	local mag = handle:FindFirstChild("Mag")

	reloading = true

	if mag then
		mag:FindFirstChild("WeldConstraint"):Destroy()
		mag.CanCollide = true
		mag.AssemblyLinearVelocity += -mag.CFrame.RightVector * 10
		mag.AssemblyAngularVelocity += mag.CFrame.LookVector * 10
		mag.Parent = workspace
		debris:AddItem(mag, 5)
		CreateSound(character.Head, 799968994, 1, 0.5, 1, false)
	else
		CreateSound(character.Head, 799968994, 1, 2.433/2, 1, false)
	end

	if not reloading then
		return
	end

	if interupt then
		interupt = false
	else
		--Making New Mag
		mag = CreatePart(handle, Vector3.new(0.5, 0.9, 0.25), Enum.Material.SmoothPlastic, false, false, 0, "Mag", main.CFrame * CFrame.new(-0.5, -0.7, 0))

		CreateWeld(mag, main)

		local ammo = CreateIntValue(mag, maxAmmo, "Ammo")
		ChangeAmmoCounter(mag)
	end

	reloading = false
end

--Equiping The Gun
character.ChildAdded:Connect(function(child)
	if not IsGun(child) then
		return
	end

	local handle = child:WaitForChild("Handle")
	local mag = handle:FindFirstChild("Mag")

	screenGui = MakeUI()

	ChangeAmmoCounter(mag)
end)

--Unequiping The Gun
character.ChildRemoved:Connect(function(child)
	if not IsGun(child) then
		return
	end

	screenGui:Destroy()
	shooting = false
	interupt = reloading
end)

--Keybinds
--Input Began
userInputService.InputBegan:Connect(function(input)
	--Shooting The Gun
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		UpdateMouse(input.Position)
		FireGun()
	end

	--Spawning NPC
	if input.KeyCode == Enum.KeyCode.F then
		if character.HumanoidRootPart.CFrame:ToObjectSpace(CFrame.new(mouse.Hit)).Position.Magnitude > 100 then
			return
		end

		local clone = npc:Clone()
		local hrpPos = character.HumanoidRootPart.Position
		local newClonePos = mouse.Hit + Vector3.new(0, 3, 0)
		clone.HumanoidRootPart.CFrame = CFrame.new(newClonePos, Vector3.new(hrpPos.X, newClonePos.Y, hrpPos.Z))
		clone.Parent = npcFolder
	end

	--Reloading
	if input.KeyCode == Enum.KeyCode.R then
		ReloadGun()
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
	if input.UserInputType ~= Enum.UserInputType.MouseMovement or shooting then
		return
	end

	UpdateMouse(input.Position)
end)

--Input Ended
userInputService.InputEnded:Connect(function(input)
	--Stop Shooting The Gun
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	UpdateMouse(input.Position)

	if shooting then
		shooting = false
	end
end)
