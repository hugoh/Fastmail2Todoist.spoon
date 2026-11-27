# FastmailTodoist Spoon

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Hammerspoon Spoon](https://img.shields.io/badge/Hammerspoon-Spoon-FFA500.svg)](https://github.com/hugoh/FastmailTodoist.spoon)

A Hammerspoon Spoon that turns the message open in the [Fastmail](https://www.fastmail.com) Mac app into a [Todoist](https://www.todoist.com) task.

**Repository**: [https://github.com/hugoh/FastmailTodoist.spoon](https://github.com/hugoh/FastmailTodoist.spoon)

## How it works

The Spoon reads the open message's subject and web address through macOS accessibility, then opens Todoist's quick add with the subject as the task and an "Open in Fastmail" link as the description. You pick the project and date, then confirm. No API token is needed.

## Requirements

* [Hammerspoon](https://www.hammerspoon.org) with the Accessibility permission
* The Fastmail and Todoist Mac apps

## Installation

Download `FastmailTodoist.spoon.zip` from the [latest release](https://github.com/hugoh/FastmailTodoist.spoon/releases/latest), unzip it, move `FastmailTodoist.spoon` to `~/.hammerspoon/Spoons/`, and reload Hammerspoon.

## Usage

```lua
hs.loadSpoon("FastmailTodoist"):bindHotkeys({ capture = { { "ctrl", "alt", "cmd" }, "i" } })
```
