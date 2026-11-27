-- vim: set ft=lua:

--- === FastmailTodoist ===
---
--- A Hammerspoon Spoon that turns the message open in the Fastmail app into a
--- Todoist task: it opens Todoist's quick add with the subject as the task and a
--- link back to the message as its description.
---
--- Download: https://github.com/hugoh/FastmailTodoist.spoon/releases/latest

local obj = {}
obj.__index = obj

obj.name = "FastmailTodoist"
obj.version = "dev"
obj.author = "Hugo Haas"
obj.license = "MIT"
obj.homepage = "https://github.com/hugoh/FastmailTodoist.spoon"

obj.log = hs.logger.new("FastmailTodoist", "info")

local BUNDLE_ID = "com.fastmail.mac.Fastmail"
-- Electron builds its accessibility tree asynchronously once asked to.
local TREE_DELAY = 1
local MAX_DEPTH = 25

--- FastmailTodoist:init()
--- Method
--- Called automatically by `hs.loadSpoon()`. Logs the loaded version.
function obj:init()
	self.log.f("Loaded %s v%s", self.name, self.version)
	return self
end

local function findWebArea(element, depth)
	if element.AXRole == "AXWebArea" then return element end
	if depth >= MAX_DEPTH then return nil end
	for _, child in ipairs(element.AXChildren or {}) do
		local found = findWebArea(child, depth + 1)
		if found then return found end
	end
end

-- A message URL ends in <thread id>.<message id>; a list or search view doesn't.
local function isMessageURL(url)
	local path = url:match("^https://app%.fastmail%.com(/mail/[^?#]*)")
	return path ~= nil and path:match("/[%w_-]+%.[%w_-]+$") ~= nil
end

-- hs.http.encodeForQuery leaves "&" and "=" alone, which would cut a subject short.
local function encode(text)
	return (text:gsub("[^%w_.~-]", function(char) return string.format("%%%02X", char:byte()) end))
end

local function openQuickAdd(subject, url)
	local description = "[Open in Fastmail](" .. url .. ")"
	hs.urlevent.openURL("todoist://openquickadd?content=" .. encode(subject) .. "&description=" .. encode(description))
end

function obj:_capture(app, mayRetry)
	local window = app:focusedWindow() or app:mainWindow()
	local webArea = window and findWebArea(hs.axuielement.windowElement(window), 0)
	if not webArea and mayRetry then
		hs.axuielement.applicationElement(app):setAttributeValue("AXManualAccessibility", true)
		self._retry = hs.timer.doAfter(TREE_DELAY, function() self:_capture(app, false) end)
		return
	end
	local url = webArea and webArea.AXURL and webArea.AXURL.url
	if not (url and isMessageURL(url)) then
		hs.alert.show("No Fastmail message open")
		return
	end
	openQuickAdd(webArea.AXTitle, url)
end

--- FastmailTodoist:capture() -> FastmailTodoist
--- Method
--- Opens Todoist's quick add, pre-filled from the message open in Fastmail.
---
--- Returns:
---  * The FastmailTodoist object, for method chaining
---
--- Notes:
---  * Nothing is saved until you confirm the task in Todoist.
---  * Hammerspoon needs the Accessibility permission.
function obj:capture()
	local app = hs.application.get(BUNDLE_ID)
	if app then
		self:_capture(app, true)
	else
		hs.alert.show("Fastmail is not running")
	end
	return self
end

--- FastmailTodoist:bindHotkeys(mapping) -> FastmailTodoist
--- Method
--- Binds hotkeys for FastmailTodoist.
---
--- Parameters:
---  * mapping - a table with a `capture` key mapped to a `{ {modifiers}, key }` spec
---
--- Returns:
---  * The FastmailTodoist object, for method chaining
function obj:bindHotkeys(mapping)
	local spec = mapping.capture
	if spec then
		if self._hotkey then self._hotkey:delete() end
		self._hotkey = hs.hotkey.bind(spec[1], spec[2], function() self:capture() end)
	end
	return self
end

--- FastmailTodoist:stop() -> FastmailTodoist
--- Method
--- Unbinds the hotkey and cancels any pending capture.
---
--- Returns:
---  * The FastmailTodoist object, for method chaining
function obj:stop()
	if self._hotkey then
		self._hotkey:delete()
		self._hotkey = nil
	end
	if self._retry then self._retry:stop() end
	return self
end

return obj
