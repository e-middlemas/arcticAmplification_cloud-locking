procedure calc_atm_heat(inpath,expname,outpath,starttime)

;----------------------------------------------------------------------------
; CALCULATING ATMOSPHERIC HEAT TRANSPORT
;
; 1. Calculate net energy imbalance at the top-of-atmosphere (FSNT-FLNT)
; 2. Calculate net energy balance at the surface, but also correct for the 
; 	lack of latent heat of fusion in the LHFLX term.
; 3. Find total energy transport using top-of-atmosphere imbalance (integrate
;	across latitudes & weigh by area
; 4. Find total atmospheric energy transports using TOA imbalance & surface
;	energy imbalance
; 5. Find latent energy transport. Calculate separately for liquid+ice and
;	liquid+ice+snow (total latent energy tarnsport).
; 6. Find dry static energy transport.
; 7. Save all terms and their associated fluxes to file.
;----------------------------------------------------------------------------

begin

; deal with time & lat/lon coordinates to be used in the rest of code
fatm = addfile(systemfunc("ls "+inpath+expname+".cam.h0.FSNT.*"),"r")
timecal = cd_calendar(fatm->time,0)
time = timecal(:,0)+mod(timecal(:,1)+10,12)/12.

startind = ind(time.eq.starttime) ; will be user-defined
endind = ind(time.eq.(starttime+50)) ; 50-year average
if ismissing(endind).eq.True ; for cloud-locked arctic-only pictrl simulation
        endind = dimsizes(time)
end if

coords = fatm->FSNT(0,:,:)
lat = fatm->lat
lon = fatm->lon
nlat = dimsizes(lat)
nlon = dimsizes(lon)

; convert constant from petawatts to Wm-2 (weigh by latitude)
pi = get_pi("float")
Re = 6.371e6            ; radius of earth (m)
convert=1e15/(2*pi*Re*Re*(1+cos(lat*(pi/180)))) 

;----------------------------------------------------------------------------
; 1. Calculate net energy imbalance at the TOA: 
;----------------------------------------------------------------------------
print("Computing top-of-atmosphere energy imbalance...")
; already loaded in the FSNT timeseries file
toa = fatm->FSNT(startind:endind-1,:,:)
fatm = addfile(systemfunc("ls "+inpath+expname+".cam.h0.FLNT.*"),"r")
toa = toa - fatm->FLNT(startind:endind-1,:,:)
toa:=dim_avg_n_Wrap(toa,0) ; average over years 100 - 150 corresponding to 
			   ; 2xCO2 simulations
copy_VarCoords(coords,toa)

; find heat flux at each latitude by summing over longitudes
toa:= dim_sum(toa)
toa!0 = "lat"
toa&lat = lat
toa@units = "W m-2"
toa@long_name = "Net top-of-atmosphere energy imbalance (FSNT - FLNT)"

;----------------------------------------------------------------------------
; 2. Calculate the net energy imbalance at the at the surface
;----------------------------------------------------------------------------
print("Computing surface energy imbalance...")
f = addfile(systemfunc("ls "+inpath+expname+".cam.h0.FSNS.*"),"r")
surf = f->FSNS(startind:endind-1,:,:)
f = addfile(systemfunc("ls "+inpath+expname+".cam.h0.FLNS.*"),"r")
surf = surf - f->FLNS(startind:endind-1,:,:)
f = addfile(systemfunc("ls "+inpath+expname+".cam.h0.SHFLX.*"),"r")
surf = surf - f->SHFLX(startind:endind-1,:,:)
f = addfile(systemfunc("ls "+inpath+expname+".cam.h0.LHFLX.*"),"r")
lhflx = f->LHFLX(startind:endind-1,:,:)

; apply correction to lhflx before subtracting it from energy budget
Lf = 3.337e5            ; latent heat of fusion (J/kg)
rho = 1000.             ; density of water kg/m3
f = addfile(systemfunc("ls "+inpath+expname+".cam.h0.PRECSC.*"),"r")
snow = f->PRECSC(startind:endind-1,:,:)
f = addfile(systemfunc("ls "+inpath+expname+".cam.h0.PRECSL.*"),"r")
snow = snow + f->PRECSL(startind:endind-1,:,:)
lhflxcorrect = lhflx + Lf*rho*snow

surf = surf - lhflxcorrect 
surf:=dim_avg_n_Wrap(surf,0)
copy_VarCoords(coords,surf)

; find flux at each latitude by summing over longitudes:
surf:=dim_sum(surf)
copy_VarCoords(toa,surf)
delete([/lhflx,lhflxcorrect/])
surf@units = "W m-2"
surf@long_name = "Net surface energy imbalance (positive down) (FSNS-FLNS-SHFLX-LHFLX); LHFLX corrected for latent heat of fusion from snow"

;----------------------------------------------------------------------------
; 3. Find total energy transport using TOA imbalance
;----------------------------------------------------------------------------
print("Finding total energy transport...")
; Find implied total northward heat transport using toa imbalance: sum flux 
;	over the longitudes
; First, define constants
coef = Re^2/1.e15       ; scaled for PW
dlon = 2.*pi/nlon 	; size of nlon in radians (shouldn't this be 360?) 
;dlon = 2.*pi/360 	; shouldn't this be total degrees of longitudes (i.e., 360?)
gw = fatm->gw ; latitude cosine weights in radians (summed to 2)

; sum to find value at each latitude; weigh by area of gridboxes
tot = new(nlat,double)
do i = nlat-1, 0, 1      ;start sum at most northern point
     tot(i)= -coef*dlon*sum(toa(i:nlat-1)*gw(i:nlat-1))
end do

tot!0 = "lat"
tot&lat = toa&lat
tot@units = "PetaWatts"
tot@long_name = "Total northward heat transport required by TOA imbalance"

tot_flux = tot*convert
tot_flux!0 = "lat"
tot_flux&lat = toa&lat
tot_flux@units = "W m-2"
tot_flux@long_name = tot@long_name

;----------------------------------------------------------------------------
; 4. Find total atmospheric energy transports using TOA imbalance & surface 
;    energy imbalance
;----------------------------------------------------------------------------
print("Finding total energy transport by atmosphere...")
atmflux = surf - toa
;
; sum to find value at each latitude
atm = new(nlat,double)
do i = nlat-1, 0, 1      ;start sum at most northern point
     atm(i)= coef*dlon*sum(atmflux(i:nlat-1)*gw(i:nlat-1))
end do
atm!0 = "lat"
atm&lat = lat
atm@units = "PetaWatts"
atm@long_name = "Northward atmospheric heat transport required by TOA imbalance & surface energy balance"

atm_flux = atm*convert
atm_flux!0 = "lat"
atm_flux&lat = lat
atm_flux@units = "W m-2"
atm_flux@long_name = atm@long_name

;----------------------------------------------------------------------------
; 5. Find latent atmospheric energy transports using water vapor & latent
;    heat. calculate separately for liquid+ice latent heat flux & 
;    liquid+ice+snow (See appendix of Kay et al. 2012, J. Clim., for more
;    details).
;----------------------------------------------------------------------------
print("Finding latent energy transport...")
f = addfile(systemfunc("ls "+inpath+expname+".cam.h0.QFLX.*"),"r")
qflx = f->QFLX(startind:endind-1,:,:)  ; net surface water flux kg/m2/s
Lv   = 2.501e6  ; latent heat of vaporization (J/kg)
lhflx_evap = Lv*qflx ; heat from evaporation

; Find implied latent heat transport using PRECT and lhflx
f = addfile(systemfunc("ls "+inpath+expname+".cam.h0.PRECC.*"),"r")
precip = f->PRECC(startind:endind-1,:,:) 
f = addfile(systemfunc("ls "+inpath+expname+".cam.h0.PRECL.*"),"r")
precip = precip+f->PRECL(startind:endind-1,:,:)

;**********************************
; 5a. Liquid + ice only, no snow
;**********************************
print("Starting with liquid + ice only for latent energy transport...")
; liquid precip in Wm-2 (m/s * kg/m3 *J/kg = J/s/m2 = W/m2).
lhflx_liq_precip = Lv*rho*(precip + 0.917*snow)  ; where does the 0.917 come from?


; latent heat transport is evaporation minus precipitation
lhflx_liq = lhflx_evap - lhflx_liq_precip

; sum over longitudes and avg over time:
lhflx_liq:=dim_sum(dim_avg_n(lhflx_liq,0))

;; sum to find NW component at each latitude
liq_latent = new(nlat,double)
do i = nlat-1, 0, 1      ;start sum at most northern point
     liq_latent(i)= -coef*dlon*sum(lhflx_liq(i:nlat-1)*gw(i:nlat-1))
end do
liq_latent!0 = "lat"
liq_latent&lat = lat
liq_latent@units = "PetaWatts"
liq_latent@long_name = "Northward atmospheric latent energy transport by liquid+ice only"

liq_latent_flux = liq_latent*convert
liq_latent_flux!0 = "lat"
liq_latent_flux&lat = lat
liq_latent_flux@units = "W m-2"
liq_latent_flux@long_name = liq_latent@long_name

;*****************************
; 5b. liquid + solid (total)
;*****************************
print("Then calculating total latent energy transport....")
; precip latent heating in Wm-2 from liquid and solid
lhflx_precip = lhflx_liq_precip + Lf*rho*0.917*snow
lhflx = lhflx_evap - lhflx_precip  ;; latent heat transport is evaporation minus precipitation

; sum over longitudes
lhflx:=dim_sum(dim_avg_n(lhflx,0))

; sum to find NW component at each latitude
tot_latent = new(nlat,double)
do i = nlat-1, 0, 1      ;start sum at most northern point
     tot_latent(i)= -coef*dlon*sum(lhflx(i:nlat-1)*gw(i:nlat-1))
end do
tot_latent!0 = "lat"
tot_latent&lat = lat
tot_latent@units = "PetaWatts"
tot_latent@long_name = "Northward atmospheric latent energy transport by total water (liquid, snow, and ice)"

tot_latent_flux = tot_latent*convert
tot_latent_flux!0 = "lat"
tot_latent_flux&lat = lat
tot_latent_flux@units = "W m-2"
tot_latent_flux@long_name = tot_latent@long_name

;----------------------------------------------------------------------------
; 6. Find dry static energy (Fatm - F_latent)
;---------------------------------------------------------------------------
print("Calculating dry static energy transport...")
dse = atm - tot_latent
dse!0 = "lat"
dse&lat = lat
dse@units = "PetaWatts"
dse@long_name = "Northward atmospheric by dry static energy (total atmospheric minus latent energy)"

dse_flux = dse*convert
dse_flux!0 = "lat"
dse_flux&lat = lat
dse_flux@units = "W m-2"
dse_flux@long_name = dse@long_name

;----------------------------------------------------------------------------
; 7. Save to a file 
;---------------------------------------------------------------------------
print("Outputting cloud-locked to file...")
filenameo = outpath+expname+".cam.tavg.total+atmheattransport.nc"
system("/bin/rm -f " + filenameo)    ; remove if exists
fout  = addfile (filenameo, "c")  ; open output file

setfileoption(fout,"DefineMode",True)

; copy file attributes from TS file.
fAtt               = True            ; assign file attributes
origatts = getfileatts(fatm)
do n=0,dimsizes(origatts)-1
     fAtt@$origatts(n)$ = fatm@$origatts(n)$
end do
fAtt@title = "Northern heat transport by atmosphere + its subcomponents from "+expname
fAtt@source_file = systemfunc("ls "+inpath+expname+"*dvidtd*")
fAtt@creation_date = systemfunc ("date")
fileattdef( fout, fAtt )            ; copy file attributes

dimNames = (/"lat"/)
dimSizes = (/nlat/)
dimUnlim = (/ False/)
filedimdef(fout,dimNames,dimSizes,dimUnlim)

filevardef(fout,"lat" ,typeof(lat),getvardims(lat))
filevardef(fout,"toa_flux",typeof(toa),getvardims(toa))
filevardef(fout,"surf_flux",typeof(surf),getvardims(surf))
filevardef(fout,"tot",typeof(tot),getvardims(tot))
filevardef(fout,"tot_flux",typeof(tot_flux),getvardims(tot_flux))
filevardef(fout,"atm",typeof(atm),getvardims(atm))
filevardef(fout,"atm_flux",typeof(atm_flux),getvardims(atm_flux))
filevardef(fout,"liq_latent",typeof(liq_latent),getvardims(liq_latent))
filevardef(fout,"liq_latent_flux",typeof(liq_latent_flux),getvardims(liq_latent_flux))
filevardef(fout,"tot_latent",typeof(tot_latent),getvardims(tot_latent))
filevardef(fout,"tot_latent_flux",typeof(tot_latent_flux),getvardims(tot_latent_flux))
filevardef(fout,"dse",typeof(dse),getvardims(dse))
filevardef(fout,"dse_flux",typeof(dse_flux),getvardims(dse_flux))

filevarattdef(fout,"lat" ,lat)
filevarattdef(fout,"toa_flux",toa)
filevarattdef(fout,"surf_flux",surf)
filevarattdef(fout,"tot",tot)
filevarattdef(fout,"tot_flux",tot_flux)
filevarattdef(fout,"atm",atm)
filevarattdef(fout,"atm_flux",atm_flux)
filevarattdef(fout,"liq_latent",liq_latent)
filevarattdef(fout,"liq_latent_flux",liq_latent_flux)
filevarattdef(fout,"tot_latent",tot_latent)
filevarattdef(fout,"tot_latent_flux",tot_latent_flux)
filevarattdef(fout,"dse",dse)
filevarattdef(fout,"dse_flux",dse_flux)

setfileoption(fout,"DefineMode",False)

fout->lat   = (/lat/)
fout->toa_flux = (/toa/)
fout->surf_flux = (/surf/)
fout->tot = (/tot/)
fout->tot_flux = (/tot_flux/)
fout->atm = (/atm/)
fout->atm_flux = (/atm_flux/)
fout->liq_latent = (/liq_latent/)
fout->liq_latent_flux = (/liq_latent_flux/)
fout->tot_latent = (/tot_latent/)
fout->tot_latent_flux = (/tot_latent_flux/)
fout->dse = (/dse/)
fout->dse_flux = (/dse_flux/)

end
