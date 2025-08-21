--[[
	DataStoreEngine V1.10 [by iamnotultra3, a.k.a Elite]
	
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
]]

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")


----Configurations

local LOG_LEVEL = 1 -- level 2 = every step is being printed
-- level 1 = only warnings are being printed
-- level 0 nothing is being printed


------Signal------
local Signal = {}
Signal.__index = Signal

--`Connection` class
local signal_connection = {}
signal_connection.__index = signal_connection

function signal_connection.new(signal_class, fn)
	local self = setmetatable({}, signal_connection)

	self.signal = signal_class
	self.fn = fn

	return self
end


function signal_connection:Disconnect()
	local i = table.find(self.signal._listeners, self)
	if i then
		table.remove(self.signal._listeners, i)
	end
end

function Signal.new()
	local self = setmetatable({}, Signal)
	self._listeners = {}

	return self
end

function Signal:Connect(fn)
	assert(type(fn) == "function", `Invalid Argument #1, function expected, got {typeof(fn)}`)

	local connection = signal_connection.new(self, fn)

	table.insert(self._listeners, connection)

	return connection
end

function Signal:Fire(...)
	
	for _, connection in ipairs(self._listeners) do
		
		task.spawn(connection.fn, ...)
		
	end
	
end


local function Log(level, ...)
	if LOG_LEVEL >= level then
		local func = level > 1 and print or level == 1 and warn or function() end

		func("[DataStoreEngine] ", ...)
	end
end




local total_ds_requests = 0

local DataStoreEngine = {}
DataStoreEngine.__index = DataStoreEngine

local data_store_processor = {
	incoming_requests = {
		SetAsync = {},
		GetAsync = {},
		UpdateAsync = {},
		IncrementAsync = {},
		RemoveAsync = {},
		ListKeysAsync = {},
		GetVersionAsync = {},
		ListVersionsAsync = {},
		RemoveVersionAsync = {},
		GetVersionAtTimeAsync = {},
		GetSortedAsync = {},
		AdvanceToNextPage = {}
	},
	keys_history = {},

	IsRunning = false
}
local request_name_modes = {
	SetAsync = "Write",
	GetAsync = "Read",
	UpdateAsync = "WriteRead",
	IncrementAsync = "Write",
	RemoveAsync = "Write"
}
local RequestFinished = Signal.new()

local MIN_INTERVAL = 0.25  -- Fastest polling when busy
local MAX_INTERVAL = 2.0  -- Slowest polling when idle
local function get_dynamic_interval(queue_size, budget_available)
	if queue_size == 0 or not budget_available then
		return MAX_INTERVAL
	end
	-- Scale interval inversely with queue size (more requests -> faster polling)
	return math.max(MIN_INTERVAL, MAX_INTERVAL / (1 + queue_size / 10))
end

local function is_key_valid_for_request(request_name, key)

	if not key then return true end--assume this is an operation that does not require key, e.g. ListKeysAsync

	local keyhistory = data_store_processor.keys_history[key]
	if not keyhistory then
		data_store_processor.keys_history[key] = {canRead = true, canWrite = true}
		keyhistory = data_store_processor.keys_history[key]
		return true
	end
	local reqmode = request_name_modes[request_name]
	if reqmode == "Read" then
		return keyhistory.canRead
	elseif reqmode == "Write" then
		return keyhistory.canWrite
	elseif reqmode == "WriteRead" then
		return keyhistory.canWrite and keyhistory.canRead
	end
end

