local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Cek dulu kalau belum ada
local Remote = ReplicatedStorage:FindFirstChild("HubRemote")
if not Remote then
    Remote = Instance.new("RemoteEvent")
    Remote.Name = "HubRemote"
    Remote.Parent = ReplicatedStorage
end
