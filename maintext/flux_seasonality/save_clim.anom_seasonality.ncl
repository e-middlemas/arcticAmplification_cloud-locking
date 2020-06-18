procedure save_Arctic_surface_seasonality(varname,units)
;
begin
;
expnames = (/(/"b.e11.B1850C5CN.f09_g16.005_2xCO2.cam.h0.","b.e11.B1850C5CN.f09_g16.005.cam.h0."/),\
(/"B1850C5CN.clock.9p.2xCO2.cam.h0.","B1850C5CN.clock.9p.global.cam.h0."/),\
(/"B1850C5CN.clock.9p.70-90N.2xCO2.cam.h0.","B1850C5CN.clock.9p.70-90N.cam.h0."/)/)
;
experiment = (/"Control","Global cloud-locked","Arctic-only cloud-locked"/)
forcing = (/"2xCO2","Preindustrial"/)
;
if varname.ne."ICEAREA"
	path = "/glade/work/eleanorm/cldlck_data/cldlck_polar/orig/"
	rad = 4.0*atan(1.0)/180.
	f = addfile(systemfunc("ls "+path+expnames(0,0)+varname+".*"),"r")
	alat = f->lat({70:90})
	clat = cos(alat*rad)
else
        path = "/glade/work/eleanorm/cldlck_data/cldlck_polar/"
end if
;
; period of time over which to calculate seasonality
noyrs = 50
years = ispan(1,noyrs,1) ; for plotting
months = ispan(1,12,1) ; for plotting
;
date = systemfunc("date")
flx = new((/2,3,noyrs,12/),float)
tend = new((/2,3/),integer) ; only care about 2xCO2 simulation
do e=0,dimsizes(experiment)-1
        print("Experiment pair is "+experiment(e))
        do r=0,1
                print("Forcing is..."+forcing(r))
                f = addfile(systemfunc("ls "+path+expnames(e,r)+varname+".*"),"r")
		if varname.eq."ICEAREA"
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
		;
		; selecting the time period that follows the branched part of the simulation:
		time = cd_calendar(f->time,0)
		if r.eq.0 ; if 2xCO2 simulation
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
		flx(r,e,:,:) = reshape(timeseries,(/noyrs,12/))
		delete([/tmp,arctictmp,time,timeseries,indend/])
        end do
end do
wallClockElapseTime(date,"Time to extract vars from polar regions ",0)
;
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

;
;-----------------------------------------------------------------
; OUTPUT TO FILE
;-----------------------------------------------------------------
print("Outputting cloud-locked to file...")
diro = "~/analysis/cldlck_polar/nclcode/basics/arctic.amp/flux_seasonality/"
outputfname = varname+".exps.seasonality_last50yrs.nc"
system("/bin/rm -f " + diro + outputfname)    ; remove if exists
fout  = addfile (diro + outputfname, "c")  ; open output file

setfileoption(fout,"DefineMode",True)

; copy file attributes from TS file.
fAtt               = True            ; assign file attributes
fAtt@title = "Climatological "+varname+" in 2xCO2 and pictrl control & cloud-locked simulations."

fAtt@conventions = "First dimension is: (0) 2xCO2, and (1) pictrl. Second dimension is (0) control (cloud feedbacks active), (1) global cloud-locked, and (2) arctic-only cloud-locked."
fAtt@source_file = str_join(ndtooned(expnames),", ")
fAtt@creation_date = systemfunc ("date")
fileattdef( fout, fAtt )            ; copy file attributes

dimNames = (/"2xCO2.preindustrial","control.global_clocked.arctic_clocked","years","months"/)
dimSizes = dimsizes(flx)
dimUnlim = (/ False, False,False, False /)
filedimdef(fout,dimNames,dimSizes,dimUnlim)

filevardef(fout,"months",typeof(months),getvardims(months))
filevardef(fout,"years",typeof(years),getvardims(years))
filevardef(fout,"clim",typeof(flx),getvardims(flx))
filevarattdef(fout,"clim",flx)
filevarattdef(fout,"months",months)
setfileoption(fout,"DefineMode",False)

fout->years = (/years/)
fout->months = (/months/)
fout->clim = (/flx/)
end
