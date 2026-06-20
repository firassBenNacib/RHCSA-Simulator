# Changelog

## [2.3.0](https://github.com/firassBenNacib/RHCSA-Simulator/compare/v2.2.0...v2.3.0) (2026-06-20)


### Features

* use composite track/id keys in progress system ([e19a821](https://github.com/firassBenNacib/RHCSA-Simulator/commit/e19a821eab1115b215e2ac0faf32656bffe76e33))


### Bug Fixes

* accept stable LVM fstab sources ([#56](https://github.com/firassBenNacib/RHCSA-Simulator/issues/56)) ([d429299](https://github.com/firassBenNacib/RHCSA-Simulator/commit/d429299f8ddbac3896e0ab493843edb50094801d))
* add go mod tidy before govulncheck in security workflow ([6964043](https://github.com/firassBenNacib/RHCSA-Simulator/commit/6964043428f7294b42516bccb1c4ce15043d6d42))
* add missing progress import, remove unused imports, fix go.mod version ([0b155c9](https://github.com/firassBenNacib/RHCSA-Simulator/commit/0b155c9987ec2b38d9b436c9b07d3efe26fdbbe6))
* align CI security checks ([a0a0a0f](https://github.com/firassBenNacib/RHCSA-Simulator/commit/a0a0a0fb80c1286610063433c5bde5d44090228d))
* align verifier profile and scenario metadata ([85e7277](https://github.com/firassBenNacib/RHCSA-Simulator/commit/85e7277269add71e28667557161871455c5b5d17))
* clarify RHCSA10 exam task targets ([fae9480](https://github.com/firassBenNacib/RHCSA-Simulator/commit/fae94807b2a307ae01014eb465e0d2b9c888a3fb))
* clear CI blockers for dual-track branch ([771d5e0](https://github.com/firassBenNacib/RHCSA-Simulator/commit/771d5e02e52123a29466a188b0db72b6efccb5bf))
* correct go.mod version to 1.25, allow toolchain auto-download in security workflow ([bcd8b12](https://github.com/firassBenNacib/RHCSA-Simulator/commit/bcd8b12cd1b79d0341f403337bf6987be2cd0d5d))
* harden replay authentication setup ([dc52c5f](https://github.com/firassBenNacib/RHCSA-Simulator/commit/dc52c5fd848c8c09fab2110f7e96dcb3e13eae90))
* harden replay cleanup after VirtualBox crash ([39d98fd](https://github.com/firassBenNacib/RHCSA-Simulator/commit/39d98fd480548db67fc00869dbf90bd15fcb3b38))
* harden replay cleanup and rhcsa9 checks ([1f28b29](https://github.com/firassBenNacib/RHCSA-Simulator/commit/1f28b29995771a3b5bcc3dbd803b5fe7e9bf7230))
* harden RHCSA10 exam checks ([#54](https://github.com/firassBenNacib/RHCSA-Simulator/issues/54)) ([dda8e4d](https://github.com/firassBenNacib/RHCSA-Simulator/commit/dda8e4d79742565b9b8c02b26b8305ad08eb1b18))
* keep baseline progress on one line ([996788c](https://github.com/firassBenNacib/RHCSA-Simulator/commit/996788cd8d998875efb3a6a74378575f3a237241))
* keep colored verifier output and avoid rebuild fallback ([fabbf13](https://github.com/firassBenNacib/RHCSA-Simulator/commit/fabbf1359abc5aa8cddbcb85e20059e96c0338ab))
* land RHCSA10 exam ordering on main ([aead7a1](https://github.com/firassBenNacib/RHCSA-Simulator/commit/aead7a1d4f2a22845d18023163faff49c2f61660))
* move GOTOOLCHAIN env to job level in security workflow ([e646bc2](https://github.com/firassBenNacib/RHCSA-Simulator/commit/e646bc20bcf5c4ba9aa7e1e588e5be60c60aa879))
* polish CLI and RHCSA10 grading ([7dae663](https://github.com/firassBenNacib/RHCSA-Simulator/commit/7dae6633be7e0f220994d1b994181ad5b0713d62))
* prefer UUID swap persistence ([b27e7f1](https://github.com/firassBenNacib/RHCSA-Simulator/commit/b27e7f1e417acd4d309d8eaffc478769ba97e2ee))
* regenerate mock exams a/b/d with correct unique tasks ([4cecfb7](https://github.com/firassBenNacib/RHCSA-Simulator/commit/4cecfb7f7c7eac1a8a09319fec5c40bbd3313bc8))
* repair CLI state handling and release dispatch ([e7e9b28](https://github.com/firassBenNacib/RHCSA-Simulator/commit/e7e9b284c6b5411c04df4c3a14cad133537ea370))
* restore CLI colors and release dispatch ([1c94002](https://github.com/firassBenNacib/RHCSA-Simulator/commit/1c940023d653c2d6f6c3e7ab09de1cc01c5edb7c))
* restore colored CLI output and release dispatch ([2604a89](https://github.com/firassBenNacib/RHCSA-Simulator/commit/2604a895f3e9365dc4d2d1681f41f1f6efe9e657))
* satisfy RHCSA10 scenario audit ([9fb529a](https://github.com/firassBenNacib/RHCSA-Simulator/commit/9fb529a813daf2c017564dbb0d14166ec760c241))
* satisfy scenario audit for exam group replay ([4033157](https://github.com/firassBenNacib/RHCSA-Simulator/commit/4033157336caba4d1f0ab19d7992b3847a6fe7ea))
* stabilize replay cleanup and rhcsa9 exams ([a25c053](https://github.com/firassBenNacib/RHCSA-Simulator/commit/a25c053638e41a7f7dc40d866998398a852163c7))
* stabilize RHCSA9 and RHCSA10 simulator tracks ([8edd73b](https://github.com/firassBenNacib/RHCSA-Simulator/commit/8edd73b998558c6c4f649a4f1360052dad391616))
* use patched Go toolchain directive ([6e76874](https://github.com/firassBenNacib/RHCSA-Simulator/commit/6e768747a4da67b47aea62baed941aa86784b9e5))
* validate persistent journald configuration ([#58](https://github.com/firassBenNacib/RHCSA-Simulator/issues/58)) ([02ab1fc](https://github.com/firassBenNacib/RHCSA-Simulator/commit/02ab1fc54fe4eff7eca5239fcc1e8762703e0eff))

## [2.2.0](https://github.com/firassBenNacib/RHCSA-Simulator/compare/v2.1.2...v2.2.0) (2026-06-20)


### Features

* add repo import cache support for ISO-backed offline repositories ([3ac6955](https://github.com/firassBenNacib/RHCSA-Simulator/commit/3ac695504d6e8d75f0877010b639c6ad8b493619))
* add setup preflight checks and baseline profile mismatch detection ([335064c](https://github.com/firassBenNacib/RHCSA-Simulator/commit/335064c392f14756641401e47026e839e81cdbb4), [cf8d59b](https://github.com/firassBenNacib/RHCSA-Simulator/commit/cf8d59b4a6ce568e95778200d38a6d78a35ea166))
* add explicit scenario target metadata and balance auditing ([fdc6804](https://github.com/firassBenNacib/RHCSA-Simulator/commit/fdc680449cd53d30f8af2e69734991109c7d9e32), [e9d5140](https://github.com/firassBenNacib/RHCSA-Simulator/commit/e9d5140cc356bd453cfeea0037e5373026302a37))
* rebalance RHCSA9 and RHCSA10 lab and exam coverage ([fe00667](https://github.com/firassBenNacib/RHCSA-Simulator/commit/fe006671e14a5769b22a95212a6b4d6d0b73329a), [39bc85c](https://github.com/firassBenNacib/RHCSA-Simulator/commit/39bc85cb78d530c8d03ed111a8f39fc63ff581b9), [423d3dd](https://github.com/firassBenNacib/RHCSA-Simulator/commit/423d3dd540f2aa03f7b2f1a5a28a17798a1e4726), [8bfd707](https://github.com/firassBenNacib/RHCSA-Simulator/commit/8bfd70795a83f5a7fe824d1464c8196d5652325d))
* diversify RHCSA10 mock exams across storage, services, networking, Flatpak, and two-system administration work ([aef25e0](https://github.com/firassBenNacib/RHCSA-Simulator/commit/aef25e0be8751738b7b0f68242771343d5fc4faa), [08b3157](https://github.com/firassBenNacib/RHCSA-Simulator/commit/08b315701bfa08115a19cce195229620b62f714e), [8a9663f](https://github.com/firassBenNacib/RHCSA-Simulator/commit/8a9663ff1ca78a35bcac74f22b5d925b2e7532c7))

### Bug Fixes

* attach and bootstrap newer RHEL 10 DVD media correctly ([612bc89](https://github.com/firassBenNacib/RHCSA-Simulator/commit/612bc8987df0d4b6463920b7d7ed089731f2755f), [efd2a4f](https://github.com/firassBenNacib/RHCSA-Simulator/commit/efd2a4f3c0a54c41ac713a035ed6cfcc79b21b3f))
* clarify RHCSA10 exam task targets ([fae9480](https://github.com/firassBenNacib/RHCSA-Simulator/commit/fae94807b2a307ae01014eb465e0d2b9c888a3fb))
* fix RHCSA10 lab and replay failures in setup, Flatpak, server resets, and at jobs ([1b23bbe](https://github.com/firassBenNacib/RHCSA-Simulator/commit/1b23bbe232f0e25949df73edfeac5cd067ec2fc0), [01fff8e](https://github.com/firassBenNacib/RHCSA-Simulator/commit/01fff8e33b40aeaf84a03e62ebc48c8081ab3d6b), [59bec23](https://github.com/firassBenNacib/RHCSA-Simulator/commit/59bec238c8ce63eebdb3e6e617e141f4436d353e), [ffe4c65](https://github.com/firassBenNacib/RHCSA-Simulator/commit/ffe4c6562f07c8f6655f02614f859b6dc641ff7d), [621afa2](https://github.com/firassBenNacib/RHCSA-Simulator/commit/621afa208ba64f7cfcb36fbd5f0176ea39fc17a1))
* harden scenario grading for final-state checks, task coverage, persistent mounts, cron, at, journald, and swap ([c73071d](https://github.com/firassBenNacib/RHCSA-Simulator/commit/c73071ddb3b4221abf9e5fae9e09dfa72803729c), [e3b1635](https://github.com/firassBenNacib/RHCSA-Simulator/commit/e3b16359f77f25dc2dbf60de2eb492e015697fb9), [feb7a18](https://github.com/firassBenNacib/RHCSA-Simulator/commit/feb7a188135a6e62ac38a7a00690d0658d1aeab0), [02ab1fc](https://github.com/firassBenNacib/RHCSA-Simulator/commit/02ab1fc54fe4eff7eca5239fcc1e8762703e0eff))
* prefer UUID swap persistence ([b27e7f1](https://github.com/firassBenNacib/RHCSA-Simulator/commit/b27e7f1e417acd4d309d8eaffc478769ba97e2ee))
* restrict automatic recovery cleanup to project-owned VirtualBox and Vagrant processes ([9cee615](https://github.com/firassBenNacib/RHCSA-Simulator/commit/9cee61575d0790457308050b6a07f6ef29d6a5c9))
* validate persistent journald configuration ([#58](https://github.com/firassBenNacib/RHCSA-Simulator/issues/58)) ([02ab1fc](https://github.com/firassBenNacib/RHCSA-Simulator/commit/02ab1fc54fe4eff7eca5239fcc1e8762703e0eff))
* verify installer checksums while preserving legacy installer assets ([af55e95](https://github.com/firassBenNacib/RHCSA-Simulator/commit/af55e958c9d2aecdfc0d7143df6427df4c5a9196), [1c0cb7e](https://github.com/firassBenNacib/RHCSA-Simulator/commit/1c0cb7e5e52c52b1d543845710ad125d4d65178e))

### Documentation

* refresh default workflow docs, scenario wording, validation guidance, and README branding ([f7169e9](https://github.com/firassBenNacib/RHCSA-Simulator/commit/f7169e97b360ac6de3791312bb7c49f58f19233a), [7aeca50](https://github.com/firassBenNacib/RHCSA-Simulator/commit/7aeca50f2a97dcaef396e8bb5a95354e9516409a), [fadae06](https://github.com/firassBenNacib/RHCSA-Simulator/commit/fadae062fa7f508a14cd55ff3a2a29550cfcc36e), [ffa2c4a](https://github.com/firassBenNacib/RHCSA-Simulator/commit/ffa2c4abf602f6723ff8772b920066602921293a))

### Chores

* update CI filters, workflow action pins, and development test requirements ([3e02896](https://github.com/firassBenNacib/RHCSA-Simulator/commit/3e028960a7156d3e17194f4ddd15a961b65cdb0f), [506740b](https://github.com/firassBenNacib/RHCSA-Simulator/commit/506740b8a6d0d4d7eea7aa1fb7e887cd3d5fed86), [35fc23c](https://github.com/firassBenNacib/RHCSA-Simulator/commit/35fc23c82785ee25085006cfc4fc85e878a26d22), [03bb545](https://github.com/firassBenNacib/RHCSA-Simulator/commit/03bb545e30afba2155cb4f3396b73cd793916478))

## [2.1.2](https://github.com/firassBenNacib/RHCSA-Simulator/compare/v2.1.1...v2.1.2) (2026-06-11)


### Bug Fixes

* accept stable LVM fstab sources ([#56](https://github.com/firassBenNacib/RHCSA-Simulator/issues/56)) ([d429299](https://github.com/firassBenNacib/RHCSA-Simulator/commit/d429299f8ddbac3896e0ab493843edb50094801d))

## [2.1.1](https://github.com/firassBenNacib/RHCSA-Simulator/compare/v2.1.0...v2.1.1) (2026-06-11)


### Bug Fixes

* harden RHCSA10 exam checks ([#54](https://github.com/firassBenNacib/RHCSA-Simulator/issues/54)) ([dda8e4d](https://github.com/firassBenNacib/RHCSA-Simulator/commit/dda8e4d79742565b9b8c02b26b8305ad08eb1b18))

## [2.1.0](https://github.com/firassBenNacib/RHCSA-Simulator/compare/v2.0.1...v2.1.0) (2026-05-31)


### Features

* detect current same-major RHEL 9 and RHEL 10 DVD ISO filenames automatically ([00cc7dc](https://github.com/firassBenNacib/RHCSA-Simulator/commit/00cc7dc0f00e39cb8c8ebc144d6ac6c35e28e885))


### Documentation

* add README showcase screenshots and refresh user documentation ([7242597](https://github.com/firassBenNacib/RHCSA-Simulator/commit/72425975229f046cfa6f4876ff6a65b0f573028d))

## [2.0.1](https://github.com/firassBenNacib/RHCSA-Simulator/compare/v2.0.0...v2.0.1) (2026-05-26)


### Bug Fixes

* harden replay authentication setup ([dc52c5f](https://github.com/firassBenNacib/RHCSA-Simulator/commit/dc52c5fd848c8c09fab2110f7e96dcb3e13eae90))

## [2.0.0](https://github.com/firassBenNacib/RHCSA-Simulator/compare/v1.0.15...v2.0.0) (2026-05-24)


### Bug Fixes

* land RHCSA10 exam ordering on main ([e82edcf](https://github.com/firassBenNacib/RHCSA-Simulator/commit/e82edcfcd2749ae7a37180f1e447a8eba9b11aa3))
* stabilize replay cleanup and rhcsa9 exams ([a31727a](https://github.com/firassBenNacib/RHCSA-Simulator/commit/a31727a69bc56661c285c469a7b77df5018f0c45))

## [1.0.15](https://github.com/firassBenNacib/RHCSA-Simulator/compare/v1.0.14...v1.0.15) (2026-05-22)


### Bug Fixes

* harden replay cleanup after VirtualBox crash ([9f6f68a](https://github.com/firassBenNacib/RHCSA-Simulator/commit/9f6f68ad4bb8cc6c57fddf1b1cf2b36ae3ddac93))
* harden replay cleanup and rhcsa9 checks ([802d167](https://github.com/firassBenNacib/RHCSA-Simulator/commit/802d1679f19037ae094d8cd3c93459f0fe9a8705))
* satisfy scenario audit for exam group replay ([cfd5519](https://github.com/firassBenNacib/RHCSA-Simulator/commit/cfd55198e26dd5b4ce700ad91c1c1bcd0a9254e4))

## [1.0.14](https://github.com/firassBenNacib/RHCSA-Simulator/compare/v1.0.13...v1.0.14) (2026-05-22)


### Bug Fixes

* restore CLI colors and release dispatch ([1c0cc22](https://github.com/firassBenNacib/RHCSA-Simulator/commit/1c0cc22755c6d8e4cf4935a90989d569d3fd02f6))
* restore colored CLI output and release dispatch ([a1da54b](https://github.com/firassBenNacib/RHCSA-Simulator/commit/a1da54ba4ebcf96e5c8f72ef8b8114a067b04abd))

## [1.0.13](https://github.com/firassBenNacib/RHCSA-Simulator/compare/v1.0.12...v1.0.13) (2026-05-22)


### Bug Fixes

* keep colored verifier output and avoid rebuild fallback ([e65ec6c](https://github.com/firassBenNacib/RHCSA-Simulator/commit/e65ec6c4e51ddc99d5f588e748c08c0ae4131263))

## [1.0.12](https://github.com/firassBenNacib/RHCSA-Simulator/compare/v1.0.11...v1.0.12) (2026-05-22)


### Bug Fixes

* repair CLI state handling and release dispatch ([d758a2f](https://github.com/firassBenNacib/RHCSA-Simulator/commit/d758a2fb491601e63ff0f3cc833047bef093c1fc))

## [1.0.11](https://github.com/firassBenNacib/RHCSA-Simulator/compare/v1.0.10...v1.0.11) (2026-05-21)


### Bug Fixes

* align verifier profile and scenario metadata ([5c68d77](https://github.com/firassBenNacib/RHCSA-Simulator/commit/5c68d77995ccf8c5e08b3d5f7cc9d103b0e3875c))
* use patched Go toolchain directive ([832ffeb](https://github.com/firassBenNacib/RHCSA-Simulator/commit/832ffeb91e0dcbb812022753ab8412fb58efc136))

## [1.0.10](https://github.com/firassBenNacib/RHCSA-Simulator/compare/v1.0.9...v1.0.10) (2026-05-21)


### Bug Fixes

* polish CLI and RHCSA10 grading ([4aa61a5](https://github.com/firassBenNacib/RHCSA-Simulator/commit/4aa61a5f112fc4be921e16d04244c54c21cda9fe))

## [1.0.9](https://github.com/firassBenNacib/RHCSA-Simulator/compare/v1.0.8...v1.0.9) (2026-05-20)


### Bug Fixes

* satisfy RHCSA10 scenario audit ([9648308](https://github.com/firassBenNacib/RHCSA-Simulator/commit/9648308b6299c01541ffdcc7aed2fe414d02baab))
