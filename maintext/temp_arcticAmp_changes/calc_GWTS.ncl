procedure calc_gwts(diro,expname,fname2xCO2,fnamepictrl,filenameo)
;===========================================================
;-------- DESCRIPTION ---------------------------------------
; This function calculates the response of temperature to a doubling of CO2.
;
; The response is calculated by subtracting the monthly climatological surface
; temperature from a simulation with preindustrial control forcing from the 
; first 150 years of a simulation with doubled CO2. 
;
; It's intended purpose was for comparing the response of temperature across a
; suite of simulations: one simulation with cloud feedbacks active, another
; with global cloud feedbacks locked, and a last with only Arctic cloud 
; feedbacks locked. Thus, there are many lines hardcoded to accommodate these
; simulations.
;
;-------- USAGE --------------------------------------------
; Inputs (all strings): 
; - diro - the directory for outputted temperature response netcdf files
; - expname - a string with no spaces that describes the experimental 
;	configuration (for our studies, it was something like "control", 
;	"globalcloudlocked", and "arcticcloudlocked")
; - fname2xCO2 - the casename for the experiment with doubled CO2
; - fnamepictrl - the casename for the experiment with preindustrial control 
;	forcing
; - filenameo - user-defined filename for output netcdf file containing 
;	temperature response
;
; Outputs: 
; Nothing is returned, but creates a new netcdf file in the desired output 
; directory. This new file contains a 3D variable called "GWTS" (global warming 
; surface temperature), where each timepoint is a map of the 2xCO2 surface 
; temperature with the climatological temperature of the preindustrial control 
; simulation for the corresponding month removed. 
;===========================================================

begin

dir = diro+"orig/"
noyrs = 50 ; years over which to calculate climatology in pictrl simulation

print("extract 2xCO2 simulation...")
f = addfile(dir+fname2xCO2,"r")
lat = f->lat
nlat = dimsizes(lat)
lon = f->lon
nlon = dimsizes(lon)
time = f->time
ntim = 150*12
time:=time(0:ntim-1) ; extract even number of years
ts2xco2 = f->TS(0:ntim-1,:,:) ; make sure even number of years

;-----------------------------------------------------------
; Figuring out appropriate time period over which to calculate climatology
; in preindustrial control simulation
;-----------------------------------------------------------
; Choose last year analyzed of 2xCO2 simulation. 
; Look for previous 50 years from pictrl.
timecal = cd_calendar(time,0)
tend = new(2,integer)
tend(0) = toint(timecal(ntim-1,0)) ; 150 years past branch date is end year
tend(1) = toint(timecal(ntim-1,1)) ; month one (kind of doesn't matter because you'll have 50 Januaries, Februaries, no matter what.)

; find corresponding month & year for the purpose of pictrl simulation:
if fname2xCO2.eq."b.e11.B1850C5CN.f09_g16.005_2xCO2.cam.h0.TS.000101-025104.nc"
	; because this simulation doesn't indicate which year is branched from pictrl
	tend(0) = 552 
else if fname2xCO2.eq."B1850C5CN.clock.9p.70-90N.2xCO2.cam.h0.TS.014003-029302.nc"
	; Arctic-only pictrl simulation doesn't last for 150 years after 2xCO2 was branched, so
	; we will use just last 50 years after that simulation (years 160 - 210; 2xCO2 simulation
	; was branched at year 140).
	tend(0) = 210
end if
end if

; find index in pictrl simulation that corresponds to these years
print("extracting pictrl")
f = addfile(dir+fnamepictrl,"r")
timept = cd_calendar(f->time,0)
indend = ind(timept(:,0).eq.tend(0) .and. timept(:,1).eq.tend(1))
pictrlts = f->TS(indend-noyrs*12+1:indend,:,:)


;----------------------------------------------------------------------
; Calculate climatology in preindustrial control simulation & subtract pictrl
;----------------------------------------------------------------------
; There are two methods: one uses conform_dims. The other, "brute force" method. 
; I think I avoid using conform_dims because two of our 2xCO2 simulationsstart in 
; March instead of January... and it was hard to keep track of the indices.

