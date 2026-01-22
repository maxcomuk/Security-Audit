local plr = game:GetService("Players").LocalPlayer;
local char = plr.Character;
local root = char:FindFirstChild("HumanoidRootPart");

local gunRemotes = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GunFramework"):WaitForChild("Remotes")
local PositionRemote = gunRemotes:FindFirstChild("Position") -- this is old and gets nil, its why I did for loop below
if not PositionRemote then
    for _, r in pairs(gunRemotes:GetChildren()) do
        if r:IsA("RemoteEvent") then
            if r.Name:sub(1,1) == "{" then -- This is what I meant by pattern scannening for this { as its the only object with this name in the folder
                PositionRemote = r
                break
            end
        end
    end
end

local serverId;
local gunId;

for _, obj in next, getgc(true) do
	if type(obj) == "function" then
		local info = debug.getinfo(obj);

		if info.name == "Fire" and info.short_src:find("GunClient") and info.nups == 8 then
			local upValues = debug.getupvalues(obj);
			serverId = upValues[4];
		end
	end
end

local function getGunId()
	local target = nil;
	if char and root and char:FindFirstChildOfClass("Tool") and char:FindFirstChildOfClass("Tool"):GetAttribute("Id") then
		target = char:FindFirstChildOfClass("Tool"):GetAttribute("Id");
	end
	if not target then
		local bag = plr:FindFirstChild("Backpack");
		if bag then
			for _, tool in pairs(bag:GetChildren()) do
				if tool:IsA("Tool") and tool:GetAttribute("Id") then
					target = tool:GetAttribute("Id");
				end
			end
		end
	end
	return target;
end

local function findTarget()
	local target = nil;
	local maxDistance = math.huge;
	for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
		if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local plrChar = plr.Character;
			if not (plrChar:FindFirstChild("OnboardingHighlight") or plrChar:FindFirstChild("SafeField")) then
				local distance = (plrChar:FindFirstChild("HumanoidRootPart").Position - root.Position).Magnitude;
				if distance < maxDistance then
					maxDistance = distance;
					target = plr;
				end
			end
		end
	end
	return target;
end

game:GetService("RunService").Heartbeat:Connect(function()
	if not gunId then
		gunId = getGunId();
	end

	local target = findTarget()
	if target and target.Character and target.Character:FindFirstChild("Head") and gunId and target.Character:FindFirstChild("Humanoid").Health > 0 then
		PositionRemote:FireServer(serverId, gunId, target.Character.Head)
	end
end)
