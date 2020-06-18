;========================================================================
; This is a script that simply calls the function written in calc_GWTS.ncl 
; to output a netcdf file containing the temperature response to some 
; forcing -- in our case, a CO2 doubling. 
;
; Replace the filenames with those corresponding to the CESM postprocessed
; timeseries output file for surface temperature (TS) for preindustrial 
; control and forced simulations.
;

load "./calc_GWTS.ncl"

diro = " " ; output directory

; Global cloud-locking configuration
expname = "globalclock"
fname2xCO2 = "B1850C5CN.clock.9p.2xCO2.cam.h0.TS.014003-034309.nc"
fnamepictrl = "B1850C5CN.clock.9p.global.cam.h0.TS.000101-030109.nc"
filenameo = "B1850C5CN.clock.9p.2xCO2.cam.h0.GWTS"
calc_gwts(diro,expname,fname2xCO2,fnamepictrl,filenameo)

; Arctic-only cloud-locking configuration 
expname = "arcticclock"
fname2xCO2 = "B1850C5CN.clock.9p.70-90N.2xCO2.cam.h0.TS.014003-029302.nc"
fnamepictrl = "B1850C5CN.clock.9p.70-90N.cam.h0.TS.000101-021106.nc"
filenameo = "B1850C5CN.clock.9p.70-90N.2xCO2.cam.h0.GWTS" 
calc_gwts(diro,expname,fname2xCO2,fnamepictrl,filenameo)

; Control, cloud feedbacks active globally
expname = "cloudsactive"
fname2xCO2 = "b.e11.B1850C5CN.f09_g16.005_2xCO2.cam.h0.TS.000101-025104.nc"
fnamepictrl = "b.e11.B1850C5CN.f09_g16.005.cam.h0.TS.040001-059912.nc"
filenameo = "b.e11.B1850C5CN.f09_g16.005_2xCO2.cam.h0.GWTS" 
calc_gwts(diro,expname,fname2xCO2,fnamepictrl,filenameo)

