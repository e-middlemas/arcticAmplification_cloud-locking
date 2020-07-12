;============================================================================
; Plot changes in northward energy transport with a variety of
; cloud-locking configurations.
;
; The resulting plots were not included in Middlemas et al. (in 
; review, GRL), but the values outputted from this script, i.e.,
; northward heat transport values for each configuration at 70N
; were included in the supplemental information.
; 
; To run this script, the user should first execute 
; 	"run_z.mean_energy.budget.ncl" found in the same folder 
;	in order to calculate the zonal mean northward energy
;	transport.
;
; The user should indicate below:
; 1) The plot output
; 2) path to energy budget data &, if plot is saved, the path to 
; 	where that figure should be saved
; 3) Experiment names if using something other than cloud-locking
;=============================================================================
;plottype = "x11"
plottype = "pdf"
northbound = 40 ; minimum latitude drawn

datapath = "/glade/work/eleanorm/cldlck_data/cldlck_polar/"
figpath = "~/analysis/cldlck_polar/figs/energybudget/"

expnames = (/"b.e11.B1850C5CN.f09_g16.005","b.e11.B1850C5CN.f09_g16.005_2xCO2", \+
"B1850C5CN.clock.9p.global","B1850C5CN.clock.9p.2xCO2", \+
"B1850C5CN.clock.9p.70-90N","B1850C5CN.clock.9p.70-90N.2xCO2"/)
noexps = dimsizes(expnames)

;----------------------------------------------------------------------------
; Define component names for legend and for keeping track of variable
; dimensions
;----------------------------------------------------------------------------
compname = (/"cam","pop","cice"/)
varnames = (/"tot","atm","ocnnht","icenht"/)
varlongname = (/"Total","Atmospheric","Oceanic","By ice"/)

; extract latitude & weight by area
f = addfile(systemfunc("ls "+datapath+expnames(0)+"."+compname(0)+".tavg*"),"r")
lat = f->lat
dlat = dimsizes(lat)
rad = 4.0*atan(1.0)/180. 
latorig = round(lat,3)
lat:=sin(rad*lat)
latstrings = sprintf("%2.0f",latorig)
inds2keep = ind(latorig.eq.-90 .or. \
latorig.eq.-60 .or. \
latorig.eq.-45 .or. \
latorig.eq.-25 .or. \
latorig.eq.60 .or. \
latorig.eq.45 .or. \
latorig.eq.25 .or. \
latorig.eq.90)
zeroind = ind(latorig.eq.0)
tmp= array_append_record(inds2keep(0:3),zeroind(0),0)
inds2keep:= array_append_record(tmp,inds2keep(4::),0)
lat!0 = "lat"
lat&lat = lat

;----------------------------------------------------------------------------
; Extract northward energy transport for each component & save to variable
;----------------------------------------------------------------------------
; Need two sets of variables: one for pictrl v. 2xCO2 in clouds active
;	* size = (/3,2,4,lat/)
; And one for the responses (2xCO2 - pictrl):
; 	* size = (/3,4,lat/)
zm = new((/dimsizes(expnames),dimsizes(varnames),dlat/),float)
do e=0,dimsizes(expnames)-1
	print("Experiment is "+expnames(e))
	do v=0,dimsizes(varnames)-1
		if v.gt.0
			c=v-1 ; because "tot" is found in the atmospheric component file
		else
			c=v
		end if
		print("Varname is "+varnames(v))
		f = addfile(systemfunc("ls "+datapath+expnames(e)+"."+compname(c)+".tavg*"),"r")
		zm(e,v,:) = tofloat(f->$varnames(v)$)
	end do
end do

; Reshape so that configurations and forcings are separated
expnames:=reshape(expnames,(/3,2/))
zm:=reshape(zm,(/3,2,dimsizes(varnames),dlat/))

; Calculate the response of energy transport to a CO2 doubling
zmresp = zm(:,1,:,:)-zm(:,0,:,:)

; Assign metadata
meta = f->$varnames(v-1)$
copy_VarMeta(meta,zm(0,0,0,:))
copy_VarMeta(meta,zmresp(0,0,:))

;------------------------------------------------------------------
; Plotting
;------------------------------------------------------------------
wks = gsn_open_wks(plottype,"energy_transport_response_to_2xCO2.pdf")
p1cols = (/"black","red"/) ; colors for different forcing; only in first panel
p2cols = (/"black","darkorange2","blue"/) ; control, global clock, arctic clock
;dps = (/0,1,2,3/) ; tot, atm, ocn, ice

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
res@tiYAxisFontHeightF = 0.022
res@tiXAxisFontHeightF = res@tiYAxisFontHeightF
res@gsnStringFontHeightF = 0.026
res@tiYAxisString = zm@units

; Label latitudes
res@tmXBMode = "Explicit"
res@tmXBValues = lat(inds2keep)
res@tmXBLabels = latstrings(inds2keep)
minorinds = ind(mod(latorig,5).eq.0)
minorinds(ind(minorinds.eq.96 .or. minorinds.eq.27 .or. minorinds.eq.164))=0
;print(minorinds)
res@tmXBMinorValues = lat(minorinds)
res@tmXBOn = True
res@tmYLOn = True

