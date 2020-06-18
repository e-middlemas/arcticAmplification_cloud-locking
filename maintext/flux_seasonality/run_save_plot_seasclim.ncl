load "~/analysis/cldlck_polar/nclcode/basics/arctic.amp/flux_seasonality/save_clim.anom_seasonality.ncl"
;
;-----------------------------------------------------------------
; save climatology of all experiments in one file according to variable.
possible_vars = (/"FLDS","LHFLX","SHFLX"/)
units = (/"W m~S~-2~N~"/)
;
;do v=0,dimsizes(possible_vars)-1
do v=1,dimsizes(possible_vars)-1
	varname = possible_vars(v)
	print("Saving "+varname)
	save_Arctic_surface_seasonality(varname,units)
end do 
;
;-----------------------------------------------------------------
; plot climatology plots for CFMIP -- like the one in the powerpoint.
