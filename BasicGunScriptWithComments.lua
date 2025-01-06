--Variables
local player = game.Players.LocalPlayer --The local player.
local character = script.Parent --The player's character (since the script is in StartCharacterScripts, the script is parented to the player's character).
local hrp = character:WaitForChild("HumanoidRootPart") --The HRP of the character (used :WaitForChild() because the script might load before the HRP).
local humanoid = character:WaitForChild("Humanoid") --The character's Humanoid.
local mouse = {					------\
	ScreenPos = Vector2.new(),	-------\
	Hit = Vector3.new(),		--------} A dictionary to store all relevant mouse information to be referenced later (gathered later in the script).
	Target = nil				-------/
}								------/
local camera = workspace.CurrentCamera --The player's camera.
local npc = game.ReplicatedStorage:WaitForChild("Dummy") --A rig (with ragdoll :D) stored in ReplicatedStoreage to be cloned later.

local screenGui			--Initialized variable but not defined. This is going to be defined as the GUI that appears when you equip the gun (the GUI gets created and deleted respective of if you have the gun equipped or not).
local maxAmmo = 60		--The max amount of ammo the mag can hold.
local shooting = false	--Helps with logic of shooting and not shooting.
local reloading = false	--Helps with logic of reloading.
local interupt = false	--Helps when the player unequips the gun while reloading.
local debugMode = false	--Visualizes the rays calculated from the mouse when true (binded to the P key).

--Folders
local bulletsFolder = workspace:FindFirstChild("Bullets") --\
														  ---\
if not bulletsFolder then								  ----| Checking if the bullets folder was already created. If not,
	bulletsFolder = Instance.new("Folder")				  ----| make a new one. I don't know why I was making it more complicated last time.
	bulletsFolder.Name = "Bullets"						  ----| This is so much simplier lol. Saved me a few lines, too.
	bulletsFolder.Parent = workspace					  ---/
end														  --/

local npcFolder = workspace:FindFirstChild("NPCs") --\
												   ---\
if not npcFolder then							   ----| Doing the same check with
	npcFolder = Instance.new("Folder")			   ----| the npc folder as the
	npcFolder.Name = "NPCs"						   ----| bullets folder.
	npcFolder.Parent = workspace				   ---/
end												   --/

--Services
local debris = game:GetService("Debris") --Debris Service to delete things in a specified time without yielding the script.
local userInputService = game:GetService("UserInputService") --UserInputService to get and listen to client inputs.

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
local function CreatePart(parent, size, material, canCollide, anchored, transparency, name, cframe)	--A function to create and return a part with specified parameters.
	local part = Instance.new("Part") --Initial creatation of the part.
	part.Size = size					--\
	part.Material = material			---\
	part.CanCollide = canCollide		----\
	part.Anchored = anchored			-----| Setting the properties with
	part.Transparency = transparency	-----| the specified parameters.
	part.Name = name					----/
	part.CFrame = cframe				---/
	part.Parent = parent				--/
	
	return part --Return the part to be used outside of this function.
end

--Part For DebugMode
local rayPart = workspace:FindFirstChild("Ray") --Checking for a part that is used to visualize the rays associated with the mouse.

if rayPart then							  ---| If rayPart already exists, debugMode will equal if rayPart is visible or not. If it is, make debugMode true. rayPart being visible
	debugMode = rayPart.Transparency ~= 1 ---| indicates debugMode was on before respawning (respawning replaces your character which replaces this script with another one of this script).
