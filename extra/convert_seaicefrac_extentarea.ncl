; This code converts CAM's ICEFRAC variable to sea ice extent & sea ice area and 
; then saves it to a file.
; These result in timeseries... I may actually export them as netcdf files that 
; conserves area quantities... if that's possible? I'm not sure. How was Ed able to 
; make covariance plots in his paper? Maybe he just applied covariances between the
; timeseries of sea ice area/extent and the spatial pattern of whatever variable.
;
procedure convert_frac_extentarea(dir:string, filename:string, diro:string, filenameIE:string, filenameIA:string)
;
; dir = directory where "filename" exists
; file = filename of the ICEFRAC file- must be timeseries file
; diro = output where to put new ICEEXTENT and ICEAREA files
; filenameIE = filename of output ICEEXTENT file
; filenameIA = filename of output ICEAREA file
;
begin
;;; read in icefrac
print("Reading in ICEFRAC...")
    f = addfile(dir+filename,"r")
    icefrac = f->ICEFRAC
    time = f->time
    ntime = dimsizes(time)
    lat = f->lat
    nlat = dimsizes(lat)
    lon = f->lon
    nlon = dimsizes(lon)

;; calculate extent
    extent=icefrac
    extent@units = "1=ice,0=water"
    extent@long_name = "Ice extent defined as greater than 15% ice fraction"
    extent=where(icefrac.gt.0.15,1,0)
    ;printVarSummary(extent)
    ;dimfoo=dimsizes(extent)

    ;; create an array with the area of each grid box in CCSM4 1 degree
     re   = 6371.009    ;; radius of the earth (km)
     pi = 4.0 * atan(1.0)
     rad  = pi / 180.0
     con  = (2*pi*re)/360.0  ;; distance in km of 1 degree at equator assuming spherical earth, circumference/360 degrees
     Earea = 4.*pi*re^2          ; surface area of Earth

   ;; calculate area averages following functions_contrib.ncl from ice diagnostics
    if (typeof(lat) .eq. "double") then
      wgt = doubletofloat(NormCosWgtGlobe(lat))
    else
      wgt = NormCosWgtGlobe(lat)
    end if

    tsum = sum(wgt)            ; sum of all weights
    nwgt = wgt/tsum            ; frac of sphere of each lat band
    boxarea = Earea*nwgt/nlon   ; area of each grid box (lat) in km^2

;;;;  calculations of ice extent and area timeseries
print("Calculating area & extent...")
    NHarea = new((/ntime,nlat/),float)
    NHextent = new((/ntime,nlat/),float)
    SHarea = new((/ntime,nlat/),float)
    SHextent = new((/ntime,nlat/),float)

    do jj = 0,ntime-1
    do ji = nlat/2, nlat-1
     NHarea(jj,ji) =  sum(boxarea(ji)*icefrac(jj,ji,:))
     NHextent(jj,ji) =  sum(boxarea(ji)*extent(jj,ji,:))
    end do
    do ji = 0,nlat/2-1
     SHarea(jj,ji) =  sum(boxarea(ji)*icefrac(jj,ji,:))
     SHextent(jj,ji) =  sum(boxarea(ji)*extent(jj,ji,:))
    end do
    end do

    NHicearea = dim_sum(NHarea)/1.e6        ;; units of million km2
    NHiceextent = dim_sum(NHextent)/1.e6
    SHicearea = dim_sum(SHarea)/1.e6
    SHiceextent = dim_sum(SHextent)/1.e6
    extent@units = "1e6 (million) kilometers squared"

    copy_VarMeta(extent(:,0,0),NHiceextent)
    copy_VarMeta(extent(:,0,0),SHiceextent)

    copy_VarMeta(extent(:,0,0),NHicearea)
    NHicearea@long_name = "Ice area defined as sea ice fraction in one gridbox times the area of that gridbox"

    copy_VarMeta(extent(:,0,0),SHicearea)
    SHicearea@long_name = "Ice area defined as sea ice fraction in one gridbox times the area of that gridbox"


;----- Output to NetCDF file: NH/SH ICE EXTENT
print("Outputting to netcdf files here: "+diro)
system("/bin/rm -f " + diro + filenameIE)    ; remove if exists
fout  = addfile (diro + filenameIE, "c")  ; open output file

setfileoption(fout,"DefineMode",True)

; copy file attributes from ICEFRAC file.
fAtt               = True            ; assign file attributes
origatts = getfileatts(f)
do n=0,dimsizes(origatts)-1
     fAtt@$origatts(n)$ = f@$origatts(n)$
end do
fAtt@title = "NH/SH ICE EXTENT timeseries"
fAtt@source_file   =  filename ; source file is ICEFRAC file.
fAtt@creation_date = systemfunc ("date")        
fileattdef( fout, fAtt )            ; copy file attributes    

dimNames = (/"time"/)  
dimSizes = (/ -1   /) 
dimUnlim = (/ True /)   
filedimdef(fout,dimNames,dimSizes,dimUnlim)

filevardef(fout,"time" ,typeof(time),getvardims(time))
filevardef(fout,"NHICEEXTENT",typeof(NHiceextent),getvardims(NHiceextent))
filevardef(fout,"SHICEEXTENT",typeof(SHiceextent),getvardims(SHiceextent))
                                                    
filevarattdef(fout,"NHICEEXTENT",NHiceextent)
filevarattdef(fout,"SHICEEXTENT",SHiceextent) 
filevarattdef(fout,"time" ,time)                    
setfileoption(fout,"DefineMode",False)

fout->time   = (/time/)     
fout->NHICEEXTENT = (/NHiceextent/)
fout->SHICEEXTENT = (/SHiceextent/)
delete(fout)

;----- Output to NetCDF file: NH/SH ICE AREA
system("/bin/rm -f " + diro + filenameIA)    ; remove if exists
fout  = addfile (diro + filenameIA, "c")  ; open output file

setfileoption(fout,"DefineMode",True)

; copy file attributes from ICEFRAC file.
fAtt               = True            ; assign file attributes
origatts = getfileatts(f)
do n=0,dimsizes(origatts)-1
     fAtt@$origatts(n)$ = f@$origatts(n)$
end do
fAtt@title = "NH/SH ICE AREA timeseries"
fAtt@source_file   =  filename ; source file is ICEFRAC file.
fAtt@creation_date = systemfunc ("date")        
fileattdef( fout, fAtt )            ; copy file attributes    

dimNames = (/"time"/)  
dimSizes = (/ -1   /) 
dimUnlim = (/ True /)   
filedimdef(fout,dimNames,dimSizes,dimUnlim)

filevardef(fout,"time" ,typeof(time),getvardims(time))
filevardef(fout,"NHICEAREA",typeof(NHicearea),getvardims(NHicearea))
filevardef(fout,"SHICEAREA",typeof(SHicearea),getvardims(SHicearea))
                                                    
filevarattdef(fout,"NHICEAREA",NHicearea)
filevarattdef(fout,"SHICEAREA",SHicearea) 
filevarattdef(fout,"time" ,time)                    
setfileoption(fout,"DefineMode",False)

fout->time   = (/time/)     
fout->NHICEAREA = (/NHicearea/)
fout->SHICEAREA = (/SHicearea/)
end
