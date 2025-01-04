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
local bulletsFolder										--\
if workspace:FindFirstChild("Bullets") then				---\
	bulletsFolder = workspace:FindFirstChild("Bullets")	----\
else													-----\
	bulletsFolder = Instance.new("Folder", workspace)	------\
	bulletsFolder.Name = "Bullets"						-------\_
end														---------| bulletsFolder: Initializing a variable to store a folder instance which will hold the bullets. The reason why I don't just make it right
														---------| away and have this if statement is to check whether it has already been created. This is so when you respawn, it won't make a new folder
local npcFolder											--------_| and instead use the one that's already been created. Same thing goes for npcFolder. This folder is used to store the dummies you spawn.
if workspace:FindFirstChild("NPCs") then				-------/
	npcFolder = workspace:FindFirstChild("NPCs")		------/
else													-----/
	npcFolder = Instance.new("Folder", workspace)		----/
	npcFolder.Name = "NPCs"								---/
end														--/

--Services
local debris = game:GetService("Debris") --Debris Service to delete things in a specified time without yielding the script.
local userInputService = game:GetService("UserInputService") --UserInputService to get and listen to client inputs.

--Functions
--Create A Part
local function CreatePart(parent, size, material, canCollide, anchored, transparency, name, cframe)	--A function to create and return a part with specified parameters.
	local part = Instance.new("Part", parent) --Initial creatation of the part.
	part.Size = size					--\
	part.Material = material			---\
	part.CanCollide = canCollide		----\
	part.Anchored = anchored			-----} Setting the properties with the specified parameters.
	part.Transparency = transparency	----/
	part.Name = name					---/
	part.CFrame = cframe				--/
	
	return part --Return the part to be used outside of this function.
end

--Part For DebugMode
local rayPart																													 --\
if not workspace:FindFirstChild("Ray") then																						 ---| Initialzing but not defining this variable for the same reasons as the folders eariler.
	rayPart = CreatePart(workspace, Vector3.new(0.1, 0.1, 10), Enum.Material.SmoothPlastic, false, true, 1, "Ray", CFrame.new()) ---| This time, though, instead of a folder, it's a part. If the part isn't created already,
else																															 ---| it will create it with the previously defined function (CreatePart()). This part is
	rayPart = workspace:FindFirstChild("Ray")																					 ---| to visualize the rays created from the mouse (more on this below) when debugMode is true.
																																 ---|
	if rayPart.Transparency ~= 1 then																							 ---| If there is a rayPart, it will check to see if it's visible. If it is, make debugMode true.
		debugMode = true																										 ---| rayPart being visible indicates debugMode was on before respawning (respawning replaces
	end																															 ---| your character which replaces this script with another one of this script).
end																																 --/

--Create A Weld
local function CreateWeld(parent, part1) --A function to create a WeldConstraint with specified parameters.
	local weld = Instance.new("WeldConstraint", parent) --Initial creatation of the weld.
	weld.Part0 = parent --I decied to make Part0 the same as the parent because that's how I always make my welds (just makes more sense to me).
	weld.Part1 = part1 --Setting Part1 to the part1 parameter.
end

--Create An IntValue
local function CreateIntValue(parent, value, name) --A function to create and return an IntValue with specified parameters.
	local intValue = Instance.new("IntValue", parent) --Initial creation of the IntValue.
	intValue.Value = value --Setting the IntValue's value to the value parameter.
	intValue.Name = name --Setting the IntValue's name to the name parameter.
	
	return intValue --Return the IntValue to be used outside of this function.
end

--Create A Sound
local function CreateSound(parent, id, volume, timePosition, pitch, playOnRemove) --A function to create a Sound with a PitchShiftSoundEffect with specified parameters.
	local sound = Instance.new("Sound", parent)	--\
	sound.SoundId = "rbxassetid://"..id			---| Creation and property-setting
	sound.Volume = volume						---| of the Sound.
	sound.TimePosition = timePosition			--/
	
	local pitchShift = Instance.new("PitchShiftSoundEffect", sound) --Creation of the PitchShiftSoundEffect and parent it to the sound.
	pitchShift.Octave = pitch --Set the Octave property of the pitchShift to the specfied pitch parameter.
	
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
	local light = Instance.new("PointLight", parent) --\
	light.Color = color								 ---| Creatation and property-setting
	light.Range = range								 ---| of the PointLight.
	light.Shadows = shadows							 --/
	
	debris:AddItem(light, 0.1) --Debris to destroy the light in 0.1 seconds without yielding the script.
	--I originally used task.delay() and idk why when I have debris lol.
end

