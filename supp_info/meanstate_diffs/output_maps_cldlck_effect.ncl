; The goal of this code is to plot a bunch of spatial maps of 
; the mean state of our cloud-locking simulations. 
;
; Each set of maps will have 9 plots: 
;  - 3 columns - Control (CNT), GCL - CNT, ACL - CNT
;  - 3 rows - annual mean, DJF, and JJA
;
; * need to ensure:
;   *   time variable is divisible by 12
;   *   first month must be January... (month=2 after cd_calendar-- CAM saves January as February.)
;   *   Grab years 100-150 from every simulation
;
; 1) TS
; 2) PSL
; 3) ICEFRAC
;
; repeat with arctic view
;-------------------------------------------------------
; User-defined
plotglobalmap = False
;plotarcticmap = False

;plotglobalmap = True
plotarcticmap = True

plottype = "eps"
;plottype = "x11"

;-------------------------------------------------------
load "/glade/u/home/eleanorm/analysis/cldlck_polar/nclcode/basics/arctic.amp/meanstate_diffs/extract_spatial_data.ncl"
load "/glade/u/home/eleanorm/analysis/cldlck_polar/nclcode/basics/arctic.amp/meanstate_diffs/plot_global_map_cldlck_effects.ncl"
load "/glade/u/home/eleanorm/analysis/cldlck_polar/nclcode/basics/arctic.amp/meanstate_diffs/plot_arctic_map_cldlck_effects.ncl"

dir = "/glade/work/eleanorm/cldlck_data/cldlck_polar/orig/"

;variable specifics:
;varshortnames = (/"ts","psl","icefrac","cldtot"/)
;vars = (/"surface temperature","sea level pressure","sea ice fraction","total cloud fraction"/)
varshortnames = (/"ts","psl","icefrac"/)
vars = (/"surface temperature","sea level pressure","sea ice fraction"/)
plottitles = "                 The effect of cloud feedbacks on ~C~the response of "+vars+" to increased CO~B~2"
units = (/"Degrees C","hPa","fraction"/)

; extract relevant data for 1x forcing 
; & compute annual, winter, and summer averages
date = systemfunc("date")
tspsice = extract_spatial_data(dir,"1x")
wallClockElapseTime(date,"time to extract data & calculate climatologies",0)

; extract relevant data for 2x forcing 
; & compute annual, winter, and summer averages
date = systemfunc("date")
tspsice_2x = extract_spatial_data(dir,"2x")
wallClockElapseTime(date,"time to extract data & calculate climatologies",0)

diffs = tspsice_2x - tspsice ; response to 2xCO2 forcing

; extract metadata
f = addfile(dir+"b.e11.B1850C5CN.f09_g16.005.cam.h0.TS.040001-059912.nc","r")
metadata = f->TS(0,:,:)

; extract ts, psl, and icefrac from computation above
ts = diffs(0,:,:,:,:)
copy_VarCoords(metadata,ts(0,0,:,:))
; control minus gcl because control has cloud feedbacks in it. so isolating the role
; of cloud feedbacks
ts(1,:,:,:) = ts(0,:,:,:)-ts(1,:,:,:) 
ts(2,:,:,:) = ts(0,:,:,:)-ts(2,:,:,:) 
ts!0 = "cnt,cnt-gcl,cnt-acl"
ts!1 = "ann,djf,jja"

psl = diffs(1,:,:,:,:)/100.
psl(1,:,:,:) = psl(0,:,:,:)-psl(1,:,:,:) 
psl(2,:,:,:) = psl(0,:,:,:)-psl(2,:,:,:) 
psl!0 = "cnt,cnt-gcl,cnt-acl"
copy_VarCoords(ts,psl)

icefrac = diffs(2,:,:,:,:)
icefrac(1,:,:,:) = icefrac(0,:,:,:)-icefrac(1,:,:,:) 
icefrac(2,:,:,:) = icefrac(0,:,:,:)-icefrac(2,:,:,:) 
icefrac!0 = "cnt,cnt-gcl,cnt-acl"
copy_VarCoords(ts,icefrac)

;cldtot = diffs(3,:,:,:,:)
;cldtot(1,:,:,:) = cldtot(0,:,:,:)-cldtot(1,:,:,:)
;cldtot(2,:,:,:) = cldtot(0,:,:,:)-cldtot(2,:,:,:)
;cldtot!0 = "cnt,cnt-gcl,cnt-acl"
;copy_VarCoords(ts,cldtot)
;
;-------------------------------------------------------
; Plot
;drawNDCGrid(wks)
expnames = (/"CNT","CNT - GCL","CNT - ACL"/)
seasons = (/"ANN","DJF","JJA"/)
txres = True
txres@txFontHeightF = 0.016
txres@txPerimOn = True
txres@txPerimThicknessF = 1.5

;-------------------------------------------------------

