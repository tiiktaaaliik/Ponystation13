GLOBAL_VAR_INIT(LOOC_COLOR, null)//If this is null, use the CSS for LOOC. Otherwise, use a custom colour.
GLOBAL_VAR_INIT(normal_looc_colour, "#00c5cc")

///talking in LOOC uses this
/client/verb/looc(msg as text)
	set name = "LOOC"
	set category = "OOC"

	if(GLOB.say_disabled) //This is here to try to identify lag problems
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return

	var/client_initalized = VALIDATE_CLIENT_INITIALIZATION(src)
	if(isnull(mob) || !client_initalized)
		if(!client_initalized)
			unvalidated_client_error() // we only want to throw this warning message when it's directly related to client failure.

		to_chat(usr, span_warning("Failed to send your LOOC message. You attempted to send the following message:\n[span_big(msg)]"))
		return

	if(isnull(holder))
		if(!GLOB.looc_allowed)
			to_chat(src, span_danger("LOOC is globally muted."))
			return
		if(prefs.muted & MUTE_LOOC)
			to_chat(src, span_danger("You cannot use LOOC (muted)."))
			return
	if(is_banned_from(ckey, "LOOC")) // This may fuck with the SQL database in ways I have not encountered yet? At least, if you're applying this onto an already-established database...
		to_chat(src, span_danger("You have been banned from LOOC."))
		return
	if(QDELETED(src))
		return

	msg = trim(copytext_char(sanitize(msg), 1, MAX_MESSAGE_LEN))
	var/raw_msg = msg

	var/list/filter_result = is_ooc_filtered(msg)
	if (!CAN_BYPASS_FILTER(usr) && filter_result)
		REPORT_CHAT_FILTER_TO_USER(usr, filter_result)
		log_filter("LOOC", msg, filter_result)
		return

	// Protect filter bypassers from themselves.
	// Demote hard filter results to soft filter results if necessary due to the danger of accidentally speaking in LOOC.
	var/list/soft_filter_result = filter_result || is_soft_ooc_filtered(msg)

	if (soft_filter_result)
		if(tgui_alert(usr,"Your message contains \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\". \"[soft_filter_result[CHAT_FILTER_INDEX_REASON]]\", Are you sure you want to say it?", "Soft Blocked Word", list("Yes", "No")) != "Yes")
			return
		message_admins("[ADMIN_LOOKUPFLW(usr)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Message: \"[msg]\"")
		log_admin_private("[key_name(usr)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Message: \"[msg]\"")

	if(!msg)
		return

	msg = emoji_parse(msg)

	if(SSticker.HasRoundStarted() && ((msg[1] in list(".",";",":","#")) || findtext_char(msg, "say", 1, 5)))
		if(tgui_alert(usr,"Your message \"[raw_msg]\" looks like it was meant for in game communication, say it in LOOC?", "Meant for LOOC?", list("Yes", "No")) != "Yes")
			return

	if(!holder)
		if(handle_spam_prevention(msg, MUTE_LOOC))
			return
		if(findtext(msg, "byond://"))
			to_chat(src, span_boldannounce("Advertising other servers is not allowed."))
			log_admin("[key_name(src)] has attempted to advertise in LOOC: [msg]")
			message_admins("[key_name_admin(src)] has attempted to advertise in LOOC: [msg]")
			return

	if(!(get_chat_toggles(src) & safe_read_pref(src, /datum/preference/toggle/chat_looc))) // am I playing it TOO safe????
		to_chat(src, span_danger("You have LOOC muted."))
		return

	mob.log_talk(raw_msg, LOG_LOOC)

	// BYOND member special icons + hearted icons deemed unnecessary for LOOC
	//The linkify span classes and linkify=TRUE below make looc text get clickable chat href links if you pass in something resembling a url
	var/list/looc_hearers = get_hearers_in_view(10, mob.get_top_level_mob(src.mob))
	for(var/mob/looc_hearer_mob in looc_hearers)
		if(!looc_hearer_mob.client)
			continue
		/// The client of mob eligible to hear the LOOC message
		var/client/looc_receiver_client = looc_hearer_mob.client
		if(!looc_receiver_client.prefs) // Client being created or deleted. Despite all, this can be null.
			continue
		if(!(get_chat_toggles(looc_receiver_client) & safe_read_pref(looc_receiver_client, /datum/preference/toggle/chat_looc)))
			continue
		if(holder?.fakekey in looc_receiver_client.prefs.ignoring)
			continue
		if(holder)
			if(!holder.fakekey || looc_receiver_client.holder)
				if(check_rights_for(src, R_ADMIN))
					var/looc_color = prefs.read_preference(/datum/preference/color/looc_color)
					to_chat(looc_receiver_client, span_adminlooc("[CONFIG_GET(flag/allow_admin_looccolor) && looc_color ? "<font color=[looc_color]>" :"" ][span_prefix("LOOC:")] <EM>[src.mob.name || "UNDEFINED"]:</EM> <span class='message linkify'>[msg]</span>"))
				else
					to_chat(looc_receiver_client, span_adminobserverlooc(span_prefix("LOOC:</span> <EM>[src.mob.name || "UNDEFINED"]:</EM> <span class='message linkify'>[msg]")))
			else
				if(GLOB.LOOC_COLOR)
					to_chat(looc_receiver_client, "<span class='loocplain'><font color='[prefs.read_preference(/datum/preference/color/looc_color) || GLOB.LOOC_COLOR || GLOB.normal_looc_colour]'><b>[span_prefix("LOOC:")] <EM>[src.mob.name || "UNDEFINED"]:</EM> <span class='message linkify'>[msg]</span></b></font></span>")
				else
					to_chat(looc_receiver_client, span_looc(span_prefix("LOOC</span> <EM>[src.mob.name || "UNDEFINED"]:</EM> <span class='message linkify'>[msg]")))

		else if(!(key in looc_receiver_client.prefs.ignoring))
			if(GLOB.LOOC_COLOR)
				to_chat(looc_receiver_client, "<span class='loocplain'><font color='[prefs.read_preference(/datum/preference/color/looc_color) || GLOB.LOOC_COLOR || GLOB.normal_looc_colour]'><b>[span_prefix("LOOC:")] <EM>[src.mob.name || "UNDEFINED"]:</EM> <span class='message linkify'>[msg]</span></b></font></span>")
			else
				to_chat(looc_receiver_client, span_looc(span_prefix("LOOC:</span> <EM>[src.mob.name || "UNDEFINED"]:</EM> <span class='message linkify'>[msg]")))

