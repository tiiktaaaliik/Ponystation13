
/// Pony grounded moodlets.
/datum/mood_event/pony_grounded
	description = "Being in space is rough for me. I feel more secure standing on this grounding surface!"
	mood_change = 2

/datum/mood_event/mirror_neuron
	description = "Someone just got hurt, fuck! God, I can feel it!"
	mood_change = -3
	timeout = 5 MINUTES

/datum/mood_event/mirror_neuron/add_effects(mob/wounded_individual)
	description = "\The [wounded_individual.name] just got hurt, fuck! God, I can feel it!"

// bat ponies disliking the light

/datum/addiction/maintenance_drugs/withdrawal_stage_3_process(mob/living/carbon/affected_carbon)
	if(!ishuman(affected_carbon))
		return
	var/mob/living/carbon/human/affected_human = affected_carbon
	var/turf/T = get_turf(affected_human)
	var/lums = T.get_lumcount()
	if(lums > 0.5)
		affected_human.add_mood_event("dislike_light", /datum/mood_event/dislike_light)
	else
		affected_carbon.clear_mood_event("dislike_light")

/datum/mood_event/dislike_light
	description = "I feel exposed, it's so bright.."
	mood_change = -4