else --Else (if rayPart doesn't already exsits), then:
	rayPart = CreatePart(workspace, Vector3.new(0.1, 0.1, 10), Enum.Material.SmoothPlastic, false, true, 1, "Ray", CFrame.new()) --It will create it with the previously defined function (CreatePart()).
end

--Create A Weld
local function CreateWeld(parent, part1) --A function to create a WeldConstraint with specified parameters.
	local weld = Instance.new("WeldConstraint") --Initial creatation of the weld.
	weld.Part0 = parent --I decied to make Part0 the same as the parent because that's how I always make my welds (just makes more sense to me).
	weld.Part1 = part1 --Setting Part1 to the part1 parameter.
	weld.Parent = parent --Setting the parent.
end

--Create An IntValue
local function CreateIntValue(parent, value, name) --A function to create and return an IntValue with specified parameters.
	local intValue = Instance.new("IntValue") --Initial creation of the IntValue.
	intValue.Value = value --Setting the IntValue's value to the value parameter.
	intValue.Name = name --Setting the IntValue's name to the name parameter.
	intValue.Parent = parent --Setting the IntValue's parent.
	
	return intValue --Return the IntValue to be used outside of this function.
end

--Create A Sound
local function CreateSound(parent, id, volume, timePosition, pitch, playOnRemove) --A function to create a Sound with a PitchShiftSoundEffect with specified parameters.
	local sound = Instance.new("Sound")	--\
	sound.SoundId = "rbxassetid://"..id	---\
	sound.Volume = volume				----} Creation and property-setting of the Sound.
	sound.TimePosition = timePosition	---/
	sound.Parent = parent				--/	
	
	local pitchShift = Instance.new("PitchShiftSoundEffect") --Creation of the PitchShiftSoundEffect and parent it to the sound.
	pitchShift.Octave = pitch --Set the Octave property of the pitchShift to the specfied pitch parameter.
	pitchShift.Parent = sound --Set the parent.
	
	if playOnRemove then							-- If the playOnRemove parameter is true, it will set the
		sound.PlayOnRemove = playOnRemove			-- sound's property PlayOnRemove to the parameter and
		sound:Destroy()								-- destroy it (this is used for the shooting soundeffect).
	else											-- Else:
		sound:Play()								-- Play the sound,
		task.wait(sound.TimeLength - timePosition)	-- wait the sound's length; substracting the timePosition parameter to ensure that it doesn't wait any longer than necessary if the sound didn't play at 0 seconds,
		sound:Destroy()								-- and destroy the sound.
	end												--| This else is used for the reloading sound. The reason why I don't do the same thing as the shooting sound is because the sound will stay at one spot in space.
end													--| I want the sound to be played at its parent.

--Create A Light
local function CreateLight(parent, brightness, color, range, shadows) --A function to create a PointLight with specified parameters.
	local light = Instance.new("PointLight") --\
	light.Color = color						 ---\
	light.Range = range						 ----} Creatation and property-setting of the PointLight.
	light.Shadows = shadows					 ---/
	light.Parent = parent					 --/
	
	debris:AddItem(light, 0.1) --Debris to destroy the light in 0.1 seconds without yielding the script.
	--I originally used task.delay() and idk why when I have debris lol.
end

--Update rayPart
local function UpdateRay(unitRay, offset, hit)
	local rayPartLength = 500 --The length of rayPart.

	if hit then --If debugMode is true, then:
		rayPart.Color = Color3.fromRGB(0, 255, 0) --Change rayPart's color to green to signify that the raycast has "hit" something.
	else --Else:
		rayPart.Color = Color3.fromRGB(255, 0, 0) --Change rayPart's color to red to signify that the raycast hasn't "hit" something.
	end
	
	rayPart.Size = Vector3.new(0.1, 0.1, rayPartLength)
	--[[
		Putting all the length in the z-axis as a part's -z face is its front face (its "facing face").
		This is important because I'm going to orient it to face the ray's end point (which is at the camera). I'm dividing it by offset
		because 5000 is too big for a part to be (it won't appear at all). So I divide it by offset to get it to 500.
	]]
	
	rayPart.CFrame = CFrame.new(unitRay.Origin + (unitRay.Direction * ((rayPart.Size.Z + offset)/2)), unitRay.Origin + unitRay.Direction) --Math time :).
	--[[
		In the first parameter of CFrame.new(), I'm setting the position of rayPart: unitRay.Origin + (unitRay.Direction * ((rayPart.Size.Z + offset)/2)). Let's start inside the parenthesis.
											   (rayPart.Size.Z + offset)/2	 -> I use rayPart's z size as it will be travelling in its relative z direction. I add the offset so the part
																				won't be RIGHT in front of the camera. I then divide it by 2 as the position of a part is calculated based on
																				its center of mass. Since its z size (or size in any direction really) from its center is half of its full
																				size, I only need to move it half its size (plus the offset).
						  unitRay.Direction * ((rayPart.Size.Z + offset)/2)	 -> Multiplying it by the unitRay's direction moves rayPart in the direction of the ray by half of rayPart's
																				size (plus the offset).
		unitRay.Origin + (unitRay.Direction * ((rayPart.Size.Z + offset)/2)) -> Finally, adding the ray's origin moves rayPart by the calculated length and direction from that point
																				in space instead of (0, 0, 0).
		
		In the second parameter of CFrame.new(), I'm setting the orientation of rayPart: unitRay.Origin + unitRay.Direction.
		rayOrigin + rayDirection = rayEndPoint... Knowing this, we can add them in the second parameter to make rayPart face towards the end point of the unit ray
		(which is back towards the camera respective of where the mouse is).
	]]