local function run_processor()
	if not DataStoreModeFiltered then
		repeat
			task.wait()
		until DataStoreModeFiltered
	end
	if data_store_processor.IsRunning then
		return
	end

	Log(2, "Running processor")

	data_store_processor.IsRunning = true

	local heartbeatConn
	local elapsed = 0

	heartbeatConn = RunService.Heartbeat:Connect(function(delta)
		elapsed += delta

		elapsed += delta
		local queue_size = 0
		for _, req_queue in data_store_processor.incoming_requests do
			queue_size += #req_queue
		end
		local budget_available = false
		
		for _, req_queue in data_store_processor.incoming_requests do
			if #req_queue > 0 and DataStoreService:GetRequestBudgetForRequestType(req_queue[1].rt) >= 1 then
				budget_available = true
				break
			end
		end

		local interval = get_dynamic_interval(queue_size, budget_available)
		if elapsed < interval then return end
		
		elapsed = 0

		local allEmpty = true

		for req_name, req_queue in data_store_processor.incoming_requests do
			if #req_queue > 0 then
				allEmpty = false
				for _, request_info in req_queue do
					if request_info.processing then
						Log(2, "Request is already being processed, skipping")
						continue
					end

					Log(2, "Processing request...")

					local budget = DataStoreService:GetRequestBudgetForRequestType(request_info.rt)

					if budget < 1 then
						Log(2, "Insufficient budget, skipping")
						continue
					end

					if not is_key_valid_for_request(req_name, request_info.tk) then
						Log(2, "Skipping request due to key having too frequent read and/or write requests")
						continue
					end

					request_info.processing = true

					task.spawn(function()
						Log(2, "Request is validated, continuing...")

						local key = request_info.tk
						local ds: DataStore = request_info.ds
						local xtra = request_info.xtra
						local opts = request_info.opts

						local result = {
							success = false,
							errmsg = nil,
							value = nil
						}

						Log(2, `Processing request info: datastore: {ds}, extra data: {xtra or "None"}, key: {key or "None"}, request name: {req_name}`)
						local rtype = ""

						local ok, err = pcall(function()
							
							if req_name == "GetAsync" then
								
								data_store_processor.keys_history[key].canRead = false
								rtype = "Read"
								result.value = ds:GetAsync(key, opts)
								
							elseif req_name == "SetAsync" then
								
								data_store_processor.keys_history[key].canWrite = false
								rtype = "Write"
								ds:SetAsync(key, xtra.set_value, xtra.uids, opts)
								
								
							elseif req_name == "UpdateAsync" then
								
								data_store_processor.keys_history[key].canWrite = false
								data_store_processor.keys_history[key].canRead = false
								rtype = "ReadWrite"
								ds:UpdateAsync(key, xtra.transform_func, xtra.uids)
								
							elseif req_name == "IncrementAsync" then
								
								data_store_processor.keys_history[key].canWrite = false
								rtype = "Write"
								ds:IncrementAsync(key, xtra.increment, xtra.uids, opts)
								
								
							elseif req_name == "RemoveAsync" then
								
								rtype = "Write"
								data_store_processor.keys_history[key].canWrite = false
								ds:RemoveAsync(key)
								
								
							elseif req_name == "ListKeysAsync" then
								
								result.value = ds:ListKeysAsync(xtra.prefix, xtra.page_size, xtra.cursor, xtra.exclude_deleted)
								
								
							elseif req_name == "GetVersionAsync" then
								
								result.value = ds:GetVersionAsync(xtra.key, xtra.version)
								
								
							elseif req_name == "ListVersionsAsync" then
								
								result.value = ds:ListVersionsAsync(xtra.key, xtra.sort_direction, xtra.min_date, xtra.max_date, xtra.page_size)
								
								
							elseif req_name == "RemoveVersionAsync" then
								
								result.value = ds:RemoveVersionAsync(xtra.key, xtra.version)
								
								
							elseif req_name == "GetVersionAtTimeAsync" then
								
								result.value = ds:GetVersionAtTimeAsync(xtra.key, xtra.timestamp)
								
								
							elseif req_name == "GetSortedAsync" then
								
								local ascending = xtra.ascending
								local pageSize = xtra.pageSize
								local minValue = xtra.minValue
								local maxValue = xtra.maxValue
								local pages = ds:GetSortedAsync(ascending, pageSize, minValue, maxValue)
								result.value = pages
								
								
							elseif req_name == "AdvanceToNextPage" then
								
								ds:AdvanceToNextPageAsync()
								
								
							else
								
								Log(1, ` [DataStoreProcessor] Unknown request type: {req_name}`)
								
								
							end
							
						end) 

						if rtype ~= "" then
							if rtype == "Read" then
								data_store_processor.keys_history[key].canRead = true
							elseif rtype == "Write" then
								data_store_processor.keys_history[key].canWrite = true
							elseif rtype == "ReadWrite" then
								data_store_processor.keys_history[key].canRead = true
								data_store_processor.keys_history[key].canWrite = true
							end
						end

						result.success = ok

						if not ok then

							result.errmsg = err
							Log(1, `[DataStoreProcessor] Error with "{req_name}" on {key}: {err}`)
							
						end

						Log(2, `Finished processing request, process succeeded: {result.success}, value: {result.value or "None"}`)

						RequestFinished:Fire(request_info.rid, result)

						-- Remove this request from the queue
						local index = table.find(req_queue, request_info)
						if index then
							table.remove(req_queue, index)
						end
					end)
				end
			end
		end

		if allEmpty then
			-- No more queued requests, stop it
			Log(2, "Stopping processor, because the queues are empty")

			data_store_processor.IsRunning = false
			heartbeatConn:Disconnect()
		end
	end)
