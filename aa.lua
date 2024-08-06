--> Services | Variables <--
local Workspace = Game:GetService("Workspace")
local RunService = Game:GetService("RunService")
local Players = Game:GetService("Players")
local CoreGui = Game:GetService("CoreGui")

--> LocalPlayer | Variables <--
local player = Players.LocalPlayer
local playerCharacter = player.Character or player.CharacterAdded:Wait()
local playerHumanoid = playerCharacter:FindFirstChild("Humanoid") or playerCharacter:WaitForChild("Humanoid")
local playerHumanoidRootPart = playerCharacter:FindFirstChild("HumanoidRootPart") or playerCharacter:WaitForChild("HumanoidRootPart")
local playerCamera = Workspace.CurrentCamera

--> TargetedPlayer | Variables <--
local TargetedPlayer = nil
local TargetedPlayerCharacter = nil
local TargetedPlayerHumanoidRootPart = nil
local TargetedPlayerAimPart = nil

--> Script | Global Table <--
local Script = {
    Camlock = {
        Enabled = false,
        AimPart = "Head",
    },
    
    FOV = {
        Circle = {
            Visible = true,
            Color = Color3.fromRGB(255, 255, 255),
            Transparency = 0.35,
            Thickness = 1,
            NumSides = 100000,
            Radius = 115,
            Filled = false, 
        },
    },
}

--> ScreenGui | Variables <--
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = CoreGui
ScreenGui.Name = "ScreenGui | Camlock"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.Enabled = true 
ScreenGui.IgnoreGuiInset = false
ScreenGui.AutoLocalize = true

--> TextButton | Variables <--
local TextButton = Instance.new("TextButton")
TextButton.Parent = ScreenGui
TextButton.Name = "Camlock Enabler"
TextButton.Size = UDim2.new(0.05, 0, 0.05, 0)
TextButton.Position = UDim2.new(0.5, 0, 0.15, 0)
TextButton.AnchorPoint = Vector2.new(0.5, 0.5)
TextButton.Text = "OFF"
TextButton.Font = Enum.Font.GothamBold
TextButton.TextSize = 25
TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TextButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton.AutoButtonColor = true
TextButton.TextScaled = false
TextButton.TextWrapped = true
TextButton.TextXAlignment = Enum.TextXAlignment.Center
TextButton.TextYAlignment = Enum.TextYAlignment.Center
TextButton.Rotation = 0
TextButton.Visible = true
TextButton.ZIndex = 999
TextButton.Active = true
TextButton.Selectable = true
TextButton.Draggable = true
TextButton.Style = Enum.ButtonStyle.Custom

--> TextButton UICorner | Variables <--
local TextButtonUICorner = Instance.new("UICorner")
TextButtonUICorner.Parent = TextButton
TextButtonUICorner.CornerRadius = UDim.new(0.25, 0)

--> FOV Circle | Drawing <--
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = Script.FOV.Circle.Visible
FOVCircle.Color = Script.FOV.Circle.Color
FOVCircle.Transparency = Script.FOV.Circle.Transparency
FOVCircle.Thickness = Script.FOV.Circle.Thickness
FOVCircle.NumSides = Script.FOV.Circle.NumSides
FOVCircle.Radius = Script.FOV.Circle.Radius
FOVCircle.Filled = Script.FOV.Circle.Filled
FOVCircle.Position = Vector2.new(playerCamera.ViewportSize.X / 2, playerCamera.ViewportSize.Y / 2)

local queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
player.OnTeleport:Connect(function(State)
    if State == Enum.TeleportState.Started and queueteleport then
        queueteleport("")
    end
end)

--> Function To Handle LocalPlayer Respawns <--
player.CharacterAdded:Connect(function(Character)
    playerCharacter = Character
    playerHumanoid = playerCharacter:FindFirstChild("Humanoid") or playerCharacter:WaitForChild("Humanoid")
    playerHumanoidRootPart = playerCharacter:FindFirstChild("HumanoidRootPart") or playerCharacter:WaitForChild("HumanoidRootPart")
end)

--> Wall Check Function <--
local function WallCheck(Part)
    local Direction = (Part.Position - playerCamera.CFrame.Position).Unit * (Part.Position - playerCamera.CFrame.Position).Magnitude
    local NewRay = Ray.new(playerCamera.CFrame.Position, Direction)
    local Hit, Position = Workspace:FindPartOnRay(NewRay, playerCharacter, false, true)

    if Hit and Hit:IsDescendantOf(Part.Parent) and Part.Parent:IsA("Model") then
        return true
    end
    return false
end

--> Function To Get The Closest Player <--
local function GetClosestPlayer()
    local ClosestPlayer = nil
    local ShortestDistance = math.huge

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= player and Player.Character and Player.Character:FindFirstChild("Humanoid").Health ~= 0 then
            for _, PlayerPart in ipairs(Player.Character:GetChildren()) do
                if PlayerPart:IsA("BasePart") and PlayerPart.Transparency ~= 1 then
                    local ViewportPointPosition, OnScreen = playerCamera:WorldToViewportPoint(PlayerPart.Position)                   
                    local MagnitudeDistance = (Vector2.new(ViewportPointPosition.X, ViewportPointPosition.Y) - FOVCircle.Position).Magnitude
                    
                    if OnScreen and (MagnitudeDistance < ShortestDistance and MagnitudeDistance <= FOVCircle.Radius) and WallCheck(PlayerPart) then
                        ClosestPlayer = Player
                        ShortestDistance = MagnitudeDistance
                    end
                end
            end
        end
    end
    return ClosestPlayer
end

--> Function To Toggle Camlock State | TextButton <--
TextButton.MouseButton1Click:Connect(function()
    Script.Camlock.Enabled = not Script.Camlock.Enabled
    
    if Script.Camlock.Enabled then
        TextButton.Text = "ON"
    elseif not Script.Camlock.Enabled then
        TextButton.Text = "OFF"
        TargetedPlayer = nil
        TargetedPlayerCharacter = nil
        TargetedPlayerHumanoidRootPart = nil
        TargetedPlayerAimPart = nil
    end
end)

--> Function To Manipulate Player Camera On Targeted Player | RunService <--
RunService.RenderStepped:Connect(function(DeltaTime)
    TargetedPlayer = GetClosestPlayer()
    
    if Script.Camlock.Enabled and TargetedPlayer then
        TargetedPlayerCharacter = TargetedPlayer.Character
        if TargetedPlayerCharacter then
            if TargetedPlayerCharacter:FindFirstChild(Script.Camlock.AimPart) and TargetedPlayerCharacter:FindFirstChild("HumanoidRootPart") then
                TargetedPlayerAimPart = TargetedPlayerCharacter:FindFirstChild(Script.Camlock.AimPart)
                TargetedPlayerHumanoidRootPart = TargetedPlayerCharacter:FindFirstChild("HumanoidRootPart")
                if TargetedPlayerAimPart then
                    playerCamera.CFrame = CFrame.new(playerCamera.CFrame.Position, TargetedPlayerAimPart.Position)
                end
            end
        end
    end
end)