end

--Update All Relevant Mouse Information
local function UpdateMouse(mousePos) --A function to update all relevant mouse information (this was a challenge (I like challenges, though.)).
	local length = 5000 --Length of the ray.
	local offset = 10 --Offset to help visualize the ray with rayPart.
	local unitRay = camera:ViewportPointToRay(mousePos.X, mousePos.Y + 58)
	--[[
		Using :ViewportPointToRay() to convert the 2D mouse position (mousePos is the 2D mouse position) into a 3D unit ray
		that will point towards the camera relative of where the mouse is.
		The +58 offset in the y-coordinate is because the topbar of roblox offsets the viewport by -58 pixels.
		I saw this when printing out it's position. Without that +58, the rays will be off by that much.
	]]

	--Raycast
	local raycastParams = RaycastParams.new()													 --| Creating a new Raycast Parameters.
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude									 --| Setting it's filter type to Exclude.
	raycastParams.FilterDescendantsInstances = {character, rayPart, bulletsFolder} 				 --| Setting the instances to be filtered (ignored) to your character, rayPart, and the bullets so they won't get in the way.
	local raycast = workspace:Raycast(unitRay.Origin, unitRay.Direction * length, raycastParams) --| Creating the raycast using the unitRay's origin and direction and the raycast parameters.
	--Multiplying the direction by length to give the raycast some length. If not, it can only "hit" objects 1 stud infront of the camera.

	mouse.ScreenPos = mousePos --Update the mouse dictionary's mousePos to the 2D position of the mouse.
	if raycast then --If the raycast has "hit" anything, then:
		mouse.Hit = raycast.Position --Set mouse.Hit to the position of the intersection of the raycast and what it "hit".
		mouse.Target = raycast.Instance --Set mouse.Target to the instance that the raycast "hit".
	else --If raycast hasn't "hit" anything, then:
		mouse.Hit = unitRay.Direction * math.pow(2, 16)
		--[[
			Using the unit ray itself, I multiply its direction by 2^16 as it seems the closer you get to infinity, the more accurate the bullets are.
			This makes sense as your mouse is pointing at nothing (or infinity). Although, during testing, it seems like anything >= 2^64 breaks it. Most likely because
			of the 64-bit integer limit (which I find very interesting). So I chose 2^16 as it's still a big number but no where near 2^64. It also seems accurate enough
			(aka: there's no noticeable shift in the bullets direction when switching from the raycast/ground to the unitray/skybox).
		]]
		mouse.Target = nil --Set mouse.Target to nil since the raycast isn't "hitting" anything.
	end
	
	if debugMode then --If debugMode == true, then:
		UpdateRay(unitRay, offset, raycast ~= nil) --Update rayPart. I pass "raycast ~= nil" because I only need to know if it has "hit" something and not all the information that comes with it (I just need a boolean value).
	end
end

--Create A Bullet
local function CreateBullet(parent, barrel) --A function to create a bullet.
	local part = CreatePart(parent, Vector3.new(0.2, 0.2, 3), Enum.Material.Neon, false, false, 0, "Bullet", CFrame.new(barrel.Position, mouse.Hit)) --Creating a part (the bullet) with the predefined function.
	--For the CFrame parameters, I put barrel.Position in the first parameter to set part's position to the barrel's position. The second parameter is used to make part face mouse.Hit.
	--For all the other parameters for the function, I just chose what I think will look good.
	
	local att = Instance.new("Attachment") --Creating an Attachment and parenting it to the bullet. Use explained below (line 205).
	att.Name = "Attachment0" --Naming the attachment.
	att.Parent = part --Setting the parent.
	
	local velocity = Instance.new("LinearVelocity") --Creating a LinearVelocity (rip BodyVelocity) and parenting it to the bullet. This is used to add a constant velocity to the bullet.
	velocity.Attachment0 = att --Setting its Attachment0 to the previously created attachment. The attachment's use is to give the LinearVelocity an origin point to apply the velocity which is just the center of the bullet since I didn't change the position of the attachment.
	velocity.MaxForce = 10000000 --Setting the MaxForce. I set it to just some high number so it doesn't take any unnecessary time to speed up.
	velocity.VectorVelocity = part.CFrame.LookVector * 500 --Setting the VectorVelocity which is the velocity applied to the bullet.
	--I'm multiplying 500 by the bullet's LookVector to make it go 500 studs a second in the direction it's facing. The direction it's facing was already defined when the bullet was created.
	velocity.Parent = part --Setting the parent.
	
	CreateSound(character.Head, 799968774, 0.5, 0, math.random(95, 110)/100, true) --Create a sound with the predfined function.
	--[[
		For the parent, I chose the character's head because it was annoying only hearing the shot in your right ear when it was parented to the gun's barrel.
		Next 3 parameters are straight forward (id, volume, timePosition).
		For the pitch, I want it to be randomized. I use math.random() to achieve this. I want a number between 0.95-1.1 (the Octave property of PitchShift only accepts numbers 0.5-2, inclusive).
			math.random() can only output whole numbers. Knowing this, I input 95 and 110 (which will give me a number between 95-110, inclusive) and divide it by 100 to give me my desired range of numbers.
		Last property (playOnRemove) I set to true because I want the sound to play once and no more.
	]]
	CreateLight(barrel, 5, Color3.fromRGB(255, 201, 39), 5, false) --Create a light and parent it to the barrel for a muzzle flash effect.
	
	debris:AddItem(part, 10) --Use debris to destroy the bullet in 10 seconds without yielding the script.
	
	--When A Bullet Hits Something With Collision And Is Visible, Delete It (Give Damage If Humanoid Is Found)
	part.Touched:Connect(function(touched) --Listening for the bullet colliding with anything (touched is what it collided with; if anything).
		if not (touched.Parent and touched.Parent.Name ~= player.Name) then --Checking to see if touched's parent is nil and if it's not yourself. I would sometimes get an error about its parent being nil if I shot in the air.
			return --Return (to not run the rest of the code).
		end
		
		if not (touched:IsA("BasePart") and touched.Transparency ~= 1 and (touched.CanCollide == true or touched.Parent:FindFirstChildWhichIsA("Humanoid"))) then
			--Checking if touched is not a BasePart, visible, or collidable or parented to something with a humanoid.
			--Limbs don't have collision when you're alive, but I want you to be able to shoot limbs so that's why I have that "or" check.
			return --Return (to not run the rest of the code).
		end
		
		if not touched.Anchored then --If touched isn't anchored, then:
			touched.AssemblyLinearVelocity += velocity.VectorVelocity * 0.025 --Add 2.5% of the bullet's velocity to touched's velocity.
		end
		
		part:Destroy() --Destroy the bullet (so it doesn't continue through whatever it just hit).
		
		if not touched.Parent:FindFirstChildWhichIsA("Humanoid") or touched.Parent:FindFirstChildWhichIsA("Humanoid").Health <= 0 then
			--Checking if there's no humanoid or the humanoid's health <= 0. The last check doesn't guarantee a humanoid was found.
			return --Return (to not run the rest of the code).
		end
		
		local tHumanoid = touched.Parent:FindFirstChildWhichIsA("Humanoid") --The found humanoid.
		local tHRP = tHumanoid.Parent:FindFirstChild("HumanoidRootPart") --Checking if the humanoid's parent has a HRP.
		local baseDamage = 10 --The base damage each bullet inflicts.
		local multiplier = {	 --\
			Head = 1.5,			 ---\
			Torso = 1,			 ----\
			["Left Arm"] = 0.9,	 -----| A dictionary with all body parts of the R6 character (expect the HRP). Each one has an associated
			["Left Leg"] = 0.9,	 -----| number value which will be used to determine how much the applied damage will be multiplied.
			["Right Arm"] = 0.9, ----/
			["Right Leg"] = 0.9	 ---/
		}						 --/
		
		if multiplier[touched.Name] then --Checking if getting touched's name from the multiplier dictionary isn't nil
			tHumanoid:TakeDamage(baseDamage * multiplier[touched.Name]) --Give the humanoid damage (baseDamage times the found multiplier). touched.Name will match up with the name of the body part the bullet has hit and will give the associated multiplier.
		end
		
		if tHumanoid.Health > 0 then --If humaoid's health is > 0, then:
			return --Return (to not run the rest of the code).
		end
		
		if tHRP then --If the touched's parent has a HRP, then:
			tHRP:Destroy() --Destory the parent's HRP. The HRP would get in the way of the ragdoll.
		end
		
		debris:AddItem(touched.Parent, 10) --Use debris to Destroy the humanoid's parent in 10 seconds without yielding the script.
	end)
end

--UI
local function MakeUI() --A function to create the UI associated with the ammo of the gun.
	local screenGUI = Instance.new("ScreenGui") --Creation of the ScreenGui.
	screenGUI.Parent = player.PlayerGui --Setting the parent.

	local frame = Instance.new("Frame")												--| Creation and property-setting of the Frame. I make the position scale on both
	frame.Size = UDim2.new(0, 250, 0, 100)											--| axises to 1 to go to the bottom right of the ScreenGui. I set the offset
	frame.Position = UDim2.new(1, -frame.Size.X.Offset, 1, -frame.Size.Y.Offset)	--| in both axises to the negative value of its respective size. This is because
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)								--| the frame's position is calculated on its upper left corner. Offsetting it by
	frame.BackgroundTransparency = 0.75												--| its size will make the whole frame visible and not clip off-screen (except
	frame.Parent = screenGUI														--| its border).

	local ammoCounter = Instance.new("TextLabel")			--\
	ammoCounter.Size = UDim2.new(1, 0, 1, 0)				---| Creation and property-setting of the TextLabel. I made the
	ammoCounter.TextScaled = true							---| scale in both axises to 1 to fit the entire frame. TextScaled
	ammoCounter.TextColor3 = Color3.fromRGB(255, 255, 255)	---| is true to make the text fit the whole TextLabel.
	ammoCounter.Parent = frame								--/
	
	return screenGUI --Return screenGUI for it to be used outside of this function.
end

--Change The Ammo Counter Text Lable
local function ChangeAmmoCounter(mag) --A function to change the displayed ammo in the UI
	if mag then --Checking if the gun has a mag.
		screenGui.Frame.TextLabel.Text = mag.Ammo.Value.."/"..maxAmmo --Change the text of the TextLabel to the mag's current ammo.
	else --If there is no mag, then:
		screenGui.Frame.TextLabel.Text = "0/"..maxAmmo --Change the text of the TextLabel to 0 out of the max ammo as there's no mag.
	end
end

--Shoot The Gun
local function FireGun()
	if not IsAlive() then --Check if the player isn't alive.
		return --Return (to not run the rest of the code).
	end
	
	local gun = character:FindFirstChild("Gun") --Checking if the player's character has the gun.
	
	if not gun then --If the player doesn't have the gun equipped, then:.
		return --Return (to not run the rest of the code).
	end

	local handle = gun.Handle --The gun's handle.
	local barrel = handle.Barrel --The barrel.
	local mag = handle:FindFirstChild("Mag") --Checking if the gun has a mag.
	
	if not mag then --If there's no mag, then:
		return --Return (to not run the rest of the code).
	end
	
	local ammo = mag.Ammo --The mag's IntValue which holds its current ammo.

	if ammo.Value > 0 and reloading == false then --Check if the player isn't reloading and the mag has ammo.
		shooting = true --Make shooting = true.
	end

	while shooting and IsAlive() do --A while loop that only loops if shooting == true and the player is alive.
		UpdateMouse(userInputService:GetMouseLocation() + Vector2.new(0, -58)) --Call the function to update all relevant mouse information.
		--[[
			I call this function while shooting because the player might be moving but not moving the mouse.
			Here, I pass userInputService:GetMouseLocation() instead of input.Position because the player's mouse could be moving while shooting.
			Since this is within the same call, input.Position will be the same position from when the player first clicked.
			I substract 58 on the y-axis to offset the offset in the function. This is because :GetMouseLocation() already accounts for that offset, so adding 58 would mess it up.
		]]
		CreateBullet(bulletsFolder, barrel) --Call the functoin to create the bullet.
		ammo.Value -= 1 --Subtract 1 from the mag's ammo.

		ChangeAmmoCounter(mag) --Change the displayed UI text.

		if ammo.Value == 0 then --If the mag's ammo is 0, then:
			shooting = false --Make shooting = false; stopping the loop.
		end

		task.wait(0.03) --Wait 0.03 seconds so your computer doesn't crash lol. This is also the firerate.
	end
end

--Reload The Gun
local function ReloadGun()
	if not IsAlive() then --Check if the player isn't alive.
		return --Return (to not run the rest of the code).
	end

	local gun = character:FindFirstChild("Gun") --Checking if the player has the gun.
	
	if not gun or reloading then --If the player has the gun unequipped or reloading, then:
		return --Return (to not run the rest of the code).
	end
	
	local handle = gun.Handle --The gun's handle.
	local main = handle.Main --The main part of the gun.
	local mag = handle:FindFirstChild("Mag") --Checking if the gun has a mag.
	
	reloading = true --Make reloading = true.
	
	if mag then --Check if the gun has a mag.
		mag:FindFirstChild("WeldConstraint"):Destroy() --Destroy the weld keeping the mag connected with main.
		mag.CanCollide = true --Turn on the mag's collision.
		mag.AssemblyLinearVelocity += -mag.CFrame.RightVector * 10 --Put the velocity of the mag to 10 studs/second in the direction of where the gun is pointing (the left side/face of the mag).
		mag.AssemblyAngularVelocity += mag.CFrame.LookVector * 10 --Put the angular velocity of the mag to 10 studs/second in the direction of where the mag is facing (its front face).
		--Angular velocity will make a part rotate counter-clockwise around the vector given.
		mag.Parent = workspace --Parent the mag to the Workspace.
		debris:AddItem(mag, 5) --Use debris to destroy the mag in 5 seconds without yielding the script.
		CreateSound(character.Head, 799968994, 1, 0.5, 1, false) --Create the reloading sound effect.
		--[[
			I parent the sound to the player's head for the same reason as the shooting sound.
			I set timePosition to 0.5 as the audio has empty space in the beginning (I never understand why people upload sounds with silence in the beginning).
			I set playOnRemove to false this time because I want to sound to play at the player's head the whole time. If it were true, the sound would just play where the player's head was initially.
		]]
	else --If the gun has no mag, then:
		CreateSound(character.Head, 799968994, 1, 2.433/2, 1, false) --Create the reloading sound effect.
	end
	
	if not reloading then --If the player isn't reloading (might have changed to false while the script was yielding), then:
		return --Return (to not let the rest of the code run).
	end
	
	if interupt then --If the player hasn't unequipped the gun while reloading, then:
		interupt = false --Making interupt = false.
	else --Else (if the player has unequipped the gun while reloading), then:
		--Making New Mag
		mag = CreatePart(handle, Vector3.new(0.5, 0.9, 0.25), Enum.Material.SmoothPlastic, false, false, 0, "Mag", main.CFrame * CFrame.new(-0.5, -0.7, 0)) --Creating the mag.
		--The I add that specific CFrame to main's CFrame as that's the offset of the mags CFrame from main's CFrame.
		
		CreateWeld(mag, main) --Creating the WeldConstraint between the mag and main.
		
		local ammo = CreateIntValue(mag, maxAmmo, "Ammo") --Creating the IntValue to store the mag's ammo and asigning it to a variable (although it's not used).
		ChangeAmmoCounter(mag) --Change the UI's text to the mag's current ammo.
	end
	
	reloading = false --Making reloading = false
