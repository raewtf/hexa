-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local floor <const> = math.floor
local ceil <const> = math.ceil
local tris_x <const> = {140, 170, 200, 230, 260, 110, 140, 170, 200, 230, 260, 290, 110, 140, 170, 200, 230, 260, 290}
local tris_y <const> = {70, 70, 70, 70, 70, 120, 120, 120, 120, 120, 120, 120, 170, 170, 170, 170, 170, 170, 170}
local tris_flip <const> = {true, false, true, false, true, true, false, true, false, true, false, true, false, true, false, true, false, true, false}
local text <const> = getLocalizedText
local min <const> = math.min
local exp <const> = math.exp
local flash <const> = pd.getReduceFlashing()
local messagerand <const> = randInt(1, 10)

class('game').extends(gfx.sprite) -- Create the scene's class
function game:init(...)
	game.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		pauseimage(vars.mode, vars.mission or nil)
		menu:removeAllMenuItems()
		if not scenemanager.transitioning then
			if vars.can_do_stuff and (vars.mode == "logic" or vars.mode == "time" or vars.mode == "picture" or vars.mode == "speedrun") then
				menu:addMenuItem(text('exitmission'), function()
					if vars.timer ~= nil then
						vars.timer:pause()
					end
					vars.can_do_stuff = false
					if vars.mission ~= nil and vars.mission > 50 then
						scenemanager:transitionscene(missions, true)
					else
						scenemanager:transitionscene(missions)
					end
					fademusic()
				end)
			end
			if (vars.mode == "zen" or vars.mode == "arcade" or vars.mode == "dailyrun") then
				menu:addMenuItem(text((vars.mode == "zen" and 'imdone') or 'endgame'), function()
					if vars.can_do_stuff then
						self:endround()
					else
						vars.play_out_timer = false
						scenemanager:transitionscene(title, false, vars.mode)
					end
				end)
				if vars.mode == "arcade" and vars.can_do_stuff then
					menu:addMenuItem(text('restart'), function()
						self:restart()
					end)
				end
			end
			menu:addCheckmarkMenuItem(text('flip'), save.flip, function(value)
				save.flip = value
			end)
		end
	end

	assets = {
		cursor = gfx.imagetable.new('images/cursor'),
		full_circle = gfx.font.new('fonts/full-circle'),
		half_circle = gfx.font.new('fonts/full-circle-halved'),
		clock = gfx.font.new('fonts/clock'),
		hexa = gfx.imagetable.new('images/hexa_' .. tostring(flash)),
		sfx_move = smp.new('audio/sfx/move'),
		sfx_bonk = smp.new('audio/sfx/bonk'),
		sfx_swap = smp.new('audio/sfx/swap'),
		sfx_hexa = smp.new('audio/sfx/hexa'),
		sfx_vine = smp.new('audio/sfx/vine'),
		sfx_boom = smp.new('audio/sfx/boom'),
		sfx_select = smp.new('audio/sfx/select'),
		sfx_count = smp.new('audio/sfx/count'),
		sfx_start = smp.new('audio/sfx/start'),
		sfx_end = smp.new('audio/sfx/end'),
		sfx_hexaprep = smp.new('audio/sfx/hexaprep'),
		sfx_mission = smp.new('audio/sfx/mission'),
		powerup_double_up = gfx.imagetable.new('images/powerup_double_up'),
		powerup_double_down = gfx.imagetable.new('images/powerup_double_down'),
		powerup_bomb_up = gfx.imagetable.new('images/powerup_bomb_up'),
		powerup_bomb_down = gfx.imagetable.new('images/powerup_bomb_down'),
		powerup_wild_up = gfx.imagetable.new('images/powerup_wild_up'),
		powerup_wild_down = gfx.imagetable.new('images/powerup_wild_down'),
		label_3 = gfx.image.new('images/label_3'),
		label_2 = gfx.image.new('images/label_2'),
		label_1 = gfx.image.new('images/label_1'),
		label_go = gfx.image.new('images/label_go_' .. checklanguage()),
		label_double = gfx.image.new('images/label_double_' .. checklanguage()),
		label_bomb = gfx.image.new('images/label_bomb_' .. checklanguage()),
		label_wild = gfx.image.new('images/label_wild'),
		modal = gfx.image.new('images/modal'),
		bg_tile = gfx.image.new('images/bg_tile'),
		stars = gfx.image.new('images/stars_large'),
		half = gfx.image.new('images/half'),
		mission_complete = gfx.image.new('images/mission_complete_' .. checklanguage()),
	}

	vars = {
		mode = args[1], -- "arcade" or "zen" or "dailyrun", or "picture" or "time" or "logic" or "speedrun"
		mission = args[2], -- number. what mission is this?
		modifier = args[3], -- modifier for whatever, depending on the mission
		start = args[4], -- starting layout
		goal = args[5], -- finishing layout, for picture mode
		seed = args[6], -- number seed, for time attack
		name = args[7], -- name, for picture puzzles
		tris = {},
		slot = 1,
		score = 0,
		combo = 0,
		anim_hexa = pd.timer.new(1, 11, 11),
		anim_cursor_x = pd.timer.new(1, 106, 106),
		anim_cursor_y = pd.timer.new(1, 42, 42),
		anim_cursor = pd.timer.new(0, 1, 1),
		anim_label = pd.timer.new(0, 400, 400),
		anim_modal = pd.timer.new(0, 400, 400),
		anim_bg_stars_x = pd.timer.new(10000, 0, -399),
		anim_bg_stars_y = pd.timer.new(15000, 0, -239),
		anim_powerup = pd.timer.new(700, 1, 4.99),
		can_do_stuff = false,
		ended = false,
		moves = 0,
		hexas = 0,
		movesbonus = 5,
		active_hexa = false,
		boomed = false,
		lastdir = false,
		skippedfanfare = false,
		missioncomplete = false,
		time = 0,
		crank_deadzone = 0,
		crank_change = 0,
		crank_degrees = 0,
		play_out_timer = true,
		sequence = {'right', 'up', 'b', 'down', 'up', 'b', 'down', 'up', 'b'},
		sequenceindex = 1,
	}
	vars.gameHandlers = {
		leftButtonDown = function()
			-- for rubdubdub
			if vars ~= nil and vars.sequence ~= nil and vars.sequenceindex ~= nil then
				if vars.sequence[vars.sequenceindex] == 'left' then
					vars.sequenceindex = vars.sequenceindex + 1
				else
					vars.sequenceindex = 1
				end
			end

			if vars.can_do_stuff then
				vars.lastdir = false
				if vars.slot == 2 then
					vars.slot = 1
					vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 106, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 42, pd.easingFunctions.outBack)
					playsound(assets.sfx_move)
				elseif vars.slot == 5 then
					vars.slot = 4
					vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 137, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
					playsound(assets.sfx_move)
				elseif vars.slot == 4 then
					vars.slot = 3
					vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 78, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
					playsound(assets.sfx_move)
				else
					playsound(assets.sfx_bonk)
				end
			end
		end,

		rightButtonDown = function()
			-- for rubdubdub
			if vars ~= nil and vars.sequence ~= nil and vars.sequenceindex ~= nil then
				if vars.sequence[vars.sequenceindex] == 'right' then
					vars.sequenceindex = vars.sequenceindex + 1
				else
					vars.sequenceindex = 1
				end
			end

			if vars.can_do_stuff then
				vars.lastdir = true
				if vars.slot == 1 then
					vars.slot = 2
					vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 166, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 42, pd.easingFunctions.outBack)
					playsound(assets.sfx_move)
				elseif vars.slot == 3 then
					vars.slot = 4
					vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 137, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
					playsound(assets.sfx_move)
				elseif vars.slot == 4 then
					vars.slot = 5
					vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 197, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
					playsound(assets.sfx_move)
				else
					playsound(assets.sfx_bonk)
				end
			end
		end,

		upButtonDown = function()
			-- for rubdubdub
			if vars ~= nil and vars.sequence ~= nil and vars.sequenceindex ~= nil then
				if vars.sequence[vars.sequenceindex] == 'up' then
					vars.sequenceindex = vars.sequenceindex + 1
				else
					vars.sequenceindex = 1
				end
			end

			if vars.can_do_stuff then
				if vars.slot == 3 or vars.slot == 4 or vars.slot == 5 then
					if vars.lastdir then
						vars.slot = 2
						vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 166, pd.easingFunctions.outBack)
						vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 42, pd.easingFunctions.outBack)
						playsound(assets.sfx_move)
					else
						vars.slot = 1
						vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 106, pd.easingFunctions.outBack)
						vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 42, pd.easingFunctions.outBack)
						playsound(assets.sfx_move)
					end
				else
					playsound(assets.sfx_bonk)
				end
			end
		end,

		downButtonDown = function()
			-- for rubdubdub
			if vars ~= nil and vars.sequence ~= nil and vars.sequenceindex ~= nil then
				if vars.sequence[vars.sequenceindex] == 'down' then
					vars.sequenceindex = vars.sequenceindex + 1
				else
					vars.sequenceindex = 1
				end
			end

			if vars.can_do_stuff then
				if vars.slot == 1 then
					vars.slot = 3
					vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 78, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
					playsound(assets.sfx_move)
				elseif vars.slot == 2 then
					vars.slot = 5
					vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 197, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
					playsound(assets.sfx_move)
				else
					playsound(assets.sfx_bonk)
				end
			end
		end,

		AButtonDown = function()
			-- for rubdubdub
			if vars ~= nil and vars.sequence ~= nil and vars.sequenceindex ~= nil then
				if vars.sequence[vars.sequenceindex] == 'a' then
					vars.sequenceindex = vars.sequenceindex + 1
				else
					vars.sequenceindex = 1
				end
			end

			if vars.can_do_stuff then
				if save.flip then
					self:swap(vars.slot, false)
				else
					self:swap(vars.slot, true)
				end
			end
		end,

		BButtonDown = function()
			-- for rubdubdub
			if vars ~= nil and vars.sequence ~= nil and vars.sequenceindex ~= nil then
				if vars.sequence[vars.sequenceindex] == 'b' then
					vars.sequenceindex = vars.sequenceindex + 1
				else
					vars.sequenceindex = 1
				end
			end

			if vars.can_do_stuff then
				if save.flip then
					self:swap(vars.slot, true)
				else
					self:swap(vars.slot, false)
				end
			end
		end,
	}
	vars.losingHandlers = {
		AButtonDown = function()
			if vars.ended and not vars.skippedfanfare then
				self:ersi()
			end
		end,

		BButtonDown = function()
			if vars.ended and not vars.skippedfanfare then
				self:ersi()
			end
		end
	}
	vars.loseHandlers = {
		AButtonDown = function()
			if vars.mode == "dailyrun" then
				if catalog then
					fademusic()
					scenemanager:transitionscene(highscores, vars.mode)
				end
			else
				fademusic()
				scenemanager:transitionscene(game, vars.mode)
			end
		end,

		BButtonDown = function()
			fademusic()
			scenemanager:transitionscene(title, false, vars.mode)
		end
	}
	pd.timer.performAfterDelay(scenemanager.transitiontime, function()
		pd.inputHandlers.push(vars.gameHandlers)
	end)

	if vars.mode == "dailyrun" or vars.mode == "arcade" or vars.mode == "zen" then
		assets.bg = gfx.image.new('images/bg_' .. vars.mode)
	else
		assets.bg = gfx.image.new('images/bg_zen')
	end

	if vars.mode == "dailyrun" then
		setRandomSeed(pd.getGMTTime().year .. pd.getGMTTime().month .. pd.getGMTTime().day)
	elseif vars.mode == "time" then
		if vars.seed ~= nil and vars.seed ~= 0 then
			setRandomSeed(vars.seed)
		else
			setRandomSeed(123459 * vars.mission)
		end
	else
		setRandomSeed(playdate.getSecondsSinceEpoch())
	end

	if vars.mode ~= "dailyrun" then
		if flash then
			vars.anim_bg_tile_x = pd.timer.new(1, 0, 0)
			vars.anim_bg_tile_y = pd.timer.new(1, 0, 0)
		else
			vars.anim_bg_tile_x = pd.timer.new(30000, 0, -399)
			vars.anim_bg_tile_y = pd.timer.new(28000, 0, -239)
			vars.anim_bg_tile_x.repeats = true
			vars.anim_bg_tile_y.repeats = true
		end
	end

	vars.anim_cursor_x.discardOnCompletion = false
	vars.anim_cursor_y.discardOnCompletion = false
	vars.anim_label.discardOnCompletion = false
	vars.anim_modal.discardOnCompletion = false
	vars.anim_hexa.discardOnCompletion = false
	vars.anim_powerup.repeats = true
	vars.anim_bg_stars_x.repeats = true
	vars.anim_bg_stars_y.repeats = true
	vars.anim_cursor.discardOnCompletion = false

	if vars.mode == "picture" then
		vars.tris = deepcopy(vars.goal)
	elseif vars.mode == "speedrun" or vars.mode == "logic" then
		vars.tris = deepcopy(vars.start)
	else
		local newcolor
		local newpowerup
		for i = 1, 19 do
			newcolor, newpowerup = self:randomizetri()
			vars.tris[i] = {index = i, color = newcolor, powerup = newpowerup}
		end
	end

	if vars.mode == "arcade" or vars.mode == "dailyrun" then
		save.lbs_lastmode = vars.mode
		assets.ui = gfx.image.new('images/ui_arcade')
		vars.timer = pd.timer.new(45000, 45000, 0)
		vars.timer.delay = 4000
		vars.old_timer_value = 45000
		vars.timer.timerEndedCallback = function()
			self:endround()
		end
		pd.timer.performAfterDelay(1000, function()
			if vars.play_out_timer then
				playsound(assets.sfx_count)
				assets.draw_label = assets.label_3
				vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
			end
		end)
		pd.timer.performAfterDelay(2000, function()
			if vars.play_out_timer then
				playsound(assets.sfx_count)
				assets.draw_label = assets.label_2
				vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
			end
		end)
		pd.timer.performAfterDelay(3000, function()
			if vars.play_out_timer then
				playsound(assets.sfx_count)
				assets.draw_label = assets.label_1
				vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
			end
		end)
		pd.timer.performAfterDelay(4000, function()
			if vars.play_out_timer then
				vars.timer.delay = 0
				assets.draw_label = assets.label_go
				vars.anim_label:resetnew(1000, 400, -200, pd.easingFunctions.linear)
				vars.anim_label.timerEndedCallback = function()
					assets.draw_label = nil
				end
				playsound(assets.sfx_start)
				newmusic('audio/music/arcade' .. randInt(1, 3), true)
				vars.can_do_stuff = true
				self:check()
			end
		end)
	elseif vars.mode == "zen" then
		assets.ui = gfx.image.new('images/ui_zen')
		pd.timer.performAfterDelay(1000, function()
			newmusic('audio/music/zen' .. randInt(1, 2), true)
			vars.can_do_stuff = true
			self:check()
		end)
	elseif vars.mode == "picture" then
		vars.anim_cursor_y:resetnew(1, 420, 420)
		assets.ui = gfx.image.new('images/ui_zen')
		pd.timer.performAfterDelay(1000, function()
			if vars.play_out_timer then
				playsound(assets.sfx_count)
				assets.draw_label = assets.label_3
				vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
			end
		end)
		pd.timer.performAfterDelay(2000, function()
			if vars.play_out_timer then
				playsound(assets.sfx_count)
				assets.draw_label = assets.label_2
				vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
			end
		end)
		pd.timer.performAfterDelay(3000, function()
			if vars.play_out_timer then
				playsound(assets.sfx_count)
				assets.draw_label = assets.label_1
				vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
			end
		end)
		pd.timer.performAfterDelay(4000, function()
			if vars.play_out_timer then
				vars.anim_cursor_y:resetnew(1, 42, 42)
				assets.draw_label = assets.label_go
				vars.anim_label:resetnew(1000, 400, -200, pd.easingFunctions.linear)
				vars.anim_label.timerEndedCallback = function()
					assets.draw_label = nil
				end
				playsound(assets.sfx_start)
				vars.tris = deepcopy(vars.start)
				newmusic('audio/music/zen' .. randInt(1, 2), true)
				vars.can_do_stuff = true
			end
		end)
	elseif vars.mode == "logic" then
		assets.ui = gfx.image.new('images/ui_zen')
		pd.timer.performAfterDelay(1000, function()
			newmusic('audio/music/zen' .. randInt(1, 2), true)
			vars.can_do_stuff = true
			self:check()
		end)
	elseif vars.mode == "speedrun" then
		assets.ui = gfx.image.new('images/ui_zen')
		pd.timer.performAfterDelay(1000, function()
			if vars.play_out_timer then
				playsound(assets.sfx_count)
				assets.draw_label = assets.label_3
				vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
			end
		end)
		pd.timer.performAfterDelay(2000, function()
			if vars.play_out_timer then
				playsound(assets.sfx_count)
				assets.draw_label = assets.label_2
				vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
			end
		end)
		pd.timer.performAfterDelay(3000, function()
			if vars.play_out_timer then
				playsound(assets.sfx_count)
				assets.draw_label = assets.label_1
				vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
			end
		end)
		pd.timer.performAfterDelay(4000, function()
			if vars.play_out_timer then
				vars.anim_cursor_y:resetnew(1, 42, 42)
				assets.draw_label = assets.label_go
				vars.anim_label:resetnew(1000, 400, -200, pd.easingFunctions.linear)
				vars.anim_label.timerEndedCallback = function()
					assets.draw_label = nil
				end
				playsound(assets.sfx_start)
				newmusic('audio/music/arcade' .. randInt(1, 3), true)
				vars.can_do_stuff = true
			end
		end)
	elseif vars.mode == "time" then
		assets.ui = gfx.image.new('images/ui_arcade')
		vars.timer = pd.timer.new(vars.modifier * 1000, vars.modifier * 1000, 0)
		vars.timer.delay = 4000
		vars.old_timer_value = vars.modifier * 1000
		vars.timer.timerEndedCallback = function()
			self:endround()
		end
		pd.timer.performAfterDelay(1000, function()
			if vars.play_out_timer then
				playsound(assets.sfx_count)
				assets.draw_label = assets.label_3
				vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
			end
		end)
		pd.timer.performAfterDelay(2000, function()
			if vars.play_out_timer then
				playsound(assets.sfx_count)
				assets.draw_label = assets.label_2
				vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
			end
		end)
		pd.timer.performAfterDelay(3000, function()
			if vars.play_out_timer then
				playsound(assets.sfx_count)
				assets.draw_label = assets.label_1
				vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
			end
		end)
		pd.timer.performAfterDelay(4000, function()
			if vars.play_out_timer then
				vars.timer.delay = 0
				assets.draw_label = assets.label_go
				vars.anim_label:resetnew(1000, 400, -200, pd.easingFunctions.linear)
				vars.anim_label.timerEndedCallback = function()
					assets.draw_label = nil
				end
				playsound(assets.sfx_start)
				newmusic('audio/music/arcade' .. randInt(1, 3), true)
				vars.can_do_stuff = true
				self:check()
			end
		end)
	else
		assets.ui = gfx.image.new('images/ui_zen')
		pd.timer.performAfterDelay(1000, function()
			vars.can_do_stuff = true
			self:check()
		end)
	end

	class('game_canvas', _, classes).extends(gfx.sprite)
	function classes.game_canvas:init()
		classes.game_canvas.super.init(self)
		self:setCenter(0, 0)
		self:setSize(400, 240)
		self:setOpaque(true)
		self:add()
	end
	function classes.game_canvas:draw()
		assets.bg:draw(0, 0)
		if vars.mode ~= "dailyrun" then
			assets.bg_tile:draw((floor(vars.anim_bg_tile_x.value / 2) * 2) - 1, (floor(vars.anim_bg_tile_y.value / 2) * 2) - 1)
		end
		assets.stars:draw(vars.anim_bg_stars_x.value, vars.anim_bg_stars_y.value)
		if assets.draw_label ~= nil then assets.draw_label:draw(vars.anim_label.value, -13) end
		assets.ui:draw(0, 0)
		for i = 1, 19 do
			game:tri(tris_x[i], tris_y[i], tris_flip[i], vars.tris[i].color, vars.tris[i].powerup)
		end
		local cursor = floor(vars.anim_cursor.value) or 1
		assets.cursor[cursor]:draw(vars.anim_cursor_x.value - (2 * (cursor - 1)), vars.anim_cursor_y.value - (3 * (cursor - 1)))
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		if vars.mode == "arcade" or vars.mode == "dailyrun" then
			assets.half_circle:drawText(text('score'), 10, 10)
			assets.full_circle:drawText(commalize(vars.score), 10, 25)
			assets.clock:drawText(ceil(vars.timer.value / 1000), 305, 55)
			if vars.mode == "arcade" then
				assets.half_circle:drawText(text('high'), 10, 45)
				if save.hardmode then
					assets.full_circle:drawText(commalize((vars.score > save.hard_score and vars.score) or (save.hard_score)), 10, 60)
				else
					assets.full_circle:drawText(commalize((vars.score > save.score and vars.score) or (save.score)), 10, 60)
				end
			else
				assets.half_circle:drawText(text('seed'), 10, 45)
				assets.full_circle:drawText(pd.getGMTTime().year .. pd.getGMTTime().month .. pd.getGMTTime().day, 10, 60)
			end
			if save.hardmode then
				assets.half_circle:drawText(text('hardmodeg'), 10, 80)
			end
		elseif vars.mode == "zen" then
			assets.half_circle:drawText(text('swaps'), 10, 10)
			assets.full_circle:drawText(commalize(vars.moves), 10, 25)
			assets.half_circle:drawText(text('hexas'), 10, 45)
			assets.full_circle:drawText(commalize(vars.hexas), 10, 60)
		elseif vars.mode == "picture" or vars.mode == "logic" then
			assets.half_circle:drawText(text('swaps'), 10, 10)
			assets.full_circle:drawText(commalize(vars.moves), 10, 25)
			assets.half_circle:drawText(text('best'), 10, 45)
			assets.full_circle:drawText(commalize(save.mission_bests['mission' .. vars.mission]), 10, 60)
		elseif vars.mode == "time" then
			assets.half_circle:drawText(text('score'), 10, 10)
			assets.full_circle:drawText(commalize(vars.score), 10, 25)
			assets.clock:drawText(ceil(vars.timer.value / 1000), 305, 55)
			assets.half_circle:drawText(text('high'), 10, 45)
			assets.full_circle:drawText(commalize((vars.score > save.mission_bests['mission' .. vars.mission] and vars.score) or (save.mission_bests['mission' .. vars.mission])), 10, 60)
		elseif vars.mode == "speedrun" then
			local mins, secs, mils = timecalc(vars.time)
			local bestmins, bestsecs, bestmils = timecalc(save.mission_bests['mission' .. vars.mission])
			assets.half_circle:drawText(text('time'), 10, 10)
			assets.full_circle:drawText(mins .. ':' .. secs .. '.' .. mils, 10, 25)
			assets.half_circle:drawText(text('best'), 10, 45)
			assets.full_circle:drawText(bestmins .. ':' .. bestsecs .. '.' .. bestmils, 10, 60)
		end
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		assets.hexa[floor(vars.anim_hexa.value)]:draw(0, 0)
		if not vars.can_do_stuff then
			assets.half:draw(0, 0)
		end
		if vars.missioncomplete then
			assets.mission_complete:draw(0, 0)
		end
		assets.modal:draw(0, vars.anim_modal.value)
	end

	sprites.canvas = classes.game_canvas()
	self:add()
	pd.datastore.write(save)
