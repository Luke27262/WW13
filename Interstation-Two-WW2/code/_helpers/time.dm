#define SECOND *10
#define SECONDS *10

#define MINUTE *600
#define MINUTES *600

#define HOUR *36000
#define HOURS *36000

#define DAY *864000
#define DAYS *864000

#define TimeOfGame (get_game_time())
#define TimeOfTick (world.tick_usage*0.01*world.tick_lag)

/proc/get_game_time()
	var/global/time_offset = FALSE
	var/global/last_time = FALSE
	var/global/last_usage = FALSE

	var/wtime = world.time
	var/wusage = world.tick_usage * 0.01

	if(last_time < wtime && last_usage > TRUE)
		time_offset += last_usage - TRUE

	last_time = wtime
	last_usage = wusage

	return wtime + (time_offset + wusage) * world.tick_lag

var/roundstart_hour = FALSE
var/station_date = ""
var/next_station_date_change = TRUE DAY

#define station_adjusted_time(time) time2text(time + station_time_in_ticks, "hh:mm")
#define worldtime2stationtime(time) time2text(roundstart_hour HOURS + time, "hh:mm")
#define roundduration2text_in_ticks (round_start_time ? world.time - round_start_time : FALSE)
#define station_time_in_ticks (roundstart_hour HOURS + roundduration2text_in_ticks)

/proc/stationtime2text()
	if(!roundstart_hour) roundstart_hour = pick(2,7,12,17)
	return time2text(station_time_in_ticks, "hh:mm")

/proc/stationdate2text()
	var/update_time = FALSE
	if(station_time_in_ticks > next_station_date_change)
		next_station_date_change += TRUE DAY
		update_time = TRUE
	if(!station_date || update_time)
		var/extra_days = round(station_time_in_ticks / (1 DAY)) DAYS
		var/timeofday = world.timeofday + extra_days
		station_date = num2text((text2num(time2text(timeofday, "YYYY"))+544)) + "-" + time2text(timeofday, "MM-DD")
	return station_date

/proc/time_stamp()
	return time2text(world.timeofday, "hh:mm:ss")

/* Returns TRUE if it is the selected month and day */
proc/isDay(var/month, var/day)
	if(isnum(month) && isnum(day))
		var/MM = text2num(time2text(world.timeofday, "MM")) // get the current month
		var/DD = text2num(time2text(world.timeofday, "DD")) // get the current day
		if(month == MM && day == DD)
			return TRUE

		// Uncomment this out when debugging!
		//else
			//return TRUE

var/next_duration_update = FALSE
var/last_roundduration2text = FALSE
var/round_start_time = FALSE

/hook/roundstart/proc/start_timer()
	round_start_time = world.time
	return TRUE

/proc/roundduration2text()
	if(!round_start_time)
		return "00:00"
	if(last_roundduration2text && world.time < next_duration_update)
		return last_roundduration2text

	var/mills = roundduration2text_in_ticks // TRUE/10 of a second, not real milliseconds but whatever
	//var/secs = ((mills % 36000) % 600) / 10 //Not really needed, but I'll leave it here for refrence.. or something
	var/mins = round((mills % 36000) / 600)
	var/hours = round(mills / 36000)

	mins = mins < 10 ? add_zero(mins, TRUE) : mins
	hours = hours < 10 ? add_zero(hours, TRUE) : hours

	last_roundduration2text = "[hours]:[mins]"
	next_duration_update = world.time + TRUE MINUTES
	return last_roundduration2text

//Can be useful for things dependent on process timing
/proc/process_schedule_interval(var/process_name)
	var/datum/controller/process/process = processScheduler.getProcess(process_name)
	return process.schedule_interval