end

--Equiping The Gun
character.ChildAdded:Connect(function(child) --Listening for an instance being parented to the player's character.
	if not IsGun(child) then --Checking if that instance isn't the player's gun.
		return --Return (to not run the rest of the code).
	end
	
	local handle = child:WaitForChild("Handle") --Handle of the gun.
	local mag = handle:FindFirstChild("Mag") --Mag of the gun (if it's there).
	
	screenGui = MakeUI() --Calling MakeUI() to display the gun's UI and setting screeGui to the returned instance.
	
	ChangeAmmoCounter(mag) --Changing the UI's text.
end)

--Unequiping The Gun
character.ChildRemoved:Connect(function(child) --Listening for an instance being unparented from the player's character.
	if not IsGun(child) then --Checking if that instance isn't the player's gun.
		return --Return (to not run the rest if the code).
	end
	
	screenGui:Destroy() --Destroy the gun's UI
	shooting = false --Making shooting = false (the player might still be holding left click when unequipping the gun).
	interupt = reloading --Make interupt = reload. If reloading is true, this makes it to where the player won't reload the gun since it's no longer being held (logic for this below).
end)

--Keybinds
--Input Began
userInputService.InputBegan:Connect(function(input) --Listening for the player's inputs being pressed.
	--Shooting The Gun
	if input.UserInputType == Enum.UserInputType.MouseButton1 then --If the pressed input is left click, then:
		UpdateMouse(input.Position) --Call the function to update all relevant mouse information.
		FireGun() --Call the function to fire the gun.
	end
	
	--Spawning NPC
	if input.KeyCode == Enum.KeyCode.F then --If the pressed input is F, then:
		if character.HumanoidRootPart.CFrame:ToObjectSpace(CFrame.new(mouse.Hit)).Position.Magnitude > 100 then --Using :ToObjectSpace(), check if the distance between the player's HRP and mouse.Hit exceeds 100 studs.
			return --Return (To not run the rest of the code).
		end
		
		local clone = npc:Clone() --Clone the dummy stored in ReplicatedStorage.
		local hrpPos = character.HumanoidRootPart.Position --Player's current HRP position.
		local newClonePos = mouse.Hit + Vector3.new(0, 3, 0) --The clone's new position.
		clone.HumanoidRootPart.CFrame = CFrame.new(newClonePos, Vector3.new(hrpPos.X, newClonePos.Y, hrpPos.Z)) --Setting the CFrame of the dummy's HRP.
		--In the first parameter, I set the dummy's HRP's position to mouse.Hit and offset it by +3 studs in the y-axis to account for the dummy's legs and half of it's torso size (this makes it spawn right on its feet).
		--In the second parameter, I orient the dummy's HRP to face the player. I set the y value to the clone's new position so the dummy can always spawn on its feet (makes the vector "rest" on the horizontal plane).
		clone.Parent = npcFolder --Parent the dummy to npcFolder.
	end
	
	--Reloading
	if input.KeyCode == Enum.KeyCode.R then --If the pressed input is R, then:
		ReloadGun() --Call the function to reload the gun.
	end
	
	--DebugMode
	if input.KeyCode == Enum.KeyCode.P then --If the pressed input is P, then:
		if debugMode then --If debugMode == true, then:
			rayPart.Transparency = 1 --Make rayPart invisible.
		else --Else (if debugMode == false), then:
			rayPart.Transparency = 0.25 --Make rayPart mostly visible.
		end
		
		debugMode = not debugMode --Make debugMode the opposite of what it currently is.
	end
end)

--Input Changed
userInputService.InputChanged:Connect(function(input) --Listening for any of the player's analog inputs changing.
	--Getting All Relevant Mouse Information When The Mouse Moves
	if input.UserInputType ~= Enum.UserInputType.MouseMovement or shooting then --If the changed input is not the movement of the mouse (the mouse moved) or shooting == true, then:
		return --Return (To not run the rest of the code).
	end
	--I also want shooting to be false here because there would be overlap between the shooting updating the mouse information and this updating the mouse information.
	
	UpdateMouse(input.Position) --Call the function to update all relevant mouse information.
end)

--Input Ended
userInputService.InputEnded:Connect(function(input) --Listening for the player's pressed inputs to stop being pressed.
	--Stop Shooting The Gun
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then --If the unpressed input isn't left click, then:
		return --Return (To not run the rest of the code).
	end
	
	UpdateMouse(input.Position) --Call the function to update all relevant mouse information.
	
	if shooting then --If shooting == true, then:
		shooting = false --Make shooting = false.
	end
end)
