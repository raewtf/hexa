-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = getLocalizedText

class('statistics').extends(gfx.sprite) -- Create the scene's class
function statistics:init(...)
	statistics.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		pauseimage()
		menu:removeAllMenuItems()
		if not scenemanager.transitioning then
			menu:addMenuItem(text('goback'), function()
				scenemanager:transitionscene(title, false, 'statistics')
			end)
		end
	end

	assets = {
		stars_small = gfx.image.new('images/stars_small'),
		stars_large = gfx.image.new('images/stars_large'),
		full_circle = gfx.font.new('fonts/full-circle'),
		half_circle = gfx.font.new('fonts/full-circle-halved'),
		sfx_back = smp.new('audio/sfx/back'),
		fg = gfx.image.new('images/fg'),
	}

	vars = {
	}
	vars.statisticsHandlers = {
		BButtonDown = function()
			playsound(assets.sfx_back)
			scenemanager:transitionscene(title, false, 'statistics')
		end
	}
	pd.timer.performAfterDelay(scenemanager.transitiontime, function()
		pd.inputHandlers.push(vars.statisticsHandlers)
	end)

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		local counter = save.playtime
		assets.stars_small:draw(-(counter % 133) * 3, -(counter % 97) * 2.45)
		assets.stars_large:draw(-(counter % 83) * 4.8, -(counter % 42) * 5.7)
		gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRect(0, 0, 400, 240)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		assets.half_circle:drawTextAligned(text('totalswaps'), 240, 5, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('totalhexas'), 240, 20, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('swapshexas'), 240, 35, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('highscore'), 240, 50, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('highscorehardmode'), 240, 65, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('playtime'), 240, 80, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('gametime'), 240, 95, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('totalscore'), 240, 110, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('hexablack'), 240, 125, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('hexagray'), 240, 140, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('hexawhite'), 240, 155, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('hexadouble'), 240, 170, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('kerplosion'), 240, 185, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('hexawild'), 240, 200, kTextAlignment.right)

		assets.full_circle:drawText(commalize(save.swaps), 250, 5)
		assets.full_circle:drawText(commalize(save.hexas), 250, 20)
		if save.swaps > 0 and save.hexas > 0 then
			assets.full_circle:drawText(string.format("%.2f", save.swaps / save.hexas) .. ':1', 250, 35)
		else
			assets.full_circle:drawText(text('na'), 250, 35)
		end
		assets.full_circle:drawText(commalize(save.score), 250, 50)
		assets.full_circle:drawText(commalize(save.hard_score), 250, 65)
		local playhours, playmins, playsecs = timecalchour(save.playtime)
		assets.full_circle:drawText(playhours .. 'h ' .. playmins .. 'm ' .. playsecs .. 's', 250, 80)
		local gamehours, gamemins, gamesecs = timecalchour(save.gametime)
		assets.full_circle:drawText(gamehours .. 'h ' .. gamemins .. 'm ' .. gamesecs .. 's', 250, 95)
		assets.full_circle:drawText(commalize(save.total_score), 250, 110)
		assets.full_circle:drawText(commalize(save.black_match), 250, 125)
		assets.full_circle:drawText(commalize(save.gray_match), 250, 140)
		assets.full_circle:drawText(commalize(save.white_match), 250, 155)
		assets.full_circle:drawText(commalize(save.double_match), 250, 170)
		assets.full_circle:drawText(commalize(save.bomb_match), 250, 185)
		assets.full_circle:drawText(commalize(save.wild_match), 250, 200)
		assets.half_circle:drawText(text('back'), 70, 220)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		assets.fg:draw(0, 0)
	end)

	self:add()
end