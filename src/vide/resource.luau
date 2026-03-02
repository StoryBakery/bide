local cleanup = require("./cleanup")
local effect = require("./effect")
local signal = require("./signal")

local taskLibrary = task

export type ResourceState = "unresolved" | "pending" | "ready" | "refreshing" | "errored"

export type ResourceControl<T, E> = {
	error: () -> E?,
	latest: () -> T?,
	loading: () -> boolean,
	mutate: (T? | ((T?) -> T?)) -> T?,
	refetch: (...unknown) -> (),
	state: () -> ResourceState,
}

type FetchContext<T> = {
	value: T?,
	refetching: boolean | unknown,
}

type ResourceOptions<T> = {
	defer: boolean?,
	initialValue: T?,
}

local function spawnThread(callback: () -> ())
	if taskLibrary and taskLibrary.spawn then
		return taskLibrary.spawn(callback)
	end

	local thread = coroutine.create(callback)
	local ok, err = coroutine.resume(thread)
	if not ok then
		error(tostring(err), 0)
	end
	return thread
end

local function cancelThread(threadToCancel: thread)
	if taskLibrary and taskLibrary.cancel then
		taskLibrary.cancel(threadToCancel)
	end
end

local function resource<TSignal, TValue, TError>(
	signalOrFetcher: any,
	fetcherOrOptions: any?,
	optionsOrNil: any?
): (() -> TValue?, ResourceControl<TValue, TError>)
	local signalInput: () -> TSignal?
	local fetcher: (TSignal, FetchContext<TValue>) -> TValue
	local options: ResourceOptions<TValue>?

	if type(fetcherOrOptions) == "function" then
		local signalValue = signalOrFetcher
		if type(signalValue) == "function" then
			signalInput = signalValue
		else
			signalInput = function()
				return signalValue
			end
		end

		fetcher = fetcherOrOptions
		options = optionsOrNil
	else
		signalInput = function()
			return true :: any
		end

		if type(signalOrFetcher) ~= "function" then
			error('invalid resource() call: expected fetcher function', 0)
		end

		fetcher = signalOrFetcher
		options = fetcherOrOptions
	end

	local isDeferred = if options then options.defer == true else false
	local initialValue = if options then options.initialValue else nil

	local data, setData = signal(initialValue :: TValue?)
	local latest, setLatest = signal(initialValue :: TValue?)
	local loading, setLoading = signal(false)
	local resourceError, setError = signal(nil :: TError?)
	local state, setState = signal(
		if initialValue == nil then "unresolved" else "ready"
	)

	local latestValue = initialValue :: TValue?
	local hasLatestValue = initialValue ~= nil
	local isLoading = false
	local latestRequestId = 0
	local activeRequestThread: thread? = nil
	local isDestroyed = false

	local function cancelActiveRequest()
		if activeRequestThread then
			cancelThread(activeRequestThread)
			activeRequestThread = nil
		end
	end

	local function startRequest(signalValue: TSignal, refetching: unknown?)
		cancelActiveRequest()

		latestRequestId += 1
		local requestId = latestRequestId

		local hasDataBeforeRequest = hasLatestValue

		isLoading = true
		setLoading(true)
		setError(nil)
		setState(if hasDataBeforeRequest then "refreshing" else "pending")

		activeRequestThread = spawnThread(function()
			local ok, result = pcall(fetcher, signalValue, {
				value = latestValue,
				refetching = if refetching == nil then false else refetching,
			})

			if isDestroyed or requestId ~= latestRequestId then
				return
			end

			activeRequestThread = nil

			if ok then
				local nextValue = result :: TValue
				latestValue = nextValue
				hasLatestValue = true

				setData(nextValue)
				setLatest(nextValue)
				setError(nil)
				isLoading = false
				setLoading(false)
				setState("ready")
			else
				setError(result :: TError)
				isLoading = false
				setLoading(false)
				setState("errored")
			end
		end)
	end

	local function refetch(...: unknown)
		local signalValue = signalInput()
		if signalValue == nil then
			return
		end

		local refetching = if select("#", ...) == 0 then true else ...
		startRequest(signalValue, refetching)
	end

	local function mutate(nextValueOrUpdater: TValue? | ((TValue?) -> TValue?)): TValue?
		local nextValue = if type(nextValueOrUpdater) == "function"
			then ((nextValueOrUpdater :: any) :: (TValue?) -> TValue?)(latestValue)
			else nextValueOrUpdater

		latestValue = nextValue
		hasLatestValue = true

		setData(nextValue)
		setLatest(nextValue)
		setError(nil)

		if not isLoading then
			setState("ready")
		end

		return nextValue
	end

	if not isDeferred then
		effect(function(previousSignalValue: TSignal?)
			local signalValue = signalInput()
			if signalValue == nil then
				cancelActiveRequest()
				isLoading = false
				setLoading(false)
				setError(nil)
				setState(if hasLatestValue then "ready" else "unresolved")
				return nil
			end

			if previousSignalValue == signalValue then
				return signalValue
			end

			startRequest(signalValue, nil)
			return signalValue
		end, nil :: TSignal?)
	end

	cleanup(function()
		isDestroyed = true
		latestRequestId += 1
		cancelActiveRequest()
	end)

	return data, {
		error = resourceError,
		latest = latest,
		loading = loading,
		state = state,
		mutate = mutate,
		refetch = refetch,
	}
end

return resource
