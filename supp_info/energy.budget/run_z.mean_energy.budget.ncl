load "calc_atm_nht.ncl"
load "calc_ice_nht.ncl"
load "calc_ocn_nht.ncl"

sourcedatapath = "/glade/work/eleanorm/cldlck_data/cldlck_polar/orig/"
outputpath = "/glade/work/eleanorm/cldlck_data/cldlck_polar/"

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