end

function game:tri(x, y, up, color, powerup)
	if color == "white" or color == "gray" then
		gfx.setColor(gfx.kColorWhite)
	end
	if color ~= "none" then
		if up then
			gfx.fillTriangle(x, y - 25, x + 30, y + 25, x - 30, y + 25)
		else
			gfx.fillTriangle(x, y + 25, x + 30, y - 25, x - 30, y - 25)
		end
		if color == "gray" then
			gfx.setColor(gfx.kColorBlack)
			gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer4x4)
			if up then
				gfx.fillTriangle(x, y - 25, x + 30, y + 25, x - 30, y + 25)
			else
				gfx.fillTriangle(x, y + 25, x + 30, y - 25, x - 30, y - 25)
			end
		end
		gfx.setColor(gfx.kColorBlack)
		if up then
			gfx.drawTriangle(x, y - 25, x + 30, y + 25, x - 30, y + 25)
		else
			gfx.drawTriangle(x, y + 25, x + 30, y - 25, x - 30, y - 25)
		end
	else
		gfx.setDitherPattern(0.75, gfx.image.kDitherTypeBayer4x4)
		if up then
			gfx.fillTriangle(x, y - 25, x + 30, y + 25, x - 30, y + 25)
		else
			gfx.fillTriangle(x, y + 25, x + 30, y - 25, x - 30, y - 25)
		end
	end
	gfx.setColor(gfx.kColorBlack)
	if powerup ~= "" then
		if flash then
			if up then
				if assets['powerup_' .. powerup .. '_up'] ~= nil then assets['powerup_' .. powerup .. '_up'][1]:draw(x - 28, y - 23) end
			else
				if assets['powerup_' .. powerup .. '_down'] ~= nil then assets['powerup_' .. powerup .. '_down'][1]:draw(x - 28, y - 23) end
			end
		elseif floor(vars.anim_powerup.value)>= 1 and floor(vars.anim_powerup.value) < 5 then
			if up then
				if assets['powerup_' .. powerup .. '_up'] ~= nil then assets['powerup_' .. powerup .. '_up'][floor(vars.anim_powerup.value)]:draw(x - 28, y - 23) end
			else
				if assets['powerup_' .. powerup .. '_down'] ~= nil then assets['powerup_' .. powerup .. '_down'][floor(vars.anim_powerup.value)]:draw(x - 28, y - 23) end
			end
		end
	end
