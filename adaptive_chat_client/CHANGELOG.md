# Changelog

## [Unreleased]

- refactor: classes use Dart 3.13 primary constructors with declaring parameters; field docs sit on the parameters in the class header and constructor docs on the in-body `this` declaration. `use_declaring_parameters` is enforced by `analysis_options.yaml`. No behavior change; public constructor signatures are unchanged.

## [0.17.0]

- chore: require Dart SDK ^3.13.0 and Flutter 3.47.4 (FVM pin, CI pins, `very_good_analysis` ^11.0.0). Constructors use the Dart 3.13 abbreviated in-body syntax (`new(...)`, `factory(...)`) and the new formatter output, as required by the lints `very_good_analysis` 11 enables.
