/obj/item/weapon/gun/projectile/svt
	name = "SVT-40"
	desc = "Soviet semi-automatic rifle chambered in 7.62x54mmR. Used by some guard units and defense units."
	icon_state = "svt"
	item_state = "svt"
	w_class = 4
	load_method = SPEEDLOADER | MAGAZINE
	max_shells = FALSE
	caliber = "a762x54"
	slot_flags = SLOT_BACK
	ammo_type = /obj/item/ammo_casing/a792x33
	accuracy = DEFAULT_SEMIAUTO_ACCURACY
	scoped_accuracy = DEFAULT_SEMIAUTO_SCOPED_ACCURACY
	magazine_type = /obj/item/ammo_magazine/svt
	firemodes = list(
		list(name="single shot",burst=1, move_delay=2, fire_delay=7)
		)

	gun_type = GUN_TYPE_RIFLE
	attachment_slots = ATTACH_IRONSIGHTS|ATTACH_SCOPE|ATTACH_BARREL
	force = 10
	throwforce = 20

/obj/item/weapon/gun/projectile/svt/update_icon()
	..()
	if(ammo_magazine)
		icon_state = "svt"
		item_state = "svt-mag"
	else
		icon_state = "svt0"
		item_state = "svt-0"
	return

/obj/item/weapon/gun/projectile/g41
	name = "Gewehr 41"
	desc = "German semi-automatic rifle using 7.92x57mm Mauser ammunition in a 10 round magazine. Devastating rifle."
	icon_state = "g43" //to-do
	item_state = "kar98k" //to-do
	w_class = 4
	load_method = SPEEDLOADER | MAGAZINE
	max_shells = FALSE
	caliber = "a792x57"
//	origin_tech = "combat=4;materials=2"
	slot_flags = SLOT_BACK
	ammo_type = /obj/item/ammo_casing/a792x57
	accuracy = DEFAULT_SEMIAUTO_ACCURACY
	scoped_accuracy = DEFAULT_SEMIAUTO_SCOPED_ACCURACY
	magazine_type = /obj/item/ammo_magazine/g41
	firemodes = list(
		list(name="single shot",burst=1, move_delay=4, fire_delay=10, dispersion = list(1))
		)
	force = 10
	throwforce = 20

/obj/item/weapon/gun/projectile/g41/update_icon()
	..()
	if(ammo_magazine)
		icon_state = "g43" //to-do
	else
		icon_state = "g430" //to-do
	return


/obj/item/weapon/gun/projectile/automatic/stg
	name = "STG-44"
	desc = "German assault rifle with a 30 round magazine, chambered in 7.92x33mm Kurz. It is a devastating weapon."
	icon_state = "stg"
	item_state = "stg"
	load_method = MAGAZINE
	slot_flags = SLOT_BACK|SLOT_BELT
	w_class = 3
	caliber = "a792x33"
	fire_sound = 'sound/weapons/stg.ogg'
	load_magazine_sound = 'sound/weapons/stg_reload.ogg'
	magazine_type = /obj/item/ammo_magazine/a792x33/stgmag

	accuracy = DEFAULT_SEMIAUTO_ACCURACY
	scoped_accuracy = DEFAULT_SEMIAUTO_SCOPED_ACCURACY

	can_wield = TRUE

/obj/item/weapon/gun/projectile/automatic/stg/update_icon()
	if(ammo_magazine)
		icon_state = "stg"
		if(wielded)
			item_state = "stg-w"
		else
			item_state = "stg"
	else
		icon_state = "stg0"
		if(wielded)
			item_state = "stg-w"
		else
			item_state = "stg0"
	update_held_icon()
	return


/obj/item/weapon/gun/projectile/automatic/akm
	name = "MP-43/B"
	desc = "German assault rifle chambered in 7.92x33mm Kurz, 30 round magazine. Variant of the STG-44, issued to SS, usually."
	icon_state = "stg"
	item_state = "stg"
	load_method = MAGAZINE
	slot_flags = SLOT_BACK|SLOT_BELT
	w_class = 4
	caliber = "a792x33"
	magazine_type = /obj/item/ammo_magazine/a762/akm

	accuracy = DEFAULT_SEMIAUTO_ACCURACY-1
	scoped_accuracy = DEFAULT_SEMIAUTO_SCOPED_ACCURACY

	can_wield = TRUE
	//must_wield = TRUE

	firemodes = list(
		list(name="semi automatic",	burst=1, burst_delay=0.8, move_delay=1, dispersion = list(0.2, 0.4, 0.4, 0.4, 0.6), accuracy = list(DEFAULT_SEMIAUTO_ACCURACY)),
		list(name="short bursts",	burst=3, burst_delay=1.0, move_delay=3, dispersion = list(0.6, 1.0, 1.0, 1.0, 1.2)),
		list(name="long bursts",	burst=5, burst_delay=1.2, move_delay=4, dispersion = list(1.0, 1.4, 1.4, 1.4, 1.6)),
		)

	sel_mode = 2

/obj/item/weapon/gun/projectile/automatic/akm/update_icon()
	if(ammo_magazine)
		icon_state = "stg"
		if(wielded)
			item_state = "stg-w"
		else
			item_state = "stg"
	else
		icon_state = "stg0"
		if(wielded)
			item_state = "stg-w"
		else
			item_state = "stg0"
	update_held_icon()
	return