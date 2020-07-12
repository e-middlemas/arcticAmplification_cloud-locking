;=================================================================================
; This script produces Fig. 1 from Middlemas et al. (GRL, in review), i.e., the
; zonal-mean temperature response and Arctic amplification from our three
; CESM cloud-locked configurations (control/clouds active, global cloud-locked,
; and Arctic-only cloud-locked).
;
; In order to run this code, one must first edit & run calc_GWTS.ncl &
; run_GWTS_calc.ncl. It shouldn't take but a minute or two to do so.
;
; After you've located where those new GWTS netcdf files are, edit the line below,
; make sure the figure is titled something you can easily identify, and run!
;=================================================================================
;---------------------------------------------------
; User-defined section

; here is where you should put the path the GWTS files.
gwtsfnames = systemfunc("ls $YOURPATHTO_GWTSFILES/*GWTS*")

; reorder files because configuration names are alphabetically out of order
gwtsfnames = gwtsfnames((/2,0,1/)) ; clouds active, global clock, arctic clock

; Decide whether to normalize by global mean warming or northern hemisphere
; warming (paper normalizes by the latter)
; * Options are "gm" and "nhw"
normalize = "nhw"

; indicate the output plot type ("eps", "pdf", "x11", "png", etc)
plottype = "x11"

;---------------------------------------------------
; Extracting relevant data

; number of experimental configurations
nofs = dimsizes(gwtsfnames)

; load in coordinates that are important for calculating the zonal mean
f = addfiles(gwtsfnames,"r")
lat = f[0]->lat
lat!0 = "lat"
lat&lat = lat
rad = 4.0*atan(1.0)/180.
;
; Average over last 50 years of time dimension to produce global warming
; maps.
; This works because when I calculated GWTS I specifically chose years
; 100 through 150
d = dimsizes(f[0]->GWTS)
gwts = new((/nofs,d(1),d(2)/),float)
do n=0,nofs-1
        gwts(n,:,:) = dim_avg_n_Wrap(f[n]->GWTS(d(0)-50*12:d(0)-1,:,:),0)
end do

;---------------------------------------------------
; Calculating warming & arctic amplification

; calculate warming over northern hemisphere:
clatnh = cos(lat({0::})*rad)
gnh = wgt_areaave_Wrap(gwts(:,{0::},:),clatnh,1.0,1)

; calculate global mean warming
clat = cos(lat*rad)
gmw = wgt_areaave_Wrap(gwts,clat,1.0,1)

; zonal mean global warming response:
gwts:=dim_avg_n_Wrap(gwts,2) ; average over all longitudes for zonal mean

; calculate global warming amplification at each latitude
if normalize.eq."gm"
        gwts_norm = gwts/conform_dims(dimsizes(gwts),gmw,0)
else
        gwts_norm = gwts/conform_dims(dimsizes(gwts),gnh,0)
end if
gwts_norm!1 = "lat"
gwts_norm&lat = lat

; find average over arctic for enumerating arctic amplification
clatarctic = cos(rad*lat({70:90}))
aa = new(3,float)
do n=0,2
	aa(n) = dim_avg_wgt_Wrap(gwts_norm(n,{70:90}),clatarctic,0)
end do

;---------------------------------------------------
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

; testing text display for new latitudinal coordinates
;latdisp = new(dimsizes(lat),string)
;latdisp = ""
;latdisp(inds2keep)=latstrings(inds2keep)
;
;-----------------------------------------------------------------
; Plot 
;-----------------------------------------------------------------
print("plotting...")

; initialize workspace
wks = gsn_open_wks(plottype,"$PATHTOFIGURES/zonalmean_warming_amplification")

; define workspace & resources for base plot & global warming plot
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

; define latitude tickmarks
res@tmXBMode = "Explicit"
minorinds = ind(mod(latorig,5).eq.0)
minorinds(ind(minorinds.eq.96 .or. minorinds.eq.27 .or. minorinds.eq.164))=0
;print(minorinds)
res@tmXBMinorValues = lat(minorinds)

; deal with labels
cols = (/"black","darkorange2","blue"/)
runnames = (/"Control ("+sprintf("%5.2f",gmw(0))+")","Global cloud-locked ("+sprintf("%5.2f",gmw(1))+")","Arctic-only cloud-locked ("+sprintf("%5.2f",gmw(2))+")"/)
aalabels = (/"Control ("+sprintf("%5.2f",aa(0))+")","Global cloud-locked ("+sprintf("%5.2f",aa(1))+")","Arctic-only cloud-locked ("+sprintf("%5.2f",aa(2))+")"/)

; resources for arctic amplification plot 
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
plotts = new(nofs,graphic)
plotAA = new(nofs,graphic)
n=0
do r=0,nofs-1 ; step through experimental configurations
	; Surface warming plot
	res@tmXBValues = lat(inds2keep(1:7))
	res@tmXBLabels = latstrings(inds2keep(1:7))
	res@tiXAxisString = " "
	res@trYMinF = 0.0
	res@trYMaxF = 14
	res@tiYAxisString = "Surface Warming (K)"
	res@xyLineColor = cols(r)
	plotts(r) = gsn_csm_xy(wks,lat,gwts(r,:),res)
	
	; Arctic amplification plot (below)
	res2@tmXBValues = lat(inds2keep)
	res2@tmXBLabels = latstrings(inds2keep)
	res2@tiXAxisString = "Latitude"
	res2@tiYAxisString = "Amplification (K/K)"
	res2@trYMinF = 0
	res2@trYMaxF = 6
	res2@xyLineColor = cols(r)
	plotAA(r) = gsn_csm_xy(wks,lat(dlat/2-1:dlat-1),gwts_norm(r,dlat/2-1:dlat-1),res2)

	if r.gt.0
		overlay(plotts(0),plotts(r))
		overlay(plotAA(0),plotAA(r))
	end if
end do

; add legend
lgres                    = True
lgres@lgLineColors       = cols(::-1)
lgres@lgLineThicknessF	 = 4.0
lgres@lgItemType         = "Lines"        ; show lines only (default)
lgres@lgLabelFontHeightF = .05            ; legend label font thickness
lgres@vpWidthF           = 0.45           ; width of legend (NDC)
lgres@vpHeightF          = 0.1           ; height of legend (NDC)
lgres@lgPerimOn		 = False
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

;---------------------------------------------------------------
; draw plot
draw(plotts)
draw(plotAA)
frame(wks)

if plottype.eq."x11"
	clear(wks)
end if
