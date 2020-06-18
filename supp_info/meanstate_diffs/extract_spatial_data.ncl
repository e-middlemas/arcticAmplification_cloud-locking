
;-------------------------------------------------------
; compute various averages
;
; * need to ensure:
;   *   time variable is divisible by 12
;   *   first month must be January... (month=2 after cd_calendar-- CAM saves January as February.)
;   *   Grab years 100-150 from every simulation

function compute_avgs(var)

begin
	;
	; annual mean
	ann = month_to_annual(var,1) ; opt=1  divide the unweighted sum by 12 to get the annual mean value(s)
	annmean = dim_avg_n_Wrap(ann,0) ; average across years for annual mean average
	;
	; seasonal
	djf = month_to_season(var,"DJF")
	djfmean = dim_avg_n_Wrap(djf,0)
	jja = month_to_season(var,"JJA")
	jjamean = dim_avg_n_Wrap(jja,0)

	return((/annmean,djfmean,jjamean/))
	
end

;-------------------------------------------------------
; Extract data from runs & compute relevant averages
;
;
function extract_spatial_data(dir:string,forcing:string)

begin

	if forcing.eq."1x"
	        exps = (/"b.e11.B1850C5CN.f09_g16.005","B1850C5CN.clock.9p.global","B1850C5CN.clock.9p.70-90N"/)
	else
	        exps = (/"b.e11.B1850C5CN.f09_g16.005_2xCO2","B1850C5CN.clock.9p.2xCO2","B1850C5CN.clock.9p.70-90N.2xCO2"/)
	end if

	; just to extract lat & lon for their dimension sizes
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
		var = f->TS(startind:endind,:,:)
		tsout(e,:,:,:) = compute_avgs(var)
		delete(time_cal)
	end do
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
		var = f->PSL(startind:endind,:,:)
		psout(e,:,:,:) = compute_avgs(var)
		delete(time_cal)
	end do
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
		var = f->ICEFRAC(startind:endind,:,:)
		iceout(e,:,:,:) = compute_avgs(var)
		delete(time_cal)
	end do
	iceout!0 = "ctrl,globalclock,arcticclock"
	iceout!1 = "ann,djf,jja"
	print("ICEFRAC done!")
	
	;; TOTAL CLOUD FRACTION
	;print("Extracting & computing averages for CLDTOT...")
	;cldout = new((/3,3,dimsizes(lat),dimsizes(lon)/),float) ; maps to be plotted
	;do e=0,dimsizes(exps)-1
	;	f = addfile(systemfunc("ls "+dir+exps(e)+".cam.h0.CLDTOT.*.nc"),"r")
	;	time_cal = cd_calendar(f->time,0)
	;	;  look for time index where month = Jan and year is 100 years after start of run
	;	startind = ind(time_cal(:,0).eq.(time_cal(0,0)+100) .and. time_cal(:,1).eq.2)
	;	;  look for time index where month = Dec and year is 150 years after start of run
	;	endind = ind(time_cal(:,0).eq.(time_cal(0,0)+150) .and. time_cal(:,1).eq.1)
	;	var = f->CLDTOT(startind:endind,:,:)
	;	cldout(e,:,:,:) = compute_avgs(var)
	;	delete(time_cal)
	;end do
	;cldout!0 = "ctrl,globalclock,arcticclock"
	;cldout!1 = "ann,djf,jja"
	;print("CLDTOT done!")
	;return((/tsout,psout,iceout,cldout/))	
	return((/tsout,psout,iceout/))	

end

