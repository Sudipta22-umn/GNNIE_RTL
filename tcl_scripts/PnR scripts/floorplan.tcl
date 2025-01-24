#########################
# floorplan
set site "sc9mcpp84_12lp" 
clearGlobalNets
globalNetConnect VDD -type pgpin -pin VDD -all  -override
globalNetConnect VSS -type pgpin -pin VSS -all  -override
globalNetConnect VDD -type tiehi -all  -override
globalNetConnect VSS -type tielo -all  -override


setOptMode -powerEffort high -leakageToDynamicRatio 0.5

setGenerateViaMode -auto true
generateVias

createBasicPathGroups -expanded

floorPlan -site $site -s 1450.0 1120.0 5.0 5.0 5.0 5.0

#source place_macro.tcl
source createFence.tcl
source place_pin.tcl

#defOut -routing ${encDir}/${design}_floorplan_auto.def
#saveNetlist ${encDir}/${design}_floorplan_auto.v
#saveDesign ${encDir}/${design}_floorplan_auto.enc
