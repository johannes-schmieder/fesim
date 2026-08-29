*! fesim retained-sample truth moments 0.0.0-dev 29aug2026
program define _fesim_truth, rclass
    version 16.0

    foreach variable in workerid time firmid employed alpha_true psi_true ///
        epsilon_true {
        capture confirm variable `variable'
        if _rc {
            di as error "required retained-sample truth variable is missing: `variable'"
            exit 111
        }
    }
    capture isid workerid time
    if _rc {
        di as error "retained-sample truth moments require a unique panel key"
        exit 459
    }
    capture assert missing(psi_true) == !employed & ///
        missing(epsilon_true) == !employed
    if _rc {
        di as error "truth-component missingness must match employment"
        exit 459
    }
    quietly count if employed
    if r(N) == 0 {
        di as error "retained-sample truth moments require observed employment"
        exit 459
    }

    tempname moments
    preserve
    quietly sort workerid time
    capture by workerid: assert alpha_true == alpha_true[1]
    local truth_rc = _rc
    if !`truth_rc' {
        quietly sort firmid workerid time
        capture by firmid: assert psi_true == psi_true[1] if employed
        local truth_rc = _rc
    }
    if !`truth_rc' {
        quietly sort workerid time
        capture noisily mata: st_matrix("`moments'", ///
            fesim_truth_moments_from_stata())
        local truth_rc = _rc
    }
    restore
    if `truth_rc' exit `truth_rc'

    matrix rownames `moments' = alpha_true_mean alpha_true_sd ///
        alpha_true_var psi_true_mean psi_true_sd psi_true_var ///
        epsilon_true_mean epsilon_true_sd epsilon_true_var ///
        cov_alpha_psi_true
    matrix colnames `moments' = realized
    return matrix moments = `moments'
end
