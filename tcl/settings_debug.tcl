# DEBUG = 1 : restrict to DEBUG_RUNS child runs
# DEBUG = 2 : omit constraint creation
# DEBUG = 3 : omit constraint creation, restrict to $DEBUG_RUNS child run

global DEBUG
set DEBUG 0
set DEBUG_RUNS 4

global fast_approach
set fast_approach true