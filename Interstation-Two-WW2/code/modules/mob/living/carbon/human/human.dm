/mob/living/carbon/human
	name = "unknown"
	real_name = "unknown"
	voice_name = "unknown"
	icon = 'icons/mob/human.dmi'
	icon_state = "body_m_s"

/mob/living/carbon/human/New(var/new_loc, var/new_species = null)

	body_build = get_body_build(gender)

	if(!dna)
		dna = new /datum/dna(null)
		// Species name is handled by set_species()

	if(!species)
		if(new_species)
			set_species(new_species,1)
		else
			set_species()

	if(species)
		real_name = species.get_random_name(gender)
		name = real_name
		if(mind)
			mind.name = real_name

	hud_list[HEALTH_HUD]      = image('icons/mob/hud.dmi', src, "hudhealth100")
	hud_list[STATUS_HUD]      = image('icons/mob/hud.dmi', src, "hudhealthy")
	hud_list[LIFE_HUD]	      = image('icons/mob/hud.dmi', src, "hudhealthy")
	hud_list[ID_HUD]          = image('icons/mob/hud.dmi', src, "hudunknown")
	hud_list[WANTED_HUD]      = image('icons/mob/hud.dmi', src, "hudblank")
	hud_list[IMPLOYAL_HUD]    = image('icons/mob/hud.dmi', src, "hudblank")
	hud_list[IMPCHEM_HUD]     = image('icons/mob/hud.dmi', src, "hudblank")
	hud_list[IMPTRACK_HUD]    = image('icons/mob/hud.dmi', src, "hudblank")
	hud_list[SPECIALROLE_HUD] = image('icons/mob/hud.dmi', src, "hudblank")
	hud_list[STATUS_HUD_OOC]  = image('icons/mob/hud.dmi', src, "hudhealthy")

	for (var/v in FACTION_TO_ENEMIES to SQUAD_FACTION)
		hud_list[v] = image('icons/mob/hud_WW2.dmi', src, "")

	human_mob_list |= src

	..()

	var/obj/item/organ/external/head/U = locate() in organs
	if(istype(U))
		U.teeth_list.Cut() //Clear out their mouth of teeth
		var/obj/item/stack/teeth/T = new species.teeth_type(U)
		U.max_teeth = T.max_amount //Set max teeth for the head based on teeth spawntype
		T.amount = T.max_amount
		U.teeth_list += T

	if(dna)
		dna.ready_dna(src)
		dna.real_name = real_name
		sync_organ_dna()

	make_blood()

	spawn (10)
		if (client)
			human_clients_mob_list |= src

/mob/living/carbon/human/Destroy()
	human_mob_list -= src
	human_clients_mob_list -= src
	for(var/organ in organs)
		qdel(organ)
	return ..()

/mob/living/carbon/human/Stat()
	. = ..()
	if (.)
		if(statpanel("Status"))
			stat("Intent:", "[a_intent]")
			stat("Move Mode:", "[m_intent]")
			if (internal)
				if (!internal.air_contents)
					qdel(internal)
				else
					stat("Internal Atmosphere Info", internal.name)
					stat("Tank Pressure", internal.air_contents.return_pressure())
					stat("Distribution Pressure", internal.distribute_pressure)

			stat("<br>STATS<br>")
			for (var/statname in stats)
				var/coeff = getStatCoeff(statname)
				if (coeff == TRUE)
					coeff = "1.00" // OCD
				if (statname != "mg")
					stat("[capitalize(statname)]: ", "[coeff]x average")
				else
					stat("[uppertext(statname)]: ", "[coeff]x average")

			stat("Stamina: ", "[round(stamina/max_stamina) * 100]%")

			if (istype(loc, /obj/tank))
				var/obj/tank/tank = loc
				var/fuel_slot_screwed = tank.fuel_slot_screwed ? "Screwed," : "Unscrewed,"
				var/fuel_slot_open = tank.fuel_slot_open ? " open" : " closed"
				stat("<br>TANK INFORMATION<br>")
				stat("Tank Integrity:", tank.health_percentage())
				stat("Ready to fire?:", (world.time - tank.last_fire > tank.fire_delay || tank.last_fire == -1) ? "Yes" : "No")
				stat("Fuel Slot:", "[fuel_slot_screwed][fuel_slot_open].")
				stat("Fuel:", "[round((tank.fuel/tank.max_fuel)*100)]%")

/mob/living/carbon/human/ex_act(severity)
	if(!blinded)
		if (HUDtech.Find("flash"))
			flick("flash", HUDtech["flash"])

	var/shielded = FALSE
	var/b_loss = null
	var/f_loss = null
	switch (severity)
		if (1.0)
			b_loss += 500
			if (!prob(getarmor(null, "bomb")))
				crush()
				return
			else
				var/atom/target = get_edge_target_turf(src, get_dir(src, get_step_away(src, src)))
				throw_at(target, 200, 4)
			//return
