-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = getLocalizedText

class('howtoplay').extends(gfx.sprite) -- Create the scene's class
function howtoplay:init(...)
	howtoplay.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		pauseimage()
		menu:removeAllMenuItems()
		if not scenemanager.transitioning then
			menu:addMenuItem(text('goback'), function()
				scenemanager:transitionscene(title, false, 'howtoplay')
			end)
		end
	end

	assets = {
		stars_small = gfx.image.new('images/stars_small'),
		stars_large = gfx.image.new('images/stars_large'),
		full_circle = gfx.font.new('fonts/full-circle'),
		half_circle = gfx.font.new('fonts/full-circle-halved'),
		sfx_back = smp.new('audio/sfx/back'),
		manual = gfx.imagetable.new('images/manual'),
		sfx_move = smp.new('audio/sfx/swap'),
		sfx_bonk = smp.new('audio/sfx/bonk'),
	}

	vars = {
		page = 1,
	}
	vars.howtoplayHandlers = {
		leftButtonDown = function()
			if vars.page > 1 then
				vars.page -= 1
				playsound(assets.sfx_move)
			else
				playsound(assets.sfx_bonk)
				shakies()
			end
		end,

		rightButtonDown = function()
			if vars.page < 7 then
				vars.page += 1
				playsound(assets.sfx_move)
			else
				playsound(assets.sfx_bonk)
				shakies()
			end
		end,

		BButtonDown = function()
			playsound(assets.sfx_back)
			scenemanager:transitionscene(title, false, 'howtoplay')
		end
	}
	pd.timer.performAfterDelay(scenemanager.transitiontime, function()
		pd.inputHandlers.push(vars.howtoplayHandlers)
	end)

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		local counter = save.playtime
		assets.stars_small:draw(-(counter % 133) * 3, -(counter % 97) * 2.45)
		assets.stars_large:draw(-(counter % 83) * 4.8, -(counter % 42) * 5.7)
		gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRect(0, 0, 400, 240)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		assets.full_circle:drawText(text('manual' .. vars.page), 10, 10)
		assets.half_circle:drawText(text('page') .. ' ' .. text('back'), 10, 220)
		assets.half_circle:drawTextAligned(vars.page .. '/7', 390, 220, kTextAlignment.right)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		assets.manual[vars.page]:draw(225, 40)
	end)

	self:add()
end