;===============================================================================
; Run code to calculate northward energy transport
; Written by Eleanor Middlemas, 2019
; Credit to Professor Jen Kay at CU Boulder for
;	coding the calculations for actually calculating northward heat
;	transport.
;
; This script runs calculations northward energy transport in the atmosphere, ice,
; 	& ocean components averaged over years 100-150 and saves to netcdf
;	files. The format of each is simply a vector of zonal-mean energy 
;	transport values corresponding to latitude. 
;
; The user must indicate where the original output CESM data lives, as well as
; 	the path to output northward heat transport estimates. 
;
; The variables needed for atmospheric component energy budget analysis include:
;	- FSNT
;	- FLNT
;	- FSNS
;	- FLNS
;	- SHFLX
;	- LHFLX
; 	- PRECSC
;	- PRECSL
;	- QFLX
;	- PRECC
; 	- PRECL
;
; The variables needed for ocean component energy budget analysis include:
;	- N_HEAT (from POP)
;	- FSNS (for interpolation only, from CAM) 
;
; The variables needed for ice component energy budget analysis include:
;	- dvidtd
;	- FSNS (for interpolation only, from CAM) 
;	
; The current code is written to analyze a suite of cloud-locking experiments,
; 	so the experiment names below ("expnames") reflect the names of those
;	experiments. Also, the loop to determine the start date is written
;	especially for those experiments. Specifically, that on lines 60-62, & 
;	lines 66-67. 
;===============================================================================

load "calc_atm_nht.ncl"
load "calc_ice_nht.ncl"
load "calc_ocn_nht.ncl"

sourcedatapath = "./orig/"
outputpath = "/"

expnames = (/"b.e11.B1850C5CN.f09_g16.005","b.e11.B1850C5CN.f09_g16.005_2xCO2", \+
"B1850C5CN.clock.9p.global","B1850C5CN.clock.9p.2xCO2", \+
"B1850C5CN.clock.9p.70-90N","B1850C5CN.clock.9p.70-90N.2xCO2"/)

; Figure out start indices based on 100 years after branch year of 2xCO2 simulation:
tstarts = new(dimsizes(expnames),float)
do e=1,6,2
	f=addfile(systemfunc("ls "+sourcedatapath+expnames(e)+".cam.h0.FSNT.*"),"r")
	timetmp = cd_calendar(f->time,0) 
	time = timetmp(:,0)+mod(timetmp(:,1)+10,12)/12.
	; start at year 100 into 2xCO2 simulation
	tstarts(e) = time(100*12)
	tstarts(e-1) = tstarts(e)
	delete([/timetmp,time/])
end do
tstarts(4) = tstarts(5)-100 ; need to start at branch year because simulation is not 240 years long
tstarts(0) = 502.0 ; because control 2xCO2 simulation is branched from January of year 402. 

do e=0,dimsizes(expnames)-1
	print("------------------------------------------------------------")
	print("Calculating zonal-mean heat budget for "+expnames(e)+":")
	print("------------------------------------------------------------")
	calc_atm_heat(sourcedatapath,expnames(e),outputpath,tstarts(e))
	calc_ocn_heat(sourcedatapath,expnames(e),outputpath,tstarts(e))
	calc_ice_heat(sourcedatapath,expnames(e),outputpath,tstarts(e))
end do
