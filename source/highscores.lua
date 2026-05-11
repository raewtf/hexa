-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = getLocalizedText

class('highscores').extends(gfx.sprite) -- Create the scene's class
function highscores:init(...)
	highscores.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		pauseimage()
		menu:removeAllMenuItems()
		if not scenemanager.transitioning then
			if not vars.loading then
				menu:addMenuItem(text('refresh'), function()
					self:refreshboards(vars.mode)
				end)
			end
			menu:addMenuItem(text('goback'), function()
				scenemanager:transitionscene(title, false, 'highscores')
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
		mode = args[1] or "arcade",
		result = {},
		best = {},
		loading = false,
		debug = false,
	}
	vars.highscoresHandlers = {
		AButtonDown = function()
			if vars.mode == "arcade" then
				self:refreshboards("dailyrun")
			elseif vars.mode == "dailyrun" then
				self:refreshboards("arcade")
			end
		end,

		BButtonDown = function()
			playsound(assets.sfx_back)
			scenemanager:transitionscene(title, false, 'highscores')
		end
	}
	pd.timer.performAfterDelay(scenemanager.transitiontime, function()
		pd.inputHandlers.push(vars.highscoresHandlers)
	end)

	self:refreshboards(vars.mode)

	if pd.getReduceFlashing() then
		vars.blink = {}
		vars.blink.value = 1
	else
		vars.blink = pd.timer.new(1000, 1.99, 0.5)
		vars.blink.repeats = true
	end

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		local counter = save.playtime
		assets.stars_small:draw(-(counter % 133) * 3, -(counter % 97) * 2.45)
		assets.stars_large:draw(-(counter % 83) * 4.8, -(counter % 42) * 5.7)
		gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRect(0, 0, 400, 240)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		if vars.mode == "arcade" then
			assets.full_circle:drawTextAligned(text('arcade'), 200, 10, kTextAlignment.center)
			assets.half_circle:drawTextAligned(text('highscores') .. (save.hardmode and text('hard') or ''), 200, 25, kTextAlignment.center)
		elseif vars.mode == "dailyrun" then
			assets.full_circle:drawTextAligned(text('dailyrun'), 200, 10, kTextAlignment.center)
			if pd.getGMTTime().hour < 23 then
				assets.half_circle:drawTextAligned(text('todaysscores') .. (save.hardmode and text('hard') or '') .. '   ⏰ ' .. (24 - pd.getGMTTime().hour) .. text('hrs'), 200, 25, kTextAlignment.center)
			elseif pd.getGMTTime().minute < 59 then
				assets.half_circle:drawTextAligned(text('todaysscores') .. (save.hardmode and text('hard') or '') .. '   ⏰ ' .. (60 - pd.getGMTTime().minute) .. text('mins'), 200, 25, kTextAlignment.center)
			else
				assets.half_circle:drawTextAligned(text('todaysscores') .. (save.hardmode and text('hard') or '') .. '   ⏰ ' .. (60 - pd.getGMTTime().second) .. text('secs'), 200, 25, kTextAlignment.center)
			end
		end
		if vars.result.scores ~= nil and next(vars.result.scores) ~= nil and not vars.loading then
			for _, v in ipairs(vars.result.scores) do
				if ((vars.best.player ~= nil and string.len(vars.best.player) == 16 and tonumber(vars.best.player)) and v.rank <= 8) or v.rank <= 9 then
					assets.half_circle:drawTextAligned(ordinal(v.rank), 80, 30 + (15 * v.rank), kTextAlignment.right)
					assets.full_circle:drawText(v.player, 90, 30 + (15 * v.rank))
					assets.half_circle:drawTextAligned(commalize(v.value), 340, 30 + (15 * v.rank), kTextAlignment.right)
				end
			end
		elseif vars.result == "fail" then
			assets.half_circle:drawTextAligned(text('failedscores'), 200, 110, kTextAlignment.center)
		else
			if vars.loading then
				assets.half_circle:drawTextAligned(text('gettingscores'), 200, 110, kTextAlignment.center)
			else
				assets.half_circle:drawTextAligned(text('emptyscores_' .. vars.mode), 200, 110, kTextAlignment.center)
			end
		end
		if vars.best.rank ~= nil then
			if string.len(vars.best.player) == 16 and tonumber(vars.best.player) then
				if math.floor(vars.blink.value) == 1 then
					assets.full_circle:drawTextAligned(text('username'), 200, 170, kTextAlignment.center)
				end
			else
				assets.full_circle:drawTextAligned(text('lbscore1') .. commalize(vars.best.value) .. text('lbscore2') .. ordinal(vars.best.rank) .. text('lbscore3'), 200, 185, kTextAlignment.center)
			end
		end
		if vars.loading then
			assets.half_circle:drawText(text('inasec'), 65, 205)
		else
			if vars.mode == "arcade" then
				assets.half_circle:drawText(text('dailyscores'), 65, 205)
			elseif vars.mode == "dailyrun" then
				assets.half_circle:drawText(text('arcadescores'), 65, 205)
			end
		end
		assets.half_circle:drawText(text('back'), 70, 220)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		assets.fg:draw(0, 0)
	end)

	self:add()
	newmusic('audio/music/title', true)
	pd.datastore.write(save)