end


local function generate_request_id()
	total_ds_requests += 1
	return "R_"..total_ds_requests
end

local function insertPrioritized(queue, newRequest)
	-- Step 1: Find first available spot (non-priority or empty)
	local insertIndex: number? = nil
	for i = 1, #queue + 1 do
		if not queue[i] or not queue[i].prioritize then
			insertIndex = i
			break
		end
	end
	if not insertIndex then
		insertIndex = #queue + 1
	end
	-- Step 2: Shift non-priority requests down
	local qc = #queue
	for i = qc + 1, insertIndex + 1, -1 do
		local prev = queue[i - 1]
		-- Only shift if previous spot has something and is NOT priority
		if not prev then continue end
		if not prev.prioritize then
			if queue[i] == nil then
				queue[i] = prev
				queue[i - 1] = nil
			else
				local add = 1
				for v = 1, qc - i + 1 do  -- Fixed loop upper bound to prevent overwriting by always allowing extension to qc+1 if no earlier nil.
					if queue[i + v] == nil then
						add = v
						break
					end
				end
				queue[i + add] = prev
				queue[i - 1] = nil
			end
		end
	end
	-- Step 3: Place the new priority request
	queue[insertIndex] = newRequest
	DataStoreModeFiltered = true
end

local function process_request(request_name: string, data_store: DataStore, request_type: Enum.DataStoreRequestType, target_key: string?, extradata: {[any]: any}?, prioritize: boolean?, opts: DataStoreOptions? | DataStoreGetOptions? | DataStoreSetOptions? | DataStoreIncrementOptions?)

	Log(2, `Incoming request to process: request naeme = {request_name}, data store: {data_store}, request type: {request_type}, target key: {target_key}, extra data: {extradata}, data store options: {opts} \n traceback: {debug.traceback()}`)

	local return_value = nil
	local process_finished = false
	local co = coroutine.running()

	if data_store_processor.incoming_requests[request_name] then

		Log(2, `Found request queue, preparing to insert the request`)

		local request_id = generate_request_id()
		local conn = nil
		conn = RequestFinished:Connect(function(r_id, return_val)
			if request_id == r_id then
				Log(2, `Finished processing request {r_id}`)
				return_value = return_val
				process_finished = true
				conn:Disconnect()
				coroutine.resume(co)
			end
		end)

		local fn = prioritize and insertPrioritized or table.insert

		fn(data_store_processor.incoming_requests[request_name], {
			ds = data_store,
			rt = request_type,
			tk = target_key,
			opts = opts,
			rid = request_id,
			processing = false,
			xtra = extradata,
			prioritize = prioritize
		})
	else
		Log(1, `No {request_name} request found`)
		process_finished = true
	end

	--start the processor once a request is made
	run_processor()

	if not process_finished then coroutine.yield() end

	Log(2, `Finished process, info: {return_value}`)

	return return_value
end

function DataStoreEngine:GetDataStore(data_store_name, data_store_scope, data_store_options)
	assert(type(data_store_name) == "string", "Invalid argument #1, string expected, got "..typeof(data_store_name))

	local self = setmetatable({}, DataStoreEngine)
	self._ds = DataStoreService:GetDataStore(data_store_name, data_store_scope, data_store_options)

	return self
