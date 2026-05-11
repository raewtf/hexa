-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = getLocalizedText

class('credits').extends(gfx.sprite) -- Create the scene's class
function credits:init(...)
	credits.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		pauseimage()
		menu:removeAllMenuItems()
		if not scenemanager.transitioning then
			menu:addMenuItem(text('goback'), function()
				scenemanager:transitionscene(title, false, 'credits')
			end)
		end
	end

	assets = {
		stars_small = gfx.image.new('images/stars_small'),
		stars_large = gfx.image.new('images/stars_large'),
		full_circle = gfx.font.new('fonts/full-circle'),
		half_circle = gfx.font.new('fonts/full-circle-halved'),
		sfx_back = smp.new('audio/sfx/back'),
		fg = gfx.image.new('images/fg_credits'),
		sfx_move = smp.new('audio/sfx/swap'),
		sfx_bonk = smp.new('audio/sfx/bonk'),
	}

	vars = {
		page = 1,
	}
	vars.creditsHandlers = {
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
			if vars.page < 3 then
				vars.page += 1
				playsound(assets.sfx_move)
			else
				playsound(assets.sfx_bonk)
				shakies()
			end
		end,

		BButtonDown = function()
			playsound(assets.sfx_back)
			scenemanager:transitionscene(title, false, 'credits')
		end
	}
	pd.timer.performAfterDelay(scenemanager.transitiontime, function()
		pd.inputHandlers.push(vars.creditsHandlers)
	end)

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		local counter = save.playtime
		assets.stars_small:draw(-(counter % 133) * 3, -(counter % 97) * 2.45)
		assets.stars_large:draw(-(counter % 83) * 4.8, -(counter % 42) * 5.7)
		gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRect(0, 0, 400, 240)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		assets.full_circle:drawTextAligned(text('credits' .. vars.page), 200, 5, kTextAlignment.center)
		assets.half_circle:drawText(text('page'), 65, 205)
		assets.half_circle:drawText(text('back'), 70, 220)
		assets.half_circle:drawTextAligned(vars.page .. '/3', 330, 220, kTextAlignment.right)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		assets.fg:draw(0, 0)
	end)

	self:add()
end