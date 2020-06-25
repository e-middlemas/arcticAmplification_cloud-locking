;===========================================================
;-------- DESCRIPTION --------------------------------------
; The functions below calculate the seasonal averages of 
; sea level pressure, surface temperature, sea ice fraction,
; and optionally total cloud fraction for either 1x or 2xCO2
; experiments. 
; These functions were written specifically to analyze a
; suite of cloud-locking experiments for Middlemas et al.
; (GRL, in review). 
;
;-------- USAGE --------------------------------------------
; After loading in this script (via 
; load "./extract_spatial_data.ncl" at the top of your NCL
; script, one must call the "extract_spatial_data" function
; defined below.
;
; INPUTS: 
; - "dir": a string indicating the path to the CESM output
; 	timeseries files. Timeseries files should all be in
;	one location and should include PSL (sea level 
;	pressure), TS (surface temperature), ICEFRAC (sea 
;	ice fraction), and optionally, CLDTOT (total cloud
;	fraction). 
; - "forcing": a string indicating which forced experiments
;	should be analyzed. The options include "1x" or "2x"
;	for 1xCO2 and 2xCO2, respectively.
;
; OUTPUTS:
; - The returned value is a matrix containing seasonal
;	average maps for TS, PSL, ICEFRAC, and optionally,
;	CLDTOT. 
;===========================================================

function compute_avgs(var)
;-------------------------------------------------------
; Compute various averages
;-------------------------------------------------------
; INPUT: 
; - "var": a data array corresponding to the variable of choice. needs to be of
;	size (/time, lat, lon/), where time is monthly and the lenght is divisible 
;	by 12
; OUTPUT:
; - An array that holds three maps corresponding to the annual mean, the DJF mean,
; 	and the JJA mean associated with that variable.
;
; !! Need to ensure!!:
;   *   time variable is divisible by 12
;   *   first month must be January... 
;	(month=2 after cd_calendar-- CAM saves January as February.)
;   *   Grab years 100-150 from every simulation
;
begin
	; annual mean
	; opt=1  divide the unweighted sum by 12 to get the annual mean value(s)
	ann = month_to_annual(var,1) ; ann goes from (/months, lat, lon/) to
					; (/years, lat, lon/), where the size of 
					; months = 12*size of years.

	annmean = dim_avg_n_Wrap(ann,0) ; average across years for annual mean average
					; size of annmean is (/lat, lon/).
	
	; seasonal
	djf = month_to_season(var,"DJF") ; size is (/years, lat, lon/)
	djfmean = dim_avg_n_Wrap(djf,0) ; size is (/lat, lon/)
	jja = month_to_season(var,"JJA") ; size is (/years, lat, lon/)
	jjamean = dim_avg_n_Wrap(jja,0) ; size is (/lat, lon/)

	; return an array that is size (/3, lat, lon/), where the first map is
	; the annual mean, the second is the winter mean, and third is the summer
	; mean.
	return((/annmean,djfmean,jjamean/)) 
	
end

function extract_spatial_data(dir:string,forcing:string,cldopt:logical)
;-------------------------------------------------------
; Extract data from runs & compute relevant averages
;-------------------------------------------------------
; This function is hard-coded to return seasonal averages
; for surface temperature, sea level pressure, and total
; cloud fraction, for all three cloud-locking configurations
; (clouds active, global cloud-locked, and Arctic-only cloud-
; locked), one forcing at a time. 
; 
; For each variable and experiment, this code reads in the 
; CESM timeseries output, extracts only years 100 through 150,
; and calculates the climatology using the function above. 
;
; This function then returns a new matrix containing a map
; of each variable's annual mean, winter, and summer 
; climatological values.
;
; INPUTS: 
; - "dir": a string indicating the path to the CESM output
; 	timeseries files. Timeseries files should all be in
;	one location and should include PSL (sea level 
;	pressure), TS (surface temperature), ICEFRAC (sea 
;	ice fraction), and optionally, CLDTOT (total cloud
;	fraction). 
; - "forcing": a string indicating which forced experiments
;	should be analyzed. The options include "1x" or "2x"
;	for 1xCO2 and 2xCO2, respectively.
;
; OUTPUTS:
; - The returned value is a matrix containing seasonal
;	average maps for TS, PSL, ICEFRAC, and optionally,
;	CLDTOT. 
; Resulting output variable will be of size (/3, 3, 3, size(lat), size(lon)/)*
; 4 corresponds to TS, PSL, ICEFRAC*
; the first 3 corresponds to the experimental configuation: clouds active, 
;	global cloud-locking, and Arctic cloud-locking
; The second 3 corresponds to the climatology: annual mean, winter DJF, summer JJA
;
; ! NOTES: 
; * If CLDTOT is output as well, the size will be (/4, 3, 3, size(lat), size(lon)/)
; - If a different set of experiments is desired, the 
;	experiment names just below must be changed.
begin

	if forcing.eq."1x"
	        exps = (/"b.e11.B1850C5CN.f09_g16.005","B1850C5CN.clock.9p.global","B1850C5CN.clock.9p.70-90N"/)
	else
	        exps = (/"b.e11.B1850C5CN.f09_g16.005_2xCO2","B1850C5CN.clock.9p.2xCO2","B1850C5CN.clock.9p.70-90N.2xCO2"/)
	end if

	; just to extract lat & lon for their dimension sizes for initializing matrices later
	f = addfile(systemfunc("ls "+dir+exps(0)+".cam.h0.TS*.nc"),"r")
	lat = f->lat
	lon = f->lon

	; SURFACE TEMPERATURE TS
	print("Extracting & computing averages for TS...")
	tsout = new((/3,3,dimsizes(lat),dimsizes(lon)/),float) ; maps to be plotted
	do e=0,dimsizes(exps)-1
		f = addfile(systemfunc("ls "+dir+exps(e)+".cam.h0.TS.*.nc"),"r")
		time_cal = cd_calendar(f->time,0)
		;  look for time index where month = Jan and year is 100 years after start of run
		startind = ind(time_cal(:,0).eq.(time_cal(0,0)+100) .and. time_cal(:,1).eq.2)
		;  look for time index where month = Dec and year is 150 years after start of run
		endind = ind(time_cal(:,0).eq.(time_cal(0,0)+150) .and. time_cal(:,1).eq.1)
		; extract only years 100-150
		var = f->TS(startind:endind,:,:)
		; use function above to return annual, winter, and summer climatology maps
		tsout(e,:,:,:) = compute_avgs(var)
		delete(time_cal)
	end do
	; Define dimensions of output variable
	tsout!0 = "ctrl,globalclock,arcticclock"
	tsout!1 = "ann,djf,jja"
	print("TS done!")

	; SURFACE PRESSURE PSL
	print("Extracting & computing averages for PSL...")
	psout = new((/3,3,dimsizes(lat),dimsizes(lon)/),float) ; maps to be plotted
	do e=0,dimsizes(exps)-1
		f = addfile(systemfunc("ls "+dir+exps(e)+".cam.h0.PSL.*.nc"),"r")
		time_cal = cd_calendar(f->time,0)
		;  look for time index where month = Jan and year is 100 years after start of run
		startind = ind(time_cal(:,0).eq.(time_cal(0,0)+100) .and. time_cal(:,1).eq.2)
		;  look for time index where month = Dec and year is 150 years after start of run
		endind = ind(time_cal(:,0).eq.(time_cal(0,0)+150) .and. time_cal(:,1).eq.1)
		; extract only years 100-150
		var = f->PSL(startind:endind,:,:)
		; use function above to return annual, winter, and summer climatology maps
		psout(e,:,:,:) = compute_avgs(var)
		delete(time_cal)
	end do
	; Define dimensions of output variable
	psout!0 = "ctrl,globalclock,arcticclock"
	psout!1 = "ann,djf,jja"
	print("PSL done!")

	; ICEFRAC
	print("Extracting & computing averages for ICEFRAC...")
	iceout = new((/3,3,dimsizes(lat),dimsizes(lon)/),float) ; maps to be plotted
	do e=0,dimsizes(exps)-1
		f = addfile(systemfunc("ls "+dir+exps(e)+".cam.h0.ICEFRAC.*.nc"),"r")
		time_cal = cd_calendar(f->time,0)
		;  look for time index where month = Jan and year is 100 years after start of run
		startind = ind(time_cal(:,0).eq.(time_cal(0,0)+100) .and. time_cal(:,1).eq.2)
		;  look for time index where month = Dec and year is 150 years after start of run
		endind = ind(time_cal(:,0).eq.(time_cal(0,0)+150) .and. time_cal(:,1).eq.1)
		; extract only years 100-150
		var = f->ICEFRAC(startind:endind,:,:)
		; use function above to return annual, winter, and summer climatology maps
		iceout(e,:,:,:) = compute_avgs(var)
		delete(time_cal)
	end do
	; Define dimensions of output variable
	iceout!0 = "ctrl,globalclock,arcticclock"
	iceout!1 = "ann,djf,jja"
	print("ICEFRAC done!")
	
	;; TOTAL CLOUD FRACTION
	if cldopt==True
		print("Extracting & computing averages for CLDTOT...")
		cldout = new((/3,3,dimsizes(lat),dimsizes(lon)/),float) ; maps to be plotted
		do e=0,dimsizes(exps)-1
			f = addfile(systemfunc("ls "+dir+exps(e)+".cam.h0.CLDTOT.*.nc"),"r")
			time_cal = cd_calendar(f->time,0)
			;  look for time index where month = Jan and year is 100 years after start of run
			startind = ind(time_cal(:,0).eq.(time_cal(0,0)+100) .and. time_cal(:,1).eq.2)
			;  look for time index where month = Dec and year is 150 years after start of run
			endind = ind(time_cal(:,0).eq.(time_cal(0,0)+150) .and. time_cal(:,1).eq.1)
			; extract only years 100-150
			var = f->CLDTOT(startind:endind,:,:)
			; use function above to return annual, winter, and summer climatology maps
			cldout(e,:,:,:) = compute_avgs(var)
			delete(time_cal)
		end do
		; Define dimensions of output variable
		cldout!0 = "ctrl,globalclock,arcticclock"
		cldout!1 = "ann,djf,jja"
		print("CLDTOT done!")
		
		; Resulting output variable will be of size (/4, 3, 3, size(lat), size(lon)/)
		; 4 corresponds to TS, PSL, ICEFRAC, and CLDTOT
		; the first 3 corresponds to the experimental configuation: clouds active, 
		;	global cloud-locking, and Arctic cloud-locking
		; The second 3 corresponds to the climatology: annual mean, winter DJF, summer JJA
		return((/tsout,psout,iceout,cldout/))
	else
	
		; Resulting output variable will be of size (/3, 3, 3, size(lat), size(lon)/)
		; 4 corresponds to TS, PSL, ICEFRAC
		; the first 3 corresponds to the experimental configuation: clouds active, 
		;	global cloud-locking, and Arctic cloud-locking
		; The second 3 corresponds to the climatology: annual mean, winter DJF, summer JJA
		return((/tsout,psout,iceout/))	
	end if

end

