/obj/item/bodypart/head
	name = BODY_ZONE_HEAD
	desc = "Didn't make sense not to live for fun, your brain gets smart but your head gets dumb."
	icon = 'icons/mob/human/bodyparts.dmi'
	icon_state = "default_human_head"
	max_damage = LIMB_MAX_HP_CORE
	body_zone = BODY_ZONE_HEAD
	body_part = HEAD
	plaintext_zone = "head"
	w_class = WEIGHT_CLASS_BULKY //Quite a hefty load
	slowdown = 1 //Balancing measure
	throw_range = 2 //No head bowling
	px_x = 0
	px_y = -8
	wound_resistance = 5
	disabled_wound_penalty = 25
	scars_covered_by_clothes = FALSE
	grind_results = null
	is_dimorphic = TRUE
	unarmed_attack_verbs = list("bite", "chomp")
	unarmed_attack_effect = ATTACK_EFFECT_BITE
	unarmed_attack_sound = 'sound/items/weapons/bite.ogg'
	unarmed_miss_sound = 'sound/items/weapons/bite.ogg'
	unarmed_damage_low = 1 // Yeah, biteing is pretty weak, blame the monkey super-nerf
	unarmed_damage_high = 3
	unarmed_effectiveness = 0
	bodypart_trait_source = HEAD_TRAIT

	/// Do we show the information about missing organs upon being examined? Defaults to TRUE, useful for Dullahan heads.
	var/show_organs_on_examine = TRUE

	//Limb appearance info:
	/// Replacement name
	var/real_name = ""
	/// Flags related to appearance, such as hair, lips, etc
	var/head_flags = HEAD_ALL_FEATURES

	/// Hair style
	var/hairstyle = "Bald"
	/// Hair colour and style
	var/hair_color = COLOR_BLACK
	/// Hair alpha
	var/hair_alpha = 255
	/// Is the hair currently hidden by something?
	var/hair_hidden = FALSE
	/// Lazy initialized hashset of all hair mask types that should be applied
	var/list/hair_masks

	///Facial hair style
	var/facial_hairstyle = "Shaved"
	///Facial hair color
	var/facial_hair_color = COLOR_BLACK
	///Facial hair alpha
	var/facial_hair_alpha = 255
	///Is the facial hair currently hidden by something?
	var/facial_hair_hidden = FALSE

	/// Gradient styles, if any
	var/list/gradient_styles = list(
		"None",	//Hair gradient style
		"None",	//Facial hair gradient style
	)
	/// Gradient colors, if any
	var/list/gradient_colors = list(
		COLOR_BLACK,	//Hair gradient color
		COLOR_BLACK,	//Facial hair gradient color
	)

	/// An override color that can be cleared later, affects both hair and facial hair
	var/override_hair_color = null
	/// An override that cannot be cleared under any circumstances, affects both hair and facial hair
	var/fixed_hair_color = null

	///Type of lipstick being used, basically
	var/lip_style
	///Lipstick color
	var/lip_color
	///Current lipstick trait, if any (such as TRAIT_KISS_OF_DEATH)
	var/stored_lipstick_trait

	/// How many teeth the head's species has, humans have 32 so that's the default. Used for a limit to dental pill implants.
	var/teeth_count = 32

	/// Offset to apply to equipment worn on the ears
	var/datum/worn_feature_offset/worn_ears_offset
	/// Offset to apply to equipment worn on the eyes
	var/datum/worn_feature_offset/worn_glasses_offset
	/// Offset to apply to equipment worn on the mouth
	var/datum/worn_feature_offset/worn_mask_offset
	/// Offset to apply to equipment worn on the head
	var/datum/worn_feature_offset/worn_head_offset
	/// Offset to apply to overlays placed on the face
	var/datum/worn_feature_offset/worn_face_offset
	/// Offset to apply to the eye overlays
	var/datum/worn_feature_offset/eye_offset

	VAR_PROTECTED
		/// Draw this head as "debrained"
		show_debrained = FALSE

		/// Draw this head as missing eyes
		show_eyeless = FALSE

		/// Can this head be dismembered normally?
		can_dismember = FALSE

/**
 * Takes in any hairstyle and manipulates it to fit a mob's HEAD.
 *
 * * gotten_hairstyle - the hairstyle that we were passed from something else (a hairstyle ON THE HEAD, since there is also a separate /mob/living/carbon/human body hairstyle,    yea)
 * * gotten_head_of_the_mob - the head that we were passed FROM somewhere else TO this proc and GOTTEN by this proc
 * * owner_of_the_head_with_a_hairstyle_change - the head's owner (my_head.owner as per `head_hair_and_lips.dm`) passed as mob/living/carbon/, a leftover from when this was used to call a debug balloon_alert().
 *
 * If the parent proc at /obj/item/bodypart/head/ encounters a non-human(oid) head it just does fuckall and moves on to the other type of head calling this proc -
 * you are supposed to call this very same proc on your /obj/item/bodypart/head/gargantuar/arbitrary_hairstyle_offsetter() or whatever with custom offsets and scaling.
 *
 * Most hairstyles are humanOID-centric, and if this proc encounters a specific non-human hair (Equestrian, Subterranean, Manticorian, *fucking whatever*),
 * it will manipulate the hair however necessary to fit the human head. HOWEVER, IT'S BETTER FOR HUMANS AND EVERYPONY ELSE IF THEY STICK TO THEIR OWN INTENDED HAIRS.
 *
 * This function is currently getting called from `head_hair_and_lips.dm`'s set_hairstyle() proc,
 * which got modified to update ONLY after this is done, and therefore expects this to return TRUE so it can proceed to update_body_parts() there.
 */
