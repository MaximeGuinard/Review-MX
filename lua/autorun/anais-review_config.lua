--[[  
	Addon : Maxouuuuu Review
	By : Maxouuuuu
]]

Anais = Anais or {}
Anais.Review = {}

// Commande pour ouvrir le menu
Anais.Review.Command = "!view"

// Touche pour annulé la scène
Anais.Review.KeyToReturn = KEY_F7

// Temps pour effacé les logs
Anais.Review.DelayToReset = 60 * 5

// Groupe ayant accès au menu
Anais.Review.Groups = {
	['superadmin'] = true,
	['admin'] = true,
	['Modérateur'] = true,
	['Modérateur-Test'] = true,
}