//				var/atom/target = get_edge_target_turf(user, get_dir(src, get_step_away(user, src)))
				//user.throw_at(target, 200, 4)

		if (2.0)
			if (!shielded)
				b_loss += 60

			f_loss += 60

			if (prob(getarmor(null, "bomb")))
				b_loss = b_loss/1.5
				f_loss = f_loss/1.5

			if (!istype(l_ear, /obj/item/clothing/ears/earmuffs) && !istype(r_ear, /obj/item/clothing/ears/earmuffs))
				ear_damage += 30
				ear_deaf += 120
			if (prob(70) && !shielded)
				Paralyse(10)

		if(3.0)
			b_loss += 30
			if (prob(getarmor(null, "bomb")))
				b_loss = b_loss/2
			if (!istype(l_ear, /obj/item/clothing/ears/earmuffs) && !istype(r_ear, /obj/item/clothing/ears/earmuffs))
				ear_damage += 15
				ear_deaf += 60
			if (prob(50) && !shielded)
				Paralyse(10)

	var/update = FALSE

	// focus most of the blast on one organ
	var/obj/item/organ/external/take_blast = pick(organs)
	update |= take_blast.take_damage(b_loss * 0.9, f_loss * 0.9, used_weapon = "Explosive blast")

	// distribute the remaining 10% on all limbs equally
	b_loss *= 0.1
	f_loss *= 0.1

	var/weapon_message = "Explosive Blast"

	for(var/obj/item/organ/external/temp in organs)
		switch(temp.name)
			if("head")
				update |= temp.take_damage(b_loss * 0.2, f_loss * 0.2, used_weapon = weapon_message)
			if("chest")
				update |= temp.take_damage(b_loss * 0.4, f_loss * 0.4, used_weapon = weapon_message)
			if("l_arm")
				update |= temp.take_damage(b_loss * 0.05, f_loss * 0.05, used_weapon = weapon_message)
			if("r_arm")
				update |= temp.take_damage(b_loss * 0.05, f_loss * 0.05, used_weapon = weapon_message)
			if("l_leg")
				update |= temp.take_damage(b_loss * 0.05, f_loss * 0.05, used_weapon = weapon_message)
			if("r_leg")
				update |= temp.take_damage(b_loss * 0.05, f_loss * 0.05, used_weapon = weapon_message)
			if("r_foot")
				update |= temp.take_damage(b_loss * 0.05, f_loss * 0.05, used_weapon = weapon_message)
			if("l_foot")
				update |= temp.take_damage(b_loss * 0.05, f_loss * 0.05, used_weapon = weapon_message)
			if("r_arm")
				update |= temp.take_damage(b_loss * 0.05, f_loss * 0.05, used_weapon = weapon_message)
			if("l_arm")
				update |= temp.take_damage(b_loss * 0.05, f_loss * 0.05, used_weapon = weapon_message)
	if(update)	UpdateDamageIcon()


/mob/living/carbon/human/restrained()
	if (handcuffed)
		return TRUE
	if (istype(wear_suit, /obj/item/clothing/suit/straight_jacket))
		return TRUE
	return FALSE

/mob/living/carbon/human/var/co2overloadtime = null
/mob/living/carbon/human/var/temperature_resistance = T0C+75


/mob/living/carbon/human/show_inv(mob/user as mob)
	if(user.incapacitated()  || !user.Adjacent(src))
		return

	var/obj/item/clothing/under/suit = null
	if (istype(w_uniform, /obj/item/clothing/under))
		suit = w_uniform

	user.set_machine(src)
	var/dat = "<B><HR><FONT size=3>[name]</FONT></B><BR><HR>"

	for(var/entry in species.hud.gear)
		var/slot = species.hud.gear[entry]
		if(slot in list(slot_l_store, slot_r_store))
			continue
		var/obj/item/thing_in_slot = get_equipped_item(slot)
		dat += "<BR><B>[entry]:</b> <a href='?src=\ref[src];item=[slot]'>[istype(thing_in_slot) ? thing_in_slot : "nothing"]</a>"

	dat += "<BR><HR>"

	if(species.hud.has_hands)
		dat += "<BR><b>Left hand:</b> <A href='?src=\ref[src];item=[slot_l_hand]'>[istype(l_hand) ? l_hand : "nothing"]</A>"
		dat += "<BR><b>Right hand:</b> <A href='?src=\ref[src];item=[slot_r_hand]'>[istype(r_hand) ? r_hand : "nothing"]</A>"

	// Do they get an option to set internals?
	if(istype(wear_mask, /obj/item/clothing/mask))
		if(istype(back, /obj/item/weapon/tank) || istype(belt, /obj/item/weapon/tank) || istype(s_store, /obj/item/weapon/tank))
			dat += "<BR><A href='?src=\ref[src];item=internals'>Toggle internals.</A>"

	// Other incidentals.
/*	if(istype(suit) && suit.has_sensor == TRUE)
		dat += "<BR><A href='?src=\ref[src];item=sensors'>Set sensors</A>"*/
	if(handcuffed)
		dat += "<BR><A href='?src=\ref[src];item=[slot_handcuffed]'>Handcuffed</A>"
	if(legcuffed)
		dat += "<BR><A href='?src=\ref[src];item=[slot_legcuffed]'>Legcuffed</A>"

	if(suit && suit.accessories.len)
		dat += "<BR><A href='?src=\ref[src];item=tie'>Remove accessory</A>"
	dat += "<BR><A href='?src=\ref[src];item=splints'>Remove splints</A>"
	dat += "<BR><A href='?src=\ref[src];item=pockets'>Empty pockets</A>"
	dat += "<BR><A href='?src=\ref[user];refresh=1'>Refresh</A>"
	dat += "<BR><A href='?src=\ref[user];mach_close=mob[name]'>Close</A>"

	user << browse(dat, text("window=mob[name];size=340x540"))
	onclose(user, "mob[name]")
	return

// Get rank from ID, ID inside PDA, PDA, ID in wallet, etc.
/mob/living/carbon/human/proc/get_authentification_rank(var/if_no_id = "No id", var/if_no_job = "No job")
	return if_no_id


