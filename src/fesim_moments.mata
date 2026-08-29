version 16.0

mata:

real scalar fesim_moment_schema_version()
{
    return(1)
}

string rowvector fesim_truth_moment_names()
{
    return(("alpha_true_mean", "alpha_true_sd", "alpha_true_var", ///
        "psi_true_mean", "psi_true_sd", "psi_true_var", ///
        "epsilon_true_mean", "epsilon_true_sd", "epsilon_true_var", ///
        "cov_alpha_psi_true"))
}

real scalar fesim_sample_variance(real colvector values)
{
    real scalar n
    real scalar value_mean

    n = rows(values)
    if (n < 2) return(.)
    value_mean = mean(values)
    return(sum((values :- value_mean) :^ 2) / (n - 1))
}

real scalar fesim_sample_covariance(
    real colvector left,
    real colvector right)
{
    real scalar n

    n = rows(left)
    if (n != rows(right)) {
        _error(3300, "truth covariance inputs must have equal length")
    }
    if (n < 2) return(.)
    return(sum((left :- mean(left)) :* (right :- mean(right))) / (n - 1))
}

real colvector fesim_truth_moments(
    real colvector alpha_worker,
    real colvector psi_firm,
    real colvector epsilon_employed,
    real colvector alpha_employed,
    real colvector psi_employed)
{
    real scalar alpha_variance
    real scalar psi_variance
    real scalar epsilon_variance

    if (rows(alpha_worker) < 1 | rows(psi_firm) < 1 | ///
        rows(epsilon_employed) < 1 | ///
        rows(alpha_employed) != rows(psi_employed) | ///
        rows(alpha_employed) < 1 | ///
        any(missing(alpha_worker)) | any(missing(psi_firm)) | ///
        any(missing(epsilon_employed)) | any(missing(alpha_employed)) | ///
        any(missing(psi_employed))) {
        _error(3300, "truth moment inputs are empty, missing, or misaligned")
    }

    alpha_variance = fesim_sample_variance(alpha_worker)
    psi_variance = fesim_sample_variance(psi_firm)
    epsilon_variance = fesim_sample_variance(epsilon_employed)
    return((mean(alpha_worker) \ sqrt(alpha_variance) \ alpha_variance \ ///
        mean(psi_firm) \ sqrt(psi_variance) \ psi_variance \ ///
        mean(epsilon_employed) \ sqrt(epsilon_variance) \ ///
        epsilon_variance \ ///
        fesim_sample_covariance(alpha_employed, psi_employed)))
}

end
