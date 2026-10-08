local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

local MAX_SPEED = 100
local SUPER_SPEED = 140
local ACCELERATION = 50
local NORMAL_SPEED = 16
local RUN_THRESHOLD = 20
local CHARGE_TIME = 1.0
local DOUBLE_JUMP_COUNT = 2

local SpinDashGui
local SpinDashButton
local ChargeBar
local SuperSonicButton
local SpeedFlashGui

local spinNormal
local spinSuper
local doubleJumpAnimation
local spinSound = Instance.new("Sound", RootPart)
local jumpSound = Instance.new("Sound", RootPart)
local superSound = Instance.new("Sound", RootPart)
local dashSound = Instance.new("Sound", RootPart)
local landSound = Instance.new("Sound", RootPart)
local speedSound = Instance.new("Sound", RootPart)

spinSound.SoundId = "rbxassetid://8620459552"
jumpSound.SoundId = "rbxassetid://7699333859"
landSound.SoundId = "rbxassetid://8404814227"

local function stopAnimations()
	for _, track in ipairs(Humanoid:GetPlayingAnimationTracks()) do
		track:Stop(0)
	end
end

local function setAnimation(state, ids)
	local animate = Character:FindFirstChild("Animate")
	if not animate then
		return
	end

	stopAnimations()

	pcall(function()
		if state == "Idle" and type(ids) == "table" then
			animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=" .. tostring(ids[1])
			animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=" .. tostring(ids[2])
		elseif state == "Walk" then
			animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. tostring(ids)
		elseif state == "Run" then
			animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. tostring(ids)
		elseif state == "Jump" then
			animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. tostring(ids)
		elseif state == "Fall" then
			animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. tostring(ids)
		end
	end)
end

local function createSpinAnimations()
	local normal = Instance.new("Animation")
	normal.AnimationId = "rbxassetid://0"
	spinNormal = Humanoid:LoadAnimation(normal)
	spinNormal:AdjustSpeed(1)

	local super = Instance.new("Animation")
	super.AnimationId = "rbxassetid://0"
	spinSuper = Humanoid:LoadAnimation(super)
	spinSuper:AdjustSpeed(1.2)

	local dbl = Instance.new("Animation")
	dbl.AnimationId = "rbxassetid://0"
	doubleJumpAnimation = Humanoid:LoadAnimation(dbl)
end

local function createTrails()
	local function getFoot(name, fallback)
		return Character:FindFirstChild(name) or Character:FindFirstChild(fallback)
	end

	local leftFoot = getFoot("LeftFoot", "Left Leg")
	local rightFoot = getFoot("RightFoot", "Right Leg")
	if not leftFoot or not rightFoot then
		return
	end

	local la0 = Instance.new("Attachment", leftFoot)
	la0.Position = Vector3.new(0, 0.2, 0.2)
	local la1 = Instance.new("Attachment", leftFoot)
	la1.Position = Vector3.new(0, -0.2, -0.2)

	local ra0 = Instance.new("Attachment", rightFoot)
	ra0.Position = Vector3.new(0, 0.2, 0.2)
	local ra1 = Instance.new("Attachment", rightFoot)
	ra1.Position = Vector3.new(0, -0.2, -0.2)

	local leftTrail = Instance.new("Trail", leftFoot)
	leftTrail.Attachment0 = la0
	leftTrail.Attachment1 = la1
	leftTrail.Lifetime = 0.25
	leftTrail.LightEmission = 0.5
	leftTrail.Color = ColorSequence.new(Color3.fromRGB(135, 206, 235))
	leftTrail.Enabled = false

	local rightTrail = Instance.new("Trail", rightFoot)
	rightTrail.Attachment0 = ra0
	rightTrail.Attachment1 = ra1
	rightTrail.Lifetime = 0.25
	rightTrail.LightEmission = 0.5
	rightTrail.Color = ColorSequence.new(Color3.fromRGB(135, 206, 235))
	rightTrail.Enabled = false

	return leftTrail, rightTrail
end

local LeftTrail, RightTrail = createTrails()
createSpinAnimations()

