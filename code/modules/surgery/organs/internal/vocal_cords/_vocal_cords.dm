/obj/item/organ/vocal_cords //organs that are activated through speech with the :x/MODE_KEY_VOCALCORDS channel
	name = "vocal cords"
	icon_state = "appendix"
	zone = BODY_ZONE_PRECISE_MOUTH
	slot = ORGAN_SLOT_VOICE
	gender = PLURAL
	decay_factor = 0 //we don't want decaying vocal cords to somehow matter or appear on scanners since they don't do anything damaged
	healing_factor = 0
	var/list/spans = null

/obj/item/organ/vocal_cords/proc/can_speak_with() //if there is any limitation to speaking with these cords
	return TRUE

/obj/item/organ/vocal_cords/proc/speak_with(message) //do what the organ does
	return

/obj/item/organ/vocal_cords/proc/handle_speech(message) //actually say the message
	owner.say(message, spans = spans, sanitize = FALSE)

/obj/item/organ/adamantine_resonator
	name = "adamantine resonator"
	desc = "Fragments of adamantine exist in all golems, stemming from their origins as purely magical constructs. These are used to \"hear\" messages from their leaders."
	zone = BODY_ZONE_HEAD
	slot = ORGAN_SLOT_ADAMANTINE_RESONATOR
	icon_state = "adamantine_resonator"

/obj/item/organ/vocal_cords/adamantine
	name = "adamantine vocal cords"
	desc = "When adamantine resonates, it causes all nearby pieces of adamantine to resonate as well. Golems containing these formations use this to broadcast messages to nearby golems."
	actions_types = list(/datum/action/item_action/organ_action/use/adamantine_vocal_cords)
	icon_state = "adamantine_cords"

/datum/action/item_action/organ_action/use/adamantine_vocal_cords/do_effect(trigger_flags)
	var/message = tgui_input_text(owner, "Resonate a message to all nearby golems", "Resonate", max_length = MAX_MESSAGE_LEN)
	if(!message)
		return FALSE
	if(QDELETED(src) || QDELETED(owner))
		return FALSE
	owner.say(".x[message]")
	return TRUE

/obj/item/organ/vocal_cords/adamantine/handle_speech(message)
	var/msg = span_resonate("[span_name("[owner.real_name]")] resonates, \"[message]\"")
	for(var/player in GLOB.player_list)
		if(iscarbon(player))
			var/mob/living/carbon/speaker = player
			if(speaker.get_organ_slot(ORGAN_SLOT_ADAMANTINE_RESONATOR))
				to_chat(speaker, msg, type = MESSAGE_TYPE_RADIO, avoid_highlighting = speaker == owner)
		else if(isobserver(player))
			var/link = FOLLOW_LINK(player, owner)
			to_chat(player, "[link] [msg]", type = MESSAGE_TYPE_RADIO)

/obj/item/organ/vocal_cords/thestral
	name = "thestral vocal cords"
	icon_state = "thestralvocalcords"
	var/datum/action/cooldown/spell/thestralscreech/screech

/obj/item/organ/vocal_cords/thestral/Initialize(mapload)
	. = ..()
	screech = new(src)
	screech.background_icon_state = "bg_tech_blue"
	screech.base_background_icon_state = screech.background_icon_state
	screech.active_background_icon_state = "[screech.base_background_icon_state]_active"
	screech.overlay_icon_state = "bg_tech_blue_border"
	screech.active_overlay_icon_state = null
	screech.panel = "Genetic"
	screech.thestralcords = src

/obj/item/organ/vocal_cords/thestral/Destroy()
	qdel(screech)
	. = ..()

/obj/item/organ/vocal_cords/thestral/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	screech.Grant(organ_owner)

/obj/item/organ/vocal_cords/thestral/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	screech.Remove(organ_owner)

/datum/action/cooldown/spell/thestralscreech
	name = "Thestral Screech"
	desc = "EEEEEEEEEE!"
	button_icon = 'icons/obj/medical/organs/organs.dmi'
	button_icon_state = "thestralvocalcords"
	cooldown_time = 40 SECONDS
	spell_requirements = NONE
	var/mob/living/carbon/human/last_caster
	var/obj/item/organ/vocal_cords/thestral/thestralcords
	var/flashbang_range = 3 // lol just stole the flashbang code!.

/datum/action/cooldown/spell/thestralscreech/before_cast(atom/cast_on)
	if(!owner.can_speak())
		to_chat(owner, span_warning("You try to screech, but you can't make a sound!"))
		return SPELL_CANCEL_CAST
	var/mob/living/carbon/human/caster = owner
	if(istype(caster.wear_mask, /obj/item/clothing/mask/muzzle))
		to_chat(owner, span_warning("You try to screech, but something is obstructing you!"))
		return SPELL_CANCEL_CAST
	return ..()

/datum/action/cooldown/spell/thestralscreech/cast(mob/living/cast_on)
	. = ..()
	last_caster = cast_on
	var/mob/living/carbon/human/thestral = cast_on
	thestral.visible_message(span_warning("[thestral] screeches!"))
	thestral.say("EEEEEEEEEEEEEEEE!", forced = "batpony screech")
	var/flashbang_turf = get_turf(thestral)
	if(!flashbang_turf)
		return
	playsound(flashbang_turf, 'sound/items/weapons/thestralscreech.ogg', 100, TRUE, 8, 0.9)
	for(var/mob/living/living_mob in get_hearers_in_view(flashbang_range, flashbang_turf))
		if(living_mob == thestral)
			continue
		bang(get_turf(living_mob), living_mob)

/datum/action/cooldown/spell/thestralscreech/proc/bang(turf/turf, mob/living/living_mob)
	if(living_mob.stat == DEAD)
		return
	var/distance = max(0, get_dist(get_turf(last_caster), turf))

	if(!distance)
		living_mob.Paralyze(10)
		living_mob.Knockdown(50)
		living_mob.soundbang_act(1, 100, 5, 5)
	else
		if(distance <= 1)
			living_mob.Paralyze(3)
			living_mob.Knockdown(15)
		living_mob.soundbang_act(1, max(50 / max(1, distance), 30), rand(0, 5))