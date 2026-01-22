# This is a quick analyses as I dont have much time but should explain it in good detail

## Step 1: Refrencing necessary variables and pattern scanning for the Position remote that will be used to hit other players
```
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
```
## Step 2: Grabbing server Id
The upvalue that holds this server ID btw exists in the clients memory as soon as its given the ID after invoking the server, meaning we can use getgc() to search the garbage collector for the variable.

One thing to note is that yes the variable exists in memory but because it also exists inside a function it makes it easier to traceback as we can lookup that specific function inside the garbage collector
and find what upvalue is the server ID.

We use the debug library which only is provided by strong executors and get the info of each function, If the function matches the details we are looking for we then store that value into our variable
```
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
```

## Step 3: Kill Aura Stuff :/
None of this is really important however to hit a player with the position remote we also need the gun ID which is stored within the guns attribute, everything else is just exploiting stuff which am sure
you are not trying to create :).
```
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
```

## Step 4: Kill Aura In Action
We fire the remote with the server ID and the gun ID, we then check the nearest player and use their head to kill them.
```
game:GetService("RunService").Heartbeat:Connect(function()
	if not gunId then
		gunId = getGunId();
	end

	local target = findTarget()
	if target and target.Character and target.Character:FindFirstChild("Head") and gunId and target.Character:FindFirstChild("Humanoid").Health > 0 then
		PositionRemote:FireServer(serverId, gunId, target.Character.Head)
	end
end)
```

## Things To Know
Kill selected player is the same thing but we target one player not the closest player.

Only thing you need to focus on is that remote event, you could maybe try encrypting the string like the anti-cheat but I cant say much without thinking about it clearly.
