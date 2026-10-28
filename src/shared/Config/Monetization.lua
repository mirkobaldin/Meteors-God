-- Game Pass and Developer Product IDs.
-- Create them in the Creator Hub (Monetization tab of your experience), then paste the IDs here.
-- An ID of 0 means "not configured": the shop shows it as unavailable and nothing breaks.

local Monetization = {}

Monetization.GamePasses = {
	VIP = { id = 0, name = "VIP", desc = "+20% Potere al secondo e tag VIP" },
	Power2x = { id = 0, name = "2x Potere", desc = "Potere al secondo raddoppiato per sempre" },
	Shards2x = { id = 0, name = "2x Frammenti", desc = "Frammenti Stellari raddoppiati per sempre" },
	ExtraAltar = { id = 0, name = "Altare Extra", desc = "+1 slot sull'altare" },
}

Monetization.Products = {
	StarterPack = {
		id = 0,
		name = "Starter Pack",
		desc = "Cometa Blu esclusiva + 5.000 Frammenti + 2x Potere per 1 ora",
	},
	PowerS = { id = 0, name = "Potere S", desc = "10 minuti di Potere istantaneo" },
	PowerM = { id = 0, name = "Potere M", desc = "1 ora di Potere istantaneo" },
	PowerL = { id = 0, name = "Potere L", desc = "6 ore di Potere istantaneo" },
	Boost2x = { id = 0, name = "Boost 2x Potere", desc = "Potere x2 per 30 minuti" },
	DivineWrath = { id = 0, name = "Ira Divina", desc = "Tutto il server fa danno x3 per 3 minuti" },
	LegendaryPlanet = { id = 0, name = "Evoca Pianeta Leggendario", desc = "Arriva subito un pianeta leggendario" },
	InstantRecharge = { id = 0, name = "Ricarica Istantanea", desc = "Tutti i tuoi meteoriti tornano pronti" },
	EvolveNow = { id = 0, name = "Evolvi Subito", desc = "Passa subito all'Evoluzione successiva" },
}

Monetization.StarterPack = {
	meteor = "Cometa Blu",
	shards = 5000,
	boostSeconds = 3600,
}

Monetization.PowerPackSeconds = {
	PowerS = 600,
	PowerM = 3600,
	PowerL = 21600,
}

Monetization.Boost2xSeconds = 1800
Monetization.DivineWrathSeconds = 180

function Monetization.ProductKeyById(productId)
	for key, p in pairs(Monetization.Products) do
		if p.id ~= 0 and p.id == productId then
			return key
		end
	end
	return nil
end

function Monetization.PassKeyById(passId)
	for key, p in pairs(Monetization.GamePasses) do
		if p.id ~= 0 and p.id == passId then
			return key
		end
	end
	return nil
end

return Monetization
