import 'missions'

-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = getLocalizedText
local tris_x <const> = {140, 170, 200, 230, 260, 110, 140, 170, 200, 230, 260, 290, 110, 140, 170, 200, 230, 260, 290}
local tris_y <const> = {70, 70, 70, 70, 70, 120, 120, 120, 120, 120, 120, 120, 170, 170, 170, 170, 170, 170, 170}
local tris_flip <const> = {true, false, true, false, true, true, false, true, false, true, false, true, false, true, false, true, false, true, false}
local floor <const> = math.floor
local flash <const> = pd.getReduceFlashing()

class('mission_command').extends(gfx.sprite) -- Create the scene's class
function mission_command:init(...)
	mission_command.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		pauseimage()
		menu:removeAllMenuItems()
		if not scenemanager.transitioning then
			if vars.mode == 'start' and not pd.keyboard.isVisible() then
				menu:addMenuItem(text('goback'), function()
					scenemanager:transitionscene(missions, vars.custom)
					fademusic()
				end)
			elseif vars.mode == 'edit' then
				if mission_command:check_validity() then
					menu:addMenuItem(text('export'), function()
						vars.mode = 'save'
						pd.inputHandlers.pop()
						pd.inputHandlers.push(vars.mission_command_saveHandlers)
						vars.scroll_x_target = 1200
						gfx.sprite.setAlwaysRedraw(false)
					end)
				end
				menu:addMenuItem(text('goback'), function()
					vars.mode = 'start'
					pd.inputHandlers.pop()
					pd.inputHandlers.push(vars.mission_command_startHandlers)
					vars.scroll_x_target = 400
					gfx.sprite.setAlwaysRedraw(false)
					sprites.error.x_target = -355
				end)
			elseif vars.mode == 'save' and not pd.keyboard.isVisible() then
				menu:addMenuItem(text('goback'), function()
					vars.mode = 'edit'
					pd.inputHandlers.pop()
					pd.inputHandlers.push(vars.mission_command_editHandlers)
					vars.scroll_x_target = 800
					gfx.sprite.setAlwaysRedraw(true)
				end)
			end
		end
	end

	assets = {
		white = gfx.image.new(400, 240, gfx.kColorWhite),
		full_circle = gfx.font.new('fonts/full-circle'),
		half_circle = gfx.font.new('fonts/full-circle-halved'),
		full_circle_outline = gfx.font.new('fonts/full-circle-outline'),
		mcsel = gfx.image.new('images/mcsel'),
		sfx_move = smp.new('audio/sfx/swap'),
		sfx_move2 = smp.new('audio/sfx/move'),
		sfx_bonk = smp.new('audio/sfx/bonk'),
		sfx_back = smp.new('audio/sfx/back'),
		sfx_select = smp.new('audio/sfx/select'),
		ui = gfx.image.new('images/ui_create'),
		modal = gfx.image.new('images/modal_small'),
		x = gfx.image.new('images/x'),
		export_complete = gfx.image.new('images/export_complete_' .. checklanguage()),
		powerup_double_up = gfx.imagetable.new('images/powerup_double_up'),
		powerup_double_down = gfx.imagetable.new('images/powerup_double_down'),
		powerup_bomb_up = gfx.imagetable.new('images/powerup_bomb_up'),
		powerup_bomb_down = gfx.imagetable.new('images/powerup_bomb_down'),
		powerup_wild_up = gfx.imagetable.new('images/powerup_wild_up'),
		powerup_wild_down = gfx.imagetable.new('images/powerup_wild_down'),
		error = gfx.image.new('images/error'),
	}

	vars = {
		custom = args[1],
		mode = 'start', -- "start", "edit", or "save"
		start_selection = 1,
		start_selections = {'type', 'timelimit', 'cleargoal', 'seed', 'start'},
		mission_type = 1,
		mission_types = {'logic', 'picture', 'speedrun', 'time'},
		time_limit = 9,
		time_limits = {'5', '10', '15', '20', '25', '30', '35', '40', '45', '50', '55', '60'},
		clear_goal = 1,
		clear_goals = {'black', 'gray', 'white', 'wild', '2x', 'bomb', 'board'},
		seed_string = '0',
		seed = 0,
		keyboard = 'seed',
		seed_old = '0',
		picture_old = 'Object',
		author_old = save.author_name ~= '' and save.author_name or 'HEXA MASTR',
		tri = 1,
		scroll_x_target = 400,
		scroll_x = 400,
		anim_modal = pd.timer.new(0, 400, 400),
		anim_powerup = pd.timer.new(700, 1, 4.99),
		anim_flash = pd.timer.new(500, 0.25, 0.75),
		save_selection = 1,
		save_selections = {'picture_name', 'author_name', 'save'},
		picture_name = 'Object',
		author_name = save.author_name ~= '' and save.author_name or 'HEXA MASTR',
		export = {},
		puzzle_exported = false,
	}
	vars.mission_command_startHandlers = {
		upButtonDown = function()
			vars.start_selection -= 1
			if vars.start_selection < 1 then vars.start_selection = #vars.start_selections end
			playsound(assets.sfx_move)
			gfx.sprite.redrawBackground()
		end,

		downButtonDown = function()
			vars.start_selection += 1
			if vars.start_selection > #vars.start_selections then vars.start_selection = 1 end
			playsound(assets.sfx_move)
			gfx.sprite.redrawBackground()
		end,

		leftButtonDown = function()
			if vars.start_selections[vars.start_selection] == 'type' then
				vars.mission_type -= 1
				if vars.mission_type < 1 then vars.mission_type = #vars.mission_types end
				playsound(assets.sfx_move)
			elseif vars.start_selections[vars.start_selection] == 'timelimit' then
				if vars.mission_types[vars.mission_type] == 'time' then
					vars.time_limit -= 1
					if vars.time_limit < 1 then vars.time_limit = #vars.time_limits end
					playsound(assets.sfx_move)
				else
					shakies()
					playsound(assets.sfx_bonk)
				end
			elseif vars.start_selections[vars.start_selection] == 'cleargoal' then
				if vars.mission_types[vars.mission_type] == 'speedrun' or vars.mission_types[vars.mission_type] == 'logic' then
					vars.clear_goal -= 1
					if vars.clear_goal < 1 then vars.clear_goal = #vars.clear_goals end
					playsound(assets.sfx_move)
				else
					shakies()
					playsound(assets.sfx_bonk)
				end
			end
			gfx.sprite.redrawBackground()
		end,

		rightButtonDown = function()
			if vars.start_selections[vars.start_selection] == 'type' then
				vars.mission_type += 1
				if vars.mission_type > #vars.mission_types then vars.mission_type = 1 end
				playsound(assets.sfx_move)
			elseif vars.start_selections[vars.start_selection] == 'timelimit' then
				if vars.mission_types[vars.mission_type] == 'time' then
					vars.time_limit += 1
					if vars.time_limit > #vars.time_limits then vars.time_limit = 1 end
					playsound(assets.sfx_move)
				else
					shakies()
					playsound(assets.sfx_bonk)
				end
			elseif vars.start_selections[vars.start_selection] == 'cleargoal' then
				if vars.mission_types[vars.mission_type] == 'speedrun' or vars.mission_types[vars.mission_type] == 'logic' then
					vars.clear_goal += 1
					if vars.clear_goal > #vars.clear_goals then vars.clear_goal = 1 end
					playsound(assets.sfx_move)
				else
					shakies()
					playsound(assets.sfx_bonk)
				end
			end
			gfx.sprite.redrawBackground()
		end,

		AButtonDown = function()
			if vars.start_selections[vars.start_selection] == 'type' then
				vars.mission_type += 1
				if vars.mission_type > #vars.mission_types then vars.mission_type = 1 end
				playsound(assets.sfx_move)
			elseif vars.start_selections[vars.start_selection] == 'timelimit' then
				if vars.mission_types[vars.mission_type] == 'time' then
					vars.time_limit += 1
					if vars.time_limit > #vars.time_limits then vars.time_limit = 1 end
					playsound(assets.sfx_move)
				else
					shakies()
					playsound(assets.sfx_bonk)
				end
			elseif vars.start_selections[vars.start_selection] == 'cleargoal' then
				if vars.mission_types[vars.mission_type] == 'speedrun' or vars.mission_types[vars.mission_type] == 'logic' then
					vars.clear_goal += 1
					if vars.clear_goal > #vars.clear_goals then vars.clear_goal = 1 end
					playsound(assets.sfx_move)
				else
					shakies()
					playsound(assets.sfx_bonk)
				end
			elseif vars.start_selections[vars.start_selection] == 'seed' then
				if vars.mission_types[vars.mission_type] == 'time' then
					pd.keyboard.show(vars.seed_string)
					vars.keyboard = 'seed'
					playsound(assets.sfx_select)
				else
					shakies()
					playsound(assets.sfx_bonk)
				end
			elseif vars.start_selections[vars.start_selection] == 'start' then
				vars.tris = {}
				if vars.mission_types[vars.mission_type] == 'time' then
					setRandomSeed(vars.seed)
					local newcolor
					local newpowerup
					for i = 1, 19 do
						newcolor, newpowerup = self:randomizetri()
						vars.tris[i] = {index = i, color = newcolor, powerup = newpowerup}
					end
				else
					for i = 1, 19 do
						vars.tris[i] = {index = i, color = 'white', powerup = ''}
					end
				end
				vars.tri = 1
				vars.mode = 'edit'
				pd.inputHandlers.pop()
				pd.inputHandlers.push(vars.mission_command_editHandlers)
				vars.scroll_x_target = 800
				gfx.sprite.setAlwaysRedraw(true)
				playsound(assets.sfx_select)
				if mission_command:check_validity() then
					sprites.error.x_target = -355
				elseif sprites.error.x_target ~= 5 then
					sprites.error.x_target = 5
					playsound(assets.sfx_bonk)
				end
			end
			gfx.sprite.redrawBackground()
		end,

		BButtonDown = function()
			playsound(assets.sfx_back)
			scenemanager:transitionscene(missions, vars.custom)
			fademusic()
		end,
	}
	vars.mission_command_editHandlers = {
		leftButtonDown = function()
			if vars.mission_types[vars.mission_type] ~= 'time' then
				if vars.tri == 1 then
					shakies()
					playsound(assets.sfx_bonk)
				elseif vars.tri == 2 then
					vars.tri = 1
					playsound(assets.sfx_move2)
				elseif vars.tri == 3 then
					vars.tri = 2
					playsound(assets.sfx_move2)
				elseif vars.tri == 4 then
					vars.tri = 3
					playsound(assets.sfx_move2)
				elseif vars.tri == 5 then
					vars.tri = 4
					playsound(assets.sfx_move2)
				elseif vars.tri == 6 then
					shakies()
					playsound(assets.sfx_bonk)
				elseif vars.tri == 7 then
					vars.tri = 6
					playsound(assets.sfx_move2)
				elseif vars.tri == 8 then
					vars.tri = 7
					playsound(assets.sfx_move2)
				elseif vars.tri == 9 then
					vars.tri = 8
					playsound(assets.sfx_move2)
				elseif vars.tri == 10 then
					vars.tri = 9
					playsound(assets.sfx_move2)
				elseif vars.tri == 11 then
					vars.tri = 10
					playsound(assets.sfx_move2)
				elseif vars.tri == 12 then
					vars.tri = 11
					playsound(assets.sfx_move2)
				elseif vars.tri == 13 then
					shakies()
					playsound(assets.sfx_bonk)
				elseif vars.tri == 14 then
					vars.tri = 13
					playsound(assets.sfx_move2)
				elseif vars.tri == 15 then
					vars.tri = 14
					playsound(assets.sfx_move2)
				elseif vars.tri == 16 then
					vars.tri = 15
					playsound(assets.sfx_move2)
				elseif vars.tri == 17 then
					vars.tri = 16
					playsound(assets.sfx_move2)
				elseif vars.tri == 18 then
					vars.tri = 17
					playsound(assets.sfx_move2)
				elseif vars.tri == 19 then
					vars.tri = 18
					playsound(assets.sfx_move2)
				end
			end
		end,

		rightButtonDown = function()
			if vars.mission_types[vars.mission_type] ~= 'time' then
				if vars.tri == 1 then
					vars.tri = 2
					playsound(assets.sfx_move2)
				elseif vars.tri == 2 then
					vars.tri = 3
					playsound(assets.sfx_move2)
				elseif vars.tri == 3 then
					vars.tri = 4
					playsound(assets.sfx_move2)
				elseif vars.tri == 4 then
					vars.tri = 5
					playsound(assets.sfx_move2)
				elseif vars.tri == 5 then
					shakies()
					playsound(assets.sfx_bonk)
				elseif vars.tri == 6 then
					vars.tri = 7
					playsound(assets.sfx_move2)
				elseif vars.tri == 7 then
					vars.tri = 8
					playsound(assets.sfx_move2)
				elseif vars.tri == 8 then
					vars.tri = 9
					playsound(assets.sfx_move2)
				elseif vars.tri == 9 then
					vars.tri = 10
					playsound(assets.sfx_move2)
				elseif vars.tri == 10 then
					vars.tri = 11
					playsound(assets.sfx_move2)
				elseif vars.tri == 11 then
					vars.tri = 12
					playsound(assets.sfx_move2)
				elseif vars.tri == 12 then
					shakies()
					playsound(assets.sfx_bonk)
				elseif vars.tri == 13 then
					vars.tri = 14
					playsound(assets.sfx_move2)
				elseif vars.tri == 14 then
					vars.tri = 15
					playsound(assets.sfx_move2)
				elseif vars.tri == 15 then
					vars.tri = 16
					playsound(assets.sfx_move2)
				elseif vars.tri == 16 then
					vars.tri = 17
					playsound(assets.sfx_move2)
				elseif vars.tri == 17 then
					vars.tri = 18
					playsound(assets.sfx_move2)
				elseif vars.tri == 18 then
					vars.tri = 19
					playsound(assets.sfx_move2)
				elseif vars.tri == 19 then
					shakies()
					playsound(assets.sfx_bonk)
				end
			end
		end,

		upButtonDown = function()
			if vars.mission_types[vars.mission_type] ~= 'time' then
				if vars.tri <= 5 then
					shakies_y()
					playsound(assets.sfx_bonk)
				elseif vars.tri == 6 then
					vars.tri = 1
					playsound(assets.sfx_move2)
				elseif vars.tri == 7 then
					vars.tri = 1
					playsound(assets.sfx_move2)
				elseif vars.tri == 8 then
					vars.tri = 2
					playsound(assets.sfx_move2)
				elseif vars.tri == 9 then
					vars.tri = 3
					playsound(assets.sfx_move2)
				elseif vars.tri == 10 then
					vars.tri = 4
					playsound(assets.sfx_move2)
				elseif vars.tri == 11 then
					vars.tri = 5
					playsound(assets.sfx_move2)
				elseif vars.tri == 12 then
					vars.tri = 5
					playsound(assets.sfx_move2)
				elseif vars.tri == 13 then
					vars.tri = 6
					playsound(assets.sfx_move2)
				elseif vars.tri == 14 then
					vars.tri = 7
					playsound(assets.sfx_move2)
				elseif vars.tri == 15 then
					vars.tri = 8
					playsound(assets.sfx_move2)
				elseif vars.tri == 16 then
					vars.tri = 9
					playsound(assets.sfx_move2)
				elseif vars.tri == 17 then
					vars.tri = 10
					playsound(assets.sfx_move2)
				elseif vars.tri == 18 then
					vars.tri = 11
					playsound(assets.sfx_move2)
				elseif vars.tri == 19 then
					vars.tri = 12
					playsound(assets.sfx_move2)
				end
			end
		end,

		downButtonDown = function()
			if vars.mission_types[vars.mission_type] ~= 'time' then
				if vars.tri == 1 then
					vars.tri = 7
					playsound(assets.sfx_move2)
				elseif vars.tri == 2 then
					vars.tri = 8
					playsound(assets.sfx_move2)
				elseif vars.tri == 3 then
					vars.tri = 9
					playsound(assets.sfx_move2)
				elseif vars.tri == 4 then
					vars.tri = 10
					playsound(assets.sfx_move2)
				elseif vars.tri == 5 then
					vars.tri = 11
					playsound(assets.sfx_move2)
				elseif vars.tri == 6 then
					vars.tri = 13
					playsound(assets.sfx_move2)
				elseif vars.tri == 7 then
					vars.tri = 14
					playsound(assets.sfx_move2)
				elseif vars.tri == 8 then
					vars.tri = 15
					playsound(assets.sfx_move2)
				elseif vars.tri == 9 then
					vars.tri = 16
					playsound(assets.sfx_move2)
				elseif vars.tri == 10 then
					vars.tri = 17
					playsound(assets.sfx_move2)
				elseif vars.tri == 11 then
					vars.tri = 18
					playsound(assets.sfx_move2)
				elseif vars.tri == 12 then
					vars.tri = 19
					playsound(assets.sfx_move2)
				elseif vars.tri >= 13 then
					shakies_y()
					playsound(assets.sfx_bonk)
				end
			end
		end,

		AButtonDown = function()
			if vars.mission_types[vars.mission_type] ~= 'time' then
				local powerup = false
				local nocolor = true
				if vars.mission_types[vars.mission_type] == 'picture' then
					nocolor = false
				else
					powerup = true
				end
				sprites.selector:open(vars.tris[vars.tri], powerup, nocolor)
				playsound(assets.sfx_select)
			end
		end,
	}
	vars.mission_command_saveHandlers = {
		upButtonDown = function()
			vars.save_selection -= 1
			if vars.save_selection < 1 then vars.save_selection = #vars.save_selections end
			playsound(assets.sfx_move)
			gfx.sprite.redrawBackground()
		end,

		downButtonDown = function()
			vars.save_selection += 1
			if vars.save_selection > #vars.save_selections then vars.save_selection = 1 end
			playsound(assets.sfx_move)
			gfx.sprite.redrawBackground()
		end,

		AButtonDown = function()
			if vars.save_selections[vars.save_selection] == 'picture_name' then
				if vars.mission_types[vars.mission_type] == 'picture' then
					pd.keyboard.show(vars.picture_name)
					vars.keyboard = 'picture'
					playsound(assets.sfx_select)
				else
					shakies()
					playsound(assets.sfx_bonk)
				end
			elseif vars.save_selections[vars.save_selection] == 'author_name' then
				pd.keyboard.show(vars.author_name)
				vars.keyboard = 'author'
				playsound(assets.sfx_select)
			elseif vars.save_selections[vars.save_selection] == 'save' then
				mission_command:save()
				playsound(assets.sfx_select)
			end
			gfx.sprite.redrawBackground()
		end,

		BButtonDown = function()
			vars.mode = 'edit'
			pd.inputHandlers.pop()
			pd.inputHandlers.push(vars.mission_command_editHandlers)
			vars.scroll_x_target = 800
			gfx.sprite.setAlwaysRedraw(true)
			playsound(assets.sfx_back)
		end,
	}
	vars.mission_command_selectorHandlers = {
		leftButtonDown = function()
			if sprites.selector.rack == 1 then
				if sprites.selector.rack2selection ~= 4 then
					sprites.selector.rack1selection -= 1
					if sprites.selector.rack1selection < 1 then
						sprites.selector.rack1selection = 1
						shakies()
						playsound(assets.sfx_bonk)
					else
						playsound(assets.sfx_move)
					end
				else
					shakies()
					playsound(assets.sfx_bonk)
				end
			else
				if not (sprites.selector.show_no_color and sprites.selector.rack1selection == 1) then
					sprites.selector.rack2selection -= 1
					if sprites.selector.rack2selection < 1 then
						sprites.selector.rack2selection = 1
						shakies()
						playsound(assets.sfx_bonk)
					else
						playsound(assets.sfx_move)
					end
				else
					shakies()
					playsound(assets.sfx_bonk)
				end
			end
		end,

		rightButtonDown = function()
			if sprites.selector.rack == 1 then
				if sprites.selector.rack2selection ~= 4 then
					sprites.selector.rack1selection += 1
					local limit = 3
					if sprites.selector.show_no_color then
						limit = 4
					end
					if sprites.selector.rack1selection > limit then
						sprites.selector.rack1selection = limit
						shakies()
						playsound(assets.sfx_bonk)
					else
						playsound(assets.sfx_move)
					end
				else
					shakies()
					playsound(assets.sfx_bonk)
				end
			else
				if not (sprites.selector.show_no_color and sprites.selector.rack1selection == 1) then
					sprites.selector.rack2selection += 1
					if sprites.selector.rack2selection > 4 then
						sprites.selector.rack2selection = 4
						shakies()
						playsound(assets.sfx_bonk)
					else
						playsound(assets.sfx_move)
					end
				else
					shakies()
					playsound(assets.sfx_bonk)
				end
			end
		end,

		upButtonDown = function()
			if sprites.selector.rack ~= 1 then
				sprites.selector.rack = 1
				playsound(assets.sfx_move)
			else
				shakies_y()
				playsound(assets.sfx_bonk)
			end
		end,

		downButtonDown = function()
			if sprites.selector.show_powerup and sprites.selector.rack == 1 then
				sprites.selector.rack = 2
				playsound(assets.sfx_move)
			else
				shakies_y()
				playsound(assets.sfx_bonk)
			end
		end,

		AButtonDown = function()
			sprites.selector:close(true)
			playsound(assets.sfx_select)
			if mission_command:check_validity() then
				sprites.error.x_target = -355
			elseif sprites.error.x_target ~= 5 then
				sprites.error.x_target = 5
				playsound(assets.sfx_bonk)
			end
		end,

		BButtonDown = function()
			sprites.selector:close(false)
			playsound(assets.sfx_back)
			if mission_command:check_validity() then
				sprites.error.x_target = -355
			elseif sprites.error.x_target ~= 5 then
				sprites.error.x_target = 5
				playsound(assets.sfx_bonk)
			end
		end,
	}
	vars.mission_command_doneHandlers = {
		AButtonDown = function()
			scenemanager:transitionscene(missions, vars.custom)
			fademusic()
		end,

		BButtonDown = function()
			scenemanager:transitionscene(missions, vars.custom)
			fademusic()
		end,
	}
	pd.timer.performAfterDelay(scenemanager.transitiontime, function()
		gfx.sprite.setAlwaysRedraw(false)
		pd.inputHandlers.push(vars.mission_command_startHandlers)
	end)

	vars.anim_powerup.repeats = true
	vars.anim_modal.discardOnCompletion = false
	vars.anim_flash.repeats = true
	vars.anim_flash.reverses = true

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		x += pd.keyboard.left() - vars.scroll_x
		assets.white:draw(0 + x, 0)
		assets.white:draw(400 + x, 0)
		assets.white:draw(800 + x, 0)
		gfx.setLineWidth(2)
		gfx.setDitherPattern(0.75, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRect(0 + x, 0, 1200, 33)
		assets.full_circle_outline:drawText(text('mission_command'), 10 + x, 8)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawLine(0 + x, 33, 1200, 33)

		assets.full_circle:drawText(text('mission_type'), 50 + x, 50)
		gfx.drawRect(195 + x, 47, 155, 20)
		assets.full_circle:drawTextAligned(text('command_' .. vars.mission_types[vars.mission_type]), 273 + x, 50, kTextAlignment.center)
		assets.half_circle:drawTextAligned(text('command_' .. vars.mission_types[vars.mission_type] .. '_d'), 200 + x, 70, kTextAlignment.center)

		assets.full_circle:drawText(text('time_limit'), 50 + x, 93)
		assets.half_circle:drawText('(' .. text('command_time') .. ')', 50 + x, 107)
		gfx.drawRect(195 + x, 97, 155, 20)
		assets.full_circle:drawTextAligned(vars.time_limits[vars.time_limit] .. text('secs'), 273 + x, 100, kTextAlignment.center)

		assets.full_circle:drawText(text('clear_goal'), 50 + x, 123)
		assets.half_circle:drawText('(' .. text('command_logic') .. '/' .. text('command_speedrun') .. ')', 50 + x, 137)
		gfx.drawRect(195 + x, 127, 155, 20)
		assets.full_circle:drawTextAligned(text('command_' .. vars.clear_goals[vars.clear_goal]), 273 + x, 130, kTextAlignment.center)

		assets.full_circle:drawText(text('number_seed'), 50 + x, 153)
		assets.half_circle:drawText('(' .. text('command_time') .. ')', 50 + x, 167)
		gfx.drawRect(195 + x, 157, 155, 20)
		assets.full_circle:drawTextAligned(vars.seed_string or '0', 273 + x, 160, kTextAlignment.center)

		if vars.start_selection == 1 then
			assets.mcsel:draw(0 + x, 46)
			assets.mcsel:draw(389 + x, 46, "flipX")
		elseif vars.start_selection == 2 then
			assets.mcsel:draw(0 + x, 96)
			assets.mcsel:draw(389 + x, 96, "flipX")
		elseif vars.start_selection == 3 then
			assets.mcsel:draw(0 + x, 126)
			assets.mcsel:draw(389 + x, 126, "flipX")
		elseif vars.start_selection == 4 then
			assets.mcsel:draw(0 + x, 156)
			assets.mcsel:draw(389 + x, 156, "flipX")
		elseif vars.start_selection == 5 then
			assets.mcsel:draw(0 + x, 192)
			assets.mcsel:draw(389 + x, 192, "flipX")
		end

		gfx.setColor(gfx.kColorWhite)
		gfx.setDitherPattern(0.50, gfx.image.kDitherTypeBayer4x4)

		if vars.mission_types[vars.mission_type] ~= 'time' then
			gfx.fillRect(40 + x, 93, 320, 30)
		end
		if vars.mission_types[vars.mission_type] ~= 'speedrun' and vars.mission_types[vars.mission_type] ~= 'logic' then
			gfx.fillRect(40 + x, 123, 320, 30)
		end
		if vars.mission_types[vars.mission_type] ~= 'time' then
			gfx.fillRect(40 + x, 153, 320, 30)
		end

		gfx.setColor(gfx.kColorBlack)

		gfx.drawRect(100 + x, 190, 200, 25)
		assets.full_circle:drawTextAligned(text('start_editing'), 200 + x, 195, kTextAlignment.center)

		assets.half_circle:drawText(text('move') .. ' ' .. text('scrolls') .. ' ' .. text('back'), 10 + x, 220)

		gfx.setLineWidth(3)

		if vars.mission_types[vars.mission_type] == 'picture' then
			if sprites.error.x < -200 then assets.full_circle_outline:drawText(text('create_picture'), 410 + x, 8) end
			assets.half_circle:drawText(text('move') .. ' ' .. text('select') .. ' ' .. text('menu_save'), 410 + x, 220)
		elseif vars.mission_types[vars.mission_type] == 'time' then
			if sprites.error.x < -200 then assets.full_circle_outline:drawText(text('review_seed'), 410 + x, 8) end
			assets.half_circle:drawText(text('menu_save'), 410 + x, 220)
		else
			if sprites.error.x < -200 then assets.full_circle_outline:drawText(text('create_start'), 410 + x, 8) end
			assets.half_circle:drawText(text('move') .. ' ' .. text('select') .. ' ' .. text('menu_save'), 410 + x, 220)
		end

		assets.ui:draw(400 + x, 0)
		if vars.tris ~= nil then
			for i = 1, 19 do
				mission_command:tri(tris_x[i] + 400 + x, tris_y[i], tris_flip[i], vars.tris[i].color, vars.tris[i].powerup)
			end
			local offset = 0
			if tris_flip[vars.tri] then
				offset += 8
			else
				offset -= 8
			end
			if vars.mission_types[vars.mission_type] ~= 'time' then
				if vars.tris[vars.tri].color == 'black' then
					gfx.setColor(gfx.kColorWhite)
				end
				gfx.drawCircleAtPoint(tris_x[vars.tri] + 400 + x, tris_y[vars.tri] + offset, 10)
				gfx.setColor(gfx.kColorBlack)
			end
		end

		gfx.setLineWidth(2)

		assets.full_circle_outline:drawText(text('export_puzzle'), 810 + x, 8)

		assets.full_circle:drawText(text('mission_type'), 850 + x, 50)
		assets.full_circle:drawTextAligned(text('command_' .. vars.mission_types[vars.mission_type]), 1150 + x, 50, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('command_' .. vars.mission_types[vars.mission_type] .. '_d'), 1000 + x, 70, kTextAlignment.center)

		assets.full_circle:drawText(text('picture_name'), 850 + x, 93)
		assets.half_circle:drawText('(' .. text('command_picture') .. ')', 850 + x, 107)
		gfx.drawRect(995 + x, 97, 155, 20)
		assets.full_circle:drawTextAligned(vars.picture_name, 1073 + x, 100, kTextAlignment.center)

		assets.full_circle:drawText(text('author_name'), 850 + x, 130)
		gfx.drawRect(995 + x, 127, 155, 20)
		assets.full_circle:drawTextAligned(vars.author_name, 1073 + x, 130, kTextAlignment.center)

		gfx.drawRect(900 + x, 175, 200, 25)
		assets.full_circle:drawTextAligned(text('export_puzzle'), 1000 + x, 180, kTextAlignment.center)

		if vars.save_selection == 1 then
			assets.mcsel:draw(800 + x, 96)
			assets.mcsel:draw(1189 + x, 96, "flipX")
		elseif vars.save_selection == 2 then
			assets.mcsel:draw(800 + x, 126)
			assets.mcsel:draw(1189 + x, 126, "flipX")
		elseif vars.save_selection == 3 then
			assets.mcsel:draw(800 + x, 176)
			assets.mcsel:draw(1189 + x, 176, "flipX")
		end

		gfx.setColor(gfx.kColorWhite)
		gfx.setDitherPattern(0.50, gfx.image.kDitherTypeBayer4x4)

		if vars.mission_types[vars.mission_type] ~= 'picture' then
			gfx.fillRect(840 + x, 93, 320, 30)
		end

		gfx.setColor(gfx.kColorBlack)

		assets.half_circle:drawText(text('move') .. ' ' .. text('scrolls') .. ' ' .. text('back'), 810 + x, 220)

		gfx.setLineWidth(3)

		if vars.puzzle_exported then
			assets.export_complete:draw(800 + x, 0)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			assets.full_circle:drawTextAligned(text('savedto') .. '\n' .. text('missionspath1') .. pd.metadata.bundleID .. text('missionspath2') .. tostring(vars.export.mission) .. text('missionspath3'), 1000 + x, 128, kTextAlignment.center)
			assets.half_circle:drawTextAligned(text('shareit') .. text('nocustommissions_4'), 1000 + x, 187, kTextAlignment.center)
			gfx.setImageDrawMode(gfx.kDrawModeCopy)
			assets.half_circle:drawText(text('back'), 810 + x, 220)
		end
	end)

	pd.keyboard.keyboardWillHideCallback = function(ok)
		if save.sfx then
			if ok then
				assets.sfx_select:play()
			else
				assets.sfx_back:play()
			end
		end
		if vars.keyboard == 'seed' then
			if not ok then
				pd.keyboard.text = vars.seed_old
				vars.seed_string = vars.seed_old
				if vars.seed_string ~= tonumber(vars.seed_string) then
					vars.seed_string:gsub("%D+", ""):sub(1, 10)
				end
				vars.seed = tonumber(vars.seed_string)
			else
				vars.seed_old = vars.seed_string
				vars.seed = tonumber(vars.seed_string)
			end
			if pd.keyboard.text == '' then
				pd.keyboard.text = '0'
				vars.seed_string = '0'
				vars.seed = 0
			end
		elseif vars.keyboard == 'picture' then
			if not ok then
				pd.keyboard.text = vars.picture_old
				vars.picture = pd.keyboard.text
			else
				vars.picture_old = pd.keyboard.text
			end
			if pd.keyboard.text == '' then
				pd.keyboard.text = 'Object'
				vars.picture_name = pd.keyboard.text
			end
		elseif vars.keyboard == 'author' then
			if not ok then
				pd.keyboard.text = vars.author_old
				vars.author = pd.keyboard.text
			else
				vars.author_old = pd.keyboard.text
			end
			if pd.keyboard.text == '' then
				pd.keyboard.text = save.author_name ~= '' and save.author_name or 'HEXA MASTR'
				vars.author_name = pd.keyboard.text
			end
		end
	end

	pd.keyboard.keyboardDidHideCallback = function()
		gfx.sprite.redrawBackground()
	end

	pd.keyboard.textChangedCallback = function()
		if vars.seed_string == nil then vars.seed_string = '0' end
		if vars.keyboard == 'seed' then
			if pd.keyboard.text ~= tonumber(pd.keyboard.text) then
				vars.seed_string = tonumber(pd.keyboard.text:gsub("%D+", ""):sub(1, 9))
			else
				vars.seed_string = tonumber(pd.keyboard.text)
			end
			pd.keyboard.text = tostring(vars.seed_string)
		elseif vars.keyboard == 'picture' then
			vars.picture_name = string.sub(pd.keyboard.text, 1, 10)
			pd.keyboard.text = vars.picture_name
		elseif vars.keyboard == 'author' then
			vars.author_name = string.sub(pd.keyboard.text, 1, 10)
			pd.keyboard.text = vars.author_name
		end
	end

	class('selector', _, classes).extends(gfx.sprite)
	function classes.selector:init()
		self:setSize(306, 169)
		self:moveTo(200, 120)
		self.opened = false
		self.show_powerup = true
		self.show_no_color = true
		self.rack = 1
		self.rack1selection = 1
		self.rack2selection = 1
		self:add()
	end
	function classes.selector:open(tri, show_powerup, show_no_color)
		self.show_powerup = show_powerup
		self.show_no_color = show_no_color
		if self.show_powerup then
			if tri.powerup == '' then
				self.rack2selection = 1
			elseif tri.powerup == 'double' then
				self.rack2selection = 2
			elseif tri.powerup == 'bomb' then
				self.rack2selection = 3
			elseif tri.powerup == 'wild' then
				self.rack2selection = 4
			else
				self.rack2selection = 1
			end
		end
		if self.show_no_color then
			if tri.color == 'none' then
				self.rack1selection = 1
			elseif tri.color == 'white' then
				self.rack1selection = 2
			elseif tri.color == 'gray' then
				self.rack1selection = 3
			elseif tri.color == 'black' then
				self.rack1selection = 4
			else
				self.rack1selection = 1
			end
		else
			if tri.color == 'white' then
				self.rack1selection = 1
			elseif tri.color == 'gray' then
				self.rack1selection = 2
			elseif tri.color == 'black' then
				self.rack1selection = 3
			else
				self.rack1selection = 1
			end
		end
		self.rack = 1
		vars.anim_modal:resetnew(300, 400, 120, pd.easingFunctions.outBack)
		pd.inputHandlers.pop()
		pd.timer.performAfterDelay(300, function()
			self.opened = true
			pd.inputHandlers.push(vars.mission_command_selectorHandlers)
		end)
	end
	function classes.selector:close(save)
		if save then
			if self.show_no_color then
				if self.rack1selection == 1 then
					vars.tris[vars.tri].color = 'none'
				elseif self.rack1selection == 2 then
					vars.tris[vars.tri].color = 'white'
				elseif self.rack1selection == 3 then
					vars.tris[vars.tri].color = 'gray'
				elseif self.rack1selection == 4 then
					vars.tris[vars.tri].color = 'black'
				end
			else
				if self.rack1selection == 1 then
					vars.tris[vars.tri].color = 'white'
				elseif self.rack1selection == 2 then
					vars.tris[vars.tri].color = 'gray'
				elseif self.rack1selection == 3 then
					vars.tris[vars.tri].color = 'black'
				end
			end
			if self.show_powerup then
				if (self.show_no_color and self.rack1selection == 1) then
					vars.tris[vars.tri].powerup = ''
				else
					if self.rack2selection == 1 then
						vars.tris[vars.tri].powerup = ''
					elseif self.rack2selection == 2 then
						vars.tris[vars.tri].powerup = 'double'
					elseif self.rack2selection == 3 then
						vars.tris[vars.tri].powerup = 'bomb'
					elseif self.rack2selection == 4 then
						vars.tris[vars.tri].powerup = 'wild'
					end
				end
			end
		end
		vars.anim_modal:resetnew(300, 120, 400, pd.easingFunctions.inBack)
		pd.inputHandlers.pop()
		pd.timer.performAfterDelay(300, function()
			self.opened = false
			pd.inputHandlers.push(vars['mission_command_' .. vars.mode .. 'Handlers'])
		end)
	end
	function classes.selector:update()
		self:moveTo(200, vars.anim_modal.value)
	end
	function classes.selector:draw()
		assets.modal:draw(0, 0)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		if self.show_powerup then
			assets.full_circle:drawTextAligned(text('choose_color'), 153, 12, kTextAlignment.center)
			assets.full_circle:drawTextAligned(text('choose_powerup'), 153, 90, kTextAlignment.center)
		else
			assets.full_circle:drawTextAligned(text('choose_color'), 153, 46, kTextAlignment.center)
		end
		if self.show_powerup then
			gfx.setColor(gfx.kColorXOR)
			if self.rack == 1 then
				gfx.fillRect(50, 11, 200, 16)
			else
				gfx.fillRect(50, 90, 200, 16)
			end
		end
		gfx.setColor(gfx.kColorWhite)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		gfx.setLineWidth(2)
		if self.show_powerup then
			assets.x:draw(50, 116)
			if flash then
				if assets['powerup_double_up'] ~= nil then assets['powerup_double_up'][1]:draw(91, 104) end
				if assets['powerup_bomb_up'] ~= nil then assets['powerup_bomb_up'][1]:draw(148, 102) end
				gfx.setClipRect(155 + 55, 112, 41, 41)
				if assets['powerup_wild_up'] ~= nil then assets['powerup_wild_up'][1]:draw(203, 104) end
				gfx.clearClipRect()
			else
				if assets['powerup_double_up'] ~= nil then assets['powerup_double_up'][floor(vars.anim_powerup.value)]:draw(91, 104) end
				if assets['powerup_bomb_up'] ~= nil then assets['powerup_bomb_up'][floor(vars.anim_powerup.value)]:draw(148, 102) end
				gfx.setClipRect(155 + 55, 112, 41, 41)
				if assets['powerup_wild_up'] ~= nil then assets['powerup_wild_up'][floor(vars.anim_powerup.value)]:draw(203, 104) end
				gfx.clearClipRect()
			end
			if self.show_no_color then
				assets.x:draw(50, 38)
				gfx.fillRoundRect(156 - 55, 35, 39, 39, 4)
				gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer2x2)
				gfx.fillRoundRect(156, 35, 39, 39, 4)
				gfx.setLineWidth(1)
				gfx.drawRoundRect(156 + 55, 35, 39, 39, 4)
			else
				gfx.fillRoundRect(156 - 77, 35, 39, 39, 4)
				gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer2x2)
				gfx.fillRoundRect(156 - 22, 35, 39, 39, 4)
				gfx.setLineWidth(1)
				gfx.drawRoundRect(156 + 33, 35, 39, 39, 4)
			end

			gfx.setLineWidth(3)
			gfx.setColor(gfx.kColorBlack)
			gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
			if self.rack2selection == 4 then
				gfx.fillRect(30, 31, 240, 50)
			else
				if self.show_no_color and self.rack1selection == 1 then
					gfx.fillRect(30, 110, 240, 50)
				end
			end

			gfx.setColor(gfx.kColorWhite)
			gfx.setDitherPattern(vars.anim_flash.value, gfx.image.kDitherTypeBayer2x2)
			if self.rack2selection ~= 4 then
				if self.show_no_color then
					gfx.drawRoundRect(153 - 165 + (55 * self.rack1selection), 32, 45, 45, 7)
				else
					gfx.drawRoundRect(153 - 132 + (55 * self.rack1selection), 32, 45, 45, 7)
				end
			end
			if not (self.show_no_color and self.rack1selection == 1) then
				gfx.drawRoundRect(153 - 165 + (55 * self.rack2selection), 110, 45, 45, 7)
			end
			gfx.setColor(gfx.kColorBlack)
		else
			if self.show_no_color then
				assets.x:draw(50, 78)
				gfx.fillRoundRect(156 - 55, 75, 39, 39, 4)
				gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer2x2)
				gfx.fillRoundRect(156, 75, 39, 39, 4)
				gfx.setLineWidth(1)
				gfx.drawRoundRect(156 + 55, 75, 39, 39, 4)
				gfx.setColor(gfx.kColorBlack)
			else
				gfx.fillRoundRect(156 - 77, 75, 39, 39, 4)
				gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer2x2)
				gfx.fillRoundRect(156 - 22, 75, 39, 39, 4)
				gfx.setLineWidth(1)
				gfx.drawRoundRect(156 + 33, 75, 39, 39, 4)
				gfx.setColor(gfx.kColorBlack)
			end

			gfx.setLineWidth(3)
			gfx.setColor(gfx.kColorWhite)
			gfx.setDitherPattern(vars.anim_flash.value, gfx.image.kDitherTypeBayer2x2)
			if self.show_no_color then
				gfx.drawRoundRect(153 - 165 + (55 * self.rack1selection), 72, 45, 45, 7)
			else
				gfx.drawRoundRect(153 - 132 + (55 * self.rack1selection), 72, 45, 45, 7)
			end
			gfx.setColor(gfx.kColorBlack)
		end
		gfx.setLineWidth(3)
	end

	class('error', _, classes).extends(gfx.sprite)
	function classes.error:init()
		self:setSize(350, 31)
		self:add()
		self:setCenter(0, 0)
		self.x_target = -355
		self:moveTo(self.x_target, 0)
	end
	function classes.error:update()
		self:moveBy((self.x_target - self.x) * 0.4, 0)
	end
	function classes.error:draw(x, y, width, height)
		--gfx.setLineWidth(2)
		--gfx.setColor(gfx.kColorWhite)
		--gfx.fillRoundRect(x, y + 2, width, height - 2, 7)
		--gfx.setColor(gfx.kColorBlack)
		--gfx.drawRoundRect(x + 1, y + 2, width - 2, height - 3, 7)
		--gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer2x2)
		--gfx.fillRoundRect(x, y + 2, width, height - 2, 7)
		--gfx.setColor(gfx.kColorBlack)
		--gfx.setLineWidth(3)
		assets.error:draw(5, 3)
		assets.full_circle_outline:drawText(text('command_error'), 36, 8)
	end

	sprites.selector = classes.selector()
	sprites.error = classes.error()

	newmusic('audio/music/zen' .. randInt(1, 2), true)
	self:add()