local function speedFlash(isWhite)
	if SpeedFlashGui then
		SpeedFlashGui:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "SpeedFlashGui"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	SpeedFlashGui = gui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.Position = UDim2.new(0, 0, 0, 0)
	frame.BackgroundColor3 = isWhite and Color3.fromRGB(255,255,255) or Color3.fromRGB(0,191,255)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local info = TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local fadeIn = TweenService:Create(frame, info, {BackgroundTransparency = 0.5})
	local fadeOut = TweenService:Create(frame, info, {BackgroundTransparency = 1})
	fadeIn:Play()
	fadeIn.Completed:Wait()
	fadeOut:Play()
	fadeOut.Completed:Wait()

	if gui.Parent then
		gui:Destroy()
	end
	if SpeedFlashGui == gui then
		SpeedFlashGui = nil
	end
end

local function setupGui()
	if SpinDashGui then
		SpinDashGui:Destroy()
	end

	SpinDashGui = Instance.new("ScreenGui")
	SpinDashGui.Name = "SpinDashGui"
	SpinDashGui.ResetOnSpawn = false
	SpinDashGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	SpinDashButton = Instance.new("ImageButton")
	SpinDashButton.Name = "SpinDashButton"
	SpinDashButton.AnchorPoint = Vector2.new(1, 1)
	SpinDashButton.BackgroundTransparency = 1
	SpinDashButton.Image = "rbxassetid://131549024042077"
	SpinDashButton.Parent = SpinDashGui

	ChargeBar = Instance.new("Frame")
	ChargeBar.Name = "ChargeBar"
	ChargeBar.Size = UDim2.new(0, 20, 0, 0)
	ChargeBar.Position = UDim2.new(0, -30, 1, 0)
	ChargeBar.AnchorPoint = Vector2.new(0, 1)
	ChargeBar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	ChargeBar.BorderSizePixel = 0
	ChargeBar.BackgroundTransparency = 1
	ChargeBar.Parent = SpinDashGui

	Instance.new("UICorner", ChargeBar).CornerRadius = UDim.new(0, 8)

	SuperSonicButton = Instance.new("ImageButton")
	SuperSonicButton.Name = "SuperSonicButton"
	SuperSonicButton.AnchorPoint = Vector2.new(1, 1)
	SuperSonicButton.BackgroundTransparency = 1
	SuperSonicButton.Image = "rbxassetid://100711260432231"
	SuperSonicButton.Parent = SpinDashGui

	local inInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local outInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	local chargeIn = TweenService:Create(ChargeBar, inInfo, {BackgroundTransparency = 0.15})
	local chargeOut = TweenService:Create(ChargeBar, outInfo, {BackgroundTransparency = 1})

	SpinDashButton.MouseButton1Down:Connect(function()
		SpinDashButton.Image = "rbxassetid://126068833364301"
		chargeIn:Play()
		startCharge()
	end)

	SpinDashButton.MouseButton1Up:Connect(function()
		SpinDashButton.Image = "rbxassetid://131549024042077"
		chargeOut:Play()
		releaseCharge()
	end)

	SuperSonicButton.MouseButton1Down:Connect(function()
		SuperSonicButton.Image = "rbxassetid://109440344652504"
	end)

	SuperSonicButton.MouseButton1Up:Connect(function()
		SuperSonicButton.Image = "rbxassetid://100711260432231"
		toggleSuper()
	end)

	RunService.RenderStepped:Connect(function()
		if UserInputService.TouchEnabled then
			local touchGui = LocalPlayer.PlayerGui:FindFirstChild("TouchGui")
			local frame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
			local jumpButton = frame and frame:FindFirstChild("JumpButton")
			if jumpButton then
				SpinDashButton.Position = UDim2.new(
					0, jumpButton.AbsolutePosition.X + jumpButton.AbsoluteSize.X - jumpButton.AbsoluteSize.X - 10,
					0, jumpButton.AbsolutePosition.Y + jumpButton.AbsoluteSize.Y
				)
				SpinDashButton.Size = UDim2.new(0, jumpButton.AbsoluteSize.X, 0, jumpButton.AbsoluteSize.Y)
				SuperSonicButton.Position = UDim2.new(
					0, jumpButton.AbsolutePosition.X + jumpButton.AbsoluteSize.X,
					0, jumpButton.AbsolutePosition.Y + jumpButton.AbsoluteSize.Y - jumpButton.AbsoluteSize.Y - 10
				)
				SuperSonicButton.Size = UDim2.new(0, jumpButton.AbsoluteSize.X, 0, jumpButton.AbsoluteSize.Y)
			end
		end
	end)
end

local charging = false
local chargeStart = 0
local dashActive = false
local superActive = false
local currentSpeed = NORMAL_SPEED
local jumpCount = 0
local lastJump = 0