if plotglobalmap.eq.True
	
;	do v=0,2
	do v=0,0
		print("Plotting "+vars(v))
		fname = "/glade/u/home/eleanorm/analysis/cldlck_polar/nclcode/basics/arctic.amp/meanstate_diffs/spatial_response_globe_cldlck_effects_"+varshortnames(v)+".eps"
		wks = gsn_open_wks(plottype,fname)

		;
		; produce plots
		if v.eq.0
			plot = plot_global_cldlck_effects(wks,ts,"ts")
		else if v.eq.1	
			plot = plot_global_cldlck_effects(wks,psl,"psl")
		;else if v.eq.2
		else
			plot = plot_global_cldlck_effects(wks,icefrac,"icefrac")
;		else
;			plot = plot_global_cldlck_effects(wks,cldtot,"cldtot")
;		end if
		end if
		end if
		;

		txres@txJust = "CenterRight"
		yfs = (/0.49,0.349,0.20/)
		do n=0,2
			gsn_text_ndc(wks,seasons(n),0.06,yfs(n),txres)
		end do
		txres@txJust = "CenterCenter"
		xfs = (/0.225,0.535,0.838/)
		do n=0,2
			gsn_text_ndc(wks,expnames(n),xfs(n),0.6,txres)
		end do

		;
		resP = True
		resP@gsnMaximize = True
		resP@gsnPanelYWhiteSpacePercent = 2
		resP@gsnPanelXWhiteSpacePercent = 4
		resP@gsnPanelLeft = 0.08
		resP@pmLabelBarOrthogonalPosF = -0.03
		resP@gsnPanelLabelBar    = True  
		resP@lbLabelFontHeightF  = 0.012
		resP@lbTitleFontHeightF = 0.015
		resP@lbTitleOn = True
		resP@lbTitleOffsetF = 0.2
		
		resP@gsnPanelMainString = plottitles(v) 
		resP@gsnPanelMainPosYF = 0.68
		resP@lbTitleString = units(v) 
		;
		gsn_panel(wks,plot,(/3,3/),resP)
		if plottype.eq."x11"
			clear(wks)
		end if
	end do
end if

;-------------------------------------------------------

if plotarcticmap.eq.True

        do v=0,2
;        do v=0,0
	; produce plots
        	fname = "/glade/u/home/eleanorm/analysis/cldlck_polar/nclcode/basics/arctic.amp/meanstate_diffs/spatial_response_arctic_percent_box_"+varshortnames(v)+".eps"
	        wks = gsn_open_wks(plottype,fname)
                if v.eq.0
                        plot = plot_arctic_cldlck_effects(wks,ts,"ts")
                else if v.eq.1
                        plot = plot_arctic_cldlck_effects(wks,psl,"psl")
                ;else if v.eq.2
                else
                        plot = plot_arctic_cldlck_effects(wks,icefrac,"icefrac")
;                else
;                        plot = plot_arctic_cldlck_effects(wks,cldtot,"cldtot")
;                end if
                end if
                end if

	        ;
	        txres@txJust = "CenterRight"
	        yfs = (/0.785,0.515,0.245/)
	        do n=0,2
	        gsn_text_ndc(wks,seasons(n),0.07,yfs(n),txres)
	        end do
	        txres@txJust = "CenterCenter"
	        xfs = (/0.23,0.515,0.79/)
	        do n=0,2
	        gsn_text_ndc(wks,expnames(n),xfs(n),0.9,txres)
	        end do

		x = (/24., 75., 75., 24., 24./)
		y = (/77.5, 77.5, 82.5, 82.5, 77.5/)
		pgres = True
		pgres@gsLineColor = "black"
		pgres@gsLineThicknessF = 3.0
		maxbox = new(dimsizes(plot),graphic)
		do n=0,dimsizes(plot)-1
	                maxbox(n) = gsn_add_polyline(wks,plot(n),x,y,pgres)
		end do
	        
		resP = True
	        resP@gsnMaximize = True
	        resP@gsnPanelYWhiteSpacePercent = 2
	        resP@gsnPanelXWhiteSpacePercent = 4
	        resP@gsnPanelBottom = 0.05
	        resP@gsnPanelTop = 0.88
	        resP@gsnPanelLeft = 0.02
	        resP@pmLabelBarOrthogonalPosF = -0.02
	        resP@gsnPanelLabelBar    = True
		resP@pmLabelBarWidthF = 0.8
	        resP@lbLabelFontHeightF  = 0.015
	        resP@lbTitleFontHeightF = 0.018
	        resP@lbTitleOn = True
                resP@gsnPanelMainString = plottitles(v)
                resP@gsnPanelMainPosYF = 0.95
                resP@lbTitleString = units(v)
;
		gsn_panel(wks,plot,(/3,3/),resP)
	        if plottype.eq."x11"
	                clear(wks)
	        end if
	end do
end if