end

function game:swap(slot, dir)
	if not vars.active_hexa then
		vars.movesbonus -= 1
		if vars.movesbonus < 0 then vars.movesbonus = 0 end
		vars.anim_cursor:resetnew(75, 2.99, 1)
		vars.moves += 1
		save.swaps += 1
		updatecheevos()
		playsound(assets.sfx_swap)
		local tochange
		temp1, temp2, temp3, temp4, temp5, temp6 = self:findslot(slot)
		if slot == 1 then
			tochange = {1, 2, 3, 7, 8, 9}
		elseif slot == 2 then
			tochange = {3, 4, 5, 9, 10, 11}
		elseif slot == 3 then
			tochange = {6, 7, 8, 13, 14, 15}
		elseif slot == 4 then
			tochange = {8, 9, 10, 15, 16, 17}
		elseif slot == 5 then
			tochange = {10, 11, 12, 17, 18, 19}
		end
		if dir then
			vars.tris[tochange[2]] = temp1
			vars.tris[tochange[3]] = temp2
			vars.tris[tochange[6]] = temp3
			vars.tris[tochange[1]] = temp4
			vars.tris[tochange[4]] = temp5
			vars.tris[tochange[5]] = temp6
		else
			vars.tris[tochange[4]] = temp1
			vars.tris[tochange[1]] = temp2
			vars.tris[tochange[2]] = temp3
			vars.tris[tochange[5]] = temp4
			vars.tris[tochange[6]] = temp5
			vars.tris[tochange[3]] = temp6
		end
		self:check()
	end
