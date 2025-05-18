/obj/item/clothing/shoes/horseshoes
	name = "insulated horseshoes"
	desc = "Rubber horseshoes that provide protection against electric shock."
	icon_state = "insulatedhorseshoes"
	equip_sound = 'sound/items/trayhit/trayhit1.ogg'
	fastening_type = SHOES_SLIPON
	custom_price = PAYCHECK_CREW * 10
	custom_premium_price = PAYCHECK_COMMAND * 6
	siemens_coefficient = 0
	strip_delay = 50
	equip_delay_other = 50

/obj/item/clothing/shoes/horseshoes/Initialize(mapload)
	. = ..()

