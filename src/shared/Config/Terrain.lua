-- Terrain material colors. Roblox colors a terrain material the same everywhere, so every
-- material has ONE job across the map and all the planets (see the comments).

local Terrain = {}

Terrain.Colors = {
	Grass = Color3.fromRGB(95, 175, 110), -- map: island tops
	Rock = Color3.fromRGB(110, 92, 128), -- map: island bodies, planets: mountains
	Slate = Color3.fromRGB(78, 66, 100), -- map: island undersides, Shadow planet spikes
	Basalt = Color3.fromRGB(48, 40, 52), -- map: meteor field, Lava planet crust, scorched craters
	CrackedLava = Color3.fromRGB(255, 110, 30), -- every planet's mantle, lava rivers, Magma craters
	Snow = Color3.fromRGB(240, 246, 255), -- mountain caps, Ice planet poles
	Ground = Color3.fromRGB(150, 100, 62), -- Rocky planet crust
	Cobblestone = Color3.fromRGB(120, 110, 98), -- Rocky planet highlands
	Ice = Color3.fromRGB(175, 220, 255), -- Ice planet crust
	Glacier = Color3.fromRGB(120, 215, 255), -- ice crystals and spikes (planets and Frost craters)
	Sand = Color3.fromRGB(255, 160, 210), -- Candy planet crust
	Limestone = Color3.fromRGB(150, 240, 205), -- Candy planet mint hills
	Pavement = Color3.fromRGB(255, 235, 150), -- Candy planet lemon hills
	Salt = Color3.fromRGB(205, 130, 255), -- Crystal planet crust and crystal spires
	Asphalt = Color3.fromRGB(26, 20, 38), -- Shadow planet crust
	Sandstone = Color3.fromRGB(240, 185, 60), -- Legendary planet crust
	Mud = Color3.fromRGB(110, 225, 60), -- Venom toxic goo in craters
}

return Terrain
