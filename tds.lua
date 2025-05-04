local v0 = game:GetService("ReplicatedStorage");
local v1 = game:GetService("TeleportService");
local v2 = v0:WaitForChild("RemoteFunction");
local v3 = game.Players.LocalPlayer;
if workspace:FindFirstChild("Elevators") then
	local v25 = 0;
	local v26;
	while true do
		if (v25 == (0 - 0)) then
			v26 = {[491 - (59 + 431)]="Multiplayer",[729 - (433 + 294)]="v2:start",[1849 - (1228 + 618)]={count=(1 - 0),mode="halloween"}};
			v2:InvokeServer(unpack(v26));
			break;
		end
	end
else
	local v27 = 0;
	while true do
		if (v27 == (3 - 2)) then
			task.wait(1);
			break;
		end
		if (v27 == (952 - (802 + 150))) then
			print("Elevators not found - skipping vote...");
			v2:InvokeServer("Voting", "Skip");
			v27 = 1;
		end
	end
end
local v4 = v3:WaitForChild("PlayerGui"):WaitForChild("ReactUniversalHotbar"):WaitForChild("Frame"):WaitForChild("values"):WaitForChild("cash"):WaitForChild("amount");
local function v5()
	local v11 = 0 - 0;
	local v12;
	local v13;
	local v14;
	while true do
		if (v11 == 0) then
			v12 = 0 - 0;
			v13 = nil;
			v11 = 1 + 0;
		end
		if (1 == v11) then
			v14 = nil;
			while true do
				if (v12 == (998 - (915 + 82))) then
					return tonumber(v14) or (0 - 0);
				end
				if (v12 == (0 + 0)) then
					v13 = v4.Text or "";
					v14 = v13:gsub("[^%d%-]", "");
					v12 = 1 - 0;
				end
			end
			break;
		end
	end
end
local function v6(v15)
	while v5() < v15 do
		task.wait(1188 - (1069 + 118));
	end
end
local function v7(v16, v17)
	local v18 = 0 - 0;
	local v19;
	local v20;
	local v21;
	while true do
		if (v18 == (0 - 0)) then
			v19 = 0 + 0;
			v20 = nil;
			v18 = 1;
		end
		if (v18 == (1 - 0)) then
			v21 = nil;
			while true do
				if (0 == v19) then
					v6(v17);
					print("Invoking:", v16[4 + 0], "Action:", v16[2], "Cost:", v17);
					v19 = 792 - (368 + 423);
				end
				if (v19 == 1) then
					v20, v21 = pcall(function()
						v2:InvokeServer(unpack(v16));
					end);
					if not v20 then
						warn("Error:", v21);
					end
					v19 = 6 - 4;
				end
				if (2 == v19) then
					task.wait(19 - (10 + 8));
					break;
				end
			end
			break;
		end
	end
end
local v8 = {{args={"Troops","Pl\208\176ce",{Rotation=CFrame.new(),Position=Vector3.new(15.668 - 11, 444.349 - (416 + 26), -(118.184 - 81))},"Shotgunner"},cost=(530 - 230)},{args={"Troops","Pl\208\176ce",{Rotation=CFrame.new(),Position=Vector3.new(-(431.643 - (44 + 386)), 2.349, -(1522.87 - (998 + 488)))},"Shotgunner"},cost=300},{args={"Troops","Pl\208\176ce",{Rotation=CFrame.new(),Position=Vector3.new(1142.487 - (116 + 1022), 8.386 - 6, -34.154)},"Shotgunner"},cost=300},{args={"Troops","Pl\208\176ce",{Rotation=CFrame.new(),Position=Vector3.new(-(860.185 - (814 + 45)), 4.386 - 2, -(2.905000000000001 + 31))},"Shotgunner"},cost=300},{args={"Troops","Pl\208\176ce",{Rotation=CFrame.new(),Position=Vector3.new(-0.616, 2.386, -(1453.504 - (630 + 793)))},"Shotgunner"},cost=(1016 - 716)},{args={"Troops","Pl\208\176ce",{Rotation=CFrame.new(),Position=Vector3.new(1754.143 - (760 + 987), 1915.35 - (1789 + 124), -(805.064 - (745 + 21)))},"Trapper"},cost=500},{args={"Troops","Pl\208\176ce",{Rotation=CFrame.new(),Position=Vector3.new(7.671, 2.386 + 0, -(1090.299 - (87 + 968)))},"Trapper"},cost=(454 + 46)},{args={"Troops","Pl\208\176ce",{Rotation=CFrame.new(),Position=Vector3.new(-(1821.269 - (1703 + 114)), 703.349 - (376 + 325), -(62.972 - 24))},"Trapper"},cost=(143 + 357)},{args={"Troops","Pl\208\176ce",{Rotation=CFrame.new(),Position=Vector3.new(4.907, 2.386, -31.026)},"Trapper"},cost=500},{args={"Troops","Pl\208\176ce",{Rotation=CFrame.new(),Position=Vector3.new(6.948 + 1, 1182.386 - (1123 + 57), -(25.539 + 5))},"Trapper"},cost=500},{args={"Troops","Pl\208\176ce",{Rotation=CFrame.new(),Position=Vector3.new(0.052 - 0, 2.386 - 0, -(4.332999999999998 + 23))},"Trapper"},cost=(470 + 30)},{args={"Troops","Pl\208\176ce",{Rotation=CFrame.new(),Position=Vector3.new(1853.45 - (1409 + 441), 720.386 - (15 + 703), -(12.265 + 13))},"Trapper"},cost=500}};
for v22, v23 in ipairs(v8) do
	v7(v23.args, v23.cost);
end
print("All towers placed. Starting 60-second timer and upgrades...");
local v9 = task.delay(250, function()
	v1:Teleport(3260590765 - (262 + 176));
end);
local v10 = workspace:WaitForChild("Towers");
while true do
	local v24 = v10:GetChildren();
	print("Tower count:", #v24);
	for v28, v29 in ipairs(v24) do
		local v30 = 0;
		local v31;
		while true do
			if ((1722 - (345 + 1376)) == v30) then
				pcall(function()
					v2:InvokeServer(unpack(v31));
				end);
				break;
			end
			if (v30 == (688 - (198 + 490))) then
				print("Tower", v28, v29.Name);
				v31 = {"Troops","Upgrade","Set",{Troop=v29,Path=1}};
				v30 = 2 - 1;
			end
		end
	end
	task.wait(1);
end