//gets name from ID or ID inside PDA or PDA itself
//Useful when player do something with computers
/mob/living/carbon/human/proc/get_authentification_name(var/if_no_id = "Unknown")
	return if_no_id

//Trust me I'm an engineer
//I think we'll put this shit right here
var/list/rank_prefix = list(\
	"Ironhammer Operative" = "Operative",\
	"Inspector" = "Inspector",\
	"Gunnery Sergeant" = "Sergeant",\
	"Ironhammer Commander" = "Lieutenant",\
	"Captain" = "Captain",\
	)

/mob/living/carbon/human/proc/rank_prefix_name(name)
	if(get_natural_rank())
		if(findtext(name, " "))
			name = copytext(name, findtext(name, " "))
		name = get_natural_rank() + " " + name
	return name

//repurposed proc. Now it combines get_id_name() and get_face_name() to determine a mob's name variable. Made into a seperate proc as it'll be useful elsewhere
/mob/living/carbon/human/proc/get_visible_name()
	if((wear_mask && (wear_mask.flags_inv&HIDEFACE)) || (head && (head.flags_inv&HIDEFACE)))	//Wearing a mask which hides our face, use id-name if possible	//Likewise for hats
		return rank_prefix_name(get_id_name())

	var/face_name = get_face_name()
	var/id_name = get_id_name("")
	if(id_name)
		if(id_name != face_name)
			return "[face_name] (as [rank_prefix_name(id_name)])"
		else
			return rank_prefix_name(id_name)
	return face_name

//Returns "Unknown" if facially disfigured and real_name if not. Useful for setting name when polyacided or when updating a human's name variable
/mob/living/carbon/human/proc/get_face_name()
	var/obj/item/organ/external/head = get_organ("head")
	if(!head || head.disfigured || head.is_stump() || !real_name || (HUSK in mutations) )	//disfigured. use id-name if possible
		return "Unknown"
	return real_name

//gets name from ID or PDA itself, ID inside PDA doesn't matter
//Useful when player is being seen by other mobs
/mob/living/carbon/human/proc/get_id_name(var/if_no_id = "Unknown")
	return if_no_id

/mob/living/carbon/human/proc/get_id_rank()
	return ""

/mob/living/carbon/human/proc/get_natural_rank()
	return ""

/*
//gets ID card object from special clothes slot or null.
/mob/living/carbon/human/proc/get_idcard()
	if(wear_id)
		return wear_id.GetID()*/

//Removed the horrible safety parameter. It was only being used by ninja code anyways.
//Now checks siemens_coefficient of the affected area by default
/mob/living/carbon/human/electrocute_act(var/shock_damage, var/obj/source, var/base_siemens_coeff = 1.0, var/def_zone = null)
	if(status_flags & GODMODE)	return FALSE	//godmode

	if (!def_zone)
		def_zone = pick("l_hand", "r_hand")

	var/obj/item/organ/external/affected_organ = get_organ(check_zone(def_zone))
	var/siemens_coeff = base_siemens_coeff * get_siemens_coefficient_organ(affected_organ)

	return ..(shock_damage, source, siemens_coeff, def_zone)


/mob/living/carbon/human/Topic(href, href_list)

	if (href_list["refresh"])
		if((machine)&&(in_range(src, usr)))
			show_inv(machine)

	if (href_list["mach_close"])
		var/t1 = text("window=[]", href_list["mach_close"])
		unset_machine()
		src << browse(null, t1)

	if(href_list["item"])
		handle_strip(href_list["item"],usr)

	if (href_list["lookitem"])
		var/obj/item/I = locate(href_list["lookitem"])
		examinate(I)

	if (href_list["lookmob"])
		var/mob/M = locate(href_list["lookmob"])
		examinate(M)

	..()
	return

///eyecheck()
///Returns a number between -1 to 2
/mob/living/carbon/human/eyecheck()
	if(!species.has_organ["eyes"]) //No eyes, can't hurt them.
		return FLASH_PROTECTION_MAJOR

	if(internal_organs_by_name["eyes"]) // Eyes are fucked, not a 'weak point'.
		var/obj/item/organ/I = internal_organs_by_name["eyes"]
		if(I.status & ORGAN_CUT_AWAY)
			return FLASH_PROTECTION_MAJOR

	return flash_protection

//Used by various things that knock people out by applying blunt trauma to the head.
//Checks that the species has a "head" (brain containing organ) and that hit_zone refers to it.
/mob/living/carbon/human/proc/headcheck(var/target_zone, var/brain_tag = "brain")
	if(!species.has_organ[brain_tag])
		return FALSE

	var/obj/item/organ/affecting = internal_organs_by_name[brain_tag]

	target_zone = check_zone(target_zone)
	if(!affecting || affecting.parent_organ != target_zone)
		return FALSE

	//if the parent organ is significantly larger than the brain organ, then hitting it is not guaranteed
	var/obj/item/organ/parent = get_organ(target_zone)
	if(!parent)
		return FALSE

	if(parent.w_class > affecting.w_class + TRUE)
		return prob(100 / 2**(parent.w_class - affecting.w_class - TRUE))

	return TRUE

/mob/living/carbon/human/IsAdvancedToolUser(var/silent)
	if(species.has_fine_manipulation)
		return TRUE
	if(!silent)
		src << "<span class='warning'>You don't have the dexterity to use that!</span>"
	return FALSE