end

function mission_command:tri(x, y, up, color, powerup)
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
		else
			if up then
				if assets['powerup_' .. powerup .. '_up'] ~= nil then assets['powerup_' .. powerup .. '_up'][floor(vars.anim_powerup.value)]:draw(x - 28, y - 23) end
			else
				if assets['powerup_' .. powerup .. '_down'] ~= nil then assets['powerup_' .. powerup .. '_down'][floor(vars.anim_powerup.value)]:draw(x - 28, y - 23) end
			end
		end
	end
end

function mission_command:randomizetri()
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
	if randompowerup == 1 or randompowerup == 2 or randompowerup == 3 then
		powerup = "double"
	elseif randompowerup == 4 then
		powerup = "bomb"
	elseif randompowerup == 5 then
		powerup = "wild"
	else
		powerup = ""
	end
	return color, powerup
end

function mission_command:save()
	local epoch = pd.getSecondsSinceEpoch()
	if vars.mission_types[vars.mission_type] == 'picture' then
		vars.export.mission = epoch
		vars.export.type = 'picture'
		vars.export.goal = deepcopy(vars.tris)
		vars.export.start = deepcopy(vars.tris)
		shuffle(vars.export.start)
		for i = 1, 19 do
			vars.export.start[i].index = i
		end
		vars.export.name = vars.picture_name
		vars.export.author = vars.author_name
	elseif vars.mission_types[vars.mission_type] == 'time' then
		vars.export.mission = epoch
		vars.export.type = 'time'
		vars.export.seed = vars.seed
		vars.export.modifier = tonumber(vars.time_limits[vars.time_limit])
		vars.export.author = vars.author_name
	elseif vars.mission_types[vars.mission_type] == 'speedrun' then
		vars.export.mission = epoch
		vars.export.type = 'speedrun'
		vars.export.modifier = vars.clear_goals[vars.clear_goal]
		vars.export.start = vars.tris
		vars.export.author = vars.author_name
	elseif vars.mission_types[vars.mission_type] == 'logic' then
		vars.export.mission = epoch
		vars.export.type = 'logic'
		vars.export.modifier = vars.clear_goals[vars.clear_goal]
		vars.export.start = vars.tris
		vars.export.author = vars.author_name
	end
	pd.datastore.write(vars.export, 'missions/' .. tostring(epoch))
	save.exported_mission = true
	vars.puzzle_exported = true
	updatecheevos()
	achievements.save()
	pd.inputHandlers.pop()
	pd.inputHandlers.push(vars.mission_command_doneHandlers)
	save.author_name = vars.author_name
