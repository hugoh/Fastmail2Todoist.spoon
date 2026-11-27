local hs_mock = require("hs_mock")

local BUNDLE_ID = "com.fastmail.mac.Fastmail"
local MESSAGE_URL = "https://app.fastmail.com/mail/Inbox/AZkD-uu_I7gB.StlHYPecoMJJ?u=abc123"

local hs, ctl, Spoon, webArea, attributes

local function area(url, title) return { AXRole = "AXWebArea", AXURL = { url = url }, AXTitle = title } end

local function runFastmail()
	local window = {}
	ctl.apps[BUNDLE_ID] = {
		focusedWindow = function() return window end,
		mainWindow = function() return window end,
	}
end

before_each(function()
	hs, ctl = hs_mock.new()
	_G.hs = hs
	attributes = {}
	webArea = area(MESSAGE_URL, "Hello")
	hs.axuielement = {
		applicationElement = function()
			return { setAttributeValue = function(_, name, value) attributes[name] = value end }
		end,
		windowElement = function()
			return { AXRole = "AXWindow", AXChildren = { { AXRole = "AXGroup", AXChildren = { webArea } } } }
		end,
	}
	Spoon = dofile("init.lua")
	runFastmail()
end)

after_each(function() Spoon:stop() end)

local function alerts()
	local texts = {}
	for _, a in ipairs(ctl.alerts) do
		table.insert(texts, a.text)
	end
	return texts
end

describe("capture", function()
	it("opens Todoist quick add with the subject and a link to the message", function()
		Spoon:capture()
		assert.are.same({
			"todoist://openquickadd?content=Hello&description="
				.. "%5BOpen%20in%20Fastmail%5D%28https%3A%2F%2Fapp.fastmail.com%2Fmail%2FInbox%2F"
				.. "AZkD-uu_I7gB.StlHYPecoMJJ%3Fu%3Dabc123%29",
		}, ctl.openedURLs)
	end)

	it("encodes characters that would break the query string", function()
		webArea = area(MESSAGE_URL, "Q&A = 100% #1+é")
		Spoon:capture()
		assert.is_truthy(ctl.openedURLs[1]:find("content=Q%26A%20%3D%20100%25%20%231%2B%C3%A9&description=", 1, true))
	end)

	it("accepts a message opened from a search", function()
		webArea = area("https://app.fastmail.com/mail/search:foo.com/Tabc.Mdef?u=1", "Hello")
		Spoon:capture()
		assert.are.equal(1, #ctl.openedURLs)
	end)

	for _, url in ipairs({
		"https://app.fastmail.com/mail/Inbox/?u=abc123",
		"https://app.fastmail.com/mail/search:foo.com?u=abc123",
		"https://app.fastmail.com/calendar/month",
		"https://example.com/mail/Inbox/Tabc.Mdef",
	}) do
		it("alerts when no message is open: " .. url, function()
			webArea = area(url, "Inbox")
			Spoon:capture()
			assert.are.same({}, ctl.openedURLs)
			assert.are.same({ "No Fastmail message open" }, alerts())
		end)
	end

	it("alerts when Fastmail is not running", function()
		ctl.apps[BUNDLE_ID] = nil
		Spoon:capture()
		assert.are.same({}, ctl.openedURLs)
		assert.are.same({ "Fastmail is not running" }, alerts())
	end)

	it("turns on Electron accessibility and retries when the page is not exposed yet", function()
		webArea = { AXRole = "AXGroup" }
		Spoon:capture()
		assert.is_true(attributes.AXManualAccessibility)
		assert.are.same({}, alerts())
		webArea = area(MESSAGE_URL, "Hello")
		ctl.advance(1)
		assert.are.equal(1, #ctl.openedURLs)
	end)

	it("gives up with an alert when the page never appears", function()
		webArea = { AXRole = "AXGroup" }
		Spoon:capture()
		ctl.advance(10)
		assert.are.same({}, ctl.openedURLs)
		assert.are.same({ "No Fastmail message open" }, alerts())
	end)
end)

describe("hotkeys", function()
	it("binds capture", function()
		Spoon:bindHotkeys({ capture = { { "cmd" }, "t" } })
		ctl.hotkeys[1].pressed()
		assert.are.equal(1, #ctl.openedURLs)
	end)

	it("stop() deletes the binding", function()
		Spoon:bindHotkeys({ capture = { { "cmd" }, "t" } }):stop()
		assert.is_true(ctl.hotkeys[1].deleted)
	end)
end)

describe("init", function()
	it("is named after its bundle", function() assert.are.equal("Fastmail2Todoist", Spoon.name) end)
end)