; conform_dims method
;---------------------
;ts2xco2 = ts2xco2-conform_dims(dimsizes(ts2xco2),tspictrl,(/1,2/)) ; conform_dims method. 

; Brute force method:
;---------------------
; calculate climatology of preindustrial control simulation
pictrl_clim = dim_avg_n_Wrap(reshape(pictrlts,(/noyrs,12,nlat,nlon/)),0) 
tspictrl = ts2xco2 
do n=0,ntim/12-1
	tspictrl(n*12:(n+1)*12-1,:,:) = (/pictrl_clim/)
end do
ts2xco2 = ts2xco2-tspictrl

copy_VarCoords(pictrl_clim(0,:,:),ts2xco2(0,:,:))
ts2xco2@units = "delta K"
ts2xco2@long_name = "Response to CO2 doubling"

;-----------------------------------------------------------------------
; Figure out string corresponding to GWTS time period for output filename
;-----------------------------------------------------------------------
time_cal = cd_calendar(time,0)
timestartyr = tostring(toint(time_cal(0,0)))
timestartmo = tostring(toint(time_cal(0,1))-1) ; because the cd_cal shows +1 month greater than what it is
timeendyr = tostring(toint(time_cal(ntim-1,0)))
timeendmo = tostring(toint(time_cal(ntim-1,1))-1) ; because the cd_cal shows +1 month greater than what it is
if timeendmo.eq."0"
timeendmo = "12"
timeendyr = tostring(toint(time_cal(ntim-1,0)-1))
end if
if dimsizes(tochar(timeendmo)).lt.2
timeendmo = "0"+timeendmo
end if
if dimsizes(tochar(timestartmo)).lt.2
timestartmo = "0"+timestartmo
end if
if dimsizes(tochar(timestartyr)).lt.2
timestartyr = "00"+timestartyr
end if
if dimsizes(tochar(timeendyr)).lt.2
timeendyr = "00"+timeendyr
else if dimsizes(tochar(timeendyr)).eq.2
timeendyr = "0"+timeendyr
end if
end if


;-----------------------------------------------------------------------
; Output to NetCDF file: control
;-----------------------------------------------------------------------
print("Outputting cloud-locked to file...")
filenameo = filenameo+".0"+timestartyr+timestartmo+"-0"+timeendyr+timeendmo+".nc"
system("/bin/rm -f " + diro + filenameo)    ; remove if exists
fout  = addfile (diro + filenameo, "c")  ; open output file

setfileoption(fout,"DefineMode",True)

; copy file attributes from TS file.
fAtt               = True            ; assign file attributes
origatts = getfileatts(f)
do n=0,dimsizes(origatts)-1
     fAtt@$origatts(n)$ = f@$origatts(n)$
end do
fAtt@title = "Surface Temp response to a doubling of CO2 in the "+expname+" simulation. Calculated as the CO2 minus the mean of years 01-150 after 2xCO2 simulation was branched in the pictrl run at every gridpt. In the Arctic-only simulation, the years subtracted are 20-70 after the 2xCO2 simulation was branched, because the pictrl simulation only went out to year 210, while the branching occurred at year 140."
fAtt@source_file = fnamepictrl +" & "+fname2xCO2 
fAtt@creation_date = systemfunc ("date")
fileattdef( fout, fAtt )            ; copy file attributes

dimNames = (/"time","lat","lon"/)
dimSizes = (/ -1   ,nlat,nlon/)
dimUnlim = (/ True ,False,False/)
filedimdef(fout,dimNames,dimSizes,dimUnlim)

filevardef(fout,"time" ,typeof(time),getvardims(time))
filevardef(fout,"lat" ,typeof(lat),getvardims(lat))
filevardef(fout,"lon" ,typeof(lon),getvardims(lon))
filevardef(fout,"GWTS",typeof(ts2xco2),getvardims(ts2xco2))
filevarattdef(fout,"GWTS",ts2xco2)
filevarattdef(fout,"time" ,time)
filevarattdef(fout,"lat" ,lat)
filevarattdef(fout,"lon" ,lon)
setfileoption(fout,"DefineMode",False)

fout->time   = (/time/)
fout->lat   = (/lat/)
fout->lon   = (/lon/)
fout->GWTS = (/ts2xco2/)
end
