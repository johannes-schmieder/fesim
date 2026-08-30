version 16.0
clear all
set more off
set varabbrev off

set obs 4
generate long original_id = _n
generate double original_value = _n / 10
quietly datasignature set, reset

foreach example in discovery simulate estimate {
    capture noisily fesim_run `example' using fesim.sthlp
    assert _rc == 0
    quietly datasignature confirm
}

capture noisily fesim_run missing_example using fesim.sthlp
assert _rc == 111
quietly datasignature confirm

capture noisily fesim_run discovery using missing_fesim_help.sthlp
assert _rc == 601
quietly datasignature confirm

di as result "FESIM CLICKABLE HELP EXAMPLES PASS"
