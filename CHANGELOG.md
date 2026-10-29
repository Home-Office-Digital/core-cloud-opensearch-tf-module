All notable changes to this project will be documented in this file. This will provide a record of all notable module updates with each new release. Semantic versioning (https://semver.org/) must be adhered to for all Core Cloud modules.

eg:

### [0.0.3] 2026-10-29

  * AWS provider constraint set back to `~> 5.40`. 0.0.2 narrowed it to `~> 6.62`, which made this module impossible to use alongside `core-cloud-sqs-tf-module` (`~> 5.40`): a v5-only and a v6-only constraint have no overlap, so Terraform cannot select a provider at all. No module code has changed since 0.0.1, which shipped against v5.

### [0.0.2] 2026-09-02

  * AWS provider constraint changed to `~> 6.62`. No module code changes.

### [0.0.1] 2026-08-27

  * Initial tag created for Core Cloud terraform module
