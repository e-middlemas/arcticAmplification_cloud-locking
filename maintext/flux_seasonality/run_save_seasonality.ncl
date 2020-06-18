load "./save_seasonality.ncl"
;=================================================================
; This script simply calls save_clim.anom_seasonality to return
; the climatology of input variables - in this case, surface 
; fluxes from CESM.
;=================================================================

;-----------------------------------------------------------------
; save climatology of all experiments in one file according to variable.
possible_vars = (/"FLDS","LHFLX","SHFLX"/)
units = (/"W m~S~-2~N~"/)

do v=0,dimsizes(possible_vars)-1
	varname = possible_vars(v)
	print("Saving "+varname)
	save_Arctic_surface_seasonality(varname,units)
end do 
