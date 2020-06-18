;
;---------------------------------------------------------------
; USER-DEFINED SECTION
;fvar = "ICEAREA" ;! This code is not written to accommodate the variable "ICEAREA". I.e., the labels on the plot read "extent"
fvar = "ICEEXTENT"
;
;minmaxorstd = "minmax"
minmaxorstd = "std"
;
aayrs = 15
;
plottype = "pdf"
;plottype = "x11"
;
;---------------------------------------------------------------
;
icefnames = systemfunc("ls /glade/work/eleanorm/cldlck_data/cldlck_polar/*2xCO2*"+fvar+"*")
;; reorder
icefnames = icefnames((/2,0,1/)) ; clouds active, global clock, arctic clock
;
f = addfiles(icefnames,"r")
nofs = dimsizes(icefnames)
;
; check to make sure they all start in the same month
; check their lengths
indst = new(3,integer)
dtime = 300*12
do n=0,nofs-1
	timetmp = cd_calendar(f[n]->time,0)
        if timetmp(0,1).ne.2
		indst(n) = toint(14-timetmp(0,1))
;		print(timetmp(indst,1))
		timetmp:=timetmp(indst(n)::,:)
	else
		indst(n) = 0
	end if
        dtime2 = dimsizes(timetmp(:,0))
	if dtime2.lt.dtime
                dtime = dtime2
        end if
	delete(timetmp)
end do
noyrs = dtime/12
dtime = dtime-mod(dtime,12)
time = fspan(0,(dtime-1)/12.,dtime)
anntime = time(0::12)
;
; extract data
var = "NH"+fvar
d = dimsizes(f[0]->$var$)
ice = new((/nofs,dtime/),float)
do n=0,nofs-1
tmp = f[n]->$var$
ice(n,0:dtime-1) = tmp(indst(n):indst(n)+dtime-1)
delete(tmp)
end do
;
; calculate annual average
icemon = reshape(ice,(/nofs,noyrs,12/))
iceann = dim_avg_n_Wrap(icemon,2); annual mean AA
; seasonality of sea ice loss
mos = ispan(1,12,1)
iceseas = dim_avg_n_Wrap(icemon(:,noyrs-aayrs:noyrs-1,:),1) 
; bounds for plotting: stddev
iceseasstd = new((/3,2,12/),float) ; +/- stddev across years
iceseasstd(:,0,:) = iceseas-dim_stddev_n_Wrap(icemon(:,noyrs-aayrs:noyrs-1,:),1)
iceseasstd(:,1,:) = iceseas+dim_stddev_n_Wrap(icemon(:,noyrs-aayrs:noyrs-1,:),1)
; bounds for plotting: min/max
iceseasminmax = iceseasstd
iceseasminmax(:,0,:) = dim_min_n_Wrap(icemon(:,noyrs-15:noyrs-1,:),1)
iceseasminmax(:,1,:) = dim_max_n_Wrap(icemon(:,noyrs-15:noyrs-1,:),1)
;
;-----------------------------------------------------------------
; Plot
;-----------------------------------------------------------------
print("plotting...")
;
; Set everything up:
;-----------------------------------------------------------------
wks = gsn_open_wks(plottype,"~/analysis/cldlck_polar/figs/2xCO2_global.v.arctic.clock_"+fvar+"loss+"+aayrs+"-yrpd_"+minmaxorstd+"_seas.pdf")
res = True
;res@gsnMaximize = True
res@gsnFrame = False
res@gsnDraw = False
res@vpXF = 0.15
res@vpYF = 0.95
res@vpWidthF = 0.8
res@vpHeightF = 0.25
res@tmYROn = False
res@tmXTOn = False
res@xyLineThicknessF = 2.0
res@tiYAxisFontHeightF = 0.018
res@tiXAxisFontHeightF = res@tiYAxisFontHeightF
res@gsnStringFontHeightF = 0.02
;res@gsnYRefLineColor = "grey30"
;res@gsnYRefLineDashPattern = 1.0
cols = (/"black","darkorange2","blue"/)
runnames = (/"Control","Global cloud-locked","Arctic-only cloud-locked"/)
;
;---------------------------------------------------------------
; adjust all resources now that they're defined
;res@trXMinF = 1.0
;res@trXMaxF = noyrs
res@trXMinF = time(0)
res@trXMaxF = time(dtime-3)
res@tiXAxisString = "Years since CO~B~2~N~ doubling"
;res@trYMinF = 0.0
res@trYMaxF = 15.5
res@tiYAxisString = "1e6 (million) km~S~2~N~"
;
; seasonality panel plot -avg
res2 = True
res2@gsnFrame = False
res2@gsnDraw = False
res2@vpXF = res@vpXF 
res2@vpYF = 0.55
res2@vpWidthF = res@vpWidthF
res2@vpHeightF = 0.25
res2@tmYROn = False
res2@tmXTOn = False
res2@xyLineThicknessF = 2.0
res2@tiYAxisFontHeightF = 0.018
res2@tiXAxisFontHeightF = res@tiYAxisFontHeightF
res2@gsnStringFontHeightF = 0.02
res2@trXMinF = 1
res2@trXMaxF = 12
res2@trYMinF = 0
res2@trYMaxF = 15.5
res2@tmXBOn = True
res2@tmXBMode = "Explicit"
res2@tmXBTickStartF = 1
res2@tmXBTickEndF = 12
res2@tmXBLabelAngleF = 45
res2@tmXBValues = ispan(1,12,1)
res2@tmXBLabels = (/"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sept","Oct","Nov","Dec"/)
res2@tiXAxisString = "Months (Jan - Dec)"
res2@tiYAxisString = "1e6 (million) km~S~2~N~"

