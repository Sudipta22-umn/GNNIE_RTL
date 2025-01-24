setPinAssignMode -pinEditInBatch true
set input_terms [dbGet [dbGet -p1 top.terms.direction input].name]
set output_terms [dbGet [dbGet -p1 top.terms.direction output].name]
editPin -pin $input_terms -spreadType RANGE -layer K2  -start {0.0 10.0}  -end {0.0 1500.0}
editPin -pin $output_terms -spreadType RANGE -layer K2  -start {1200.0 0.0}  -end {10.0 0.0}
#editPin -pin $input_terms -spreadType SIDE -layer K2 -side {LEFT RIGHT}
#editPin -pin $output_terms -spreadType SIDE -layer K2  -side BOTTOM
#editPin -pin $input_terms -spreadType EDGE -layer K2 -edge 0
#editPin -pin $output_terms -spreadType EDGE -layer K2  -edge 3
#editPin -pin $output_terms -spreadType RANGE -layer K2  -start {267.74 1572.23}  -end {1303.77 1572.23}
setPinAssignMode -pinEditInBatch false