end

function game:check()
	if vars.mode == "picture" then
		local picturetest = true
		for i = 1, 19 do
			local colorcheck1 = vars.tris[i].color
			local colorcheck2 = vars.goal[i].color
			if colorcheck1 ~= colorcheck2 then
				picturetest = false
				return
			end
		end
		if picturetest then
			self:endround()
		end
		return
	end
	if vars.can_do_stuff then
		local temp1
		local temp2
		local temp3
		local temp4
		local temp5
		local temp6
		local bomb_temp1
		local bomb_temp2
		local bomb_temp3
		local bomb_temp4
		local bomb_temp5
		local bomb_temp6
		local bomb_imminent = false
		local color
		for i = 1, 5 do
			temp1, temp2, temp3, temp4, temp5, temp6 = self:findslot(i)
			for i = 1, 3 do
				if i == 1 then
					color = "white"
				elseif i == 2 then
					color = "black"
				elseif i == 3 then
					color = "gray"
				end
				if (temp1.color == color or temp1.powerup == "wild") and (temp2.color == color or temp2.powerup == "wild") and (temp3.color == color or temp3.powerup == "wild") and (temp4.color == color or temp4.powerup == "wild") and (temp5.color == color or temp5.powerup == "wild") and (temp6.color == color or temp6.powerup == "wild") then
					if temp1.powerup == "bomb" or temp2.powerup == "bomb" or temp3.powerup == "bomb" or temp4.powerup == "bomb" or temp5.powerup == "bomb" or temp6.powerup == "bomb" then
						bomb_temp1 = temp1
						bomb_temp2 = temp2
						bomb_temp3 = temp3
						bomb_temp4 = temp4
						bomb_temp5 = temp5
						bomb_temp6 = temp6
						bomb_imminent = true
					else
						self:hexa(temp1, temp2, temp3, temp4, temp5, temp6)
						return
					end
				end
			end
		end
		if bomb_imminent then
			self:hexa(bomb_temp1, bomb_temp2, bomb_temp3, bomb_temp4, bomb_temp5, bomb_temp6)
			return
		end
		if vars.combo > 0 then
			vars.combo = 0
		end
	end
end

function game:colorflip(temp1, temp2, temp3, temp4, temp5, temp6, yes)
	if yes then
		if (temp1.color == "white" and temp1.powerup ~= "wild") or (temp2.color == "white" and temp2.powerup ~= "wild") or (temp3.color == "white" and temp3.powerup ~= "wild") or (temp4.color == "white" and temp4.powerup ~= "wild") or (temp5.color == "white" and temp5.powerup ~= "wild") or (temp6.color == "white" and temp6.powerup ~= "wild") then
			temp1.color = "gray"
			temp2.color = "gray"
			temp3.color = "gray"
			temp4.color = "gray"
			temp5.color = "gray"
			temp6.color = "gray"
		else
			temp1.color = "white"
			temp2.color = "white"
			temp3.color = "white"
			temp4.color = "white"
			temp5.color = "white"
			temp6.color = "white"
		end
	else
		temp1.color = vars.tempcolor1
		temp2.color = vars.tempcolor2
		temp3.color = vars.tempcolor3
		temp4.color = vars.tempcolor4
		temp5.color = vars.tempcolor5
		temp6.color = vars.tempcolor6
	end
