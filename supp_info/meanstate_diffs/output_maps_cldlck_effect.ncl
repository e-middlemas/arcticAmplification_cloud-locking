;=========================================================================
; This script utilizes the two other scripts in this directory to plot 
; climatological response of surface temperature (TS), sea level pressure (PSL), 
; and sea ice fraction (ICEFRAC) to a doubling of CO2.
;
; These figures are intended for the supporting information for 
; Middlemas et al. GRL paper (in review). 
; 
; This code produces 3 figures: one for each variable (TS, PSL, ICEFRAC).
; Each figure has 9 panels: 
; - 3 rows showing the annual, DJF, and JJA-mean map of the Arctic region
; - 3 columns corresponding to CNT (clouds active), CNT-GCL (control minus
;	global cloud-locked simulation), and CNT-ACL (control minus Arctic
;	cloud-locked simulation).
;
; The middle and right columns, CNT-GCL and CNT-ACL, represent cloud
; feedbacks' contribution to the response of the variable to a CO2
; doubling. This is because we are subtracting an experiment without cloud
; feedbacks (GCL or ACL) from an experiment with cloud feedbacks (CNT). 
;
; Comparing middle and right columns show the effects of local Arctic 
; cloud feedbacks (right column, CNT-ACL) versus the effects of both local
; and non-local cloud feedbcaks (middle column, CNT-GCL).
;
;=========================================================================
;-------------------------------------------------------------------------
; User-defined
;-------------------------------------------------------------------------
; Output figure type
plottype = "eps"
;plottype = "x11"

; This is where the TS, PSL, ICEFRAC, and CLDTOT CESM timeseries data live.
dir = "$PATHTOCESMDATA"

;-------------------------------------------------------------------------
; Load other necessary scripts in the current directory
;-------------------------------------------------------------------------
load "./meanstate_diffs/extract_spatial_data.ncl"
load "./meanstate_diffs/plot_arctic_map_cldlck_effects.ncl"


;-------------------------------------------------------------------------
; Variable definitions for plot labels:
;-------------------------------------------------------------------------
varshortnames = (/"ts","psl","icefrac"/)
vars = (/"surface temperature","sea level pressure","sea ice fraction"/)
plottitles = "                 The effect of cloud feedbacks on ~C~the response of "+vars+" to increased CO~B~2"
units = (/"Degrees C","hPa","fraction"/)

;-------------------------------------------------------------------------
; Extract relevant data for both 1x & 2x forcing & compute annual, winter,
; and summer averages
;-------------------------------------------------------------------------
; Extract and calculate climatologies for 1xCO2 Forcing
date = systemfunc("date")
tspsice = extract_spatial_data(dir,"1x")
wallClockElapseTime(date,"time to extract data & calculate climatologies",0)

; Extract and calculate climatologies for 2xCO2 Forcing
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
ts(1,:,:,:) = ts(0,:,:,:)-ts(1,:,:,:) ; CNT - GCL 
ts(2,:,:,:) = ts(0,:,:,:)-ts(2,:,:,:) ; CNT - ACL
ts!0 = "cnt,cnt-gcl,cnt-acl"
ts!1 = "ann,djf,jja"

psl = diffs(1,:,:,:,:)/100. ; convert from Pascals to Hectapascals
psl(1,:,:,:) = psl(0,:,:,:)-psl(1,:,:,:) ; CNT - ACL 
psl(2,:,:,:) = psl(0,:,:,:)-psl(2,:,:,:) ; CNT - ACL
psl!0 = "cnt,cnt-gcl,cnt-acl"
copy_VarCoords(ts,psl)

icefrac = diffs(2,:,:,:,:)
icefrac(1,:,:,:) = icefrac(0,:,:,:)-icefrac(1,:,:,:) ; CNT - ACL
icefrac(2,:,:,:) = icefrac(0,:,:,:)-icefrac(2,:,:,:) ; CNT - ACL
icefrac!0 = "cnt,cnt-gcl,cnt-acl"
copy_VarCoords(ts,icefrac)

;-------------------------------------------------------------------------
; Plot
;-------------------------------------------------------------------------
; Define resources and labels for the sides of the plot
expnames = (/"CNT","CNT - GCL","CNT - ACL"/)
seasons = (/"ANN","DJF","JJA"/)
txres = True
txres@txFontHeightF = 0.016
txres@txPerimOn = True
txres@txPerimThicknessF = 1.5

; Step through variables (TS, PSL, ICEFRAC) to produce plots
do v=0,2
	; outputs a figure to the meanstate_diffs folder with the variable
	; 	name in the title
	fname = "./meanstate_diffs/arctic_response_cldlck_"+varshortnames(v)

	; Initialize plotting workspace
        wks = gsn_open_wks(plottype,fname)

	; Determine which variable to plot based on index in loop
        if v.eq.0
                plot = plot_arctic_cldlck_effects(wks,ts,"ts")
        else if v.eq.1
                plot = plot_arctic_cldlck_effects(wks,psl,"psl")
        else
                plot = plot_arctic_cldlck_effects(wks,icefrac,"icefrac")
        end if
        end if

        ; Place labels for columns & rows
        txres@txJust = "CenterRight"
	; Define y-axis positions for row names
        yfs = (/0.785,0.515,0.245/)
        do n=0,2
        gsn_text_ndc(wks,seasons(n),0.07,yfs(n),txres)
        end do
        txres@txJust = "CenterCenter"
	; Define x-axis positions for column names
        xfs = (/0.23,0.515,0.79/)
        do n=0,2
        gsn_text_ndc(wks,expnames(n),xfs(n),0.9,txres)
        end do

	; Define panel resources
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

	; Finally plot!
	gsn_panel(wks,plot,(/3,3/),resP)

	; If workspace type is a popup window, call "clear(wks)" so user
	;	has to click for it to go away (otherwise may disappear
	;	before user has a chance to see it)
        if plottype.eq."x11"
                clear(wks)
        end if
end do

