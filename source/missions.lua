import 'missions_list'
import 'mission_command'
import 'title'
import 'game'

-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = getLocalizedText

class('missions').extends(gfx.sprite) -- Create the scene's class
function missions:init(...)
	missions.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		pauseimage()
		menu:removeAllMenuItems()
		if not scenemanager.transitioning then
			menu:addCheckmarkMenuItem(text('custom'), vars.custom, function(value)
				vars.custom = value
			end)
			menu:addMenuItem(text('create'), function()
				scenemanager:transitionscene(mission_command, vars.custom)
				fademusic()
			end)
			menu:addMenuItem(text('goback'), function()
				scenemanager:transitionscene(title, false, 'missions')
			end)
		end
	end

	assets = {
		stars_small = gfx.image.new('images/stars_small'),
		stars_large = gfx.image.new('images/stars_large'),
		full_circle = gfx.font.new('fonts/full-circle'),
		half_circle = gfx.font.new('fonts/full-circle-halved'),
		grid = pd.ui.gridview.new(200, 125),
		sfx_move = smp.new('audio/sfx/swap'),
		sfx_select = smp.new('audio/sfx/select'),
		sfx_back = smp.new('audio/sfx/back'),
		sfx_bonk = smp.new('audio/sfx/bonk'),
		check = gfx.image.new('images/check'),
	}

	assets.grid:setNumberOfRows(1)
	assets.grid:setNumberOfColumns(50)
	assets.grid:setCellPadding(5, 5, 0, 0)
	assets.grid:setSelection(1, 1, math.min((((save.highest_mission > 50) and 1) or (save.highest_mission)), 50))
	assets.grid:scrollCellToCenter(1, 1, math.min((((save.highest_mission > 50) and 1) or (save.highest_mission)), 50), false)

	vars = {
		custom = args[1],
	}
	vars.missionsHandlers = {
		leftButtonDown = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
			vars.keytimer = pd.timer.keyRepeatTimerWithDelay(150, 75, function()
				if vars.custom and #vars.custom_files > 0 then
					local _, _, column = assets.custom_grid:getSelection()
					if column == 1 then
						playsound(assets.sfx_bonk)
						shakies()
					else
						playsound(assets.sfx_move)
						assets.custom_grid:selectPreviousColumn(false)
					end
				elseif not vars.custom then
					local _, _, column = assets.grid:getSelection()
					if column == 1 then
						playsound(assets.sfx_bonk)
						shakies()
					else
						playsound(assets.sfx_move)
						assets.grid:selectPreviousColumn(false)
					end
				end
			end)
		end,

		leftButtonUp = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
		end,

		rightButtonDown = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
			vars.keytimer = pd.timer.keyRepeatTimerWithDelay(150, 75, function()
				if vars.custom and #vars.custom_files > 0 then
					local _, _, column = assets.custom_grid:getSelection()
					if column == #vars.custom_files then
						playsound(assets.sfx_bonk)
						shakies()
					else
						playsound(assets.sfx_move)
						assets.custom_grid:selectNextColumn(false)
					end
				elseif not vars.custom then
					local _, _, column = assets.grid:getSelection()
					if column == 50 then
						playsound(assets.sfx_bonk)
						shakies()
					else
						playsound(assets.sfx_move)
						assets.grid:selectNextColumn(false)
					end
				end
			end)
		end,

		rightButtonUp = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
		end,

		BButtonDown = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
			playsound(assets.sfx_back)
			scenemanager:transitionscene(title, false, 'missions')
		end,

		AButtonDown = function()
			if (vars.custom and #vars.custom_files > 0) then
				local _, _, column = assets.custom_grid:getSelection()
				if vars.keytimer ~= nil then vars.keytimer:remove() end
				playsound(assets.sfx_select)
				scenemanager:transitionscene(game, vars.custom_missions[column].type, vars.custom_missions[column].mission, vars.custom_missions[column].modifier or nil, vars.custom_missions[column].start or nil, vars.custom_missions[column].goal or nil, vars.custom_missions[column].seed or nil, vars.custom_missions[column].name or nil)
				fademusic()
			elseif not vars.custom then
				local _, _, column = assets.grid:getSelection()
				if vars.keytimer ~= nil then vars.keytimer:remove() end
				local _, _, column = assets.grid:getSelection()
				if column > save.highest_mission then
					playsound(assets.sfx_bonk)
					shakies()
				else
					playsound(assets.sfx_select)
					scenemanager:transitionscene(game, missions_list[column].type, column, missions_list[column].modifier or nil, missions_list[column].start, missions_list[column].goal, nil, missions_list[column].name)
					fademusic()
				end
			end
		end,
	}
	pd.timer.performAfterDelay(scenemanager.transitiontime, function()
		pd.inputHandlers.push(vars.missionsHandlers)
	end)

	function assets.grid:drawCell(section, row, column, selected, x, y, width, height)
		local offset = 0
		if checklanguage() == 'jp' then offset = 7 end
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(x, y, width, height)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawRect(x, y, width, height)
		if selected then
			gfx.setDitherPattern(0.75, gfx.image.kDitherTypeBayer2x2)
			gfx.fillPolygon(x, y, x + width, y, x + width, y + height, x + width - (width * 0.2), y + height, x + width - (width * 0.05), y + (height / 2), x + width - (width * 0.2), y, x + width * 0.2, y, x + width * 0.05, y + (height / 2), x + width * 0.2, y + height, x, y + height, x, y)
			gfx.setColor(gfx.kColorBlack)
		end
		if column > save.highest_mission then
			assets.half_circle:drawTextAligned('🔒 ' .. text('mission_label') .. column, x + (width / 2), y + 8, kTextAlignment.center)
			assets.half_circle:drawTextAligned(text('mission_locked'), x + (width / 2), y + (height / 3) + offset, kTextAlignment.center)
		else
			assets.full_circle:drawTextAligned(text('mission_label') .. column, x + (width / 2), y + 8, kTextAlignment.center)
			if missions_list[column].type == "picture" then
				assets.full_circle:drawTextAligned(text('mission_picture1') .. missions_list[column].name .. text('mission_picture2'), x + (width / 2), y + (height / 3.7) + offset, kTextAlignment.center)
			elseif missions_list[column].type == "logic" or missions_list[column].type == "speedrun" then
				assets.full_circle:drawTextAligned(text('mission_' .. missions_list[column].type .. '_' .. missions_list[column].modifier), x + (width / 2), y + (height / 3.7) + offset, kTextAlignment.center)
			else
				assets.full_circle:drawTextAligned(text('mission_' .. missions_list[column].type), x + (width / 2), y + (height / 3.7) + offset, kTextAlignment.center)
			end
			if missions_list[column].type == "picture" or missions_list[column].type == "logic" then
				assets.full_circle:drawTextAligned(text('swaps') .. text('divvy') .. commalize(save.mission_bests['mission' .. column] or 0), x + (width / 2), y + (height - 22), kTextAlignment.center)
			elseif missions_list[column].type == "time" then
				assets.full_circle:drawTextAligned(text('score') .. text('divvy') .. commalize(save.mission_bests['mission' .. column] or 0), x + (width / 2), y + (height - 22), kTextAlignment.center)
			elseif missions_list[column].type == "speedrun" then
				local mins, secs, mils = timecalc(save.mission_bests['mission' .. column])
				assets.full_circle:drawTextAligned(text('time') .. text('divvy') .. mins .. ':' .. secs .. '.' .. mils, x + (width / 2), y + (height - 22), kTextAlignment.center)
			end
		end
		if save.highest_mission > column then
			assets.check:draw(x + width - 45, y + height - 50)
		end
	end

	vars.custom_files = pd.file.listFiles('missions/')

	if #vars.custom_files > 0 then
		vars.custom_missions = {}
		for i = 1, #vars.custom_files do
			if not string.find(vars.custom_files[i], '.json') then
				table.remove(vars.custom_files, i)
			end
		end
		for i = 1, #vars.custom_files do
			if save.mission_bests['mission' .. string.gsub(tostring(vars.custom_files[i]), ".json", "")] == nil then
				save.mission_bests['mission' .. string.gsub(tostring(vars.custom_files[i]), ".json", "")] = 0
			end
			vars.custom_missions[i] = pd.datastore.read('missions/' .. string.gsub(tostring(vars.custom_files[i]), ".json", ""))
			if vars.custom_missions[i].type == 'time' then
			elseif vars.custom_missions[i].type == 'speedrun' then
			elseif vars.custom_missions[i].type == 'picture' then
				if vars.custom_missions[i].start_point ~= nil then
					vars.custom_missions[i].start = {}
					for n = 1, 19 do
						table.insert(vars.custom_missions[i].start, vars.custom_missions[i].start_point['tri' .. n])
					end
					vars.custom_missions[i].start_point = nil
				end
				if vars.custom_missions[i].goal_point ~= nil then
					vars.custom_missions[i].goal = {}
					for n = 1, 19 do
						table.insert(vars.custom_missions[i].goal, vars.custom_missions[i].goal_point['tri' .. n])
					end
					vars.custom_missions[i].goal_point = nil
				end
			elseif vars.custom_missions[i].type == 'logic' then
			end
		end

		assets.custom_grid = pd.ui.gridview.new(200, 125)
		assets.custom_grid:setNumberOfRows(1)
		assets.custom_grid:setNumberOfColumns(#vars.custom_files)
		assets.custom_grid:setCellPadding(5, 5, 0, 0)
		assets.custom_grid:setSelection(1, 1, 1)
		assets.custom_grid:scrollCellToCenter(1, 1, 1, false)

		function assets.custom_grid:drawCell(section, row, column, selected, x, y, width, height)
			local offset = 0
			if checklanguage() == 'jp' then offset = 7 end
			gfx.setColor(gfx.kColorWhite)
			gfx.fillRect(x, y, width, height)
			gfx.setColor(gfx.kColorBlack)
			gfx.drawRect(x, y, width, height)
			if selected then
				gfx.setDitherPattern(0.75, gfx.image.kDitherTypeBayer2x2)
				gfx.fillPolygon(x, y, x + width, y, x + width, y + height, x + width - (width * 0.2), y + height, x + width - (width * 0.05), y + (height / 2), x + width - (width * 0.2), y, x + width * 0.2, y, x + width * 0.05, y + (height / 2), x + width * 0.2, y + height, x, y + height, x, y)
				gfx.setColor(gfx.kColorBlack)
			end
			assets.full_circle:drawTextAligned(text('mission_by') .. vars.custom_missions[column].author, x + (width / 2), y + 8, kTextAlignment.center)
			if vars.custom_missions[column].type == "picture" then
				assets.full_circle:drawTextAligned(text('mission_picture1') .. vars.custom_missions[column].name .. text('mission_picture2'), x + (width / 2), y + (height / 3.7) + offset, kTextAlignment.center)
			elseif vars.custom_missions[column].type == "logic" or vars.custom_missions[column].type == "speedrun" then
				assets.full_circle:drawTextAligned(text('mission_' .. vars.custom_missions[column].type .. '_' .. vars.custom_missions[column].modifier), x + (width / 2), y + (height / 3.7) + offset, kTextAlignment.center)
			else
				assets.full_circle:drawTextAligned(text('mission_' .. vars.custom_missions[column].type), x + (width / 2), y + (height / 3.7) + offset, kTextAlignment.center)
			end
			if vars.custom_missions[column].type == "picture" or vars.custom_missions[column].type == "logic" then
				assets.full_circle:drawTextAligned(text('swaps') .. text('divvy') .. commalize(save.mission_bests['mission' .. vars.custom_missions[column].mission]), x + (width / 2), y + (height - 22), kTextAlignment.center)
			elseif vars.custom_missions[column].type == "time" then
				assets.full_circle:drawTextAligned(text('score') .. text('divvy') .. commalize(save.mission_bests['mission' .. vars.custom_missions[column].mission]), x + (width / 2), y + (height - 22), kTextAlignment.center)
			elseif vars.custom_missions[column].type == "speedrun" then
				local mins, secs, mils = timecalc(save.mission_bests['mission' .. vars.custom_missions[column].mission])
				assets.full_circle:drawTextAligned(text('time') .. text('divvy') .. mins .. ':' .. secs .. '.' .. mils, x + (width / 2), y + (height - 22), kTextAlignment.center)
			end
		end
	end

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		local counter = save.playtime
		assets.stars_small:draw(-(counter % 133) * 3, -(counter % 97) * 2.45)
		assets.stars_large:draw(-(counter % 83) * 4.8, -(counter % 42) * 5.7)
		if (vars.custom and #vars.custom_files > 0) or (not vars.custom) then
			gfx.setColor(gfx.kColorWhite)
			gfx.setDitherPattern(0.75, gfx.image.kDitherTypeBayer2x2)
			gfx.fillRect(0, 40, 400, 145)
			gfx.setColor(gfx.kColorBlack)
		else
			gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
			gfx.fillRect(0, 40, 400, 145)
		end
		if vars.custom then
			if #vars.custom_files > 0 then
				assets.custom_grid:drawInRect(0,50, 400, 125)
			else
				gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
				assets.full_circle:drawTextAligned(text('nocustommissions_1'), 200, 70, kTextAlignment.center)
				assets.full_circle:drawTextAligned(text('nocustommissions_2'), 200, 85, kTextAlignment.center)
				assets.half_circle:drawTextAligned(text('nocustommissions_3'), 200, 120, kTextAlignment.center)
				assets.half_circle:drawTextAligned(text('nocustommissions_4'), 200, 135, kTextAlignment.center)
				gfx.setImageDrawMode(gfx.kDrawModeCopy)
			end
		else
			assets.grid:drawInRect(0,50, 400, 125)
		end
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		assets.half_circle:drawText(text('menucustom'), 10, 205)
		assets.half_circle:drawText(text('move') .. ' ' .. text('select') .. ' ' .. text('back'), 10, 220)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end)

	self:add()
	newmusic('audio/music/title', true)
end

function missions:update()
	local ticks = pd.getCrankTicks(6)
	if ticks ~= 0 and #pd.inputHandlers > 1 then
		if vars.custom then
			local _, _, column = assets.custom_grid:getSelection()
			if ticks > 0 then
				if column == #vars.custom_files then
					playsound(assets.sfx_bonk)
					shakies()
				else
					playsound(assets.sfx_move)
					assets.custom_grid:selectNextColumn(false)
				end
			elseif ticks < 0 then
				if column == 1 then
					playsound(assets.sfx_bonk)
					shakies()
				else
					playsound(assets.sfx_move)
					assets.custom_grid:selectPreviousColumn(false)
				end
			end
		else
			local _, _, column = assets.grid:getSelection()
			if ticks > 0 then
				if column == 50 then
					playsound(assets.sfx_bonk)
					shakies()
				else
					playsound(assets.sfx_move)
					assets.grid:selectNextColumn(false)
				end
			elseif ticks < 0 then
				if column == 1 then
					playsound(assets.sfx_bonk)
					shakies()
				else
					playsound(assets.sfx_move)
					assets.grid:selectPreviousColumn(false)
				end
			end
		end
	end
end