load "~/analysis/cldlck_polar/postprocess/convert_seaicefrac_extentarea.ncl"
;
;
dir = "/glade/work/eleanorm/cldlck_data/cldlck_polar/orig/"
diro = "/glade/work/eleanorm/cldlck_data/cldlck_polar/"
;
fs = systemfunc("ls "+dir+"*ICEFRAC*")
do r=0,dimsizes(fs)-1
;do r=5,5
	; figure out filenames
	initxpath = str_split(fs(r),"/")
	filename = initxpath(dimsizes(initxpath)-1)
	tmp = str_split(filename,".")
	tmp(ind(tmp.eq."ICEFRAC")) = "ICEEXTENT"
	filenameIE = str_join(tmp,".")
	tmp(ind(tmp.eq."ICEEXTENT")) = "ICEAREA"
	filenameIA = str_join(tmp,".")
	convert_frac_extentarea(dir,filename,diro,filenameIE,filenameIA)
	delete([/initxpath,tmp/])
end do
