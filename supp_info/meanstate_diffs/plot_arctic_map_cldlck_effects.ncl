;
function plot_arctic_cldlck_effects(wks:graphic,var:float,varname:string)

begin
;
;-----------------------------------------------
; calculate percentage
;-----------------------------------------------
percents = new((/2,3/),float)
f = addfile("/glade/work/eleanorm/cldlck_data/cldlck_polar/orig/b.e11.B1850C5CN.f09_g16.005.cam.h0.TS.040001-059912.nc","r")
lat = f->lat
rad = 4.0*atan(1.0)/180.
clat = cos(rad*lat({77.5:82.5}))
percents(0,:) = wgt_areaave_Wrap(var(1,:,{77.5:82.5},{24:75})/var(0,:,{77.5:82.5},{24:75})*100.,clat,1.0,1)
percents(1,:) = wgt_areaave_Wrap(var(2,:,{77.5:82.5},{24:75})/var(0,:,{77.5:82.5},{24:75})*100.,clat,1.0,1)
percents!0 = "CNT-GCL//CNT-ACL"
percents!1 = "ANN_DJF_JJA"
;-----------------------------------------------
;
res = True
res@gsnDraw = False
res@gsnFrame = False
res@tmXTOn = False
res@tmYROn = False
;
res@gsnPolar = "NH"
res@mpPerimOn = False
res@mpMinLatF = 70
res@mpGridLatSpacingF = 5
res@mpMaxLatF = 90
res@cnFillOn = True
res@cnFillPalette = "NCV_blu_red"
res@cnLinesOn = False
res@cnLineLabelsOn = False
res@cnInfoLabelOn = False
res@gsnPolarLabelFontHeightF = 0.026
res@gsnLeftString = ""
res@gsnRightString = ""
res@gsnRightStringFontHeightF = 0.04
res@gsnRightStringParallelPosF = 1.1
res@gsnRightStringOrthogonalPosF = -0.97
res@gsnCenterString = " "
res@lbLabelBarOn = False
res@cnLevelSelectionMode= "ManualLevels"
res@gsnTickMarksOn = False
;
;-----------------------------------------------
if varname.eq."ts"

	res@cnMinLevelValF  = -25.0
	res@cnMaxLevelValF  = 25.0
	res@cnLevelSpacingF = res@cnMaxLevelValF/25.

else if varname.eq."psl"

        res@cnMinLevelValF  = -5.5
        res@cnMaxLevelValF  = 5.5
        res@cnLevelSpacingF = res@cnMaxLevelValF/20.

else if varname.eq."icefrac"

        res@cnMinLevelValF  = -0.8
        res@cnMaxLevelValF  = 0.8
        res@cnLevelSpacingF = 0.02

else

        res@cnMinLevelValF  = -0.1
        res@cnMaxLevelValF  = 0.1
        res@cnLevelSpacingF = 0.01

end if
end if
end if
;-----------------------------------------------
plot = new(9,graphic)
n=0
do s=0,2
        do e=0,2;
		if e.gt.0
			res@gsnRightString = sprintf("%5.1f",percents(e-1,s))+"%"
		else
			res@gsnRightString = " "
		end if
		plot(n) = gsn_csm_contour_map_polar(wks,var(e,s,:,:),res)
		n=n+1
	end do
end do
;
;-----------------------------------------------

return(plot)
end
