-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = getLocalizedText
local floor <const> = math.floor

class('jukebox').extends(gfx.sprite) -- Create the scene's class
function jukebox:init(...)
	jukebox.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		pauseimage()
		menu:removeAllMenuItems()
		if not scenemanager.transitioning then
			menu:addCheckmarkMenuItem(text('autolock'), vars.autolock, function(value)
				vars.autolock = value
				pd.setAutoLockDisabled(not vars.autolock)
			end)
			menu:addCheckmarkMenuItem(text('showtext'), vars.showtext, function(value)
				vars.showtext = value
				if vars.showtext then
					vars.anim_text_y:resetnew(300, vars.anim_text_y.value, 0, pd.easingFunctions.outBack)
				else
					vars.anim_text_y:resetnew(300, vars.anim_text_y.value, 50, pd.easingFunctions.inBack)
				end
			end)
			menu:addMenuItem(text('goback'), function()
				vars.anim_ship_x:resetnew(700, vars.anim_ship_x.value, 500, pd.easingFunctions.inBack)
				pd.timer.performAfterDelay(400, function()
					scenemanager:transitionscene(title, false, 'arcade')
				end)
				if music ~= nil then
					music:setFinishCallback(function()
						music = nil
					end)
				end
				fademusic()
				pd.setAutoLockDisabled(false)
			end)
		end
	end

	assets = {
		stars_small = gfx.image.new('images/stars_small'),
		stars_large = gfx.image.new('images/stars_large'),
		full_circle = gfx.font.new('fonts/full-circle'),
		half_circle = gfx.font.new('fonts/full-circle-halved'),
		sfx_back = smp.new('audio/sfx/back'),
		ship = gfx.imagetable.new('images/ship'),
	}

	vars = {
		anim_ship_x = pd.timer.new(1700, -100, 200, pd.easingFunctions.outCubic),
		anim_ship = pd.timer.new(400, 1, 4.99),
		tunes = {'arcade1', 'arcade2', 'arcade3', 'title', 'zen1', 'zen2'},
		num = 6,
		showtext = true,
		autolock = false,
		anim_text_y = pd.timer.new(1, 0, 0)
	}
	vars.jukeboxHandlers = {
		BButtonDown = function()
			playsound(assets.sfx_back)
			vars.anim_ship_x:resetnew(700, vars.anim_ship_x.value, 500, pd.easingFunctions.inBack)
			pd.timer.performAfterDelay(400, function()
				scenemanager:transitionscene(title, false, 'arcade')
			end)
			if music ~= nil then
				music:setFinishCallback(function()
					music = nil
				end)
			end
			fademusic()
			pd.setAutoLockDisabled(false)
		end
	}
	pd.timer.performAfterDelay(scenemanager.transitiontime, function()
		pd.inputHandlers.push(vars.jukeboxHandlers)
	end)

	vars.anim_ship.repeats = true
	vars.anim_ship_x.discardOnCompletion = false
	vars.anim_text_y.discardOnCompletion = false

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		local counter = save.playtime
		assets.stars_small:draw(-(counter % 133) * 3, 0)
		assets.stars_large:draw(-(counter % 83) * 4.8, 0)
		gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRect(0, 0, 400, 240)
		assets.ship[floor(vars.anim_ship.value)]:drawAnchored(vars.anim_ship_x.value, 120, 0.5, 0.5)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		if (save.music > 0) and vars.rand ~= nil then
			assets.full_circle:drawText(text('music_' .. vars.tunes[vars.rand]), 10, 205 + vars.anim_text_y.value)
		end
		assets.half_circle:drawText(text('back'), 10, 220 + vars.anim_text_y.value)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end)

	pd.setAutoLockDisabled(true)
	self:add()
	if save.music then
		self:shuffle()
	end
end

function jukebox:shuffle()
	vars.rand = randInt(1, vars.num)
	newmusic('audio/music/' .. vars.tunes[vars.rand])
	if music ~= nil then
		music:setFinishCallback(function()
			music = nil
			self:shuffle()
		end)
	end
end