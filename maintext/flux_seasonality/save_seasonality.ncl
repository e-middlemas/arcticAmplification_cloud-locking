procedure save_Arctic_surface_seasonality(varname,units)
;================================================================
; This function returns timeseries of a given variable from 1xCO2
; & 2xCO2 experiments in such a format that makes them easy to
; plot in figure 3 in Middlemas et al., in review at GRL. 
;
; The only inputs required are the CESM variable name and the
; associated units. 
;
; Nothing is returned, but a netcdf file is created that contains
; the monthly climatology timeseries (12 timesteps) of a variable
; averaged across the Arctic region, for each year in both 1xCO2
; and 2xCO2 simulations, across all three modeling configurations
; used in Middlemas et al. 
;================================================================
begin

;----------------------------------------------------------------
; User-defined section

; A list of filename prefixes to compute responses. 
; The format is 
; ((/config1_2xCO2, config1_1xCO2/),(/config2_2xCO2, config2_1xCO2/),../) 
; And so on.
expnames = (/(/"b.e11.B1850C5CN.f09_g16.005_2xCO2.cam.h0.","b.e11.B1850C5CN.f09_g16.005.cam.h0."/),\
(/"B1850C5CN.clock.9p.2xCO2.cam.h0.","B1850C5CN.clock.9p.global.cam.h0."/),\
(/"B1850C5CN.clock.9p.70-90N.2xCO2.cam.h0.","B1850C5CN.clock.9p.70-90N.cam.h0."/)/)

; descriptive names for each configuration & forcing
experiment = (/"Control","Global cloud-locked","Arctic-only cloud-locked"/)
forcing = (/"2xCO2","Preindustrial"/)

; output file directory & filename
diro = "$OUTPUTDIR"
outputfname = varname+".exps.seasonality_last50yrs.nc"

; How many years do you want to use to calculate the climatology?
noyrs = 50
;----------------------------------------------------------------
; Extract data

; extract special parameters for ICEAREA (or ICEEXTENT)
; *NOTE: ICEAREA must be calculated from CAM's ICEFRAC variable. 
; *code to do so is in the ../extra/ folder
if varname.ne."ICEAREA"
	path = "$PATHTO_ICEAREA_NCFILE" ; 
	rad = 4.0*atan(1.0)/180.
	f = addfile(systemfunc("ls "+path+expnames(0,0)+varname+".*"),"r")
	alat = f->lat({70:90})
	clat = cos(alat*rad)
else
        path = "$PATHTO_OTHERVARIABLES"
end if

; period of time over which to calculate seasonality
years = ispan(1,noyrs,1) ; for plotting
months = ispan(1,12,1) ; for plotting

; Loop through 1) experimental configuration, 2) forcing scenario
date = systemfunc("date") ; to time how long it takes
flx = new((/2,3,noyrs,12/),float) ; 0!: forcing scenario, 1!: experimental config
tend = new((/2,3/),integer) ; the end time index for each 2xCO2 experiment 
do e=0,dimsizes(experiment)-1
        print("Experiment pair is "+experiment(e))
        do r=0,1
                print("Forcing is..."+forcing(r))
                f = addfile(systemfunc("ls "+path+expnames(e,r)+varname+".*"),"r")
		if varname.eq."ICEAREA" ; The variables associated with ICEAREA
					; are split up into northern hemisphere & 
					; southern hemisphere
			var2extract = "NH"+varname
                        tmp = f->$var2extract$
                        ; the ice area or ice extent is already a timeseries
			arctictmp = tmp
		else
                        f = addfile(systemfunc("ls "+path+expnames(e,r)+varname+".*"),"r")
                        tmp = f->$varname$
                        ; average only arctic only.
                        arctictmp = wgt_areaave_Wrap(tmp(:,{70:90},:),clat,1.0,1)
		end if
		
		;------------------------------------------------------------------------
		; Dealing with time indices

		; save the time indices associated with the first timestep & 150th timestep
		; of the 2xCO2 simulation
		time = cd_calendar(f->time,0)
		if r.eq.0 ; if 2xCO2 simulation, save time indices accordindly
			tend(0,e) = toint(time(0,0)+150)
			tend(1,e) = 1
		end if
		indend = ind(time(:,0).eq.tend(0,e) .and. time(:,1).eq.tend(1,e))

		; find time index in simulation corresponding to tend coordinates
		timeseries = arctictmp(indend-noyrs*12:indend-1)

		; change the year for the control simulation because the branched year isn't
		; saved in the 2xCO2 simulation. Branched from year 402. +150 = 552.
		if expnames(e,r).eq."b.e11.B1850C5CN.f09_g16.005_2xCO2.cam.h0."
		        tend(0,e) = 552
		; the Arctic-only clocked control run doesn't have 150 years past the branched run.
		; so just take the last 50 years.
		else if expnames(e,r).eq."B1850C5CN.clock.9p.70-90N.2xCO2.cam.h0."
			tend(0,e) = 210
		end if
		end if

		;------------------------------------------------------------------------
		; Reshape timeseries into years & months
		flx(r,e,:,:) = reshape(timeseries,(/noyrs,12/))
		delete([/tmp,arctictmp,time,timeseries,indend/])
        end do
end do
wallClockElapseTime(date,"Time to extract vars from polar regions ",0)

; Define coordinates
flx!0 = "2xCO2.preindustrial"
flx!1 = "control.global_clocked.arctic_clocked"
flx!2 = "years"
flx!3 = "months"
years!0 = "years"
months!0 = "months"

years&years = years
flx&years = years
months&months = months
flx&months = months
flx@units = units

;-----------------------------------------------------------------
; OUTPUT TO FILE
;-----------------------------------------------------------------
print("Outputting cloud-locked to file...")

; remove netcdf file if one exists with the same name
system("/bin/rm -f " + diro + outputfname)

; initialize new netcdf file for writing
fout  = addfile (diro + outputfname, "c")
setfileoption(fout,"DefineMode",True)

; Define netcdf file attributes 
fAtt               = True            ; assign file attributes
fAtt@title = "Climatological "+varname+" in 2xCO2 and pictrl control & cloud-locked simulations."
fAtt@conventions = "First dimension is: (0) 2xCO2, and (1) pictrl. Second dimension is (0) control (cloud feedbacks active), (1) global cloud-locked, and (2) arctic-only cloud-locked."
fAtt@source_file = str_join(ndtooned(expnames),", ")
fAtt@creation_date = systemfunc ("date")
fileattdef( fout, fAtt )            ; copy file attributes

; Define coordinates or dimensions found in file
dimNames = (/"2xCO2.preindustrial","control.global_clocked.arctic_clocked","years","months"/)
dimSizes = dimsizes(flx)
dimUnlim = (/ False, False,False, False /)
filedimdef(fout,dimNames,dimSizes,dimUnlim)

; Define variables found in file (including coordinate variables)
filevardef(fout,"months",typeof(months),getvardims(months))
filevardef(fout,"years",typeof(years),getvardims(years))
filevardef(fout,"clim",typeof(flx),getvardims(flx))
filevarattdef(fout,"clim",flx)
filevarattdef(fout,"months",months)
setfileoption(fout,"DefineMode",False)

; Write to file
fout->years = (/years/)
fout->months = (/months/)
fout->clim = (/flx/)
end