end

function DataStoreEngine:GetGlobalDataStore()
	local self = setmetatable({}, DataStoreEngine)
	self._ds = DataStoreService:GetGlobalDataStore()

	return self
end

function DataStoreEngine:ListDataStoresAsync(prefix, pagesize, cursor)
	
	return DataStoreService:ListDataStoresAsync(prefix, pagesize, cursor)
	
end

function DataStoreEngine:GetRequestBudgetForRequestType(request_type)
	
	return DataStoreService:GetRequestBudgetForRequestType(request_type)
	
end

function DataStoreEngine:GetOrderedDataStore(data_store_name, data_store_scope)
	assert(type(data_store_name) == "string", "Invalid argument #1, string expected, got "..typeof(data_store_name))

	local self = setmetatable(DataStoreEngine, {})
	self._ds = DataStoreService:GetOrderedDataStore(data_store_name, data_store_scope)

	return self
end

function DataStoreEngine:GetAsync(data_store_key, datastore_get_options, prioritize)
	assert(type(data_store_key) == "string", `Invalid argument #1, string expected, got {typeof(data_store_key)}`)


	local request_result = process_request("GetAsync", self._ds, Enum.DataStoreRequestType.GetAsync, data_store_key, nil, prioritize,  datastore_get_options)

	if not request_result.success then

		Log(1, `Failed to process request, error: {request_result.errmsg}`)
		return false, request_result.errmsg

	end

	return true, request_result.value
end

function DataStoreEngine:RemoveAsync(data_store_key, prioritize)
	assert(type(data_store_key) == "string", `Invalid argument #1, string expected, got {typeof(data_store_key)}`)

	local request_result = process_request("RemoveAsync", self._ds, Enum.DataStoreRequestType.SetIncrementAsync, data_store_key, nil, prioritize)

	if not request_result.success then

		Log(1, `Failed to process request, error: {request_result.errmsg}`)
		return false, request_result.errmsg

	end

	return true, request_result.value
end

function DataStoreEngine:SetAsync(data_store_key, save_value, user_ids, datastore_set_options, prioritize)
	assert(type(data_store_key) == "string", `Invalid argument #1, string expected, got {typeof(data_store_key)}`)


	local request_result = process_request("SetAsync", self._ds, Enum.DataStoreRequestType.SetIncrementAsync, data_store_key, {set_value = save_value, uids = user_ids}, prioritize)

	if not request_result.success then

		Log(1, `Failed to process request, error: {request_result.errmsg}`)

	end
	
	return request_result.success, request_result.errmsg
end

function DataStoreEngine:UpdateAsync(data_store_key, transform_function, user_ids, prioritize)
	assert(type(data_store_key) == "string", `Invalid argument #1, string expected, got {typeof(data_store_key)}`)
	assert(type(transform_function) == "function", `Invalid argument #2, function expected, got {typeof(transform_function)}`)

	local request_result = process_request("UpdateAsync", self._ds, Enum.DataStoreRequestType.UpdateAsync, data_store_key, {transform_func = transform_function, uids = user_ids}, prioritize)

	if not request_result.success then

		Log(1, `Failed to process request, error: {request_result.errmsg}`)

	end
	
	return request_result.success, request_result.errmsg

end

function DataStoreEngine:IncrementAsync(data_store_key, increment_value, user_ids, datastore_increment_options, prioritize)
	assert(type(data_store_key) == "string", `Invalid argument #1, string expected, got {typeof(data_store_key)}`)
	assert(type(increment_value) == "number", `Invalid argument #2, number expected, got {typeof(increment_value)}`)

	local request_result = process_request("IncrementAsync", self._ds, Enum.DataStoreRequestType.SetIncrementAsync, data_store_key, {set_value = increment_value, uids = user_ids}, prioritize, datastore_increment_options)

	if not request_result.success then

		Log(1, `Failed to process request, error: {request_result.errmsg}`)

	end
	
	return request_result.success, request_result.errmsg

end