/obj/item/bodypart/head/proc/arbitrary_hairstyle_offsetter(gotten_hairstyle, obj/item/bodypart/head/gotten_head_of_the_mob, mob/living/carbon/owner_of_the_head_with_a_hairstyle_change) // I think this fucking sucks but it also works. what do
	QDEL_NULL(worn_face_offset)

	// checking if our HEAD is HUMAN(OID) (or, rather, NON-PONY, since all the other races (species) are "just" reskinned humanoids and don't need any extra special hair treatment, and currently we only have ponies as the only species with unusual hairstyle offset needs);
    // checking for the EXACT TYPE and not a subtype like "istype()" does (example taken from ``[/datum/reagent/consumable/ethanol/screwdrivercocktail/on_new(data)] of `alcohol_reagents.dm` at October 16, 2025``)
	if(gotten_head_of_the_mob.type != /obj/item/bodypart/head/pony)
		// our HEAD is not a pony, therefore HUMAN(OID); (otherwise don't do anything and let another /head/nonhumanoidhead/arbitrary_hairstyle_offsetter() to do their own head-specific code, that's their problem!)
		if(findtext("[gotten_hairstyle]", "Equestrian")) // only do offsets and smush-scaling if this is a human head and the hair on it is pony (if we find PONY (non-humanoid) HAIR on our HUMAN(OID) HEAD...)
			worn_face_offset = new(
				attached_part = src,
				feature_key = OFFSET_FACE,
				offset_x = list("north" = 0, "south" = 0, "east" = -3, "west" = 3),
				offset_y = list("north" = 4, "south" = 4, "east" = 4, "west" = 4),
				size_modifier = list("north" = 0.8, "south" = 0.8, "east" = 0.8, "west" = 0.8)
			)

	return TRUE

/obj/item/bodypart/head/Destroy()
	QDEL_NULL(worn_ears_offset)
	QDEL_NULL(worn_glasses_offset)
	QDEL_NULL(worn_mask_offset)
	QDEL_NULL(worn_head_offset)
	QDEL_NULL(worn_face_offset)
	QDEL_NULL(eye_offset)
	return ..()

/obj/item/bodypart/head/examine(mob/user)
	. = ..()
	if(show_organs_on_examine && IS_ORGANIC_LIMB(src))
		var/obj/item/organ/brain/brain = locate(/obj/item/organ/brain) in src
		if(!brain)
			. += span_info("The brain has been removed from [src].")
		else if(brain.suicided || (brain.brainmob && HAS_TRAIT(brain.brainmob, TRAIT_SUICIDED)))
			. += span_info("There's a miserable expression on [real_name]'s face; they must have really hated life. There's no hope of recovery.")
		else if(brain.brainmob)
			if(brain.brainmob?.health <= HEALTH_THRESHOLD_DEAD)
				. += span_info("It's leaking some kind of... clear fluid? The brain inside must be in pretty bad shape.")
			if(brain.brainmob.key || brain.brainmob.get_ghost(FALSE, TRUE))
				. += span_info("Its muscles are twitching slightly... It seems to have some life still in it.")
			else
				. += span_info("It's completely lifeless. Perhaps there'll be a chance for them later.")
		else if(brain?.decoy_override)
			. += span_info("It's completely lifeless. Perhaps there'll be a chance for them later.")
		else
			. += span_info("It's completely lifeless.")

		if(!(locate(/obj/item/organ/eyes) in src))
			. += span_info("[real_name]'s eyes have been removed.")

		if(!(locate(/obj/item/organ/ears) in src))
			. += span_info("[real_name]'s ears have been removed.")

		if(!(locate(/obj/item/organ/tongue) in src))
			. += span_info("[real_name]'s tongue has been removed.")

/obj/item/bodypart/head/can_dismember(obj/item/item)
	if (!can_dismember)
		return FALSE

	if(!HAS_TRAIT(owner, TRAIT_CURSED) && owner.stat < HARD_CRIT)
		return FALSE

	return ..()

/obj/item/bodypart/head/drop_organs(mob/user, violent_removal)
	if(user)
		user.visible_message(span_warning("[user] saws [src] open and pulls out a brain!"), span_notice("You saw [src] open and pull out a brain."))
	var/obj/item/organ/brain/brain = locate(/obj/item/organ/brain) in src
	if(brain && violent_removal && prob(90)) //ghetto surgery can damage the brain.
		to_chat(user, span_warning("[brain] was damaged in the process!"))
		brain.set_organ_damage(brain.maxHealth)

	update_limb()
	return ..()