/mob/living/carbon/human/abiotic(var/full_body = FALSE)
	if(full_body && ((l_hand && !( l_hand.abstract )) || (r_hand && !( r_hand.abstract )) || (back || wear_mask || head || shoes || w_uniform || wear_suit || glasses || l_ear || r_ear || gloves)))
		return TRUE

	if( (l_hand && !l_hand.abstract) || (r_hand && !r_hand.abstract) )
		return TRUE

	return FALSE


/mob/living/carbon/human/proc/check_dna()
	dna.check_integrity(src)
	return

/mob/living/carbon/human/get_species()
	if(!species)
		set_species()
	return species.name

/mob/living/carbon/human/proc/play_xylophone()
	if(!xylophone)
		visible_message("<span class = 'red'>\The [src] begins playing \his ribcage like a xylophone. It's quite spooky.</span>","<span class = 'notice'>You begin to play a spooky refrain on your ribcage.</span>","<span class = 'red'>You hear a spooky xylophone melody.</span>")
		var/song = pick('sound/effects/xylophone1.ogg','sound/effects/xylophone2.ogg','sound/effects/xylophone3.ogg')
		playsound(loc, song, 50, TRUE, -1)
		xylophone = TRUE
		spawn(1200)
			xylophone=0
	return

/mob/living/carbon/human/proc/check_has_mouth()
	// Todo, check stomach organ when implemented.
	var/obj/item/organ/external/head/H = get_organ("head")
	if(!H || !H.can_intake_reagents)
		return FALSE
	return TRUE

/mob/living/carbon/human/proc/vomit()

	if(!check_has_mouth())
		return
	if(stat == DEAD)
		return
	if(!lastpuke)
		lastpuke = TRUE
		src << "<span class='warning'>You feel nauseous...</span>"
		spawn(150)	//15 seconds until second warning
			src << "<span class='warning'>You feel like you are about to throw up!</span>"
			spawn(100)	//and you have 10 more for mad dash to the bucket
				Stun(5)

				visible_message("<span class='warning'>[src] throws up!</span>","<span class='warning'>You throw up!</span>")
				playsound(loc, 'sound/effects/splat.ogg', 50, TRUE)

				var/turf/location = loc
				if (istype(location, /turf))
					location.add_vomit_floor(src, TRUE)

				nutrition -= 40
				adjustToxLoss(-3)
				spawn(350)	//wait 35 seconds before next volley
					lastpuke = FALSE

/mob/living/carbon/human/proc/morph()
	set name = "Morph"
	set category = "Superpower"

	if(stat!=CONSCIOUS)
		reset_view(0)
		remoteview_target = null
		return

	if(!(mMorph in mutations))
		verbs -= /mob/living/carbon/human/proc/morph
		return

	var/new_facial = input("Please select facial hair color.", "Character Generation",rgb(r_facial,g_facial,b_facial)) as color
	if(new_facial)
		r_facial = hex2num(copytext(new_facial, 2, 4))
		g_facial = hex2num(copytext(new_facial, 4, 6))
		b_facial = hex2num(copytext(new_facial, 6, 8))

	var/new_hair = input("Please select hair color.", "Character Generation",rgb(r_hair,g_hair,b_hair)) as color
	if(new_facial)
		r_hair = hex2num(copytext(new_hair, 2, 4))
		g_hair = hex2num(copytext(new_hair, 4, 6))
		b_hair = hex2num(copytext(new_hair, 6, 8))

	var/new_eyes = input("Please select eye color.", "Character Generation",rgb(r_eyes,g_eyes,b_eyes)) as color
	if(new_eyes)
		r_eyes = hex2num(copytext(new_eyes, 2, 4))
		g_eyes = hex2num(copytext(new_eyes, 4, 6))
		b_eyes = hex2num(copytext(new_eyes, 6, 8))
		update_eyes()

	var/new_tone = input("Please select skin tone level: TRUE-220 (1=albino, 35=caucasian, 150=black, 220='very' black)", "Character Generation", "[35-s_tone]")  as text

	if (!new_tone)
		new_tone = 35
	s_tone = max(min(round(text2num(new_tone)), 220), TRUE)
	s_tone =  -s_tone + 35

	// hair
	var/list/all_hairs = typesof(/datum/sprite_accessory/hair) - /datum/sprite_accessory/hair
	var/list/hairs = list()

	// loop through potential hairs
	for(var/x in all_hairs)
		var/datum/sprite_accessory/hair/H = new x // create new hair datum based on type x
		hairs.Add(H.name) // add hair name to hairs
		qdel(H) // delete the hair after it's all done

	var/new_style = input("Please select hair style", "Character Generation",h_style)  as null|anything in hairs

	// if new style selected (not cancel)
	if (new_style)
		h_style = new_style

	// facial hair
	var/list/all_fhairs = typesof(/datum/sprite_accessory/facial_hair) - /datum/sprite_accessory/facial_hair
	var/list/fhairs = list()

	for(var/x in all_fhairs)
		var/datum/sprite_accessory/facial_hair/H = new x
		fhairs.Add(H.name)
		qdel(H)

	new_style = input("Please select facial style", "Character Generation",f_style)  as null|anything in fhairs

	if(new_style)
		f_style = new_style

	var/new_gender = alert(usr, "Please select gender.", "Character Generation", "Male", "Female")
	if (new_gender)
		if(new_gender == "Male")
			gender = MALE
		else
			gender = FEMALE
	regenerate_icons()
	check_dna()

	visible_message("<span class = 'notice'>\The [src] morphs and changes [get_visible_gender() == MALE ? "his" : get_visible_gender() == FEMALE ? "her" : "their"] appearance!</span>", "<span class = 'notice'>You change your appearance!</span>", "<span class = 'red'>Oh, god!  What the hell was that?  It sounded like flesh getting squished and bone ground into a different shape!</span>")

