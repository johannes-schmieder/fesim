# Calibration sources and status

## `akm/simple`

The `akm/simple` values are the owner-approved D-015 teaching and testing baseline. They are stylized package values, not estimates from a paper or administrative dataset.

## `akm/stylized`

The `akm/stylized` values are the owner-approved D-026 stress-design defaults. They are explicitly uncalibrated. Wage and firm-size scales reuse `akm/simple`. The three log-hazard intercepts transform the simple preset's annual probabilities into continuous annual hazards: EU and EE use their shares of the joint `-log(1-.08-.12)` competing rate, and UE uses `-log(1-.60)`. Correlations, covariate slopes, duration slopes, and destination coefficients are modest transparent values selected to exercise the D-025 mechanisms.

No German, paper, or administrative-data label applies to this preset. A later Germany-labeled or targeted preset requires an audited source table, explicit transformations, target definitions, and target-versus-realized qualification under DG-08.
