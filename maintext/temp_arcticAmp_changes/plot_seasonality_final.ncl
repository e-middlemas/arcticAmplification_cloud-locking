;=================================================================================
; This script produces Fig. 2 from Middlemas et al. (GRL, in review), i.e., the 
; seasonality of the temperature response and Arctic amplification from our three 
; CESM cloud-locked configurations (control/clouds active, global cloud-locked,
; and Arctic-only cloud-locked). 
;
; In order to run this code, one must first edit & run calc_GWTS.ncl & 
; run_GWTS_calc.ncl. It shouldn't take but a minute or two to do so. 
; 
; After you've located where those new GWTS netcdf files are, edit the line below,
; make sure the figure is titled something you can easily identify, and run!
;=================================================================================

; Replace $YOURPATHTO_GWTSFILES with the your path to the GWTS files.
gwtsfnames = systemfunc("ls $YOURPATHTO_GWTSFILES/*GWTS*") 

;; reorder files because configuration names are alphabetically out of order
gwtsfnames = gwtsfnames((/2,0,1/)) ; clouds active, global clock, arctic clock
nofs = dimsizes(gwtsfnames)
f = addfiles(gwtsfnames,"r")

; indicate the output plot type ("eps", "pdf", "x11", "png", etc)
plottype = "eps"

; would you rather the error shading indicate the standard deviation across years
; ("std") or the max/min of the values across years ("minmax")?
stdminmax = "std"

; Ensure that the time extracted from GWTS is for corresponding to the last 150 years
;  of the 2xCO2 simulation.
dtime = 150*12
indst = new(nofs,integer)
do n=0,nofs-1
        if n.eq.0
                timesave = f[0]->time ; this starts from year 1 so it's a good
                ; x-axis label (i.e., for "Years since CO2 doubling")
        end if
        time = cd_calendar(f[n]->time,0)
        janmos = ind(time(:,1).eq.2) ; 2 is index for january
        indst(n) = janmos(0)
        ;
        ; If the length of time in the input file is less than 150, just ensure the 
	; number of timesteps extracted is divisible by 12.
        if dimsizes(time(indst(n)::,0)).lt.dtime
                dtime = dimsizes(time(indst(n)::,0))
                dtime = dtime-mod(dtime,12)
        end if
        delete(time)
end do
time = timesave(0:dtime-1)/365
lat = f[0]->lat
rad = 4.0*atan(1.0)/180.
;
; extract temperature response from precalculated dataset
print("Extracting global warming & calculating arctic amplification...")
d = dimsizes(f[0]->GWTS(0,:,:))
deltats = new((/nofs,dtime,d(0),d(1)/),float)
do n=0,nofs-1
        deltats(n,0:dtime-1,:,:) = f[n]->GWTS(indst(n):indst(n)+dtime-1,:,:)
end do
;
; calculate warming over northern hemisphere
clat = cos(lat({0::})*rad)
gmw = wgt_areaave_Wrap(deltats(:,:,{0::},:),clat,1.0,1)
;
; calculate arctic warming & amplification
clatarctic = cos(lat({70:90})*rad)
aw = wgt_areaave_Wrap(deltats(:,:,{70:90},:),clatarctic,1.0,1)
aa = aw/gmw ; normalize by northern hemisphere warming
;
; Find a value for Arctic amplification (average over time)
aano = dim_avg_Wrap(aa)
;
;---------------------------------------------------
; Finding seasonal cycle of warming & amplification:
print("Finding seasonal cycle of warming & amplification...")
noyrs = dtime/12
awmon = reshape(aw,(/nofs,noyrs,12/))
aamon = reshape(aa,(/nofs,noyrs,12/))
mos = ispan(1,12,1)
;
awclim = new((/nofs,12/),float)
aaclim = new((/nofs,12/),float)
do n=0,nofs-1
	awclim(n,:) = dim_avg_n_Wrap(awmon(n,noyrs-50-1:noyrs-1,:),0) ; last 10 years
	aaclim(n,:) = dim_avg_n_Wrap(aamon(n,noyrs-50-1:noyrs-1,:),0) ; last 10 years
end do
;
if stdminmax.eq."minmax"
	; for plotting shading (min/max):
	awmonminmax = awmon(:,0:1,:) ; instead of using "new" function
	awmonminmax(:,0,:) = dim_min_n(awmon,1)
	awmonminmax(:,1,:) = dim_max_n(awmon,1)
	aamonminmax = aamon(:,0:1,:) ; instead of using "new" function
	aamonminmax(:,0,:) = dim_min_n(aamon,1)
	aamonminmax(:,1,:) = dim_max_n(aamon,1)
else
	; for plotting shading (stddev):
	awmonminmax = awmon(:,0:1,:) ; instead of using "new" function
	awmonminmax(:,0,:) = awclim-dim_stddev_n(awmon,1)
	awmonminmax(:,1,:) = awclim+dim_stddev_n(awmon,1)
	aamonminmax = aamon(:,0:1,:) ; instead of using "new" function
	aamonminmax(:,0,:) = aaclim-dim_stddev_n(aamon,1)
	aamonminmax(:,1,:) = aaclim+dim_stddev_n(aamon,1)
