--[[

key_combos.register_key_combo(name, combo_list, function(player))

^^^^ Main function

-- Example of a new global (used by all players) combo:
key_combos.register_key_combo("dude", {{'jump', 'down', 'up'}}, function(player)
	player:add_velocity(vector.multiply(player:get_look_dir(), 50))
end)

^^^
This function makes the player jump at a velocity of 50 in the direction the player is looking when
the keys "jump", "down", and "up" are pressed in order.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

key_combos.register_key_combo("abra", {{'jump', 'left', 'right', 'up'}, {'jump', 'right', 'left', 'up'}}, function(player)
	minetest.chat_send_player(player:get_player_name(), "Combo!!")
	player:add_velocity(vector.new(0,10,0))
end)

^^^
This makes the player jump straight up at a velocity of 10 when the keys "jump", "left+right", and "up"
are pressed in order. You may notice I said "left+right", this is because there are two different ways
to call this function and this allows left and right to be mashed together.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

key_combos.disallow_key_combo(combo_name, player_name)
	if the combo_name is the string 'all', then it will disallow all combos for this player

^^^
This disallows a certain player to use a global combo. Example:
key_combos.disallow_key_combo('dude', 'singleplayer')


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

key_combos.allow_key_combo(combo_name, player_name)
	if the combo_name is the string 'all', then it will allow all combos for this player

^^^
This allows a certain player to use a global combo granted it had previously been disallowed. Example:
key_combos.allow_key_combo('dude', 'singleplayer')

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

]]

key_combos = {
	keys_pressed = {},
	key_last_pressed = {},
	combos = {},
	funcs = {},
	disallowed_combos = {},
	combo_names = {},
}

local function get_list_in_list(t,n)
	for i=1, #n-#t+1 do
		for i_,v in pairs(t) do
			if v ~= n[i_+i-1][1] then
				break
			end
			if i_ == #t then
				return true
			end
		end
	end
end

local function get_item_in_list(list, item)
	for _,v in pairs(list) do
		if item == v then
			return true
		else
			return false
		end
	end
end



key_combos.register_key_combo = function(name, combo_list, func)
	key_combos.combos[name] = combo_list
	key_combos.funcs[name] = func
	table.insert(key_combos.combo_names, name)
end

key_combos.disallow_key_combo = function(combo_name, player_name)
	if combo_name == 'all' then
		key_combos.disallowed_combos[player_name] = key_combos.combo_names
		return
	end
	if not key_combos.disallowed_combos[player_name] then
		key_combos.disallowed_combos[player_name] = {}
	end
	if not get_item_in_list(key_combos.disallowed_combos[player_name], combo_name) then
		table.insert(key_combos.disallowed_combos[player_name], combo_name)
	end
end

key_combos.allow_key_combo = function(combo_name, player_name)
	if combo_name == 'all' then
		key_combos.disallowed_combos[player_name] = {}
		return
	end
	if key_combos.disallowed_combos[player_name] then
		for _s,v in pairs(key_combos.disallowed_combos[player_name]) do
			if combo_name == v then
				table.remove(key_combos.disallowed_combos[player_name], _s)
			end
		end
	end
end

minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	key_combos.keys_pressed[player_name] = {}
	key_combos.key_last_pressed[player_name] = 0
end)


local pressed_keys = {
	['jump'] = 0,
	['up'] = 0,
	['right'] = 0,
	['left'] = 0,
	['down'] = 0,
	['sneak'] = 0,
	['aux1'] = 0,
}



for k,v in pairs(pressed_keys) do
	keyevent.register_on_keypress(k, function(keys, old_keys, dtime, player_name)
		if minetest.get_player_by_name(player_name):get_player_control()[k] then
			key_combos.key_last_pressed[player_name] = 0
			table.insert(key_combos.keys_pressed[player_name], {k, 1})
		end
	end)
end

local function lower_keys(player_name)
	for _s,v in ipairs(key_combos.keys_pressed[player_name]) do
		if key_combos.keys_pressed[player_name][_s][2] > 0 then
			key_combos.keys_pressed[player_name][_s][2] = key_combos.keys_pressed[player_name][_s][2] - 0.1
		else
			table.remove(key_combos.keys_pressed[player_name], _s)
		end
	end
end


local function check_for_set_combos(player_name)
	for k,v in pairs(key_combos.combos) do
		for i,_s in ipairs(v) do
			if get_list_in_list(_s, key_combos.keys_pressed[player_name]) and (key_combos.disallowed_combos[player_name] and not get_item_in_list(key_combos.disallowed_combos[player_name], k) or not key_combos.disallowed_combos[player_name]) then
				key_combos.funcs[k](minetest.get_player_by_name(player_name))
				key_combos.keys_pressed[player_name] = {}
				break
			end
		end
	end
end


minetest.register_globalstep(function(dtime)
	for _,player in pairs(minetest.get_connected_players()) do
		local player_name = player:get_player_name()
		if key_combos.key_last_pressed[player_name] > 1 then
			if #key_combos.keys_pressed[player_name] > 0 then
				lower_keys(player_name)
			end
		else
			key_combos.key_last_pressed[player_name]=key_combos.key_last_pressed[player_name]+0.2
			check_for_set_combos(player_name)
		end
	end
end)