end

function game:hexa(temp1, temp2, temp3, temp4, temp5, temp6)
	pd.inputHandlers.pop()
	vars.active_hexa = true
	vars.tempcolor1 = temp1.color
	vars.tempcolor2 = temp2.color
	vars.tempcolor3 = temp3.color
	vars.tempcolor4 = temp4.color
	vars.tempcolor5 = temp5.color
	vars.tempcolor6 = temp6.color
	assets.sfx_hexaprep:setRate(1 + (0.1 * vars.combo))
	playsound(assets.sfx_hexaprep)
	self:colorflip(temp1, temp2, temp3, temp4, temp5, temp6, true)
	pd.timer.performAfterDelay(100, function()
		if not flash then
			self:colorflip(temp1, temp2, temp3, temp4, temp5, temp6, false)
		end
	end)
	pd.timer.performAfterDelay(200, function()
		playsound(assets.sfx_hexaprep)
		if flash then
			self:colorflip(temp1, temp2, temp3, temp4, temp5, temp6, false)
		else
			self:colorflip(temp1, temp2, temp3, temp4, temp5, temp6, true)
		end
	end)
	pd.timer.performAfterDelay(300, function()
		if not flash then
			self:colorflip(temp1, temp2, temp3, temp4, temp5, temp6, false)
		end
	end)
	pd.timer.performAfterDelay(400, function()
		if vars.can_do_stuff or (not vars.can_do_stuff and vars.ended) then
			vars.hexas += 1
			save.hexas += 1
			vars.combo += 1
			shakies()
			shakies_y()
			if temp1.powerup == 'wild' or temp2.powerup == 'wild' or temp3.powerup == 'wild' or temp4.powerup == 'wild' or temp5.powerup == 'wild' or temp6.powerup == 'wild' then
				save.wild_match += 1
			end
			if temp1.powerup == "double" or temp2.powerup == "double" or temp3.powerup == "double" or temp4.powerup == "double" or temp5.powerup == "double" or temp6.powerup == "double" then
				save.double_match += 1
				if (temp1.color == "white" and temp1.powerup ~= "wild") or (temp2.color == "white" and temp2.powerup ~= "wild") or (temp3.color == "white" and temp3.powerup ~= "wild") or (temp4.color == "white" and temp4.powerup ~= "wild") or (temp5.color == "white" and temp5.powerup ~= "wild") or (temp6.color == "white" and temp6.powerup ~= "wild") then
					vars.score += 200 * vars.combo
					save.total_score += 200 * vars.combo
					save.white_match += 1
				elseif (temp1.color == "gray" and temp1.powerup ~= "wild") or (temp2.color == "gray" and temp2.powerup ~= "wild") or (temp3.color == "gray" and temp3.powerup ~= "wild") or (temp4.color == "gray" and temp4.powerup ~= "wild") or (temp5.color == "gray" and temp5.powerup ~= "wild") or (temp6.color == "gray" and temp6.powerup ~= "wild") then
					vars.score += 300 * vars.combo
					save.total_score += 300 * vars.combo
					save.gray_match += 1
				elseif (temp1.color == "black" and temp1.powerup ~= "wild") or (temp2.color == "black" and temp2.powerup ~= "wild") or (temp3.color == "black" and temp3.powerup ~= "wild") or (temp4.color == "black" and temp4.powerup ~= "wild") or (temp5.color == "black" and temp5.powerup ~= "wild") or (temp6.color == "black" and temp6.powerup ~= "wild") then
					vars.score += 400 * vars.combo
					save.total_score += 400 * vars.combo
					save.black_match += 1
				end
				playsound(assets.sfx_select)
				assets.draw_label = assets.label_double
				vars.anim_label:resetnew(1200, 400, -200, pd.easingFunctions.linear)
				vars.anim_label.timerEndedCallback = function()
					assets.draw_label = nil
				end
				if (vars.mode == "arcade" or vars.mode == "dailyrun") and vars.can_do_stuff then
					if save.hardmode then
						vars.timer:resetnew(min(vars.timer.value + (11000 * exp(-0.105 * vars.hexas)) + 1375, 60000), min(vars.timer.value + (11000 * exp(-0.105 * vars.hexas)) + 1375, 60000), 0)
					else
						vars.timer:resetnew(min(vars.timer.value + (11000 * exp(-0.105 * vars.hexas)) + 2750, 60000), min(vars.timer.value + (11000 * exp(-0.105 * vars.hexas)) + 2750, 60000), 0)
					end
				end
			else
				if (temp1.color == "white" and temp1.powerup ~= "wild") or (temp2.color == "white" and temp2.powerup ~= "wild") or (temp3.color == "white" and temp3.powerup ~= "wild") or (temp4.color == "white" and temp4.powerup ~= "wild") or (temp5.color == "white" and temp5.powerup ~= "wild") or (temp6.color == "white" and temp6.powerup ~= "wild") then
					vars.score += 100 * vars.combo
					save.total_score += 100 * vars.combo
					save.white_match += 1
				elseif (temp1.color == "gray" and temp1.powerup ~= "wild") or (temp2.color == "gray" and temp2.powerup ~= "wild") or (temp3.color == "gray" and temp3.powerup ~= "wild") or (temp4.color == "gray" and temp4.powerup ~= "wild") or (temp5.color == "gray" and temp5.powerup ~= "wild") or (temp6.color == "gray" and temp6.powerup ~= "wild") then
					vars.score += 150 * vars.combo
					save.total_score += 150 * vars.combo
					save.gray_match += 1
				elseif (temp1.color == "black" and temp1.powerup ~= "wild") or (temp2.color == "black" and temp2.powerup ~= "wild") or (temp3.color == "black" and temp3.powerup ~= "wild") or (temp4.color == "black" and temp4.powerup ~= "wild") or (temp5.color == "black" and temp5.powerup ~= "wild") or (temp6.color == "black" and temp6.powerup ~= "wild") then
					vars.score += 200 * vars.combo
					save.total_score += 200 * vars.combo
					save.black_match += 1
				end
				if (vars.mode == "arcade" or vars.mode == "dailyrun") and vars.can_do_stuff then
					if save.hardmode then
						vars.timer:resetnew(min(vars.timer.value + (7000 * exp(-0.105 * vars.hexas)) + 875, 60000), min(vars.timer.value + (7000 * exp(-0.105 * vars.hexas)) + 875, 60000), 0)
					else
						vars.timer:resetnew(min(vars.timer.value + (7000 * exp(-0.105 * vars.hexas)) + 1750, 60000), min(vars.timer.value + (7000 * exp(-0.105 * vars.hexas)) + 1750, 60000), 0)
					end
				end
			end
			vars.score += 10 * vars.movesbonus
			save.total_score += 10 * vars.movesbonus
			vars.movesbonus = 5
			if temp1.powerup == "bomb" or temp2.powerup == "bomb" or temp3.powerup == "bomb" or temp4.powerup == "bomb" or temp5.powerup == "bomb" or temp6.powerup == "bomb" then
				save.bomb_match += 1
				for i = 1, 19 do
					newcolor, newpowerup = self:randomizetri()
					vars.tris[i] = {index = i, color = newcolor, powerup = newpowerup}
				end
				playsound(assets.sfx_boom)
				assets.draw_label = assets.label_bomb
				vars.anim_label:resetnew(1200, 400, -200, pd.easingFunctions.linear)
				vars.anim_label.timerEndedCallback = function()
					assets.draw_label = nil
				end
			else
				temp1.color, temp1.powerup = self:randomizetri()
				temp2.color, temp2.powerup = self:randomizetri()
				temp3.color, temp3.powerup = self:randomizetri()
				temp4.color, temp4.powerup = self:randomizetri()
				temp5.color, temp5.powerup = self:randomizetri()
				temp6.color, temp6.powerup = self:randomizetri()
				if save.sfx then
					local random = randInt(1, 10000)
					if random == 1 then
						assets.sfx_vine:play()
					else
						assets.sfx_hexa:play()
					end
				end
			end
			vars.anim_hexa:resetnew(600, 1, 11)
			if vars.mode == "logic" or vars.mode == "speedrun" then
				local logictest = true
				if vars.modifier == "board" then
					for i = 1, 19 do
						if vars.tris[i].color ~= "none" then
							logictest = false
						end
					end
				elseif vars.modifier == "black" then
					for i = 1, 19 do
						if vars.tris[i].color == "black" then
							logictest = false
						end
					end
				elseif vars.modifier == "gray" then
					for i = 1, 19 do
						if vars.tris[i].color == "gray" then
							logictest = false
						end
					end
				elseif vars.modifier == "white" then
					for i = 1, 19 do
						if vars.tris[i].color == "white" then
							logictest = false
						end
					end
				elseif vars.modifier == "2x" then
					for i = 1, 19 do
						if vars.tris[i].powerup == "double" then
							logictest = false
						end
					end
				elseif vars.modifier == "bomb" then
					for i = 1, 19 do
						if vars.tris[i].powerup == "bomb" then
							logictest = false
						end
					end
				elseif vars.modifier == "wild" then
					for i = 1, 19 do
						if vars.tris[i].powerup == "wild" then
							logictest = false
						end
					end
				end
				if logictest then
					self:endround()
				end
			end
			pd.timer.performAfterDelay(200, function()
				pd.inputHandlers.push(vars.gameHandlers)
				vars.active_hexa = false
				updatecheevos()
				self:check()
			end)
		end
	end)
