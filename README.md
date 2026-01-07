# [DEPRECATED] DataStoreEngine V1.10 [by iamnotultra3, a.k.a Elite]
	
	[MIT LICENSE]
	
	Tired of facing the DataStoreService sudden errors/rate limits? Use DataStoreEngine!
	
	Why use DataStoreEngine:
	- Fully handles rate limiting via our custom processor
	- Has full functionality of DataStoreService (and some more), which means you do not have to learn this module if you already know DataStoreService :D (still read documentation tho)
	- Optimized for performance
	- Has strong type annotations
	
	Warnings:
	- You must enable API Services to use this module(otherwise it will not work)
	- The data size MUST NOT exceed 4MB per key
	- The data type MUST be JSONAcceptable or nil
	- The module DOES NOT have retries system, because it is made so that users have a free control of what to do
	
	JSONAcceptable = { JSONAcceptable } | { [string]: JSONAcceptable } | number | string | boolean | buffer
	
	Members:
	
	DataStoreEngine:
		| :GetDataStore(DataStoreName: string, DataStoreScope: string?, DataStoreOptions: DataStoreOptions?) -> EngineDataStore
		| :GetOrderedDataStore(DataStoreName: string, DataStoreScope: string?) -> EngineOrderedDataStore
		| :ListDatastoresAsync(Prefix: string?, PageSize: number? Cursor: string?) -> DataStoreListingPages
		| :GetGlobalDataStore() -> EngineDataStore
		| :GetRequestBudgetForRequestType(RequestType: Enum.DataStoreRequestType) -> number
		
	_____________________
	
	EngineDataStore:
		| :GetAsync(Key: string, Options: DataStoreGetOptions?, Prioritize: boolean?) -> ( success: boolean, result: JSONAcceptable? )
			| note: if success == false,  `result` becomes the error message, if Prioritize == true, will process the request faster than the other ones
		
		| :SetAsync(Key: string, SetData: JSONAcceptable?, UserIds: { number? }? Options: DataStoreSetOptions?, Prioritize: boolean?) -> ( success: boolean, error_message: string? )
			| note: if Prioritize == true, will process the request faster than the other ones
		
		| :UpdateAsync(Key: string, TransformFunction: function(OldData: JSONAcceptable?) -> JSONAcceptable?, UserIds: { number? }?, Prioritize: boolean?) -> ( success: boolean, error_message: string? )
			| note: if Prioritize == true, will process the request faster than the other ones
		
		| :IncrementAsync(Key: string, IncrementAmount: number, UserIds: { number? }?, Options: DataStoreIncrementOptions?, Prioritize: boolean?) -> ( success: boolean, error_message: string? )
			| note: The Key data must be number, otherwise it will not succeed, if Prioritize == true, will process the request faster than the other ones
			
		| :RemoveAsync(Key: string, Prioritize: boolean?) -> ( success: boolean, removed_data: JSONAcceptable? )
			| note: if success == false,  `removed_data` becomes the error message, if Prioritize == true, will process the request faster than the other ones
			
		| :ListVersionsAsync(
			Key: string,
			SortDirection: Enum.SortDirection?,
			MinDate: number?,
			MaxDate: number?,
			PageSize: number?,
			Prioritize: boolean?
		  ) -> (success: boolean, result: DataStoreVersionPages?),
			| note: if success == false,  `result` becomes the error message, if Prioritize == true, will process the request faster than the other ones
		
		| :RemoveVersionAsync(
			Key: string,
			Version: string,
			Prioritize: boolean?
		  ) -> (success: boolean, error_message: string?)
			| note: if Prioritize == true, will process the request faster than the other ones
		
		| :GetVersionAtTimeAsync(
			Key: string,
			Timestamp: number,<-- unix timestamp
			Prioritize: boolean?
		  ) -> (success: boolean, version: JSONAcceptable?),
			| note: if success == false, `version` becomes the error message, if Prioritize == true, will process the request faster than the other ones

		| GetVersionAsync(
			Key: string,
			Version: string,
			Prioritize: boolean?
		) -> (success: boolean, version: JSONAcceptable?),
			| note: if success == false, `version` becomes the error message, if Prioritize == true, will process the request faster than the other ones
	
	EngineOrderedDataStore:
		| :GetAsync(Key: string, Options: DataStoreGetOptions?, Prioritize: boolean?) -> ( success: boolean, result: number? )
			| note: if success == false,  `result` becomes the error message, if Prioritize == true, will process the request faster than the other ones
		
		| :SetAsync(Key: string, SetData: number?, UserIds: { number? }? Options: DataStoreSetOptions?, Prioritize: boolean?) -> ( success: boolean, error_message: string? )
			| note: if Prioritize == true, will process the request faster than the other ones
		
		| :UpdateAsync(Key: string, TransformFunction: function(OldData: number?) -> number?, UserIds: { number? }?, Prioritize: boolean?) -> ( success: boolean, error_message: string? )
			| note: if Prioritize == true, will process the request faster than the other ones
		
		| :IncrementAsync(Key: string, IncrementAmount: number, UserIds: { number? }?, Options: DataStoreIncrementOptions?, Prioritize: boolean?) -> ( success: boolean, error_message: string? )
			| note: The Key data must be number, otherwise it will not succeed, if Prioritize == true, will process the request faster than the other ones
			
		| :RemoveAsync(Key: string, Prioritize: boolean?) -> ( success: boolean, removed_data: number? )
			| note: if success == false,  `removed_data` becomes the error message, if Prioritize == true, will process the request faster than the other ones
		
		| GetSortedAsync(
			Ascending: boolean,
			PageSize: number,
			MinValue: number?,
			MaxValue: number?,
			Prioritize: boolean?
		  ) -> (success: boolean, result: DataStorePages?),
		| note: if success == false,  `removed_data` becomes the error message, if Prioritize == true, will process the request faster than the other ones
		
	Usage example(player data management):
	```
		local Players = game:GetService("Players")
		local RunService = game:GetService("RunService")

		--require the module
		local DataStoreEngine = require(script.Parent.DataStoreEngine)

		local PlayersStore = DataStoreEngine:GetDataStore("PlayersStore")

		--best practice: store the sessions data inside a table
		local PlayersData = {}

		--Store a default data table(when a new player joins, their data will be Default Data)
		local DefaultData = {
			Coins = 100,
			Inventory = { Sword = 1 },
			Gold = 1
		}

		local Connections = {}

		--Function to fill missing fields, compared to Default Data (this version is not for nested data, do not use this in production with nested data)
		local function RestructureData(Data)
			
			local tbl = table.clone(DefaultData)
			
			for key, value in pairs(Data) do
				
				tbl[key] = value
				
			end
			
			return tbl
			
		end

		--best practice: DRY(dont repeat yourself)
		local function OnInventoryChildDataChanged(child, PlayerData, Player)
			local connection = child:GetPropertyChangedSignal("Value"):Connect(function()

				print(`Changed data: name: {child.Name}, new value: {child.Value}`)

				PlayerData.Inventory[child.Name] = child.Value

			end)
			
			table.insert(Connections[Player], connection)
		end

		--initializator function for player(create leaderstats, configure data, etc)
		local function InitializePlayer(Player: Player, PlayerData: typeof(DefaultData))
			
			PlayerData = RestructureData(PlayerData)
			
			PlayersData[tostring(Player.UserId)] = PlayerData
			Connections[Player] = {}
			
			local leaderstats = Instance.new("Folder", Player)
			leaderstats.Name = "leaderstats"
			
			local Coins = Instance.new("IntValue", leaderstats)
			Coins.Name = "Coins"
			Coins.Value = PlayerData.Coins
			
			local Gold = Instance.new("IntValue", leaderstats)
			Gold.Name = "Gold"
			Gold.Value = PlayerData.Gold
			
			local Inventory = Instance.new("Folder", Player)
			Inventory.Name = "Inventory"
			
			for itemName, itemAmount in PlayerData.Inventory do
				
				local NewItem = Instance.new("IntValue", Inventory)
				
				NewItem.Name = itemName
				NewItem.Value  = itemAmount
				
			end
			
			--Listen to data changes
			
			for _, child in leaderstats:GetChildren() do
				
				local connection = child:GetPropertyChangedSignal("Value"):Connect(function()
					
					print(`Changed data: name: {child.Name}, new value: {child.Value}`)
					
					PlayerData[child.Name] = child.Value
					
				end)
				
				table.insert(Connections[Player], connection)
				
			end
			
			for _, child in ipairs(Inventory:GetChildren()) do
				
				OnInventoryChildDataChanged(child, PlayerData)
				
			end
			
			Inventory.ChildAdded:Connect(function(child)
				
				PlayerData.Inventory[child.Name] = child.Value
				
				OnInventoryChildDataChanged(child, PlayerData)
				
			end)
			
		end

		--Connect to PlayerAdded event
		Players.PlayerAdded:Connect(function(Player)
			
			local PlayerKey = tostring(Player.UserId)
			
			local PlayerData = nil
			
			--best practice: use UpdateAsync in most cases
			local success, error_message = PlayersStore:UpdateAsync(PlayerKey, function(old_data)
				
				old_data = old_data or DefaultData
				
				PlayerData = old_data
				
				return old_data
				
			end, { Player.UserId }, true)--prioritize player load request
			
			if success then
				
				InitializePlayer(Player, PlayerData)
				
			else
				
				Player:Kick("Failed to retreive your data, please rejoin")
				
			end
			
		end)


		Players.PlayerRemoving:Connect(function(Player)
			
			local PlayerKey = tostring(Player.UserId)
			
			local PlayerData = PlayersData[PlayerKey]
			
			if PlayerData then
				
				local success, error_message = PlayersStore:SetAsync(PlayerKey, PlayerData, { Player.UserId }, nil, true)--prioritize the request
				
				if not success then
					
					warn(` Failed to save data for player {Player.Name}, user_id: {PlayerKey} `)
					
				end
				
				PlayersData[PlayerKey] = nil
				
				--best practice: disconnect player connections in order to avoid memory leaks
				for i, connection in Connections[Player] do
					
					connection:Disconnect()
					
				end
				
				Connections[Player] = nil
				
			end
			
		end)



		--autosave

		local function save_player_data(currentIndex, ActivePlayers)
			
			if currentIndex > #ActivePlayers then
				currentIndex = 1
			end
			
			local player = ActivePlayers[currentIndex]

			local key = tostring(player.UserId)

			local player_data = PlayersData[key]

			if player_data then
				
				PlayersStore:SetAsync(key, player_data)
				
			else
				return save_player_data(currentIndex + 1, ActivePlayers)
			end
			
			currentIndex += 1
			
			if currentIndex > #ActivePlayers then
				currentIndex = 1
			end
			
			return currentIndex
			
		end
		task.spawn(function()
			
			local currentIndex = 1
			local autosave_time = 300
			local last_updated = os.time()
			

			RunService.Heartbeat:Connect(function()
				
				--best practice: autosave player data one after another, do not suddenly overload datastore by saving every players data at a time
				
				local ActivePlayers = Players:GetPlayers()
				local PlayersCount = #ActivePlayers
				
				local next_save = autosave_time / PlayersCount
				
				if (os.time() - last_updated) >= next_save then
					
					last_updated = os.time()
					
					currentIndex = save_player_data(currentIndex, ActivePlayers)
					
				end
				
			end)
			
		end)
	```
	
	If you do not know how to use DataStoreService, then here, read this official roblox doc:
	"https://create.roblox.com/docs/reference/engine/classes/DataStoreService"