/mob/living/carbon/human/proc/remotesay()
	set name = "Project mind"
	set category = "Superpower"

	if(stat!=CONSCIOUS)
		reset_view(0)
		remoteview_target = null
		return

	if(!(mRemotetalk in mutations))
		verbs -= /mob/living/carbon/human/proc/remotesay
		return
	var/list/creatures = list()
	for(var/mob/living/carbon/h in world)
		creatures += h
	var/mob/target = input("Who do you want to project your mind to ?") as null|anything in creatures
	if (isnull(target))
		return

	var/say = sanitize(input("What do you wish to say"))
	if(mRemotetalk in target.mutations)
		target.show_message("<span class = 'notice'>You hear [real_name]'s voice: [say]</span>")
	else
		target.show_message("<span class = 'notice'>You hear a voice that seems to echo around the room: [say]</span>")
	usr.show_message("<span class = 'notice'>You project your mind into [target.real_name]: [say]</span>")
	log_say("[key_name(usr)] sent a telepathic message to [key_name(target)]: [say]")
	for(var/mob/observer/ghost/G in world)
		G.show_message("<i>Telepathic message from <b>[src]</b> to <b>[target]</b>: [say]</i>")

/mob/living/carbon/human/proc/remoteobserve()
	set name = "Remote View"
	set category = "Superpower"

	if(stat!=CONSCIOUS)
		remoteview_target = null
		reset_view(0)
		return

	if(!(mRemote in mutations))
		remoteview_target = null
		reset_view(0)
		verbs -= /mob/living/carbon/human/proc/remoteobserve
		return

	if(client.eye != client.mob)
		remoteview_target = null
		reset_view(0)
		return

	var/list/mob/creatures = list()

	for(var/mob/living/carbon/h in world)
		var/turf/temp_turf = get_turf(h)
		if((temp_turf.z != TRUE && temp_turf.z != 5) || h.stat!=CONSCIOUS) //Not on mining or the station. Or dead
			continue
		creatures += h

	var/mob/target = input ("Who do you want to project your mind to ?") as mob in creatures

	if (target)
		remoteview_target = target
		reset_view(target)
	else
		remoteview_target = null
		reset_view(0)

/mob/living/carbon/human/proc/get_visible_gender()
	if(wear_suit && wear_suit.flags_inv & HIDEJUMPSUIT && ((head && head.flags_inv & HIDEMASK) || wear_mask))
		return NEUTER
	return gender

/mob/living/carbon/human/proc/increase_germ_level(n)
	if(gloves)
		gloves.germ_level += n
	else
		germ_level += n

/mob/living/carbon/human/revive()

	if(species && !(species.flags & NO_BLOOD))
		vessel.add_reagent("blood",species.blood_volume-vessel.total_volume)
		fixblood()

	// Fix up all organs.
	// This will ignore any prosthetics in the prefs currently.
	species.create_organs(src)

	if(!client || !key) //Don't boot out anyone already in the mob.
		for (var/obj/item/organ/brain/H in world)
			if(H.brainmob)
				if(H.brainmob.real_name == real_name)
					if(H.brainmob.mind)
						H.brainmob.mind.transfer_to(src)
						qdel(H)

/*
	for (var/ID in virus2)
		var/datum/disease2/disease/V = virus2[ID]
		V.cure(src)*/

	losebreath = FALSE

	..()

/mob/living/carbon/human/proc/is_lung_ruptured()
	var/obj/item/organ/lungs/L = internal_organs_by_name["lungs"]
	return L && L.is_bruised()

/mob/living/carbon/human/proc/rupture_lung()
	var/obj/item/organ/lungs/L = internal_organs_by_name["lungs"]

	if(L && !L.is_bruised())
		custom_pain("You feel a stabbing pain in your chest!", TRUE)
		L.bruise()

/*
/mob/living/carbon/human/verb/simulate()
	set name = "sim"
	set background = TRUE

	var/damage = input("Wound damage","Wound damage") as num

	var/germs = FALSE
	var/tdamage = FALSE
	var/ticks = FALSE
	while (germs < 2501 && ticks < 100000 && round(damage/10)*20)
		log_misc("VIRUS TESTING: [ticks] : germs [germs] tdamage [tdamage] prob [round(damage/10)*20]")
		ticks++
		if (prob(round(damage/10)*20))
			germs++
		if (germs == 100)
			world << "Reached stage TRUE in [ticks] ticks"
		if (germs > 100)
			if (prob(10))
				damage++
				germs++
		if (germs == 1000)
			world << "Reached stage 2 in [ticks] ticks"
		if (germs > 1000)
			damage++
			germs++
		if (germs == 2500)
			world << "Reached stage 3 in [ticks] ticks"
	world << "Mob took [tdamage] tox damage"
*/
//returns TRUE if made bloody, returns FALSE otherwise

/mob/living/carbon/human/add_blood(mob/living/carbon/human/M as mob)
	if (!..())
		return FALSE
	//if this blood isn't already in the list, add it
	if(istype(M))
		if(!blood_DNA[M.dna.unique_enzymes])
			blood_DNA[M.dna.unique_enzymes] = M.dna.b_type
	hand_blood_color = blood_color
	update_inv_gloves()	//handles bloody hands overlays and updating