end

-- Shuffly code from https://gist.github.com/Uradamus/10323382
function shuffle(tbl)
  for i = #tbl, 2, -1 do
	local j = randInt(1, i)
	tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

function mission_command:check_validity()
	if vars.mission_types[vars.mission_type] == 'logic' or vars.mission_types[vars.mission_type] == 'speedrun' then
		local black_tiles = 0
		local gray_tiles = 0
		local white_tiles = 0
		local wild_tiles = 0
		local double_black_tiles = 0
		local double_gray_tiles = 0
		local double_white_tiles = 0
		local bomb_black_tiles = 0
		local bomb_gray_tiles = 0
		local bomb_white_tiles = 0
		for i = 1, 19 do
			local tri = vars.tris[i]
			if tri.color == 'black' then
				black_tiles += 1
			elseif tri.color == 'gray' then
				gray_tiles += 1
			elseif tri.color == 'white' then
				white_tiles += 1
			end
			if tri.powerup == 'wild' then
				wild_tiles += 1
			elseif tri.powerup == 'double' then
				if tri.color == 'black' then
					double_black_tiles += 1
				elseif tri.color == 'gray' then
					double_gray_tiles += 1
				elseif tri.color == 'white' then
					double_white_tiles += 1
				end
			elseif tri.powerup == 'bomb' then
				if tri.color == 'black' then
					bomb_black_tiles += 1
				elseif tri.color == 'gray' then
					bomb_gray_tiles += 1
				elseif tri.color == 'white' then
					bomb_white_tiles += 1
				end
			end
		end
		if vars.clear_goals[vars.clear_goal] == 'black' then
			local exportable = false
			if black_tiles > 0 and ((black_tiles % 6 == 0) or ((black_tiles + wild_tiles) % 6 == 0)) then
				exportable = true
			end
			if bomb_black_tiles > 0 and ((black_tiles >= 6) or ((black_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if bomb_gray_tiles > 0 and ((gray_tiles >= 6) or ((gray_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if bomb_white_tiles > 0 and ((white_tiles >= 6) or ((white_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if black_tiles == 0 then
				exportable = false
			end
			return exportable
		elseif vars.clear_goals[vars.clear_goal] == 'gray' then
			local exportable = false
			if gray_tiles > 0 and ((gray_tiles % 6 == 0) or ((gray_tiles + wild_tiles) % 6 == 0)) then
				exportable = true
			end
			if bomb_black_tiles > 0 and ((black_tiles >= 6) or ((black_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if bomb_gray_tiles > 0 and ((gray_tiles >= 6) or ((gray_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if bomb_white_tiles > 0 and ((white_tiles >= 6) or ((white_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if gray_tiles == 0 then
				exportable = false
			end
			return exportable
		elseif vars.clear_goals[vars.clear_goal] == 'white' then
			local exportable = false
			if white_tiles > 0 and ((white_tiles % 6 == 0) or ((white_tiles + wild_tiles) % 6 == 0)) then
				exportable = true
			end
			if bomb_black_tiles > 0 and ((black_tiles >= 6) or ((black_tiles + wild_tiles) % 6 == 0)) then
				exportable = true
			end
			if bomb_gray_tiles > 0 and ((gray_tiles >= 6) or ((gray_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if bomb_white_tiles > 0 and ((white_tiles >= 6) or ((white_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if white_tiles == 0 then
				exportable = false
			end
			return exportable
		elseif vars.clear_goals[vars.clear_goal] == 'wild' then
			local exportable = false
			if wild_tiles > 0 and ((wild_tiles % 6 == 0) or ((black_tiles + wild_tiles) % 6 == 0) or ((gray_tiles + wild_tiles) % 6 == 0) or ((white_tiles + wild_tiles) % 6 == 0)) then
				exportable = true
			end
			if bomb_black_tiles > 0 and ((black_tiles >= 6) or ((black_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if bomb_gray_tiles > 0 and ((gray_tiles >= 6) or ((gray_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if bomb_white_tiles > 0 and ((white_tiles >= 6) or ((white_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if wild_tiles == 0 then
				exportable = false
			end
			return exportable
		elseif vars.clear_goals[vars.clear_goal] == '2x' then
			local exportable = false
			if double_black_tiles > 0 then
				if ((black_tiles % 6 == 0) or ((black_tiles + wild_tiles) % 6 == 0)) then
					exportable = true
				else
					exportable = false
				end
			end
			if double_gray_tiles > 0 then
				if  ((gray_tiles % 6 == 0) or ((gray_tiles + wild_tiles) % 6 == 0)) then
					exportable = true
				else
					exportable = false
				end
			end
			if double_white_tiles > 0 then
				if ((white_tiles % 6 == 0) or ((white_tiles + wild_tiles) % 6 == 0)) then
					exportable = true
				else
					exportable = false
				end
			end
			if bomb_black_tiles > 0 and ((black_tiles >= 6) or ((black_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if bomb_gray_tiles > 0 and ((gray_tiles >= 6) or ((gray_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if bomb_white_tiles > 0 and ((white_tiles >= 6) or ((white_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if double_black_tiles == 0 and double_gray_tiles == 0 and double_white_tiles == 0 then
				exportable = false
			end
			return exportable
		elseif vars.clear_goals[vars.clear_goal] == 'bomb' then
			local exportable = false
			if bomb_black_tiles > 0 and ((black_tiles >= 6) or ((black_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if bomb_gray_tiles > 0 and ((gray_tiles >= 6) or ((gray_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if bomb_white_tiles > 0 and ((white_tiles >= 6) or ((white_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if bomb_black_tiles == 0 and bomb_gray_tiles == 0 and bomb_white_tiles == 0 then
				exportable = false
			end
			return exportable
		elseif vars.clear_goals[vars.clear_goal] == 'board' then
			local exportable = false
			if black_tiles > 0 and ((black_tiles % 6 == 0) or ((black_tiles + wild_tiles) % 6 == 0)) then
				exportable = true
			end
			if gray_tiles > 0 and ((gray_tiles % 6 == 0) or ((gray_tiles + wild_tiles) % 6 == 0)) then
				exportable = true
			end
			if white_tiles > 0 and ((white_tiles % 6 == 0) or ((white_tiles + wild_tiles) % 6 == 0)) then
				exportable = true
			end
			if bomb_black_tiles > 0 and ((black_tiles >= 6) or ((black_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if bomb_gray_tiles > 0 and ((gray_tiles >= 6) or ((gray_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if bomb_white_tiles > 0 and ((white_tiles >= 6) or ((white_tiles + wild_tiles) >= 6)) then
				exportable = true
			end
			if black_tiles > 0 and not ((black_tiles % 6 == 0) or ((black_tiles + wild_tiles) % 6 == 0)) then
				exportable = false
			end
			if gray_tiles > 0 and not ((gray_tiles % 6 == 0) or ((gray_tiles + wild_tiles) % 6 == 0)) then
				exportable = false
			end
			if white_tiles > 0 and not ((white_tiles % 6 == 0) or ((white_tiles + wild_tiles) % 6 == 0)) then
				exportable = false
			end
			if bomb_black_tiles > 0 and not ((black_tiles >= 6) or ((black_tiles + wild_tiles) >= 6)) then
				exportable = false
			end
			if bomb_gray_tiles > 0 and not ((gray_tiles >= 6) or ((gray_tiles + wild_tiles) >= 6)) then
				exportable = false
			end
			if bomb_white_tiles > 0 and not ((white_tiles >= 6) or ((white_tiles + wild_tiles) >= 6)) then
				exportable = false
			end
			return exportable
		end
	else
		return true
	end
end

function mission_command:update()
	vars.scroll_x += (vars.scroll_x_target - vars.scroll_x) * 0.4
	if (vars.scroll_x > vars.scroll_x_target - 0.05 and vars.scroll_x < vars.scroll_x_target + 0.05) and vars.scroll_x ~= vars.scroll_x_target then
		vars.scroll_x = vars.scroll_x_target
		gfx.sprite.redrawBackground()
	end
	if vars.scroll_x ~= vars.scroll_x_target then
		gfx.sprite.redrawBackground()
	end
	if pd.keyboard.isVisible() then
		gfx.sprite.redrawBackground()
	end
	local ticks = pd.getCrankTicks(6)
	if ticks ~= 0 and not scenemanager.transitioning then
		if vars.mode == 'start' then
			playsound(assets.sfx_move)
			vars.start_selection += ticks
			if vars.start_selection < 1 then
				vars.start_selection = #vars.start_selections
			elseif vars.start_selection > #vars.start_selections then
				vars.start_selection = 1
			end
			gfx.sprite.redrawBackground()
		elseif vars.mode == 'edit' then
			if sprites.selector.opened then
				if sprites.selector.rack == 1 then
					if sprites.selector.rack2selection ~= 4 then
						sprites.selector.rack1selection += ticks
						local limit = 3
						if sprites.selector.show_no_color then
							limit = 4
						end
						if sprites.selector.rack1selection < 1 then
							sprites.selector.rack1selection = 1
							shakies()
							playsound(assets.sfx_bonk)
						elseif sprites.selector.rack1selection > limit then
							sprites.selector.rack1selection = limit
							shakies()
							playsound(assets.sfx_bonk)
						else
							playsound(assets.sfx_move)
						end
					else
						shakies()
						playsound(assets.sfx_bonk)
					end
				else
					if not (sprites.selector.show_no_color and sprites.selector.rack1selection == 1) then
						sprites.selector.rack2selection += ticks
						if sprites.selector.rack2selection < 1 then
							sprites.selector.rack2selection = 1
							shakies()
							playsound(assets.sfx_bonk)
						elseif sprites.selector.rack2selection > 4 then
							sprites.selector.rack2selection = 4
							shakies()
							playsound(assets.sfx_bonk)
						else
							playsound(assets.sfx_move)
						end
					else
						shakies()
						playsound(assets.sfx_bonk)
					end
				end
			elseif #pd.inputHandlers > 1 then
				if vars.mission_types[vars.mission_type] ~= 'time' then
					local powerup = false
					local nocolor = true
					if vars.mission_types[vars.mission_type] == 'picture' then
						nocolor = false
					else
						powerup = true
					end
					if ticks > 0 then
						if not pd.buttonIsPressed('b') then
							if nocolor then
								if vars.tris[vars.tri].color == 'none' then
									vars.tris[vars.tri].color = 'white'
								elseif vars.tris[vars.tri].color == 'white' then
									vars.tris[vars.tri].color = 'gray'
								elseif vars.tris[vars.tri].color == 'gray' then
									vars.tris[vars.tri].color = 'black'
								elseif vars.tris[vars.tri].color == 'black' then
									vars.tris[vars.tri].color = 'none'
									vars.tris[vars.tri].powerup = ''
								end
							else
								if vars.tris[vars.tri].color == 'white' then
									vars.tris[vars.tri].color = 'gray'
								elseif vars.tris[vars.tri].color == 'gray' then
									vars.tris[vars.tri].color = 'black'
								elseif vars.tris[vars.tri].color == 'black' then
									vars.tris[vars.tri].color = 'white'
								end
							end
						elseif powerup then
							if vars.tris[vars.tri].color == 'none' then
								playsound(assets.sfx_bonk)
							else
								if vars.tris[vars.tri].powerup == '' then
									vars.tris[vars.tri].powerup = 'double'
								elseif vars.tris[vars.tri].powerup == 'double' then
									vars.tris[vars.tri].powerup = 'bomb'
								elseif vars.tris[vars.tri].powerup == 'bomb' then
									vars.tris[vars.tri].powerup = 'wild'
								elseif vars.tris[vars.tri].powerup == 'wild' then
									vars.tris[vars.tri].powerup = ''
								end
							end
						end
					else
						if not pd.buttonIsPressed('b') then
							if nocolor then
								if vars.tris[vars.tri].color == 'none' then
									vars.tris[vars.tri].color = 'black'
								elseif vars.tris[vars.tri].color == 'white' then
									vars.tris[vars.tri].color = 'none'
									vars.tris[vars.tri].powerup = ''
								elseif vars.tris[vars.tri].color == 'gray' then
									vars.tris[vars.tri].color = 'white'
								elseif vars.tris[vars.tri].color == 'black' then
									vars.tris[vars.tri].color = 'gray'
								end
							else
								if vars.tris[vars.tri].color == 'white' then
									vars.tris[vars.tri].color = 'black'
								elseif vars.tris[vars.tri].color == 'gray' then
									vars.tris[vars.tri].color = 'white'
								elseif vars.tris[vars.tri].color == 'black' then
									vars.tris[vars.tri].color = 'gray'
								end
							end
						elseif powerup then
							if vars.tris[vars.tri].color == 'none' then
								playsound(assets.sfx_bonk)
							else
								if vars.tris[vars.tri].powerup == '' then
									vars.tris[vars.tri].powerup = 'wild'
								elseif vars.tris[vars.tri].powerup == 'double' then
									vars.tris[vars.tri].powerup = ''
								elseif vars.tris[vars.tri].powerup == 'bomb' then
									vars.tris[vars.tri].powerup = 'double'
								elseif vars.tris[vars.tri].powerup == 'wild' then
									vars.tris[vars.tri].powerup = 'bomb'
								end
							end
						end
					end
				end
				if mission_command:check_validity() then
					sprites.error.x_target = -355
				elseif sprites.error.x_target ~= 5 then
					sprites.error.x_target = 5
					playsound(assets.sfx_bonk)
				end
			end
		elseif vars.mode == 'save' and not vars.puzzle_exported then
			playsound(assets.sfx_move)
			vars.save_selection += ticks
			if vars.save_selection < 1 then
				vars.save_selection = #vars.save_selections
			elseif vars.save_selection > #vars.save_selections then
				vars.save_selection = 1
			end
			gfx.sprite.redrawBackground()
		end
	end
end