/obj/item/bodypart/head/update_limb(dropping_limb, is_creating)
	. = ..()
	if(!isnull(owner))
		if(HAS_TRAIT(owner, TRAIT_HUSK))
			real_name = "Unknown"
		else
			real_name = owner.real_name
	update_hair_and_lips(dropping_limb, is_creating)

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/obj/item/bodypart/head/get_limb_icon(dropped, mob/living/carbon/update_on)
	. = ..()

	. += get_hair_and_lips_icon(dropped)
	// We need to get the eyes if we are dropped (ugh)
	if(dropped)
		var/obj/item/organ/eyes/eyes = locate(/obj/item/organ/eyes) in src
		// This is a bit of copy/paste code from eyes.dm:generate_body_overlay
		if(eyes?.eye_icon_state && (head_flags & HEAD_EYESPRITES))
			var/image/eye_left = image('icons/mob/human/human_face.dmi', "[eyes.eye_icon_state]_l", -BODY_LAYER, SOUTH)
			var/image/eye_right = image('icons/mob/human/human_face.dmi', "[eyes.eye_icon_state]_r", -BODY_LAYER, SOUTH)
			if(head_flags & HEAD_EYECOLOR)
				if(eyes.eye_color_left)
					eye_left.color = eyes.eye_color_left
				if(eyes.eye_color_right)
					eye_right.color = eyes.eye_color_right
			if(eyes.overlay_ignore_lighting)
				eye_left.overlays += emissive_appearance(eye_left.icon, eye_left.icon_state, src, alpha = eye_left.alpha)
				eye_right.overlays += emissive_appearance(eye_right.icon, eye_right.icon_state, src, alpha = eye_right.alpha)
			else if(blocks_emissive != EMISSIVE_BLOCK_NONE)
				var/atom/location = loc || owner || src
				eye_left.overlays += emissive_blocker(eye_left.icon, eye_left.icon_state, location, alpha = eye_left.alpha)
				eye_right.overlays += emissive_blocker(eye_right.icon, eye_right.icon_state, location, alpha = eye_right.alpha)
			if(eye_offset)
				eye_offset?.apply_offset(eye_left)
				eye_offset?.apply_offset(eye_right)
			. += eye_left
			. += eye_right
		else if(!eyes && (head_flags & HEAD_EYEHOLES))
			var/image/no_eyes = image('icons/mob/human/human_face.dmi', "eyes_missing", -BODY_LAYER, SOUTH)
			eye_offset?.apply_offset(no_eyes)
			. += no_eyes

	return

/obj/item/bodypart/head/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/toy_talk)

/obj/item/bodypart/head/GetVoice()
	return "The head of [real_name]"

/obj/item/bodypart/head/monkey
	icon = 'icons/mob/human/species/monkey/bodyparts.dmi'
	icon_static = 'icons/mob/human/species/monkey/bodyparts.dmi'
	icon_husk = 'icons/mob/human/species/monkey/bodyparts.dmi'
	husk_type = "monkey"
	icon_state = "default_monkey_head"
	limb_id = SPECIES_MONKEY
	bodyshape = BODYSHAPE_MONKEY
	should_draw_greyscale = FALSE
	dmg_overlay_type = SPECIES_MONKEY
	is_dimorphic = FALSE
	head_flags = HEAD_LIPS|HEAD_DEBRAIN

/obj/item/bodypart/head/monkey/Initialize(mapload)
	worn_head_offset = new(
		attached_part = src,
		feature_key = OFFSET_HEAD,
		offset_y = list("south" = 1),
	)
	worn_glasses_offset = new(
		attached_part = src,
		feature_key = OFFSET_GLASSES,
		offset_y = list("south" = 1),
	)
	return ..()

/obj/item/bodypart/head/alien
	icon = 'icons/mob/human/species/alien/bodyparts.dmi'
	icon_static = 'icons/mob/human/species/alien/bodyparts.dmi'
	icon_state = "alien_head"
	limb_id = BODYPART_ID_ALIEN
	is_dimorphic = FALSE
	should_draw_greyscale = FALSE
	px_x = 0
	px_y = 0
	bodypart_flags = BODYPART_UNREMOVABLE
	max_damage = LIMB_MAX_HP_ALIEN_CORE
	burn_modifier = LIMB_ALIEN_BURN_DAMAGE_MULTIPLIER
	bodytype = BODYTYPE_ALIEN | BODYTYPE_ORGANIC
	bodyshape = BODYSHAPE_HUMANOID

/obj/item/bodypart/head/larva
	icon = 'icons/mob/human/species/alien/bodyparts.dmi'
	icon_static = 'icons/mob/human/species/alien/bodyparts.dmi'
	icon_state = "larva_head"
	limb_id = BODYPART_ID_LARVA
	is_dimorphic = FALSE
	should_draw_greyscale = FALSE
	px_x = 0
	px_y = 0
	bodypart_flags = BODYPART_UNREMOVABLE
	max_damage = LIMB_MAX_HP_ALIEN_LARVA
	burn_modifier = LIMB_ALIEN_BURN_DAMAGE_MULTIPLIER
	bodytype = BODYTYPE_LARVA_PLACEHOLDER | BODYTYPE_ORGANIC
