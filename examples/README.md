# Examples

`akmsimple.do` is the tested end-to-end example for the qualified stylized
`akm/simple` DGP. It simulates a linked worker-firm panel, inspects returned
targets, and runs an AKM-style regression with Stata's built-in `areg`:

```stata
do examples/akmsimple.do
```

The example has no user-written runtime dependency. Apart from the three public
AKM presets documented here, registered DGPs and presets remain discovery-only
until their implementation plans and scientific gates are complete.

`akm_stylized.do` exercises the qualified uncalibrated monthly empirical-mobility
route, inspects year-valued duration diagnostics, and demonstrates that all
model coefficients remain inside `parameters()`:

```stata
do examples/akm_stylized.do
```

`akm_germany_chk.do` exercises the distinct CHK-targeted 2002–2009 West
Germany preset and inspects its four wage-dispersion and sorting targets:

```stata
do examples/akm_germany_chk.do
```