--Update All Relevant Mouse Information
local function UpdateMouse(mousePos) --A function to update all relevant mouse information (this was a challenge (I like challenges, though.)).
	local length = 5000 --Length of the ray.
	local rayPartLength = 500 --The length of rayPart.
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

		if debugMode then --If debugMode is true, then:
			rayPart.Color = Color3.fromRGB(0, 255, 0) --Change rayPart's color to green to signify that the raycast has "hit" something.
		end
	else --If raycast hasn't "hit" anything, then:
		mouse.Hit = unitRay.Direction * math.pow(2, 16)
		--[[
			Using the unit ray itself, I multiply its direction by 2^16 as it seems the closer you get to infinity, the more accurate the bullets are.
			This makes sense as your mouse is pointing at nothing (or infinity). Although, during testing, it seems like anything >= 2^64 breaks it. Most likely because
			of the 64-bit integer limit (which I find very interesting). So I chose 2^16 as it's still a big number but no where near 2^64. It also seems accurate enough
			(aka: there's no noticeable shift in the bullets direction when switching from the raycast/ground to the unitray/skybox).
		]]
		mouse.Target = nil --Set mouse.Target to nil since the raycast isn't "hitting" anything.

		if debugMode then --If debugMode is true, then:
			rayPart.Color = Color3.fromRGB(255, 0, 0) --Change rayPart's color to red to signify that the raycast hasn't "hit" something.
		end
	end
	
	if debugMode then
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
end

--Create A Bullet
local function CreateBullet(parent, barrel) --A function to create a bullet.
	local part = CreatePart(parent, Vector3.new(0.2, 0.2, 3), Enum.Material.Neon, false, false, 0, "Bullet", CFrame.new(barrel.Position, mouse.Hit)) --Creating a part (the bullet) with the predefined function.
	--For the CFrame parameters, I put barrel.Position in the first parameter to set part's position to the barrel's position. The second parameter is used to make part face mouse.Hit.
	--For all the other parameters for the function, I just chose what I think will look good.
	
	local att = Instance.new("Attachment", part) --Creating an Attachment and parenting it to the bullet. Use explained below (line 196).
	att.Name = "Attachment0" --Naming the attachment.
	
	local velocity = Instance.new("LinearVelocity", part) --Creating a LinearVelocity (rip BodyVelocity) and parenting it to the bullet. This is used to add a constant velocity to the bullet.
	velocity.Attachment0 = att --Setting its Attachment0 to the previously created attachment. The attachment's use is to give the LinearVelocity an origin point to apply the velocity which is just the center of the bullet since I didn't change the position of the attachment.
	velocity.MaxForce = 10000000 --Setting the MaxForce. I set it to just some high number so it doesn't take any unnecessary time to speed up.
	velocity.VectorVelocity = part.CFrame.LookVector * 500 --Setting the VectorVelocity which is the velocity applied to the bullet.
	--I'm multiplying 500 by the bullet's LookVector to make it go 500 studs a second in the direction it's facing. The direction it's facing was already defined when the bullet was created.
	
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
		if touched.Parent then --Checking to see if touched's parent isn't nil. I would sometimes get an error about its parent being nil if I shot in the air.
			if touched:IsA("BasePart") and touched.Transparency ~= 1 and (touched.CanCollide == true or touched.Parent:FindFirstChildWhichIsA("Humanoid")) then --Checking if touched is a BasePart, visible, and collidable or parented to something with a humanoid. Limbs don't
				if touched.Parent.Name ~= player.Name then --Making sure you can't shoot yourself.																	have collision when you're alive, but I want you to be able to shoot limbs so that's why I have that "or" check.
					if touched.Parent:FindFirstChildWhichIsA("Humanoid") and touched.Parent:FindFirstChildWhichIsA("Humanoid").Health > 0 then --Checking for a humanoid and that it's alive. The last check doesn't guarantee a humanoid was found.
						local humanoid = touched.Parent:FindFirstChildWhichIsA("Humanoid") --The found humanoid.
						local multiplier = {		--\
							Head = 1.15,			---\
							Torso = 1,				----\
							["Left Arm"] = 0.9,		-----| A dictionary with all body parts of the R6 character (expect the HRP). Each one has an associated
							["Left Leg"] = 0.9,		-----| number value which will be used to determine how much the applied damage will be multiplied.
							["Right Arm"] = 0.9,	----/
							["Right Leg"] = 0.9		---/
						}							--/
						
						if multiplier[touched.Name] then --Checking if getting touched's name from the multiplier dictionary isn't nil
							humanoid:TakeDamage(10 * multiplier[touched.Name]) --Give the humanoid damage (10 times the found multiplier). touched.Name will match up with the name of the body part the bullet has hit and will give the associated multiplier.
						end
						
						if humanoid.Health <= 0 then --If humaoid's health is <= 0, then:
							if humanoid.Parent:FindFirstChild("HumanoidRootPart") then --If the touched's parent has a HRP, then:
								humanoid.Parent:FindFirstChild("HumanoidRootPart"):Destroy() --Destory the parent's HRP. The HRP would get in the way of the ragdoll.
							end
							
							debris:AddItem(touched.Parent, 10) --Use debris to Destroy the humanoid's parent in 10 seconds without yielding the script.
						end
					end
					
					if not touched.Anchored then --If touched isn't anchored, then:
						touched.AssemblyLinearVelocity += velocity.VectorVelocity * 0.025 --Add 2.5% of the bullet's velocity to touched's velocity.
					end
					
					part:Destroy() --Destroy the bullet (so it doesn't continue through whatever it just hit).
				end
			end
		end
	end)
end

--UI
local function MakeUI() --A function to create the UI associated with the ammo of the gun.
	local screenGUI = Instance.new("ScreenGui", player.PlayerGui) --Creation of the ScreenGui.

	local frame = Instance.new("Frame", screenGUI)									--| Creation and property-setting of the Frame. I make the position scale on both
	frame.Size = UDim2.new(0, 250, 0, 100)											--| axises to 1 to go to the bottom right of the ScreenGui. I set the offset in both
	frame.Position = UDim2.new(1, -frame.Size.X.Offset, 1, -frame.Size.Y.Offset)	--| axises to the negative value of its respective size. This is because the frame's
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)								--| position is calculated on its upper left corner. Offsetting it by its size
	frame.BackgroundTransparency = 0.75												--| will make the whole frame visible and not clip off-screen (except its border).

	local ammoCounter = Instance.new("TextLabel", frame)	--\
	ammoCounter.Size = UDim2.new(1, 0, 1, 0)				---| Creation and property-setting of the TextLabel. I made the scale in both axises
	ammoCounter.TextScaled = true							---| to 1 to fit the entire frame. TextScaled is true to make the text fit the whole TextLabel.
	ammoCounter.TextColor3 = Color3.fromRGB(255, 255, 255)	--/
	
	return screenGUI --Return screenGUI for it to be used outside of this function.