end

function game:boom(boomed)
	if vars.mode == "arcade" or vars.mode == "dailyrun" or vars.mode == "zen" then
		if ((boomed and not vars.boomed) or (not boomed)) and vars.can_do_stuff then
			shakies()
			shakies_y()
			for i = 1, 19 do
				newcolor, newpowerup = self:randomizetri()
				vars.tris[i] = {index = i, color = newcolor, powerup = newpowerup}
			end
			playsound(assets.sfx_boom)
			assets.draw_label = assets.label_bomb
			vars.anim_label:resetnew(1200, 400, -200, pd.easingFunctions.linear)
			if boomed then
				vars.boomed = true
				self:check()
			end
		end
	end
end

function game:findslot(slot)
	local temp1
	local temp2
	local temp3
	local temp4
	local temp5
	local temp6
	if slot == 1 then
		-- 1, 2, 3, 7, 8, 9
		temp1 = vars.tris[1]
		temp2 = vars.tris[2]
		temp3 = vars.tris[3]
		temp4 = vars.tris[7]
		temp5 = vars.tris[8]
		temp6 = vars.tris[9]
	elseif slot == 2 then
		-- 3, 4, 5, 9, 10, 11
		temp1 = vars.tris[3]
		temp2 = vars.tris[4]
		temp3 = vars.tris[5]
		temp4 = vars.tris[9]
		temp5 = vars.tris[10]
		temp6 = vars.tris[11]
	elseif slot == 3 then
		-- 6, 7, 8, 13, 14, 15
		temp1 = vars.tris[6]
		temp2 = vars.tris[7]
		temp3 = vars.tris[8]
		temp4 = vars.tris[13]
		temp5 = vars.tris[14]
		temp6 = vars.tris[15]
	elseif slot == 4 then
		-- 8, 9, 10, 15, 16, 17
		temp1 = vars.tris[8]
		temp2 = vars.tris[9]
		temp3 = vars.tris[10]
		temp4 = vars.tris[15]
		temp5 = vars.tris[16]
		temp6 = vars.tris[17]
	elseif slot == 5 then
		-- 10, 11, 12, 17, 18, 19
		temp1 = vars.tris[10]
		temp2 = vars.tris[11]
		temp3 = vars.tris[12]
		temp4 = vars.tris[17]
		temp5 = vars.tris[18]
		temp6 = vars.tris[19]
	end
	return temp1, temp2, temp3, temp4, temp5, temp6
end

function game:randomizetri()
	if vars.mode == "speedrun" or vars.mode == "logic" then
		color = "none"
		powerup = ""
		return color, powerup
	else
		local randomcolor = randInt(1, 3)
		local randompowerup = randInt(1, 50)
		local color
		local powerup
		if randomcolor == 1 then
			color = "black"
		elseif randomcolor == 2 then
			color = "white"
		elseif randomcolor == 3 then
			color = "gray"
		end
		if vars.mode == "arcade" or vars.mode == "dailyrun" or vars.mode == "time" then
			if randompowerup == 1 or randompowerup == 2 or randompowerup == 3 then
				powerup = "double"
			elseif randompowerup == 4 then
				powerup = "bomb"
			elseif randompowerup == 5 then
				powerup = "wild"
			else
				powerup = ""
			end
		else
			powerup = ""
		end
		return color, powerup
	end
end

function game:restart()
	fademusic(1)
	self:boom(false)
	vars.can_do_stuff = false
	vars.score = 0
	vars.boomed = false
	vars.moves = 0
	vars.hexas = 0
	vars.anim_hexa:resetnew(1, 11, 11)
	vars.active_hexa = false
	vars.slot = 1
	vars.anim_cursor_x:resetnew(1, 106, 106)
	vars.anim_cursor_y:resetnew(1, 42, 42)
	vars.anim_label:resetnew(0, 400, 400)
	vars.timer:resetnew(45000, 45000, 0)
	vars.timer:pause()
	vars.old_timer_value = 45000
	if #playdate.inputHandlers == 1 then
		pd.inputHandlers.push(vars.gameHandlers)
	end
	vars.old_timer_value = 45000
	vars.timer.timerEndedCallback = function()
		self:endround()
	end
	pd.timer.performAfterDelay(1000, function()
		if vars.play_out_timer then
			playsound(assets.sfx_count)
			assets.draw_label = assets.label_3
			vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
		end
	end)
	pd.timer.performAfterDelay(2000, function()
		if vars.play_out_timer then
			playsound(assets.sfx_count)
			assets.draw_label = assets.label_2
			vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
		end
	end)
	pd.timer.performAfterDelay(3000, function()
		if vars.play_out_timer then
			playsound(assets.sfx_count)
			assets.draw_label = assets.label_1
			vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
		end
	end)
	pd.timer.performAfterDelay(4000, function()
		if vars.play_out_timer then
			vars.timer:start()
			assets.draw_label = assets.label_go
			vars.anim_label:resetnew(1000, 400, -200, pd.easingFunctions.linear)
			vars.anim_label.timerEndedCallback = function()
				assets.draw_label = nil
			end
			playsound(assets.sfx_start)
			newmusic('audio/music/arcade' .. randInt(1, 3), true)
			vars.can_do_stuff = true
			self:check()
		end
	end)
end