end if
;
;-----------------------------------------------------------------
; Plot
;-----------------------------------------------------------------
print("plotting...")

; Set everything up:
;-----------------------------------------------------------------
wks = gsn_open_wks(plottype,".$PATHTOFIGURES/arcticWarming+Amplification_seasonality_"+stdminmax)
cols = (/"black","darkorange2","blue"/)
runnames = (/"Control","Global cloud-locked","Arctic-only cloud-locked"/)

; seasonality res
res = True
;res@gsnMaximize = True
res@gsnFrame = False
res@gsnDraw = False
res@vpWidthF = 0.8
res@vpHeightF = 0.25
res@tmYROn = False
res@tmXTOn = False
res@xyLineThicknessF = 2.0
res@tiYAxisFontHeightF = 0.018
res@tiXAxisFontHeightF = res@tiYAxisFontHeightF
res@gsnStringFontHeightF = 0.02
res@vpWidthF = 0.60
res@vpHeightF = 0.3
res@trXMinF = 1
res@trXMaxF = 12
res@tmXBOn = True
res@tmXBMode = "Explicit"
res@tmXBTickStartF = 1
res@tmXBTickEndF = 12
res@tmXBLabelAngleF = 45
res@tmXBValues = ispan(1,12,1)
res@tmXBLabels = (/"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sept","Oct","Nov","Dec"/)

lnres = True
lnres@xyDashPattern = 2.0

; seasonal avg resources
res2 = res

; shading resources
res@gsnXYFillOpacities = (/0.2,0.2/)
fillcols = (/"gray50","orange","dodgerblue"/)

;---------------------------------------------------------------
; put it all together on a plot!

; initialize plots
plotsc = new((/2,nofs/),graphic)
plotscavg = new((/2,nofs/),graphic)

n=0
do r=0,nofs-1
	; shading (base plot) 
	res@xyLineColor = "transparent"
	res@gsnXYAboveFillColors = fillcols(r)
	res@gsnXYBelowFillColors = fillcols(r)
	res@trYMinF = 0.0
	res@trYMaxF = max(awmonminmax)
	res@tiYAxisString = "Arctic Warming (K)"
	plotsc(0,r) = gsn_csm_xy(wks,mos,awmonminmax(r,:,:),res)
	res@tiYAxisString = "Arctic Amplification (K/K)"
	res@trYMinF = 1.0
	res@trYMaxF = max(aamonminmax)
	plotsc(1,r) = gsn_csm_xy(wks,mos,aamonminmax(r,:,:),res)

	; overlay cldlck onto ctrl, means on top of shading
	if r.gt.0
		overlay(plotsc(0,0),plotsc(0,r))
		overlay(plotsc(1,0),plotsc(1,r))
		do n=0,nofs-1 ; add average seasonal cycle last
			res2@xyLineColor = cols(n)
			res2@trYMinF = 0.0
			res2@trYMaxF = max(awmonminmax)
			plotscavg(0,n) = gsn_csm_xy(wks,mos,awclim(n,:),res2)
			res2@trYMinF = 1.0
			res2@trYMaxF = max(aamonminmax)
			plotscavg(1,n) = gsn_csm_xy(wks,mos,aaclim(n,:),res2)
			overlay(plotsc(0,r),plotscavg(0,n))
			overlay(plotsc(1,r),plotscavg(1,n))
		end do
	end if
end do

; add legend
lgres                    = True
lgres@lgLineColors       = cols(::-1) 
lgres@lgLineThicknessF   = 6.0
lgres@lgItemType         = "Lines"
lgres@lgLabelFontHeightF = .07 
lgres@vpWidthF           = 0.3
lgres@vpHeightF          = 0.12   
lgres@lgPerimOn          = False
lgres@lgMonoDashIndex    = True
lgres@lgDashIndex        = 0
labels = runnames(::-1)
nitems = dimsizes(labels)                 ; number of legend items
lbid = gsn_create_legend(wks,nitems,labels,lgres)
amres = True
amres@amJust = "TopRight"
amres@amParallelPosF = 0.2
amres@amOrthogonalPosF = -0.5
annoid = gsn_add_annotation(plotsc(0,0),lbid,amres)

; panel the two plots (warming response & amplification) 
resP = True
resP@gsnPanelFigureStrings = (/"a","b"/)
resP@gsnPanelFigureStringsFontHeightF = 0.027
resP@gsnPanelFigureStringsPerimOn = True 
resP@amJust = "TopLeft"
resP@amOrthogonalPosF = -0.5
resP@amParallelPosF = -0.5
gsn_panel(wks,plotsc(:,0),(/2,1/),resP)


if plottype.eq."x11"
	clear(wks)
end if
