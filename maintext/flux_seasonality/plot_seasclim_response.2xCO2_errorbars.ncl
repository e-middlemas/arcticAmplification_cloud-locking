;==================================================================
; This code produces a set of 2 panels, side by side, that shows 
; (1) the seasonality of some surface-related variable in both 
;	1xCO2 and 2xCO2 simulations in the control simulation in 
;	the first panel, and 
; (2) the difference between 2xCO2-1xCO2 simulations, i.e., the 
;	response of a CO2 doubling, for each experimental 
;	configuration in the second panel
;
; USAGE:
; 	User must edit & run "save_seasonality.ncl" and 
;	"run_save_seasonality.ncl" prior to using this code.
;==================================================================

;------------------------------------------------------------------
; User-defined section
path = "$OUTPUTDIR" ; directory for output figure

; plot type ("pdf","eps","x11","png",etc)
plottype = "eps"
outputfname = path+"fluxseasonal_fig3_errorbars" ; figure name

; legend & variable long names names
response = (/"Clouds active (2xCO2 CTL - CTL)", "Global cloud-locked (2xCO2 GLC - GLC)", "Arctic-only cloud-locked (2xCO2 ACL - ACL)"/)
forcing = (/"2xCO2 CTL","CTL"/)
varnames = (/"FLDS","SHFLX","LHFLX"/)
varlongnames = (/"Downwelling Longwave ~C~    Radiation (DLR)","Sensible Heat ~C~   Flux (SHF)","Latent Heat~C~ Flux (LHF)"/)
varchangenames = (/"DLR response","SHF response","LHF response"/)

;------------------------------------------------------------------
; Extract data
f = addfiles(path+varnames+".exps.seasonality_last50yrs.nc","r")
nofs = dimsizes(varnames)

mos = f[0]->months
clim = new((/nofs,dimsizes(forcing),dimsizes(mos)/),float) 
stdclim = new((/nofs,dimsizes(forcing),2,dimsizes(mos)/),float)
anom = new((/nofs,dimsizes(response),dimsizes(mos)/),float)
stdanom = new((/nofs,dimsizes(response),2,dimsizes(mos)/),float)

; Loop through variables available in given directory that have
do n=0,nofs-1
	tmp = f[n]->clim
	; climatology from control/clouds active
	clim(n,:,:) = dim_avg_n_Wrap(tmp(:,0,:,:),1) 

	; Find standard deviation across years to produce error bars
	stdclim(n,:,0,:) = clim(n,:,:)-dim_stddev_n_Wrap(tmp(:,0,:,:),1)
	stdclim(n,:,1,:) = clim(n,:,:)+dim_stddev_n_Wrap(tmp(:,0,:,:),1)

	; Loop through cloud-locking configurations (i.e., control, global
	; clocking, arctic clocking)
	do r=0,dimsizes(response)-1
		; calculate response
		resptmp = tmp(0,r,:,:)-tmp(1,r,:,:) ; 2xCO2 - pictrl

		; average response across years
		anom(n,r,:) = dim_avg_n_Wrap(resptmp,0) 

		; deviation of response across years
		stdanom(n,r,0,:) = anom(n,r,:)-dim_stddev_n_Wrap(resptmp,0) 
		stdanom(n,r,1,:) = anom(n,r,:)+dim_stddev_n_Wrap(resptmp,0) 
		delete(resptmp)
	end do
	delete(tmp)
end do

; Define coordinates & metadata for new variables
clim!0 = str_join(varnames,".")

anom!0 = clim!0
anom!1 = "control_global.cloud-locked_arctic.cloud-locked"
anom!2 = clim!2
anom&months = mos

copy_VarMeta(clim,stdclim(:,:,0,:))
stdclim!2 = "neg.pos_stddev"
copy_VarMeta(anom,stdanom(:,:,0,:))
stdanom!2 = stdclim!2

;-----------------------------------------------------------------
; Plot
;-----------------------------------------------------------------
print("plotting...")

; initialize plot workspace
wks = gsn_open_wks(plottype,outputfname)

; colors for line plots
forcols = (/"red","black"/) ; colors for different forcing; only in first panel
cloudcols = (/"black","darkorange2","blue"/)

; resources for line plots
res = True
res@gsnMaximize = False
res@gsnFrame = False
res@gsnDraw = False
res@xyLineThicknessF = 2.0
res@gsnYRefLine  = 0.0;
res@gsnYRefLineColor = "gray80"

; resources for error bars/shading
resshade = res
resshade@vpWidthF = 0.35
resshade@vpHeightF = 0.18
resshade@tiYAxisFontHeightF = 0.015
resshade@trXMinF = 1
resshade@trXMaxF = 12
resshade@tmYROn = False
resshade@tmXTOn = False
resshade@tmXBOn = True
resshade@tmXBMode = "Explicit"
resshade@tmXBTickStartF = 1
resshade@tmXBTickEndF = 12
resshade@tmXBLabelAngleF = 45
resshade@tmXBValues = ispan(1,12,1)
resshade@tmXBLabelsOn = False
resshade@tmXBLabels = (/"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sept","Oct","Nov","Dec"/)
resshade@tmXBLabelFontHeightF = 0.013
resshade@tmYLLabelFontHeightF = 0.013
resshade@tiXAxisString = " "
resshade@gsnCenterString = " "
resshade@gsnXYFillOpacities = (/0.2,0.2/)
resshade@xyLineColor = "transparent"
forfillcols = (/"red","gray50"/)
cloudfillcols = (/"gray50","orange","dodgerblue"/)