function game:ersi()
	vars.skippedfanfare = true
	pd.inputHandlers.push(vars.loseHandlers, true)
	if vars.mode == "zen" then
		gfx.pushContext(assets.modal)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
				assets.full_circle:drawTextAligned(text('zen1'), 240, 50, kTextAlignment.center)
				if vars.moves == 1 then
					assets.full_circle:drawTextAligned(text('stats1') .. commalize(vars.moves) .. text('stats2b'), 240, 90, kTextAlignment.center)
				else
					assets.full_circle:drawTextAligned(text('stats1') .. commalize(vars.moves) .. text('stats2a'), 240, 90, kTextAlignment.center)
				end
				if vars.hexas == 1 then
					assets.full_circle:drawTextAligned(text('stats3') .. commalize(vars.hexas) .. text('stats4b'), 240, 105, kTextAlignment.center)
				else
					assets.full_circle:drawTextAligned(text('stats3') .. commalize(vars.hexas) .. text('stats4a'), 240, 105, kTextAlignment.center)
				end
				assets.full_circle:drawTextAligned(text(vars.mode .. '_message' .. messagerand), 190, 150, kTextAlignment.center)
				assets.half_circle:drawText(text('newgame') .. ' ' .. text('back'), 40, 205)
			gfx.setImageDrawMode(gfx.kDrawModeCopy)
		gfx.popContext()
	else
		gfx.pushContext(assets.modal)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
				assets.full_circle:drawTextAligned(text('score1') .. commalize(vars.score) .. text('score2'), 240, 50, kTextAlignment.center)
				if vars.moves == 1 then
					assets.full_circle:drawTextAligned(text('stats1') .. commalize(vars.moves) .. text('stats2b'), 240, 90, kTextAlignment.center)
				else
					assets.full_circle:drawTextAligned(text('stats1') .. commalize(vars.moves) .. text('stats2a'), 240, 90, kTextAlignment.center)
				end
				if vars.hexas == 1 then
					assets.full_circle:drawTextAligned(text('stats3') .. commalize(vars.hexas) .. text('stats4b'), 240, 105, kTextAlignment.center)
				else
					assets.full_circle:drawTextAligned(text('stats3') .. commalize(vars.hexas) .. text('stats4a'), 240, 105, kTextAlignment.center)
				end
				assets.full_circle:drawTextAligned(text(vars.mode .. '_message' .. messagerand), 190, 150, kTextAlignment.center)
				if vars.mode == "dailyrun" then
					if catalog then
						assets.half_circle:drawText(text('showsdailyscores') .. ' ' .. text('back'), 40, 205)
					else
						assets.half_circle:drawText(text('back'), 40, 205)
					end
				else
					assets.half_circle:drawText(text('newgame') .. ' ' .. text('back'), 40, 205)
				end
			gfx.setImageDrawMode(gfx.kDrawModeCopy)
		gfx.popContext()
	end
end

