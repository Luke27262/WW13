/obj/item/weapon/storage/bible
	name = "Testament of Terra"
	desc = "Apply to head repeatedly."
	icon_state ="bible"
	item_state = "bible"
	throw_speed = TRUE
	throw_range = 5
	w_class = 3.0
	var/mob/affecting = null

/obj/item/weapon/storage/bible/booze
	name = "bible"
	desc = "To be applied to the head repeatedly."
	icon_state ="bible"

/obj/item/weapon/storage/bible/booze/New()
	..()
	new /obj/item/weapon/reagent_containers/food/drinks/bottle/small/beer(src)
	new /obj/item/weapon/reagent_containers/food/drinks/bottle/small/beer(src)
//	new /obj/item/weapon/spacecash(src)
//	new /obj/item/weapon/spacecash(src)
//	new /obj/item/weapon/spacecash(src)

/obj/item/weapon/storage/bible/afterattack(atom/A, mob/user as mob, proximity)
	if(!proximity) return
	if(user.mind && (user.mind.assigned_role == "Monochurch Preacher"))
		if(A.reagents && A.reagents.has_reagent("water")) //blesses all the water in the holder
			user << "<span class='notice'>You bless [A].</span>"
			var/water2holy = A.reagents.get_reagent_amount("water")
			A.reagents.del_reagent("water")
			A.reagents.add_reagent("holywater",water2holy)

/obj/item/weapon/storage/bible/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if (use_sound)
		playsound(loc, use_sound, 50, TRUE, -5)
	..()
