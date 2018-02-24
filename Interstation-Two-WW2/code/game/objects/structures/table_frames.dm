/* Table Frames
 * Contains:
 *		Frames
 *		Wooden Frames
 */


/*
 * Normal Frames
 */

/obj/structure/table_frame
	name = "table frame"
	desc = "Four metal legs with four framing rods for a table. You could easily pass through this."
	icon = 'icons/obj/structures_FO13.dmi'
	icon_state = "table_frame"
	density = FALSE
	anchored = FALSE
	layer = 2.8
	var/framestack = /obj/item/stack/rods
	var/framestackamount = 2

/obj/structure/table_frame/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/weapon/wrench))
		user << "<span class='notice'>You start disassembling [src]...</span>"
		playsound(loc, 'sound/items/Ratchet.ogg', 50, TRUE)
		if(do_after(user, 30, target = src))
			playsound(loc, 'sound/items/Deconstruct.ogg', 50, TRUE)
			for(var/i = TRUE, i <= framestackamount, i++)
				new framestack(get_turf(src))
			qdel(src)
			return
	if(istype(I, /obj/item/stack/material/iron))
		var/obj/item/stack/material/iron/M = I
		if(M.get_amount() < TRUE)
			user << "<span class='warning'>You need one metal sheet to do this!</span>"
			return
		user << "<span class='notice'>You start adding [M] to [src]...</span>"
		if(do_after(user, 20, target = src))
			M.use(1)
			new /obj/structure/table(loc)
			qdel(src)
		return
	if(istype(I, /obj/item/stack/material/glass))
		var/obj/item/stack/material/glass/G = I
		if(G.get_amount() < TRUE)
			user << "<span class='warning'>You need one glass sheet to do this!</span>"
			return
		user << "<span class='notice'>You start adding [G] to [src]...</span>"
		if(do_after(user, 20, target = src))
			G.use(1)

			new /obj/structure/table/glass(loc)
			qdel(src)
		return
	if(istype(I, /obj/item/stack/material/silver))
		var/obj/item/stack/material/silver/S = I
		if(S.get_amount() < TRUE)
			user << "<span class='warning'>You need one silver sheet to do this!</span>"
			return
		user << "<span class='notice'>You start adding [S] to [src]...</span>"
		if(do_after(user, 20, target = src))
			S.use(1)
			new /obj/structure/table/optable(loc)
			qdel(src)
		return

/*
 * Wooden Frames
 */

/obj/structure/table_frame/wood
	name = "wooden table frame"
	desc = "Four wooden legs with four framing wooden rods for a wooden table. You could easily pass through this."
	icon_state = "wood_frame"
	framestack = /obj/item/stack/material/wood
	framestackamount = 2

/obj/structure/table_frame/wood/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/weapon/wrench))
		..()
	if(istype(I, /obj/item/stack/material/wood))
		var/obj/item/stack/material/wood/W = I
		if(W.get_amount() < TRUE)
			user << "<span class='warning'>You need one wood sheet to do this!</span>"
			return
		user << "<span class='notice'>You start adding [W] to [src]...</span>"
		if(do_after(user, 20, target = src))
			W.use(1)
			new /obj/structure/table/wood(loc)
			qdel(src)
		return
	if(istype(I, /obj/item/stack/tile/carpet))
		var/obj/item/stack/tile/carpet/C = I
		if(C.get_amount() < TRUE)
			user << "<span class='warning'>You need one carpet sheet to do this!</span>"
			return
		user << "<span class='notice'>You start adding [C] to [src]...</span>"
		if(do_after(user, 20, target = src))
			C.use(1)
			new /obj/structure/table/wood/poker(loc)
			qdel(src)
		return