end

function highscores:refreshboards(mode)
	if not vars.loading then
		vars.result = {}
		vars.best = {}
		vars.loading = true
		vars.mode = mode
		if vars.mode == "arcade" and save.score ~= 0 then
			pd.scoreboards.addScore((save.hardmode and 'hardarcade') or ('arcade'), 0, function(status, result)
				if vars.debug then
					print('--- ' .. (save.hardmode and 'hard' .. vars.mode) or (vars.mode) .. ' fake score check ---')
					printTable(status)
					printTable(result)
				end
			end)
		elseif vars.mode == "dailyrun" and save.lastdaily.score ~= 0 and save.lastdaily.sent == false and (save.lastdaily.year == pd.getGMTTime().year and save.lastdaily.month == pd.getGMTTime().month and save.lastdaily.day == pd.getGMTTime().day) then
			pd.scoreboards.addScore((save.hardmode and 'harddailyrun') or ('dailyrun'), 0, function(status, result)
				if vars.debug then
					print('--- ' .. (save.hardmode and 'hard' .. vars.mode) or (vars.mode) .. ' fake score check ---')
					printTable(status)
					printTable(result)
				end
			end)
		end
		if vars.debug then
			pd.scoreboards.getScoreboards(function(status, result)
				print('--- All scoreboards ---')
				printTable(status)
				printTable(result)
			end)
		end
		pd.scoreboards.getScores((save.hardmode and 'hard' .. vars.mode) or (vars.mode), function(status, result)
			if vars.debug then
				print('--- ' .. (save.hardmode and 'hard' .. vars.mode) or (vars.mode) .. ' scoreboard ---')
				printTable(status)
				printTable(result)
			end
			if status.code == "OK" and vars.mode ~= nil then
				vars.result = result
				pd.scoreboards.getPersonalBest((save.hardmode and 'hard' .. vars.mode) or (vars.mode), function(status, result)
					if vars.debug then
						print('--- ' .. (save.hardmode and 'hard' .. vars.mode) or (vars.mode) .. ' personal best ---')
						printTable(status)
						printTable(result)
					end
					if status.code == "OK" and vars.best ~= nil then
						vars.best = result
					end
					vars.loading = false
				end)
			else
				vars.result = "fail"
				vars.loading = false
			end
		end)
	end
end

function highscores:update()
	local gmt = pd.getGMTTime()
	if gmt.hour == 0 and gmt.minute == 0 and gmt.second == 0 and not vars.loading and vars.mode == "dailyrun" then
		self:refreshboards(vars.mode)
	end
end