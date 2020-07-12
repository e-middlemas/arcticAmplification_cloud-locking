procedure calc_ice_heat(inpath,expname,outpath,starttime)
;=============================================================
; CALCULATING HEAT TRANSPORT BY ICE
;
; This procedure was written by Eleanor Middlemas (2019) but based 
; entirely from calculations written by Jen Kay at CU Boulder.
;
; 1. Load in "dvidtd", or ice volume convergence tendency
; 2. Average over last 50 years of 2xCO2 simulation or years
;       100 - 150 after branch year
; 3. Convert to atmospheric grid using PopLatLon (look on NCL website
;	for more information. Requires the use of script popRemap.ncl)
; 4. Convert tendency to volume flux and then to energy flux
; 5. Convert also between transport and flux (PW --> W m-2)
; 6. Save to file
;=============================================================
begin

; must also have popRemap.ncl saved in local directory. User should
; search for it on the NCL website.
load "./popRemap.ncl"

; need dvidtd from CICE
fice = addfile(systemfunc("ls "+inpath+expname+".cice.h.dvidtd*"),"r")
timecal = cd_calendar(fice->time,0)
time = timecal(:,0)+mod(timecal(:,1)+10,12)/12.

; user must provide start & end indices ("startind" & "endind")
startind = ind(time.eq.starttime)
endind = ind(time.eq.starttime+50) ; 50-year average
if ismissing(endind).eq.True ; for cloud-locked arctic-only pictrl simulation
	endind = dimsizes(time)
end if
dvidtd = fice->dvidtd(startind:endind-1,:,:)
;nheat:=dim_avg_n_Wrap(nheat(startind:endind-1,:,:),0)
dvidtd:=dim_avg_n_Wrap(dvidtd,0)

;-------------------------------------------------------------
; Convert to atm grid
;-------------------------------------------------------------
; extract atmospheric coordinates
fatm = addfile(systemfunc("ls "+inpath+expname+".cam.h0.FSNS.*.nc"),"r")
atmcoord=fatm->FSNS(0,:,:)
lat = atmcoord&lat
lon = atmcoord&lon
atmcoord&lat@units = "degrees_north"
atmcoord&lon@units = "degrees_east"
nlon = dimsizes(lon)
nlat = dimsizes(lat)

dvidtd_atm=tofloat(PopLatLon(dvidtd,"gx1v6","fv0.9x1.25","aave","da","090309"))
copy_VarCoords(atmcoord,dvidtd_atm)
copy_VarAtts(dvidtd,dvidtd_atm)

;-------------------------------------------------------------
; convert ice to a volume flux and then to an energy flux
;-------------------------------------------------------------
; create an array called "boxarea" with the area of each grid box
; calculate area averages following functions_contrib.ncl from ice diagnostics
Re   = 6.371e6    ;; radius of the earth (m)
pi = 4.0 * atan(1.0)
Earea = 4.*pi*Re^2          ; surface area of Earth
;
; come up with conversion for weighing each latitude/longitude
if (typeof(lat) .eq. "double") then
     wgt = doubletofloat(NormCosWgtGlobe(lat))
else
     wgt = NormCosWgtGlobe(lat)
end if
;
tsum = sum(wgt)            ; sum of all weights
nwgt = wgt/tsum            ; frac of sphere of each lat band
boxarea = Earea*nwgt/nlon   ; area of each grid box (lat) in m2
boxarea!0="lat"
boxarea&lat=lat
;
dvidtd_atm_zsum=dim_sum_n_Wrap(dvidtd_atm,1)*boxarea ; take a zonal sum- sum across longitudes
dvidtd_atm_zsum = dvidtd_atm_zsum/(100*24*3600.0) ; to cm/day to m/sec
;
; find northward ice flux: integrate flux along latitudes
dvidtd_north=dvidtd_atm_zsum*0.0
do j = 0, nlat-2
   dvidtd_north(j) = dvidtd_atm_zsum(j) + sum(dvidtd_atm_zsum(j+1:nlat-1))
end do
;
; convert from ice flux (m^3 ice per second) to energy flux (Watts, Joules per second)
Lf = 3.337e5            ; latent heat of fusion (J/kg)
rho_ice = 917.           ; density of ice kg/m3
heatice_north = -(dvidtd_north*rho_ice*Lf)/1e15  ;;; m3/s * kg/m3 * J/kg = J/s = Watt/10e15 = PetaWatt
copy_VarCoords(boxarea,heatice_north)
heatice_north@units = "PetaWatts"
;
;print(heatice_north)
convert=1e15/(2*pi*Re*Re*(1+cos(lat*(pi/180)))) ;; convert constant from petawatts to Wm-2
; conver to a flux
heatice_north_flux = heatice_north*convert
copy_VarCoords(heatice_north,heatice_north_flux)
heatice_north_flux@units = "W m-2"
;
;-------------------------------------------------------------
; Output to a netcdf file in path 
print("Outputting cloud-locked to file...")
filenameo = outpath+expname+".cice.tavg.iceheattransport.nc"
system("/bin/rm -f " + filenameo)    ; remove if exists
fout  = addfile (filenameo, "c")  ; open output file

setfileoption(fout,"DefineMode",True)

; copy file attributes from TS file.
fAtt               = True            ; assign file attributes
origatts = getfileatts(fice)
do n=0,dimsizes(origatts)-1
     fAtt@$origatts(n)$ = fice@$origatts(n)$
end do
fAtt@title = "Northern heat transport by ice from "+expname
fAtt@source_file = systemfunc("ls "+inpath+expname+"*dvidtd*")
fAtt@creation_date = systemfunc ("date")
fileattdef( fout, fAtt )            ; copy file attributes

dimNames = (/"lat"/)
dimSizes = (/nlat/)
dimUnlim = (/ False/)
filedimdef(fout,dimNames,dimSizes,dimUnlim)

filevardef(fout,"lat" ,typeof(lat),getvardims(lat))
filevardef(fout,"icenht",typeof(heatice_north),getvardims(heatice_north))
filevarattdef(fout,"icenht",heatice_north)
filevardef(fout,"icenhflux",typeof(heatice_north_flux),getvardims(heatice_north_flux))
filevarattdef(fout,"icenhflux",heatice_north_flux)
filevarattdef(fout,"lat" ,lat)
setfileoption(fout,"DefineMode",False)

fout->lat   = (/lat/)
fout->icenht = heatice_north
fout->icenhflux = heatice_north_flux

end 