function startCharge()
	if charging then return end
	charging = true
	chargeStart = tick()
end

function releaseCharge()
	if not charging then return end
	charging = false
	local charge = math.clamp((tick() - chargeStart) / CHARGE_TIME, 0, 1)
	dashActive = true
	currentSpeed = MAX_SPEED + ((SUPER_SPEED - MAX_SPEED) * charge)

	if spinSuper then
		spinSuper:Play()
	end
	if LeftTrail then LeftTrail.Enabled = true end
	if RightTrail then RightTrail.Enabled = true end

	local velocity = Instance.new("BodyVelocity")
	velocity.MaxForce = Vector3.new(100000, 0, 100000)
	velocity.Velocity = Vector3.new(0, 0, 0)
	velocity.P = 1250
	velocity.Parent = RootPart
	dashSound:Play()

	task.delay(0.35, function()
		if velocity.Parent then
			velocity:Destroy()
		end
		dashActive = false
		if LeftTrail then LeftTrail.Enabled = false end
		if RightTrail then RightTrail.Enabled = false end
		if spinSuper then spinSuper:Stop() end
		if spinNormal then spinNormal:Stop() end
	end)
end

function toggleSuper()
	superActive = not superActive
	if superActive then
		speedFlash(true)
	else
		speedFlash(false)
	end
end

UserInputService.JumpRequest:Connect(function()
	if jumpCount < DOUBLE_JUMP_COUNT and tick() - lastJump > 0.2 then
		lastJump = tick()
		jumpCount += 1
		Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		if jumpCount == 1 then
			jumpSound:Play()
		elseif jumpCount == 2 then
			if doubleJumpAnimation then
				doubleJumpAnimation:Play()
			end
			jumpSound:Play()
		end
	end
end)

Humanoid.StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Landed then
		jumpCount = 0
		if doubleJumpAnimation and doubleJumpAnimation.IsPlaying then
			doubleJumpAnimation:Stop()
		end
	end
end)

if UserInputService.KeyboardEnabled then
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.C then
			startCharge()
		elseif input.KeyCode == Enum.KeyCode.V then
			toggleSuper()
		end
	end)

	UserInputService.InputEnded:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.C then
			releaseCharge()
		end
	end)
end

setupGui()

RunService.Heartbeat:Connect(function(dt)
	if not Character or not Character.Parent then return end

	if dashActive then
		local target = superActive and SUPER_SPEED or MAX_SPEED
		currentSpeed += (target - currentSpeed) * math.clamp(dt * 8, 0, 1)
	elseif Humanoid.MoveDirection.Magnitude > 0 then
		currentSpeed += ACCELERATION * dt
		currentSpeed = math.min(currentSpeed, superActive and SUPER_SPEED or MAX_SPEED)
	else
		currentSpeed += (NORMAL_SPEED - currentSpeed) * math.clamp(dt * 8, 0, 1)
	end

	Humanoid.WalkSpeed = currentSpeed

	if ChargeBar then
		local progress = charging and math.clamp((tick() - chargeStart) / CHARGE_TIME, 0, 1) or 0
		ChargeBar.Size = UDim2.new(0, 20, 0, (SpinDashButton and SpinDashButton.AbsoluteSize.Y or 0) * progress)
		if progress >= 0.95 then
			ChargeBar.BackgroundColor3 = superActive and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
		else
			ChargeBar.BackgroundColor3 = superActive and Color3.fromRGB(0,200,255) or Color3.fromRGB(255,255,0)
		end
	end

	if currentSpeed >= RUN_THRESHOLD then
		if not superActive then
			setAnimation("Run", 0)
		end
	end

	if superActive then
		Humanoid.WalkSpeed = math.max(Humanoid.WalkSpeed, SUPER_SPEED)
	end
end)

LocalPlayer.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
	Humanoid = Character:WaitForChild("Humanoid")
	RootPart = Character:WaitForChild("HumanoidRootPart")
	jumpCount = 0
	currentSpeed = NORMAL_SPEED
	dashActive = false
	charging = false

	createSpinAnimations()
	LeftTrail, RightTrail = createTrails()
	setupGui()
end)

local function showCreatorMessage()
	pcall(function()
		warn("Creator Script: SupErMoNK")
		warn("Subscribe to my Channel: @SupermonkXscripts, ScriptBlox account: Supermonkxscripts")
	end)
end

showCreatorMessage()