function DataStoreEngine:ListKeysAsync(prefix, page_size, cursor, exclude_deleted, prioritize)
	
	local request_result = process_request("ListKeysAsync", self._ds, Enum.DataStoreRequestType.ListAsync, nil, {prefix = prefix, page_size = page_size, cursor = cursor, exclude_deleted = exclude_deleted}, prioritize)

	if not request_result.success then

		Log(1, `Failed to process request, error: {request_result.errmsg}`)
		
		return false, request_result.errmsg
		
	end

	return request_result.success, request_result.value
end

function DataStoreEngine:ListVersionsAsync(key, sort_direction, min_date, max_date, page_size, prioritize)
	assert(type(key) == "string", `Invalid argument #1, string expected, got {typeof(key)}`)


	local request_result = process_request("ListVersionsAsync", self._ds, Enum.DataStoreRequestType.ListAsync, nil, {key = key, sort_direction = sort_direction, min_date = min_date, max_date = max_date, page_size = page_size}, prioritize)

	if not request_result.success then

		Log(1, `Failed to process request, error: {request_result.errmsg}`)
		return false, request_result.errmsg
	end

	return request_result.success, request_result.value
end

function DataStoreEngine:GetVersionAsync(key, version, prioritize)
	assert(type(key) == "string", `Invalid argument #1, string expected, got {typeof(key)}`)


	local request_result = process_request("GetVersionAsync", self._ds, Enum.DataStoreRequestType.GetVersionAsync, nil, {key = key, version = version}, prioritize)

	if not request_result.success then

		Log(1, `Failed to process request, error: {request_result.errmsg}`)
		return false, request_result.errmsg
	end

	return request_result.success, request_result.value
end

function DataStoreEngine:RemoveVersionAsync(key, version, prioritize)
	assert(type(key) == "string", `Invalid argument #1, string expected, got {typeof(key)}`)


	local request_result = process_request("RemoveVersionAsync", self._ds, Enum.DataStoreRequestType.RemoveVersionAsync, nil, {key = key, version = version}, prioritize)

	if not request_result.success then

		Log(1, `Failed to process request, error: {request_result.errmsg}`)
		return false, request_result.errmsg
	end

	return request_result.success, request_result.value
end

function DataStoreEngine:GetVersionAtTimeAsync(key, timestamp, prioritize)
	assert(type(key) == "string", `Invalid argument #1, string expected, got {typeof(key)}`)
	assert(type(timestamp) == "number", `Invalid argument #2, number expected, got {typeof(timestamp)}`)



	local request_result = process_request("GetVersionAtTimeAsync", self._ds, Enum.DataStoreRequestType.GetVersionAsync, nil, {key = key, timestamp = timestamp}, prioritize)

	if not request_result.success then

		Log(1, `Failed to process request, error: {request_result.errmsg}`)
		return false, request_result.errmsg
	end

	return request_result.success, request_result.value
end

function DataStoreEngine:GetSortedAsync(ascending: boolean, page_size: number, min_value: number?, max_value: number?, prioritize)
	assert(type(ascending) == "boolean", `Invalid argument #1, boolean expected, got {typeof(ascending)}`)
	assert(type(page_size) == "number", `Invalid argument #2, number expected, got {typeof(page_size)}`)
	if min_value ~= nil then
		assert(type(min_value) == "number", `Invalid argument #3, number or nil expected, got {typeof(min_value)}`)
	end
	if max_value ~= nil then
		assert(type(max_value) == "number", `Invalid argument #4, number or nil expected, got {typeof(max_value)}`)
	end
	
	if not self._ds:IsA("OrderedDataStore") then
		error(`The datastore must be Ordered`)
	end

	local request_result = process_request(
		"GetSortedAsync",
		self._ds,
		Enum.DataStoreRequestType.GetSortedAsync,
		nil,
		{
			ascending = ascending,
			pageSize = page_size,
			minValue = min_value,
			maxValue = max_value
		},
		prioritize
	)

	if not request_result.success then

		Log(1, `Failed to process request, error: {request_result.errmsg}`)
		return false, request_result.errmsg
	end

	return request_result.success, request_result.value
end

export type JSONAcceptable = { JSONAcceptable } | { [string]: JSONAcceptable } | number | string | boolean | buffer

