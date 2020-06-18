; This code
;
gwtsfnames = systemfunc("ls ./*GWTS*")
;; reorder
gwtsfnames = gwtsfnames((/2,0,1/)) ; clouds active, global clock, arctic clock
;plottype = "x11"
;plottype = "pdf"
plottype = "eps"

nofs = dimsizes(gwtsfnames)
f = addfiles(gwtsfnames,"r")
lat = f[0]->lat
lat!0 = "lat"
lat&lat = lat
rad = 4.0*atan(1.0)/180.
;
; extract data: average over last 50 years of time dimension
; this works because when I calculated GWTS I specifically chose years
; 100 through 150
d = dimsizes(f[0]->GWTS)
gwts = new((/nofs,d(1),d(2)/),float)
do n=0,nofs-1
        gwts(n,:,:) = dim_avg_n_Wrap(f[n]->GWTS(d(0)-50*12:d(0)-1,:,:),0)
end do

; calculate global mean warming
;clat = cos(lat*rad)
;gmw = wgt_areaave_Wrap(gwts,clat,1.0,1)
;

; calculate warming over northern hemisphere:
clat = cos(lat({0::})*rad)
gmw = wgt_areaave_Wrap(gwts(:,{0::},:),clat,1.0,1)
;
; zonal mean global warming response:
gwts:=dim_avg_n_Wrap(gwts,2) ; average over all longitudes for zonal mean
;
; calculate global warming amplification at each latitude
gwts2 = gwts/conform_dims(dimsizes(gwts),gmw,0)
gwts2!1 = "lat"
gwts2&lat = lat
clatarctic = cos(rad*lat({70:90}))
aa = new(3,float)
do n=0,2
aa(n) = dim_avg_wgt_Wrap(gwts2(n,{70:90}),clatarctic,0)
end do
;
; make latitude area-conserving for plot:
latorig = round(lat,3)
lat:=sin(rad*lat)
latstrings = sprintf("%2.0f",latorig)
inds2keep = ind(latorig.eq.-90 .or. \
latorig.eq.-70 .or. \
latorig.eq.-50 .or. \
latorig.eq.-30 .or. \
latorig.eq.30 .or. \
latorig.eq.50 .or. \
latorig.eq.70 .or. \
latorig.eq.90)
zeroind = ind(latorig.eq.0)
tmp= array_append_record(inds2keep(0:3),zeroind(0),0)
inds2keep:= array_append_record(tmp,inds2keep(4::),0)
;
;latdisp = new(dimsizes(lat),string)
;latdisp = ""
;latdisp(inds2keep)=latstrings(inds2keep)
;
;-----------------------------------------------------------------
; Plot 
;-----------------------------------------------------------------
print("plotting...")
wks = gsn_open_wks(plottype,"~/analysis/cldlck_polar/figs/2xCO2_clock_global.v.arcticonly_arcticAmp")
res = True
;res@gsnMaximize = True
res@gsnFrame = False
res@gsnDraw = False
res@vpXF = 0.15
res@vpYF = 0.9
res@vpWidthF = 0.7
res@vpHeightF = 0.25
res@tmYROn = False
res@tmXTOn = False
res@vpWidthF = 0.8
res@vpHeightF = 0.3
res@xyLineThicknessF = 3.0
res@tiYAxisFontHeightF = 0.018
res@tiXAxisFontHeightF = res@tiYAxisFontHeightF
res@gsnStringFontHeightF = 0.02
res@tmXBMode = "Explicit"
minorinds = ind(mod(latorig,5).eq.0)
minorinds(ind(minorinds.eq.96 .or. minorinds.eq.27 .or. minorinds.eq.164))=0
;print(minorinds)
res@tmXBMinorValues = lat(minorinds)
;res@gsnYRefLineColor = "grey30"
;res@gsnYRefLineDashPattern = 1.0
cols = (/"black","darkorange2","blue"/)
runnames = (/"Control ("+sprintf("%5.2f",gmw(0))+")","Global cloud-locked ("+sprintf("%5.2f",gmw(1))+")","Arctic-only cloud-locked ("+sprintf("%5.2f",gmw(2))+")"/)
aalabels = (/"Control ("+sprintf("%5.2f",aa(0))+")","Global cloud-locked ("+sprintf("%5.2f",aa(1))+")","Arctic-only cloud-locked ("+sprintf("%5.2f",aa(2))+")"/)
;
res2 = res
res2@vpXF = 0.15
res2@vpYF = 0.5
res2@vpWidthF = 0.8
res2@vpHeightF = 0.3
dlat = dimsizes(lat)
res2@trXMinF = lat(dlat/2-1) 
res2@trXMaxF = max(lat)
res@trXMinF = min(lat)
res@trXMaxF = max(lat)
;
; for horizontal lines on TS plot
lnres = True
lnres@gsLineDashPattern = 1.0
;
plotts = new(nofs,graphic)
plotAA = new(nofs,graphic)
lin = new(nofs,graphic)
linAA = new(nofs,graphic)
arcticlines = new(2,graphic)
n=0
do r=0,nofs-1
res@tmXBValues = lat(inds2keep(1:7))
res@tmXBLabels = latstrings(inds2keep(1:7))
res@tiXAxisString = " "
res@trYMinF = 0.0
res@trYMaxF = 14
res@tiYAxisString = "Surface Warming (K)"
res@xyLineColor = cols(r)
plotts(r) = gsn_csm_xy(wks,lat,gwts(r,:),res)
;lnres@gsLineColor = cols(r)
;lin(r) = gsn_add_polyline(wks,plotts(r),(/lat(0),lat(dimsizes(lat)-1)/),(/gmw(r),gmw(r)/),lnres)
res2@tmXBValues = lat(inds2keep)
res2@tmXBLabels = latstrings(inds2keep)
res2@tiXAxisString = "Latitude"
res2@tiYAxisString = "Amplification (K/K)"
res2@trYMinF = 0
res2@trYMaxF = 6
res2@xyLineColor = cols(r)
plotAA(r) = gsn_csm_xy(wks,lat(dlat/2-1:dlat-1),gwts2(r,dlat/2-1:dlat-1),res2)
;res2@tiXAxisString = "Time"
;res2@tiYAxisString = "Arctic Amplification"
;plotAA(r) = gsn_csm_xy(wks,yrs,AA(r,:),res2)
; add horizontal line to TS plot according to mean AA 
;lnres@gsLineColor = cols(r)
;;lin(r) = gsn_add_polyline(wks,plotAA(r),(/1,33/),(/avg(AA(r,12::)),avg(AA(r,12::))/),lnres)
;linAA(r) = gsn_add_polyline(wks,plotAA(r),(/lat(0),lat(dimsizes(lat)-1)/),(/1.0,1.0/),lnres)
; overlay cldlck onto ctrl
if r.gt.0
overlay(plotts(0),plotts(r))
overlay(plotAA(0),plotAA(r))
end if
;lnres@gsLineColor = "red"
;if r.eq.nofs-1
;	arcticlines(0) = gsn_add_polyline(wks,plotts(r),(/lat(ind(latorig.eq.70)),lat(ind(latorig.eq.70))/),(/res@trYMinF,res@trYMaxF/),lnres)
;	arcticlines(1) = gsn_add_polyline(wks,plotAA(r),(/lat(ind(latorig.eq.70)),lat(ind(latorig.eq.70))/),(/res2@trYMinF,res2@trYMaxF/),lnres)
;end if
end do
;
; add legend
lgres                    = True
lgres@lgLineColors       = cols(::-1)
lgres@lgLineThicknessF	 = 4.0
lgres@lgItemType         = "Lines"        ; show lines only (default)
lgres@lgLabelFontHeightF = .05            ; legend label font thickness
lgres@vpWidthF           = 0.45           ; width of legend (NDC)
lgres@vpHeightF          = 0.1           ; height of legend (NDC)
lgres@lgPerimOn		 = False
;lgres@lgPerimThicknessF  = 2.0
lgres@lgMonoDashIndex    = True
lgres@lgDashIndex        = 0
lbid = gsn_create_legend(wks,dimsizes(runnames),runnames(::-1),lgres) ; for warming plot
lbidaa = gsn_create_legend(wks,dimsizes(aalabels),aalabels(::-1),lgres) ; for warming plot
amres = True
amres@amJust = "CenterRight"
amres@amParallelPosF = 0.25
amres@amOrthogonalPosF = -0.335
annoid = gsn_add_annotation(plotts(0),lbid,amres)
annoidaa = gsn_add_annotation(plotAA(0),lbidaa,amres)

;---------------------------------------------------------------
; Add boxes to indicate labels a, b:
txres = True
txres@txPerimOn = True
txres@txFontHeightF = 0.022

txid = new(2,graphic)
textposid = new(2,graphic)
textpos = True
textpos@amParallelPosF = 0.5
textpos@amParallelPosF   = -0.5
textpos@amOrthogonalPosF = -0.5
textpos@amJust           = "TopLeft"
panellabel = (/"a","b"/)
i=0
txid(i) = gsn_create_text(wks,panellabel(i),txres)
textposid(i) = gsn_add_annotation(plotts(0),txid(i),textpos)
i=1
txid(i) = gsn_create_text(wks,panellabel(i),txres)
textposid(i) = gsn_add_annotation(plotAA(0),txid(i),textpos)
;
;
draw(plotts)
draw(plotAA)
frame(wks)