//	verbs += /mob/living/carbon/human/proc/bloody_doodle
	return TRUE //we applied blood to the item

/mob/living/carbon/human/proc/get_full_print()
	if(!dna ||!dna.uni_identity)
		return
	return md5(dna.uni_identity)

/mob/living/carbon/human/clean_blood(var/clean_feet)
	.=..()
	gunshot_residue = null
	if(clean_feet && !shoes)
		feet_blood_color = null
		feet_blood_DNA = null
		update_inv_shoes(1)
		return TRUE

/mob/living/carbon/human/verb/check_pulse()
	set category = "Object"
	set name = "Check pulse"
	set desc = "Approximately count somebody's pulse. Requires you to stand still at least 6 seconds."
	set src in view(1)
	var/self = FALSE

	if(usr.stat || usr.restrained() || !isliving(usr)) return

	if(usr == src)
		self = TRUE
	if(!self)
		usr.visible_message("<span class='notice'>[usr] kneels down, puts \his hand on [src]'s wrist and begins counting their pulse.</span>",\
		"You begin counting [src]'s pulse")
	else
		usr.visible_message("<span class='notice'>[usr] begins counting their pulse.</span>",\
		"You begin counting your pulse.")

	if(pulse())
		usr << "<span class='notice'>[self ? "You have a" : "[src] has a"] pulse! Counting...</span>"
	else
		usr << "<span class='danger'>[src] has no pulse!</span>"	//it is REALLY UNLIKELY that a dead person would check his own pulse
		return

	usr << "You must[self ? "" : " both"] remain still until counting is finished."
	if(do_mob(usr, src, 60))
		usr << "<span class='notice'>[self ? "Your" : "[src]'s"] pulse is [get_pulse(GETPULSE_HAND)].</span>"
	else
		usr << "<span class='warning'>You failed to check the pulse. Try again.</span>"

/mob/living/carbon/human/proc/set_species(var/new_species, var/default_colour)
//	world << "set species"
	if(!dna)
		if(!new_species)
			new_species = "Human"
	else
		if(!new_species)
			new_species = dna.species
		else
			dna.species = new_species

	// No more invisible screaming wheelchairs because of set_species() typos.
	if(!all_species[new_species])
		new_species = "Human"

	if(species)

		if(species.name && species.name == new_species)
			return
		if(species.language)
			remove_language(species.language)
		if(species.default_language)
			remove_language(species.default_language)
		// Clear out their species abilities.
		species.remove_inherent_verbs(src)
	//	holder_type = null

	species = all_species[new_species]

	if(species.language)
		add_language(species.language)

	if(species.default_language)
		add_language(species.default_language)

	if(species.base_color && default_colour)
		//Apply colour.
		r_skin = hex2num(copytext(species.base_color,2,4))
		g_skin = hex2num(copytext(species.base_color,4,6))
		b_skin = hex2num(copytext(species.base_color,6,8))
	else
		r_skin = FALSE
		g_skin = FALSE
		b_skin = FALSE

	/*if(species.holder_type)
		holder_type = species.holder_type*/

	icon_state = lowertext(species.name)

	species.create_organs(src)
	sync_organ_dna()
	species.handle_post_spawn(src)

	maxHealth = species.total_health

	spawn(0)
		regenerate_icons()
		if(vessel.total_volume < species.blood_volume)
			vessel.maximum_volume = species.blood_volume
			vessel.add_reagent("blood", species.blood_volume - vessel.total_volume)
		else if(vessel.total_volume > species.blood_volume)
			vessel.remove_reagent("blood", vessel.total_volume - species.blood_volume)
			vessel.maximum_volume = species.blood_volume
		fixblood()


	// Rebuild the HUD. If they aren't logged in then login() should reinstantiate it for them.
	if(client && client.screen)//HUD HERE!!!!!!!!!!
		client.screen.Cut()
//		if(hud_used)
//			qdel(hud_used)
//		hud_used = new /datum/hud(src)

	if(species)
		return TRUE
	else
		return FALSE
