# Analysis code for Middlemas et al., 2020, GRL (*in review*)
From the paper titled
#### "Quantifying the influence of cloud radiative feedbacks on Arctic surface warming using cloud locking in an earth system model" 
  
## Description
The code in this repository corresponds to plots and analysis found in Middlemas et al.'s 2020 GRL paper. In this paper, we investigate the effect of cloud radiative feedbacks on Arctic surface warming and amplification. The data used for this analysis is from a suite of 6 CESM1 configurations. The configurations include 3 cloud-locked setups (cloud feedbacks active, global cloud feedbacks locked, and Arctic cloud feedbacks locked only) with two different forcings (1xCO2/preindustrial control forcing & 150 years of 2xCO2).
&nbsp;   
&nbsp;   

  
Notes:
* The original data is too large to be hosted on github, but we have provided as much of the postprocessed data needed to create appropriate plots. The original CESM output data can be accessed on NCAR's Campaign with a Cheyenne user account. If those interested do not have access to Cheyenne, one may contact one of the co-authors below for data access.  
* The radiative kernels presented in Table 1 (main text) and Table 2 in the supporting information may be found on a separate github repo. Right now this repo is private, but we can share access with those interested.
&nbsp;   
&nbsp;   

------------------------------------
## Code layout
Generally, the pipelines for each analysis require CESM output to be in monthly timeseries format. Each figure generally has three sets of code:  
  
1) A function that calculates the metric of interest.   
2) A run script that runs the calculation function and outputs the processed data to a netcdf file. Most of the data output from this script is saved in the same folder or a subdirectory in the same folder.    
3) A script that plots the resulting metric from the new netcdf file.
&nbsp;   
&nbsp;   

### Main text figures
There are two main analyses of how cloud feedbacks influence the Arctic warming response presented in the paper: the Arctic surface warming itself and the associated surface flux changes.
#### temp_arcticAmp_changes
Code for figures 1 and 2 in the main text may be found here. 
#### flux_seasonality
Code and data for figure 3 may be found here.
&nbsp;   
&nbsp;   
### Supporting Information figures & analysis
There are two main analyses included in this folder: mean state differences and energy budget analysis.  
  
#### meanstate_diffs
The mean state differences just produce a selection of Arctic maps that show the climatological differences in surface temperature, sea level pressure, and sea ice fraction (SI figures 1-3).   

#### energy.budget
The energy budget analysis plots the zonal mean northward energy transport in atmosphere, ocean, and sea ice components of the model (Table 1). 
&nbsp;   
&nbsp;   

### Extra
Some extra code lives here to plot the timeseries of Arctic sea ice loss with a doubling of CO2 in all three cloud-locking configurations.
  
&nbsp;   
&nbsp;   

------------------------------------

## Acknowledgements 
The code on this repo was written mainly by Eleanor Middlemas, though Jen Kay, Elizabeth Maroon, and Brian Medeiros contributed to ideation and direction. The energy budget code was written mainly by Jen Kay. 


## Contact
For questions about the code in this repository or data access, please contact  
Eleanor Middlemas (*elmiddlemas at gmail dot com*) or  
Jennifer Kay (*jennifer.e.kay at colorado dot edu*)

