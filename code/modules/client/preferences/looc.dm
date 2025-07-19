/datum/preference/toggle/chat_looc // thanks https://github.com/tgstation/tgstation/pull/71040
	default_value = TRUE
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES
	savefile_key = "chat_looc"
	savefile_identifier = PREFERENCE_PLAYER


/// The color admins will speak in for LOOC.
/datum/preference/color/looc_color
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES
	savefile_key = "looccolor"
	savefile_identifier = PREFERENCE_PLAYER

/datum/preference/color/looc_color/create_default_value()
	return "#00c5cc"

/datum/preference/color/looc_color/is_accessible(datum/preferences/preferences)
	if (!..(preferences))
		return FALSE

	return is_admin(preferences.parent) || preferences.unlock_content