/*
/mob/living/carbon/human/proc/bloody_doodle()
	set category = "IC"
	set name = "Write in blood"
	set desc = "Use blood on your hands to write a short message on the floor or a wall, murder mystery style."

	if (stat)
		return

	if (usr != src)
		return FALSE //something is terribly wrong

	if (!bloody_hands)
		verbs -= /mob/living/carbon/human/proc/bloody_doodle

	if (gloves)
		src << "<span class='warning'>Your [gloves] are getting in the way.</span>"
		return

	var/turf/T = loc
	if (!istype(T)) //to prevent doodling out of mechs and lockers
		src << "<span class='warning'>You cannot reach the floor.</span>"
		return

	var/direction = input(src,"Which way?","Tile selection") as anything in list("Here","North","South","East","West")
	if (direction != "Here")
		T = get_step(T,text2dir(direction))
	if (!istype(T))
		src << "<span class='warning'>You cannot doodle there.</span>"
		return

	var/num_doodles = FALSE
	for (var/obj/effect/decal/cleanable/blood/writing/W in T)
		num_doodles++
	if (num_doodles > 4)
		src << "<span class='warning'>There is no space to write on!</span>"
		return

	var/max_length = bloody_hands * 30 //tweeter style

	var/message = sanitize(input("Write a message. It cannot be longer than [max_length] characters.","Blood writing", ""))

	if (message)
		var/used_blood_amount = round(length(message) / 30, TRUE)
		bloody_hands = max(0, bloody_hands - used_blood_amount) //use up some blood

		if (length(message) > max_length)
			message += "-"
			src << "<span class='warning'>You ran out of blood to write with!</span>"

		var/obj/effect/decal/cleanable/blood/writing/W = new(T)
		W.basecolor = (hand_blood_color) ? hand_blood_color : "#A10808"
		W.update_icon()
		W.message = message
		W.add_fingerprint(src)
*/
/mob/living/carbon/human/can_inject(var/mob/user, var/error_msg, var/target_zone)
	. = TRUE

	if(!target_zone)
		if(!user)
			target_zone = pick("chest","chest","chest","left leg","right leg","left arm", "right arm", "head")
		else
			target_zone = user.targeted_organ

	var/obj/item/organ/external/affecting = get_organ(target_zone)
	var/fail_msg
	if(!affecting)
		. = FALSE
		fail_msg = "They are missing that limb."
	else if (affecting.status & ORGAN_ROBOT)
		. = FALSE
		fail_msg = "That limb is robotic."
	else
		switch(target_zone)
			if("head")
				if(head && head.item_flags & THICKMATERIAL)
					. = FALSE
			else
				if(wear_suit && wear_suit.item_flags & THICKMATERIAL)
					. = FALSE
	if(!. && error_msg && user)
		if(!fail_msg)
			fail_msg = "There is no exposed flesh or thin material [target_zone == "head" ? "on their head" : "on their body"] to inject into."
		user << "<span class='alert'>[fail_msg]</span>"