; 
; seasonality panel plot -spread
resspread = res2
resspread@gsnXYFillOpacities = (/0.2,0.2/)
fillcols = (/"gray20","orange","dodgerblue"/)
;
;
yr1calc = tostring(toint(noyrs-aayrs))
yr2calc = tostring(toint(noyrs))
yrperiod = yr1calc+"-"+yr2calc
plot = new(nofs,graphic)
plotsc = new(nofs,graphic)
plotscavg = new(nofs,graphic)
plotscstddev = new((/2,nofs/),graphic)
n=0
do r=0,nofs-1
; seasonal plot
resspread@xyLineColor = "transparent"
resspread@gsnXYAboveFillColors = fillcols(r)
resspread@gsnXYBelowFillColors = fillcols(r)
if minmaxorstd.eq."std"
plotsc(r) = gsn_csm_xy(wks,mos,iceseasstd(r,:,:),resspread)
else
plotsc(r) = gsn_csm_xy(wks,mos,iceseasminmax(r,:,:),resspread)
end if
;
; overlay cldlck onto ctrl
if r.gt.0
	overlay(plotsc(0),plotsc(r))
if r.eq.(nofs-1)
	do n=0,nofs-1 ; add average seasonal cycle last
		if n.eq.(nofs-1)
			res2@gsnCenterString = "Seasonal cycle of sea ice extent over yrs. "+yrperiod
		else
			res2@gsnCenterString = " "
		end if
		res2@xyLineColor = cols(n)
		plotscavg(n) = gsn_csm_xy(wks,mos,iceseas(n,:),res2)
		overlay(plotsc(r),plotscavg(n))
	end do;

end if
end if
;
if r.eq.(nofs-1)
res@gsnCenterString = "Annual mean sea ice extent"
else
res@gsnCenterString = ""
end if
res@xyLineColor = cols(r)
;plot(r) = gsn_csm_xy(wks,time(0:tlengths(r)-1),ice(r,0:tlengths(r)-1),res)
plot(r) = gsn_csm_xy(wks,time(::12),iceann(r,:),res)
;
; overlay cldlck onto ctrl
if r.gt.0
overlay(plot(0),plot(r))
end if
;
end do
;
; add legend
lgres                    = True
lgres@lgLineColors       = cols(::-1)
lgres@lgLineThicknessF   = 6.0
lgres@lgItemType         = "Lines"        ; show lines only (default)
lgres@lgLabelFontHeightF = .04            ; legend label font thickness
lgres@vpWidthF           = 0.45          ; width of legend (NDC)
lgres@vpHeightF          = 0.1           ; height of legend (NDC)
lgres@lgPerimOn          = False
;lgres@lgPerimThicknessF  = 2.0
lgres@lgMonoDashIndex    = True
lgres@lgDashIndex        = 0
labels = runnames(::-1)
nitems = dimsizes(labels)                 ; number of legend items
lbid = gsn_create_legend(wks,nitems,labels,lgres)
amres = True
amres@amJust = "CenterRight"
amres@amParallelPosF = 0.3
amres@amOrthogonalPosF = -0.3
annoid = gsn_add_annotation(plot(0),lbid,amres)
;
draw(plot)
draw(plotsc)
frame(wks)
if plottype.eq."x11"
clear(wks)
end if