; add a horizontal line?
res@gsnYRefLine = 0.0
res@gsnYRefLineColor = "grey30"
res@gsnYRefLineDashPattern = 1
;
northind = ind(latorig.eq.northbound)
res@trXMinF = min(lat(northind::))
res@trXMaxF = max(lat)
;res@trYMinF = 0.0
;res@trYMaxF = 14
;
; for horizontal lines on TS plot
lnres = True
lnres@gsLineDashPattern = 1.0
;
; res for vertical lines indicating 70N
plres = True
plres@gsLineColor = "red"
plres@gsLineOpacityF = 0.4
plres@gsLineDashPattern = 0.0
plres@gsLineThicknessF = 2.5 
lineind =lat(ind(latorig.eq.70))
dum = new(4,graphic)
;---------------------------------------------------------------
; Panel plots
;---------------------------------------------------------------
plotforcing = new((/2,4/),graphic) ; left panels
plotresp = new((/3,4/),graphic) ; right panels
do v=0,dimsizes(varnames)-1 ; variables plotted
	if varnames(v).eq."icenht"
		res@tiXAxisString = "Latitude"
	else
		res@tiXAxisString = " "
	end if
	do e=0,2 ; cloud configs
		if e.eq.2
			;res@gsnCenterString = "response to 2xCO2 doubling"
			res@gsnCenterString = varlongname(v)
		else
			res@gsnCenterString = " "
		end if
		res@trYMinF = -0.20 
		res@trYMaxF = 0.20
                res@xyLineColor = p2cols(e)
		plotresp(e,v) = gsn_csm_xy(wks,lat(northind::),zmresp(e,v,{northbound::}),res)
		overlay(plotresp(0,v),plotresp(e,v))
  		dum(v) = gsn_add_polyline(wks, plotresp(0,v), (/lineind,lineind/), (/res@trYMinF,res@trYMaxF/), plres)
        end do
	do x=0,1 ; forcings
		if x.eq.1
			res@gsnCenterString = varlongname(v)
		else
			res@gsnCenterString = " "
		end if
		res@trYMinF = -6.0 
		res@trYMaxF = 6.0
       		res@xyLineColor = p1cols(x)
       		plotforcing(x,v) = gsn_csm_xy(wks,lat(northind::),zm(0,x,v,{northbound::}),res)
		overlay(plotforcing(0,v),plotforcing(x,v))
	end do
end do
;
plotfinal = new((/4,2/),graphic) ; final plot 
plotfinal(:,0) = plotforcing(0,:)
plotfinal(:,1) = plotresp(0,:)
;
;; panel 1 legend
;;---------------
;lgres@lgLabelFontHeightF = .06
;lgres@vpWidthF           = 0.4
;lgres@vpHeightF          = 0.2
;p1dpsleg = (/dps(0),dps(0),dps(1),dps(1)/)
;lgres@lgDashIndexes      = p1dpsleg(::-1)
;p1colsleg = ndtooned((/p1cols,p1cols/))
;lgres@lgLineColors       = p1colsleg(::-1)
;p1labels = ndtooned((/(/forcing+" "+varnames(0)/),(/forcing+" "+varnames(1)/)/))
;nitems = dimsizes(p1labels)                 ; number of legend items
;p1lbid = gsn_create_legend(wks,nitems,p1labels(::-1),lgres)
;amres@amParallelPosF = 0.3
;amres@amOrthogonalPosF = 1.1
;p1annoid = gsn_add_annotation(plot(0,0),p1lbid,amres)
;delete([/lgres@lgDashIndexes,lgres@lgLineColors/])
;;
;; panel 2 legend
;;---------------
;lgres@lgLabelFontHeightF = .06
;lgres@vpWidthF           = 0.5
;lgres@vpHeightF          = 0.25
;p2dpsleg = (/dps(0),dps(0),dps(0),dps(1),dps(1),dps(1)/)
;lgres@lgDashIndexes      = p2dpsleg(::-1)
;p2colsleg = ndtooned((/p2cols,p2cols/))
;lgres@lgLineColors       = p2colsleg(::-1)
;p2labels = ndtooned((/(/response+" "+varnames(0)/),(/response+" "+varnames(1)/)/))
;nitems = dimsizes(p2labels)                 ; number of legend items
;p2lbid = gsn_create_legend(wks,nitems,p2labels(::-1),lgres)
;amres@amParallelPosF = 0.3
;amres@amOrthogonalPosF = 1.15
;p2annoid = gsn_add_annotation(plot(1,0),p2lbid,amres)
;delete([/lgres@lgDashIndexes,lgres@lgLineColors/])
;
;---------------------------------------------------------------
; plot in panels
resp = True
resp@gsnPanelBottom = 0.05
gsn_panel(wks,ndtooned(plotfinal(:,1)),(/4,1/),resp)
;
if plottype.eq."x11"
clear(wks)
end if

