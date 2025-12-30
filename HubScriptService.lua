local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HubRemote = ReplicatedStorage:FindFirstChild("HubRemote")
if not HubRemote then
    HubRemote = Instance.new("RemoteEvent")
    HubRemote.Name = "HubRemote"
    HubRemote.Parent = ReplicatedStorage
end