/mob/living/carbon/human/proc/exam_self()
	var/organpain = FALSE
	if(istype(src, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = usr
		if(!stat)
			visible_message("<span class = 'notice'>[src] examines [gender==MALE?"himself":"herself"].</span>")

		for(var/obj/item/organ/external/org in H.organs)
			var/status = ""

			if(H.painchecks())//Can we feel pain? If we can then it tells us how much pain our limbs are in.
				organpain = org.get_damage()
				if(organpain > FALSE)
					status = " <small>pain</small>"
				if(organpain > 5)
					status = " pain"
				if(organpain > 20)
					status = " PAIN!"
				if(organpain > 40)
					status = "<large><b> PAIN!</b></large>"

			if(org.is_stump())//it missing
				status = " MISSING!"


			//This is all spaghetti.
			if(organpain && (org.status & ORGAN_BLEEDING))//Is the limb bleeding and hurt?
				status += " || <b>BLEEDING!</b>"

			if((!organpain) && (org.status & ORGAN_BLEEDING))//Or just bleeding.
				status = "<b> BLEEDING!</b>"

			if((!organpain) && (org.status & ORGAN_BROKEN) && (org.status & ORGAN_BLEEDING))//Or is it bleeding and broken but you're not hurt.
				status = "<b>BLEEDING! || BROKEN!</b>"


			if(organpain && (org.status & ORGAN_BROKEN))//Is the limb broken and hurt?
				status += " || <b>BROKEN!</b>"

			if((!organpain) && (org.status & ORGAN_BROKEN))//Or just broken.
				status = "<b> IT'S BROKEN!</b>"


			if(organpain && (org.dislocated == 2))//Hurt and dislocated?
				status += " || <b>DISLOCATED!</b>"

			if((!organpain) && (org.dislocated == 2))//Or just dislocated.
				status = "<b> DISLOCATED!</b>"


			if(org.status & ORGAN_DEAD)//it dead
				status = "</b> NECROTIC!</b>"

			if(!org.is_usable())//it useless
				status = "</b> USELESS!</b>"

			if(status == "")
				status = " OK"

			src << output(text("\t [] []:[][]",status==" OK"?"<span class = 'notice'>":"<span class = 'warning'> ", capitalize(org.name), status, "</span>"), TRUE)




/mob/living/carbon/human/print_flavor_text(var/shrink = TRUE)
	var/list/equipment = list(head,wear_mask,glasses,w_uniform,wear_suit,gloves,shoes)

	for(var/obj/item/clothing/C in equipment)
		if(C.body_parts_covered & FACE)
			// Do not show flavor if face is hidden
			return

	flavor_text = flavor_text

	if (flavor_text && flavor_text != "" && !shrink)
		var/msg = trim(replacetext(flavor_text, "\n", " "))
		if(!msg) return ""
		if(lentext(msg) <= 40)
			return "<span class = 'notice'>[msg]</span>"
		else
			return "<span class = 'notice'>[copytext_preserve_html(msg, TRUE, 37)]... <a href='byond://?src=\ref[src];flavor_more=1'>More...</a></span>"
	return ..()

/mob/living/carbon/human/getDNA()
	if(species.flags & NO_SCAN)
		return null
	..()

/mob/living/carbon/human/setDNA()
	if(species.flags & NO_SCAN)
		return
	..()

/mob/living/carbon/human/has_brain()
	if(internal_organs_by_name["brain"])
		var/obj/item/organ/brain = internal_organs_by_name["brain"]
		if(brain && istype(brain))
			return TRUE
	return FALSE

/mob/living/carbon/human/has_eyes()
	if(internal_organs_by_name["eyes"])
		var/obj/item/organ/eyes = internal_organs_by_name["eyes"]
		if(eyes && istype(eyes) && !(eyes.status & ORGAN_CUT_AWAY))
			return TRUE
	return FALSE

/mob/living/carbon/human/slip(var/slipped_on, stun_duration=8)
	if((species.flags & NO_SLIP) || (shoes && (shoes.item_flags & NOSLIP)))
		return FALSE
	..(slipped_on,stun_duration)

/mob/living/carbon/human/proc/undislocate()
	set category = "Object"
	set name = "Undislocate Joint"
	set desc = "Pop a joint back into place. Extremely painful."
	set src in view(1)

	if(!isliving(usr) || !usr.canClick())
		return

	usr.setClickCooldown(20)

	if(usr.stat > FALSE)
		usr << "You are unconcious and cannot do that!"
		return

	if(usr.restrained())
		usr << "You are restrained and cannot do that!"
		return

	var/mob/S = src
	var/mob/U = usr
	var/self = null
	if(S == U)
		self = TRUE // Removing object from yourself.

	var/list/limbs = list()
	for(var/limb in organs_by_name)
		var/obj/item/organ/external/current_limb = organs_by_name[limb]
		if(current_limb && current_limb.dislocated == 2)
			limbs |= limb
	var/choice = input(usr,"Which joint do you wish to relocate?") as null|anything in limbs

	if(!choice)
		return

	var/obj/item/organ/external/current_limb = organs_by_name[choice]

	if(self)
		src << "<span class='warning'>You brace yourself to relocate your [current_limb.joint]...</span>"
	else
		U << "<span class='warning'>You begin to relocate [S]'s [current_limb.joint]...</span>"

	if(!do_after(U, 30, src))
		return
	if(!choice || !current_limb || !S || !U)
		return

	if(self)
		src << "<span class='danger'>You pop your [current_limb.joint] back in!</span>"
	else
		U << "<span class='danger'>You pop [S]'s [current_limb.joint] back in!</span>"
		S << "<span class='danger'>[U] pops your [current_limb.joint] back in!</span>"
	current_limb.undislocate()

/mob/living/carbon/human/drop_from_inventory(var/obj/item/W, var/atom/Target = null)
	if(W in organs)
		return
	..()

/mob/living/carbon/human/reset_view(atom/A, update_hud = TRUE)
	..()
	if(update_hud)
		handle_regular_hud_updates()


/mob/living/carbon/human/can_stand_overridden()
	for (var/obj/structure/noose/N in get_turf(src))
		if (N.hanging == src)
			return TRUE
	return FALSE
/*
/mob/living/carbon/human/MouseDrop(var/atom/over_object)
	var/mob/living/carbon/human/H = over_object
	if(holder_type && istype(H) && H.a_intent == I_HELP && !H.lying && !issmall(H) && Adjacent(H))
		get_scooped(H, (usr == src))
		return
	return ..()
*/
//Puts the item into our active hand if possible. returns TRUE on success.
/mob/living/carbon/human/put_in_active_hand(var/obj/item/W)
	return (hand ? put_in_l_hand(W) : put_in_r_hand(W))

//Puts the item into our inactive hand if possible. returns TRUE on success.
/mob/living/carbon/human/put_in_inactive_hand(var/obj/item/W)
	return (hand ? put_in_r_hand(W) : put_in_l_hand(W))

/mob/living/carbon/human/put_in_hands(var/obj/item/W)
	if(!W)
		return FALSE
	if(put_in_active_hand(W))
		update_inv_l_hand()
		update_inv_r_hand()
		return TRUE
	else if(put_in_inactive_hand(W))
		update_inv_l_hand()
		update_inv_r_hand()
		return TRUE
	else
		return ..()

/mob/living/carbon/human/put_in_l_hand(var/obj/item/W)
	if(!..() || l_hand)
		return FALSE
	W.forceMove(src)
	l_hand = W
	W.equipped(src,slot_l_hand)
	W.add_fingerprint(src)
	update_inv_l_hand()
	return TRUE

/mob/living/carbon/human/put_in_r_hand(var/obj/item/W)
	if(!..() || r_hand)
		return FALSE
	W.forceMove(src)
	r_hand = W
	W.equipped(src,slot_r_hand)
	W.add_fingerprint(src)
	update_inv_r_hand()
	return TRUE

/mob/living/carbon/human/verb/pull_punches()
	set name = "Pull Punches"
	set desc = "Try not to hurt them."
	set category = "IC"

	if(stat) return
	pulling_punches = !pulling_punches
	src << "<span class='notice'>You are now [pulling_punches ? "pulling your punches" : "not pulling your punches"].</span>"
	return

//generates realistic-ish pulse output based on preset levels
/mob/living/carbon/human/proc/get_pulse(var/method)	//method FALSE is for hands, TRUE is for machines, more accurate
	var/temp = FALSE
	switch(pulse())
		if(PULSE_NONE)
			return "0"
		if(PULSE_SLOW)
			temp = rand(40, 60)
		if(PULSE_NORM)
			temp = rand(60, 90)
		if(PULSE_FAST)
			temp = rand(90, 120)
		if(PULSE_2FAST)
			temp = rand(120, 160)
		if(PULSE_THREADY)
			return method ? ">250" : "extremely weak and fast, patient's artery feels like a thread"
	return "[method ? temp : temp + rand(-10, 10)]"
//			output for machines^	^^^^^^^output for people^^^^^^^^^

/mob/living/carbon/human/proc/pulse()
	var/obj/item/organ/heart/H = internal_organs_by_name["heart"]
	if(!H)
		return PULSE_NONE
	else
		return H.pulse