;---------------------------------------------------------------
; Put all together & plot!

plot = new((/6,6/),graphic) 
plotfills = plot

do n=0,2 ; FLDS, SHFLX, LHFLX
	; added print statements to check if it's plotting the right thing
;	print("--------------------------")
;	print("Variable is "+varlongnames(n))
;	print("--------------------------")
	if n.eq.0
		resshade@trYMinF = 150.
		resshade@trYMaxF = 330.
	else
		resshade@trYMinF = -4.
		resshade@trYMaxF = 24.
	end if

	; -------- Climatology -----------;
	if n.eq.2
		resshade@tmXBLabelsOn = True
	else
		resshade@tmXBLabelsOn = False
	end if
	resshade@tiYAxisString = varlongnames(n)
	resshade@tiYAxisOffsetXF = -0.01 	
	do i=0,dimsizes(forcing)-1
		; Plot error shading
		resshade@gsnXYAboveFillColors = forfillcols(i)
		resshade@gsnXYBelowFillColors = forfillcols(i)
		plotfills(2*n,i) = gsn_csm_xy(wks,mos,stdclim(n,i,:,:),resshade)
		overlay(plotfills(2*n,0),plotfills(2*n,i))

		; Plot average
		res@xyLineColor = forcols(i) ; color according to forcing
		plot(2*n,i) = gsn_csm_xy(wks,mos,clim(n,i,:),res)
		overlay(plotfills(2*n,0),plot(2*n,i))
	end do

	; -------- Response to 2xCO2 --------;
	if n.eq.0
		resshade@trYMinF = 10.
		resshade@trYMaxF = 60.
	else
		resshade@trYMinF = -3.
		resshade@trYMaxF = 15.
	end if
	resshade@tiYAxisString = varchangenames(n)
	resshade@tiYAxisOffsetXF = 0.0
	do i=0,dimsizes(responise)-1
		; plot error shading
		resshade@gsnXYAboveFillColors = cloudfillcols(i)
                resshade@gsnXYBelowFillColors = cloudfillcols(i)
                plotfills(2*n+1,i) = gsn_csm_xy(wks,mos,stdanom(n,i,:,:),resshade)

		; plot average
		overlay(plotfills(2*n+1,0),plotfills(2*n+1,i))
		res@xyLineColor = cloudcols(i)
		plot(2*n+1,i) = gsn_csm_xy(wks,mos,anom(n,i,:),res)
		overlay(plotfills(2*n+1,0),plot(2*n+1,i))
	end do
end do

;---------------------------------------------------------------
; add legends: 
; 1) red & black for 2xCO2 & pictrl
; 2) colors for responses
; 3) dashed/solid black lines for variable names
lgres= True
lgres@lgLineThicknessF   = 6.0
lgres@lgItemType         = "Lines"        ; show lines only (default)
lgres@lgPerimOn          = False
;lgres@lgPerimThicknessF  = 2.0
amres = True
amres@amJust = "CenterRight"

; forcing legend:
lgres@lgLabelFontHeightF = .15
lgres@vpWidthF           = 0.15
lgres@vpHeightF          = 0.08
lgres@lgMonoDashIndex    = True
lgres@lgLabelOffsetF	 = 0.1
lgres@lgLineColors       = forcols(::-1)
nitems = dimsizes(forcing)
forcingleg = gsn_create_legend(wks,nitems,forcing(::-1),lgres)
amres@amParallelPosF = 0.2
amres@amOrthogonalPosF = 1.05
forcingannoid = gsn_add_annotation(plotfills(4,0),forcingleg,amres)
delete(lgres@lgLineColors)

; responses legend:
lgres@lgLabelFontHeightF = .1
lgres@vpWidthF           = 0.35
lgres@vpHeightF          = 0.1
lgres@lgLineColors       = cloudcols(::-1)
nitems = dimsizes(response)
responseleg = gsn_create_legend(wks,nitems,response(::-1),lgres)
amres@amParallelPosF = 0.5
amres@amOrthogonalPosF = 1.1
forcingannoid = gsn_add_annotation(plotfills(5,0),responseleg,amres)
delete(lgres@lgLineColors)

;---------------------------------------------------------------
; Draw
resPanel = True
resPanel@gsnPanelBottom = 0.15
resPanel@gsnPanelRight = 0.98
resPanel@gsnPanelLeft = 0.005
gsn_panel(wks,plotfills(:,0),(/3,2/),resPanel)

if plottype.eq."x11"
clear(wks)
end if