export type EngineDataStore = {
	GetAsync: (self: EngineDataStore, key: string, options: DataStoreGetOptions?, prioritize: boolean?) -> (boolean, JSONAcceptable?),
	SetAsync: (self: EngineDataStore, key: string, value: JSONAcceptable?, userIds: {number?}?, options: DataStoreSetOptions?, prioritize: boolean?) -> (boolean, string?),
	UpdateAsync: (self: EngineDataStore, key: string, transform: (oldValue: JSONAcceptable?) -> any, userIds: { number? }?, prioritize: boolean?) -> (boolean, string?),
	IncrementAsync: (self: EngineDataStore, key: string, incrementAmount: number, userIds: {number?}?, options: DataStoreOptions?, prioritize: boolean?) -> (boolean, string?),
	RemoveAsync: (self: EngineDataStore, key: string, prioritize: boolean?) -> (boolean, JSONAcceptable?),
	
	ListVersionsAsync: (
		self: EngineDataStore,
		key: string,
		sortDirection: Enum.SortDirection?,
		minDate: number?,
		maxDate: number?,
		pageSize: number?,
		prioritize: boolean?
	) -> (boolean, DataStoreVersionPages?),

	GetVersionAsync: (
		self: EngineDataStore,
		key: string,
		version: string,
		prioritize: boolean?
	) -> (boolean, JSONAcceptable?),

	GetVersionAtTimeAsync: (
		self: EngineDataStore,
		key: string,
		timestamp: number,
		prioritize: boolean?
	) -> (boolean, JSONAcceptable?),

	RemoveVersionAsync: (
		self: EngineDataStore,
		key: string,
		version: string,
		prioritize: boolean?
	) -> (boolean, string?),

	ListKeysAsync: (
		self: EngineDataStore,
		prefix: string?,
		pageSize: number?,
		cursor: string?,
		excludeDeleted: boolean?,
		prioritize: boolean?
	) -> (boolean, DataStoreKeyPages?)
}

export type EngineOrderedDataStore = {
	GetSortedAsync: (
		self: EngineOrderedDataStore,
		ascending: boolean,
		pageSize: number,
		minValue: number?,
		maxValue: number?
	) -> (boolean, DataStorePages),

	GetAsync: (self: EngineOrderedDataStore, key: string, options: DataStoreGetOptions?, prioritie: boolean?) -> (boolean, JSONAcceptable?),
	SetAsync: (self: EngineOrderedDataStore, key: string, value: any, userIds: {number?}?, options: DataStoreSetOptions?, prioritize: boolean?) -> (boolean, string?),
	UpdateAsync: (self: EngineOrderedDataStore, key: string, transform: (oldValue: JSONAcceptable?) -> JSONAcceptable?, user_ids: { number? }?, prioritize: boolean?) -> (boolean, string?),
	IncrementAsync: (self: EngineOrderedDataStore, key: string, delta: number, userIds: {number?}?, options: DataStoreOptions?, prioritize: boolean?) -> (boolean, string?),
	RemoveAsync: (self: EngineOrderedDataStore, key: string, prioritize: boolean?) -> (boolean, JSONAcceptable?),
}
export type DataStoreEngine = {
	GetDataStore: (
		self: DataStoreEngine,
		DataStoreName: string,
		Scope: string?,
		DataStoreOptions: DataStoreOptions?
	) -> EngineDataStore,

	GetOrderedDataStore: (
		self: DataStoreEngine,
		DataStoreName: string,
		Scope: string?
	) -> EngineOrderedDataStore,

	ListDataStoresAsync: (
		self: DataStoreEngine,
		prefix: string?,
		pageSize: number?,
		cursor: string?
	) -> DataStoreListingPages,
	
	GetGlobalDataStore: (self: DataStoreEngine) -> EngineDataStore,
	
	GetRequestBudgetByRequestType: (self: DataStoreEngine, RequestType: Enum.DataStoreRequestType) -> number
}


--handle server shutdown
game:BindToClose(function()
	
	task.wait(3)--small delay for the other scripts to quickly send save data requests
	
	repeat
		task.wait()
	until data_store_processor.IsRunning == false--wait until processor finishes it's work
end)


return DataStoreEngine :: DataStoreEngine
