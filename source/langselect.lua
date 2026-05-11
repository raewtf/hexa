-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = getLocalizedText

class('langselect').extends(gfx.sprite) -- Create the scene's class
function langselect:init(...)
	langselect.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		pauseimage()
		menu:removeAllMenuItems()
	end

	assets = {
		stars_small = gfx.image.new('images/stars_small'),
		stars_large = gfx.image.new('images/stars_large'),
		full_circle = gfx.font.new('fonts/full-circle'),
		half_circle = gfx.font.new('fonts/full-circle-halved'),
		fg = gfx.image.new('images/fg_langselect'),
		sfx_move = smp.new('audio/sfx/swap'),
		sfx_bonk = smp.new('audio/sfx/bonk'),
		sfx_select = smp.new('audio/sfx/select'),
		flag_en = gfx.image.new('images/flag_en'),
		flag_fr = gfx.image.new('images/flag_fr'),
		flag_jp = gfx.image.new('images/flag_jp'),
		flag_select = gfx.image.new('images/flag_select'),
	}

	vars = {
		selection = 1,
		selections = {'en', 'fr', 'jp'},
	}
	vars.langselectHandlers = {
		leftButtonDown = function()
			if vars.selection <= 1 then
				shakies()
				playsound(assets.sfx_bonk)
			else
				vars.selection -= 1
				playsound(assets.sfx_move)
			end
		end,

		rightButtonDown = function()
			if vars.selection >= #vars.selections then
				shakies()
				playsound(assets.sfx_bonk)
			else
				vars.selection += 1
				playsound(assets.sfx_move)
			end
		end,

		AButtonDown = function()
			save.lang = vars.selections[vars.selection]
			playsound(assets.sfx_select)
			scenemanager:transitionscene(title)
		end
	}
	pd.inputHandlers.push(vars.langselectHandlers)

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		local counter = save.playtime
		assets.stars_small:draw(-(counter % 133) * 3, -(counter % 97) * 2.45)
		assets.stars_large:draw(-(counter % 83) * 4.8, -(counter % 42) * 5.7)
		gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRect(0, 0, 400, 240)

		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		assets.full_circle:drawTextAligned('Please choose a language.\nVeuillez choisir une langue.\n言語を選択してください', 200, 18, kTextAlignment.center)

		if vars.selections[vars.selection] == 'en' then
			assets.full_circle:drawTextAligned('English', 70, 165, kTextAlignment.center)
		else
			assets.half_circle:drawTextAligned('English', 70, 165, kTextAlignment.center)
		end
		if vars.selections[vars.selection] == 'fr' then
			assets.full_circle:drawTextAligned('Français', 200, 165, kTextAlignment.center)
		else
			assets.half_circle:drawTextAligned('Français', 200, 165, kTextAlignment.center)
		end
		if vars.selections[vars.selection] == 'jp' then
			assets.full_circle:drawTextAligned('日本語', 330, 165, kTextAlignment.center)
		else
			assets.half_circle:drawTextAligned('日本語', 330, 165, kTextAlignment.center)
		end

		assets.half_circle:drawText('The D-pad moves. A picks.', 10, 190)
		assets.half_circle:drawText('Croix : déplacer. A : sélectionner. ', 10, 205)
		assets.half_circle:drawText('十字ボタンで選ぶ。 Aで決める。', 10, 220)

		gfx.setImageDrawMode(gfx.kDrawModeCopy)

		assets.flag_en:draw(6, 80)
		assets.flag_fr:draw(137, 80)
		assets.flag_jp:draw(268, 80)

		assets.flag_select:draw(6 + (131 * (vars.selection - 1)), 80)
	end)

	self:add()
end