function game:endround()
	fademusic(1)
	if vars.mode == "arcade" or vars.mode == "dailyrun" then
		if not vars.ended then
			vars.timer:pause()
			playsound(assets.sfx_end)
		end
		pd.timer.performAfterDelay(2000, function()
			if vars.active_hexa then
				self:endround()
				return
			end
			if not save.skipfanfare then
				pd.inputHandlers.push(vars.losingHandlers, true)
			end
			if vars.mode == "dailyrun" then
				if save.lastdaily.year == pd.getGMTTime().year and save.lastdaily.month == pd.getGMTTime().month and save.lastdaily.day == pd.getGMTTime().day then
					save.lastdaily.score = vars.score
					if catalog then
						pd.scoreboards.addScore((save.hardmode and 'hard' .. vars.mode) or (vars.mode), vars.score, function(status, result)
							if status.code == "OK" then
								save.lastdaily.sent = true
							else
								save.lastdaily.sent = false
							end
							if pd.isSimulator == 1 then
								printTable(status)
								printTable(result)
							end
						end)
					end
				end
			else
				if catalog then
					pd.scoreboards.addScore((save.hardmode and 'hardarcade') or ('arcade'), vars.score, function(status, result)
						if pd.isSimulator == 1 then
							printTable(status)
							printTable(result)
						end
					end)
				end
			end
			if save.hardmode then
				if vars.score > save.hard_score and vars.mode == "arcade" then save.hard_score = vars.score end
			else
				if vars.score > save.score and vars.mode == "arcade" then save.score = vars.score end
			end
			updatecheevos()
			pd.datastore.write(save)
			newmusic('audio/music/lose')
			vars.anim_modal:resetnew(500, 240, 0, pd.easingFunctions.outBack)
			if save.skipfanfare then
				self:ersi()
			else
				pd.timer.performAfterDelay(548, function()
					if not vars.skippedfanfare then
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
								assets.full_circle:drawTextAligned(text('score1') .. commalize(vars.score) .. text('score2'), 240, 50, kTextAlignment.center)
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
				pd.timer.performAfterDelay(2146, function()
					if not vars.skippedfanfare then
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
							if vars.moves == 1 then
								assets.full_circle:drawTextAligned(text('stats1') .. commalize(vars.moves) .. text('stats2b'), 240, 90, kTextAlignment.center)
							else
								assets.full_circle:drawTextAligned(text('stats1') .. commalize(vars.moves) .. text('stats2a'), 240, 90, kTextAlignment.center)
							end
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
				pd.timer.performAfterDelay(3957, function()
					if not vars.skippedfanfare then
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
							if vars.hexas == 1 then
								assets.full_circle:drawTextAligned(text('stats3') .. commalize(vars.hexas) .. text('stats4b'), 240, 105, kTextAlignment.center)
							else
								assets.full_circle:drawTextAligned(text('stats3') .. commalize(vars.hexas) .. text('stats4a'), 240, 105, kTextAlignment.center)
							end
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
				pd.timer.performAfterDelay(6138, function()
					if not vars.skippedfanfare then
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
							assets.full_circle:drawTextAligned(text(vars.mode .. '_message' .. messagerand), 190, 150, kTextAlignment.center)
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
				pd.timer.performAfterDelay(8976, function()
					if not vars.skippedfanfare then
						pd.inputHandlers.push(vars.loseHandlers, true)
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
							if vars.mode == "dailyrun" then
								assets.half_circle:drawText(text('showsdailyscores') .. ' ' .. text('back'), 40, 205)
							else
								assets.half_circle:drawText(text('newgame') .. ' ' .. text('back'), 40, 205)
							end
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
			end
		end)
	elseif vars.mode == "zen" then
		achievements.grant("chill")
		if not vars.ended then
			playsound(assets.sfx_start)
		end
		pd.timer.performAfterDelay(1000, function()
			if vars.active_hexa then
				self:endround()
				return
			end
			if not save.skipfanfare then
				pd.inputHandlers.push(vars.losingHandlers, true)
			end
			pd.datastore.write(save)
			newmusic('audio/music/zen_end')
			vars.anim_modal:resetnew(500, 240, 0, pd.easingFunctions.outBack)
			if save.skipfanfare then
				self:ersi()
			else
				pd.timer.performAfterDelay(2140, function()
					if not vars.skippedfanfare then
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
								assets.full_circle:drawTextAligned(text('zen1'), 240, 50, kTextAlignment.center)
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
				pd.timer.performAfterDelay(3296, function()
					if not vars.skippedfanfare then
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
							if vars.moves == 1 then
								assets.full_circle:drawTextAligned(text('stats1') .. commalize(vars.moves) .. text('stats2b'), 240, 90, kTextAlignment.center)
							else
								assets.full_circle:drawTextAligned(text('stats1') .. commalize(vars.moves) .. text('stats2a'), 240, 90, kTextAlignment.center)
							end
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
				pd.timer.performAfterDelay(4152, function()
					if not vars.skippedfanfare then
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
							if vars.hexas == 1 then
								assets.full_circle:drawTextAligned(text('stats3') .. commalize(vars.hexas) .. text('stats4b'), 240, 105, kTextAlignment.center)
							else
								assets.full_circle:drawTextAligned(text('stats3') .. commalize(vars.hexas) .. text('stats4a'), 240, 105, kTextAlignment.center)
							end
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
				pd.timer.performAfterDelay(5297, function()
					if not vars.skippedfanfare then
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
							assets.full_circle:drawTextAligned(text(vars.mode .. '_message' .. messagerand), 190, 150, kTextAlignment.center)
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
				pd.timer.performAfterDelay(8000, function()
					if not vars.skippedfanfare then
						pd.inputHandlers.push(vars.loseHandlers, true)
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
							assets.half_circle:drawText(text('newgame') .. ' ' .. text('back'), 40, 205)
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
			end
		end)
	elseif vars.mode == "picture" then
		if not vars.ended then
			playsound(assets.sfx_start)
			if vars.mission == save.highest_mission then
				save.highest_mission += 1
			end
			if save.mission_bests['mission' .. vars.mission] == 0 or save.mission_bests['mission' .. vars.mission] > vars.moves then
				save.mission_bests['mission' .. vars.mission] = vars.moves
			end
		end
		pd.timer.performAfterDelay(1500, function()
			playsound(assets.sfx_mission)
			vars.missioncomplete = true
			updatecheevos(vars.mission == 50 and true or false)
			pd.datastore.write(save)
		end)
		pd.timer.performAfterDelay(3000, function()
			if vars.mission ~= nil and vars.mission > 50 then
				scenemanager:transitionscene(missions, true)
			else
				scenemanager:transitionscene(missions)
			end
		end)
	elseif vars.mode == "time" then
		if not vars.ended then
			playsound(assets.sfx_end)
			if vars.mission == save.highest_mission then
				save.highest_mission += 1
			end
			if save.mission_bests['mission' .. vars.mission] < vars.score then
				save.mission_bests['mission' .. vars.mission] = vars.score
			end
		end
		pd.timer.performAfterDelay(1500, function()
			if vars.active_hexa then
				self:endround()
				return
			end
			playsound(assets.sfx_mission)
			vars.missioncomplete = true
			updatecheevos(vars.mission == 50 and true or false)
			pd.datastore.write(save)
			pd.timer.performAfterDelay(1500, function()
				if vars.mission ~= nil and vars.mission > 50 then
					scenemanager:transitionscene(missions, true)
				else
					scenemanager:transitionscene(missions)
				end
			end)
		end)
	elseif vars.mode == "logic" then
		if not vars.ended then
			playsound(assets.sfx_end)
			if vars.mission == save.highest_mission then
				save.highest_mission += 1
			end
			if save.mission_bests['mission' .. vars.mission] == 0 or save.mission_bests['mission' .. vars.mission] > vars.moves then
				save.mission_bests['mission' .. vars.mission] = vars.moves
			end
		end
		pd.timer.performAfterDelay(1500, function()
			if vars.active_hexa then
				self:endround()
				return
			end
			playsound(assets.sfx_mission)
			vars.missioncomplete = true
			updatecheevos(vars.mission == 50 and true or false)
			pd.datastore.write(save)
			pd.timer.performAfterDelay(1500, function()
				if vars.mission ~= nil and vars.mission > 50 then
					scenemanager:transitionscene(missions, true)
				else
					scenemanager:transitionscene(missions)
				end
			end)
		end)
	elseif vars.mode == "speedrun" then
		if not vars.ended then
			playsound(assets.sfx_end)
			if vars.mission == save.highest_mission then
				save.highest_mission += 1
			end
			if save.mission_bests['mission' .. vars.mission] == 0 or save.mission_bests['mission' .. vars.mission] > vars.time then
				save.mission_bests['mission' .. vars.mission] = vars.time
			end
		end
		pd.timer.performAfterDelay(1500, function()
			if vars.active_hexa then
				self:endround()
				return
			end
			playsound(assets.sfx_mission)
			vars.missioncomplete = true
			updatecheevos(vars.mission == 50 and true or false)
			pd.datastore.write(save)
			pd.timer.performAfterDelay(1500, function()
				if vars.mission ~= nil and vars.mission > 50 then
					scenemanager:transitionscene(missions, true)
				else
					scenemanager:transitionscene(missions)
				end
			end)
		end)
	end
	vars.can_do_stuff = false
	vars.ended = true
end

function game:update()
	local ticks = pd.getCrankTicks(3 * save.sensitivity)
	if save.crank and vars.can_do_stuff and not vars.active_hexa then
		vars.crank_degrees += pd.getCrankChange()
		if ticks ~= 0 and vars.crank_deadzone == 0 then
			vars.crank_deadzone = ticks
		end
		if vars.crank_deadzone == 0 then
			vars.crank_change += pd.getCrankChange()
		end
		if vars.crank_degrees >= (vars.crank_change + 2) then
			if vars.crank_deadzone > 0 then
				for i = 1, vars.crank_deadzone do
					if save.flip then
						self:swap(vars.slot, false)
					else
						self:swap(vars.slot, true)
					end
				end
			end
			vars.crank_deadzone = 0
			vars.crank_degrees = 0
			vars.crank_change = 0
		end
		if vars.crank_degrees <= (vars.crank_change - 2) then
			if vars.crank_deadzone < 0 then
				for i = 1, -vars.crank_deadzone do
					if save.flip then
						self:swap(vars.slot, true)
					else
						self:swap(vars.slot, false)
					end
				end
			end
			vars.crank_deadzone = 0
			vars.crank_degrees = 0
			vars.crank_change = 0
		end
	end

	if vars.mode == "arcade" or vars.mode == "dailyrun" or vars.mode == "time" then
		if vars.old_timer_value > 10000 and vars.timer.value <= 10000 then
			shakies(500, 1)
			shakies_y(750, 1)
			playsound(assets.sfx_count)
		end
		if vars.old_timer_value > 9000 and vars.timer.value <= 9000 then
			shakies(500, 2)
			shakies_y(750, 2)
			playsound(assets.sfx_count)
		end
		if vars.old_timer_value > 8000 and vars.timer.value <= 8000 then
			shakies(500, 3)
			shakies_y(750, 3)
			playsound(assets.sfx_count)
		end
		if vars.old_timer_value > 7000 and vars.timer.value <= 7000 then
			shakies(500, 4)
			shakies_y(750, 4)
			playsound(assets.sfx_count)
		end
		if vars.old_timer_value > 6000 and vars.timer.value <= 6000 then
			shakies(500, 5)
			shakies_y(750, 5)
			playsound(assets.sfx_count)
		end
		if vars.old_timer_value > 5000 and vars.timer.value <= 5000 then
			shakies(500, 6)
			shakies_y(750, 6)
			playsound(assets.sfx_count)
		end
		if vars.old_timer_value > 4000 and vars.timer.value <= 4000 then
			shakies(500, 7)
			shakies_y(750, 7)
			playsound(assets.sfx_count)
		end
		if vars.old_timer_value > 3000 and vars.timer.value <= 3000 then
			shakies(500, 8)
			shakies_y(750, 8)
			playsound(assets.sfx_count)
		end
		if vars.old_timer_value > 2000 and vars.timer.value <= 2000 then
			shakies(500, 9)
			shakies_y(750, 9)
			playsound(assets.sfx_count)
		end
		if vars.old_timer_value > 1000 and vars.timer.value <= 1000 then
			shakies(500, 10)
			shakies_y(750, 10)
			playsound(assets.sfx_count)
		end
		vars.old_timer_value = vars.timer.value
	end
	if vars.mode == "speedrun" and vars.can_do_stuff then
		vars.time += 1
	end
	if vars.can_do_stuff then
		save.gametime += 1
	end
	if vars.sequenceindex > #vars.sequence and not vars.boomed then
		if vars.can_do_stuff then
			self:boom(true)
		else
			vars.sequenceindex = 1
		end
	end
end