end

--Change The Ammo Counter Text Lable
local function ChangeAmmoCounter(mag) --A function to change the displayed ammo in the UI
	if mag then --Checking if the gun has a mag.
		screenGui.Frame.TextLabel.Text = mag.Ammo.Value.."/"..maxAmmo --Change the text of the TextLabel to the mag's current ammo.
	else
		screenGui.Frame.TextLabel.Text = "0/"..maxAmmo --Change the text of the TextLabel to 0 out of the max ammo as there's no mag.
	end
end

--Equiping The Gun
character.ChildAdded:Connect(function(child) --Listening for an instance being parented to the player's character.
	if child:IsA("Tool") and child.Name == "Gun" then --Checking if that instance is the player's gun.
		local handle = child:WaitForChild("Handle") --Handle of the gun.
		local mag = handle:FindFirstChild("Mag") --Mag of the gun (if it's there).
		
		screenGui = MakeUI() --Calling MakeUI() to display the gun's UI and setting screeGui to the returned instance.
		
		ChangeAmmoCounter(mag) --Changing the UI's text.
	end
end)

--Unequiping The Gun
character.ChildRemoved:Connect(function(child) --Listening for an instance being unparented from the player's character.
	if child:IsA("Tool") and child.Name == "Gun" then --Checking if that instance is the player's gun.
		screenGui:Destroy() --Destroy the gun's UI
		shooting = false --Making shooting = false (the player might still be holding left click when unequipping the gun).
		
		if reloading then --If the player is reloading the gun, then:
			interupt = true --Make interupt = true. This makes it to where the player won't reload the gun since it's no longer being held (logic for this below).
		end
	end
end)

--Keybinds
--Input Began
userInputService.InputBegan:Connect(function(input) --Listening for the player's inputs being pressed.
	--Shooting The Gun
	if input.UserInputType == Enum.UserInputType.MouseButton1 then --If the pressed input is left click, then:
		UpdateMouse(input.Position) --Call the function to update all relevant mouse information.
		
		if character:FindFirstChild("Gun") then --Check if the player has the gun equipped.
			local gun = character:FindFirstChild("Gun") --The gun.
			local handle = gun.Handle --The gun's handle.

			if handle:FindFirstChild("Mag") then --Check if the gun has a mag.
				local barrel = handle:FindFirstChild("Barrel") --The barrel.
				local mag = handle:FindFirstChild("Mag") --The mag.
				local ammo = mag.Ammo --The mag's IntValue which holds its current ammo.

				if ammo.Value > 0 and reloading == false and humanoid.Health > 0 then --Check if the player isn't reloading and the mag has ammo.
					shooting = true --Make shooting = true.
				end

				while shooting and humanoid.Health > 0 do --A while loop that only loops if shooting == true and the player is alive.
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
		end
	end
	
	--Spawning NPC
	if input.KeyCode == Enum.KeyCode.F then --If the pressed input is F, then:
		if character.HumanoidRootPart.CFrame:ToObjectSpace(CFrame.new(mouse.Hit)).Position.Magnitude <= 100 then --Using :ToObjectSpace(), check if the distance between the player's HRP and mouse.Hit don't exceed 100 studs.
			local clone = npc:Clone() --Clone the dummy stored in ReplicatedStorage.
			clone.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit + Vector3.new(0, 3, 0), character.HumanoidRootPart.Position) --Setting the CFrame of the dummy's HRP.
			--In the first parameter, I set the dummy's HRP's position to mouse.Hit and offset it by +3 studs in the y-axis to account for the dummy's legs and half of it's torso size (this makes it spawn right on its feet).
			--In the second parameter, I orient the dummy's HRP to face the player's HRP.
			clone.Parent = npcFolder --Parent the dummy to npcFolder.
		end
	end
	
	--Reloading
	if input.KeyCode == Enum.KeyCode.R then --If the pressed input is R, then:
		if character:FindFirstChild("Gun") and reloading == false then --If the player has the gun equipped, then:
			local gun = character:FindFirstChild("Gun") --The gun.
			local handle = gun.Handle --The gun's handle.
			local main = handle.Main --The main part of the gun.
			local mag = handle:FindFirstChild("Mag") --The mag.
			
			reloading = true --Make reloading = true.
			
			if mag then --Check if the gun has a mag.
				mag:FindFirstChild("WeldConstraint"):Destroy() --Destroy the weld keeping the mag connected with main.
				mag.Parent = workspace --Parent the mag to the Workspace.
				mag.CanCollide = true --Turn on the mag's collision.
				mag.AssemblyLinearVelocity += -mag.CFrame.RightVector * 10 --Put the velocity of the mag to 10 studs/second in the direction of where the gun is pointing (the left side/face of the mag).
				mag.AssemblyAngularVelocity += mag.CFrame.LookVector * 10 --Put the angular velocity of the mag to 10 studs/second in the direction of where the mag is facing (its front face).
				--Angular velocity will make a part rotate counter-clockwise around the vector given.
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
			
			if reloading == true then --If the player is reloading, then:
				if interupt == false then --If the player hasn't unequipped the gun while reloading, then:
					--Making New Mag
					mag = CreatePart(handle, Vector3.new(0.5, 0.9, 0.25), Enum.Material.SmoothPlastic, false, false, 0, "Mag", main.CFrame * CFrame.new(-0.5, -0.7, 0)) --Creating the mag.
					--The I add that specific CFrame to main's CFrame as that's the offset of the mags CFrame from main's CFrame.
					
					CreateWeld(mag, main) --Creating the WeldConstraint between the mag and main.
					
					local ammo = CreateIntValue(mag, maxAmmo, "Ammo") --Creating the IntValue to store the mag's ammo and asigning it to a variable (although it's not used).
					ChangeAmmoCounter(mag) --Change the UI's text to the mag's current ammo.
				else --Else (if the player has unequipped the gun while reloading), then:
					interupt = false --Making interupt = false.
				end
			end
			
			reloading = false --Making reloading = false
		end
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
	if input.UserInputType == Enum.UserInputType.MouseMovement and shooting == false then --If the changed input is the movement of the mouse (the mouse moved) and shooting == false, then:
		--I also check if shooting is false here because there would be overlap between the shooting updating the mouse information and this updating the mouse information.
		UpdateMouse(input.Position) --Call the function to update all relevant mouse information.
	end
end)

--Input Ended
userInputService.InputEnded:Connect(function(input) --Listening for the player's pressed inputs to stop being pressed.
	--Stop Shooting The Gun
	if input.UserInputType == Enum.UserInputType.MouseButton1 then --If the unpressed input is left click, then:
		UpdateMouse(input.Position) --Call the function to update all relevant mouse information.
		
		if shooting then --If shooting == true, then:
			shooting = false --Make shooting = false.
		end
	end
end)
