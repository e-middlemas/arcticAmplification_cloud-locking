procedure calc_ocn_heat(inpath,expname,outpath,starttime)
;=============================================================
; CALCULATING OCEANIC HEAT TRANSPORT
;
; This procedure was written by Eleanor Middlemas (2019) but based 
; entirely from calculations written by Jen Kay at CU Boulder.
;
; 1. Load in global total, northward heat transport N_HEAT 
; 2. Average over last 50 years of 2xCO2 simulation or years
; 	100 - 150 after branch year
; 3. Convert to atmospheric grid using linear interpolation
; 4. Convert also between transport and flux (PW --> W m-2)
; 5. Save to file
;=============================================================
begin

; need N_HEAT from POP
focn = addfile(systemfunc("ls "+inpath+expname+".pop.h.N_HEAT*"),"r")
timecal = cd_calendar(focn->time,0)
time = timecal(:,0)+mod(timecal(:,1)+10,12)/12.

; Avg over years 150-200 (yr 1 is branch year)
; user must provide branch year and month
startind = ind(time.eq.starttime)
endind = ind(time.eq.(starttime+50)) ; 50-year average
if ismissing(endind).eq.True ; for cloud-locked arctic-only pictrl simulation
        endind = dimsizes(time)
end if

nheat = focn->N_HEAT(startind:endind-1,0,0,:)
; transport regions is global ocean
; transport components is total
nheat:=dim_avg_n_Wrap(nheat,0)
;
;-------------------------------------------------------------
; Convert to atm grid

lat_aux_grid = focn->lat_aux_grid
;
; extract atmospheric coordinates
fatm = addfile(systemfunc("ls "+inpath+expname+".cam.h0.FSNS.*.nc"),"r")
atmcoord=fatm->FSNS(0,:,:)
lat = atmcoord&lat
atmcoord&lat@units = "degrees_north"
nlat = dimsizes(lat)
;
ocn_nht=linint1(lat_aux_grid,nheat,False,atmcoord&lat,0)
copy_VarCoords(atmcoord,ocn_nht)
copy_VarAtts(nheat,ocn_nht)
ocn_nht@units = "PetaWatts"
;
Re   = 6.371e6    ;; radius of the earth (m)
pi = 4.0 * atan(1.0)
convert=1e15/(2*pi*Re*Re*(1+cos(lat*(pi/180)))) ;; convert constant from petawatts to Wm-2
; conver to a flux
ocn_nht_flux = ocn_nht*convert
copy_VarCoords(ocn_nht,ocn_nht_flux)
ocn_nht_flux@units = "W m-2"
;
;-------------------------------------------------------------
; Output to a netcdf file in path
print("Outputting cloud-locked to file...")
filenameo = outpath+expname+".pop.tavg.oceanheattransport.nc"
system("/bin/rm -f " + filenameo)    ; remove if exists
fout  = addfile (filenameo, "c")  ; open output file

setfileoption(fout,"DefineMode",True)

; copy file attributes from TS file.
fAtt               = True            ; assign file attributes
origatts = getfileatts(focn)
do n=0,dimsizes(origatts)-1
     fAtt@$origatts(n)$ = focn@$origatts(n)$
end do
fAtt@title = "Northern heat transport by ocn from "+expname+", averaged over years 100 - 150, where year 1 is the year that the 2xCO2 simulation was branched from the pictrl simulation."
fAtt@source_file = systemfunc("ls "+inpath+expname+"*N_HEAT*")
fAtt@creation_date = systemfunc ("date")
fileattdef( fout, fAtt )            ; copy file attributes

dimNames = (/"lat"/)
dimSizes = (/nlat/)
dimUnlim = (/ False/)
filedimdef(fout,dimNames,dimSizes,dimUnlim)

filevardef(fout,"lat" ,typeof(lat),getvardims(lat))
filevardef(fout,"ocnnht",typeof(ocn_nht),getvardims(ocn_nht))
filevarattdef(fout,"ocnnht",ocn_nht)
filevardef(fout,"ocnnhflux",typeof(ocn_nht_flux),getvardims(ocn_nht_flux))
filevarattdef(fout,"ocnnhflux",ocn_nht_flux)
filevarattdef(fout,"lat" ,lat)
setfileoption(fout,"DefineMode",False)

fout->lat   = (/lat/)
fout->ocnnht = ocn_nht
fout->ocnnhflux = ocn_nht_flux

end
