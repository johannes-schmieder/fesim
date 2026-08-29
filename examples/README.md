# Examples

`akmsimple.do` is the tested end-to-end example for the qualified stylized
`akm/simple` DGP. It simulates a linked worker-firm panel, inspects returned
targets, and runs an AKM-style regression with Stata's built-in `areg`:

```stata
do examples/akmsimple.do
```

The example has no user-written runtime dependency. Other registered DGPs and
presets remain discovery-only until their implementation plans and scientific
gates are complete.
