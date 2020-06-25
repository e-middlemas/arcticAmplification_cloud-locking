;
function plot_arctic_cldlck_effects(wks:graphic,var:float,varname:string)
;========================================================================
; This function serves as a plotting function that is used in 
; ./meanstat_diffs/output_maps_cldlck_effect.ncl. 
;
; INPUT:
; - wks: workstation defined by gsn_open_wks
; - var: a variable (either TS, PSL, or ICEFRAC) of size (/3,3,size(lat),
;	size(lon)/), where the first dimension is the experiment or 
;	effects due to cloud-locking (CNT, CNT-GCL, CNT-ACL), and the
;	first dimension is the annual or seasonal mean.
; - varname: a string indicating the variable name ("TS","PSL", or 
;	"ICEFRAC"). 
;
; OUTPUT:
; The output is a variable of graphical type consisting of 9 panel plots.
; Those panel plots are organized as follows:
; - 3 rows: 1) annual mean, 2) DJF mean, 3) JJA mean
; - 3 columns: 1) CNT (clouds active), 2) CNT-GCL (control minus global
;	cloud-locked, and 3) CNT-ACL (control minus Arctic cloud-locked).
;
; Each plot shows the climatological change in a given variable in
; in response to a CO2 doubling.
;========================================================================

begin
;------------------------------------------------------------------------
; Define resources
;------------------------------------------------------------------------
; Define general plot resources
res = True
res@gsnDraw = False
res@gsnFrame = False
res@tmXTOn = False
res@tmYROn = False

; Define Arctic-projection-specific resources
res@gsnPolar = "NH"
res@mpPerimOn = False
res@mpMinLatF = 70
res@mpGridLatSpacingF = 5
res@mpMaxLatF = 90
res@gsnPolarLabelFontHeightF = 0.026

; Define contour resources
res@cnFillOn = True
res@cnFillPalette = "NCV_blu_red"
res@cnLinesOn = False
res@cnLineLabelsOn = False
res@cnInfoLabelOn = False
res@cnLevelSelectionMode= "ManualLevels"
res@lbLabelBarOn = False

; Define string and label resources
res@gsnLeftString = ""
res@gsnRightString = ""
res@gsnRightStringFontHeightF = 0.04
res@gsnRightStringParallelPosF = 1.1
res@gsnRightStringOrthogonalPosF = -0.97
res@gsnCenterString = " "
res@gsnTickMarksOn = False

;------------------------------------------------------------------------
; Plot variable!
;------------------------------------------------------------------------
; Depending on variable name, figure out contour spacing. This might
; take some tweaking. 

if varname.eq."ts"

	res@cnMinLevelValF  = -25.0
	res@cnMaxLevelValF  = 25.0
	res@cnLevelSpacingF = res@cnMaxLevelValF/25.

else if varname.eq."psl"

        res@cnMinLevelValF  = -5.5
        res@cnMaxLevelValF  = 5.5
        res@cnLevelSpacingF = res@cnMaxLevelValF/20.

else

        res@cnMinLevelValF  = -0.8
        res@cnMaxLevelValF  = 0.8
        res@cnLevelSpacingF = 0.02

end if
end if

; Initialize plot variable & plot!
plot = new(9,graphic)
n=0
do s=0,2 ; step through seasons
        do e=0,2 ; step through experimental configurations
		plot(n) = gsn_csm_contour_map_polar(wks,var(e,s,:,:),res)
		n=n+1
	end do
end do

return(plot)
end