/proc/toggle_looc(toggle = null)
	if(toggle != null) //if we're specifically en/disabling looc
		if(toggle != GLOB.looc_allowed)
			GLOB.looc_allowed = toggle
		else
			return
	else //otherwise just toggle it
		GLOB.looc_allowed = !GLOB.looc_allowed
	to_chat(world, "<span class='oocplain'><B>The LOOC channel has been globally [GLOB.looc_allowed ? "enabled" : "disabled"].</B></span>")


///// COLORS /////


/client/proc/set_looc()
	set name = "Set Player LOOC Color"
	set desc = "Modifies player LOOC Color"
	set category = "Server"
	if(IsAdminAdvancedProcCall())
		return

ADMIN_VERB(set_looc_color, R_FUN, "Set Player LOOC Color", "Modifies the global LOOC color.", ADMIN_CATEGORY_SERVER)
	var/newColor = input(user, "Please select the new player LOOC color.", "LOOC color") as color|null
	if(isnull(newColor))
		return
	var/new_color = sanitize_color(newColor)
	message_admins("[key_name_admin(user)] has set the players' looc color to [new_color].")
	log_admin("[key_name_admin(user)] has set the player looc color to [new_color].")
	GLOB.LOOC_COLOR = new_color


/client/proc/reset_looc()
	set name = "Reset Player LOOC Color"
	set desc = "Returns player LOOC Color to default"
	set category = "Server"
	if(IsAdminAdvancedProcCall())
		return

ADMIN_VERB(reset_looc_color, R_FUN, "Reset Player LOOC Color", "Returns player LOOC color to default.", ADMIN_CATEGORY_SERVER)
	if(tgui_alert(user, "Are you sure you want to reset the LOOC color of all players?", "Reset Player LOOC Color", list("Yes", "No")) != "Yes")
		return
	message_admins("[key_name_admin(user)] has reset the players' looc color.")
	log_admin("[key_name_admin(user)] has reset player looc color.")
	GLOB.LOOC_COLOR = null