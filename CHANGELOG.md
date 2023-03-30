# Changelog

All notable changes to this project will be documented in this file.

The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).
This changelog is generated automatically based on [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## [1.0.2](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/compare/v1.0.1...v1.0.2) (2023-03-30)


### Bug Fixes

* remove optional for backwards compatibility ([#68](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/issues/68)) ([01348c9](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/01348c9c145252b6bb040c39cb3104db7965e884))

## [1.0.1](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/compare/v1.0.0...v1.0.1) (2023-03-30)


### Bug Fixes

* **deps:** update terraform terraform-google-modules/kubernetes-engine/google to v25 ([#56](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/issues/56)) ([c929094](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/c92909422ac235363b7b6d4c49e28b9ce282211f))
* walkthrough updates ([#64](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/issues/64)) ([5148197](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/5148197fcd19b95690f93db76001a9215866ee72))

## [1.0.0](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/compare/v0.3.1...v1.0.0) (2023-03-29)


### ⚠ BREAKING CHANGES

* Use Connect Gateway as alternative to VPN for deploying to private GKE clusters from Cloud Build (addressing https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/issues/20)
* Require Cloud Build BYOSA in secure-cd submodule instead of default CB SA
* Use Connect Gateway for standalone example ([#59](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/issues/59))

### Features

* automatic app deployment testing in standalone example verification test ([771f462](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/771f462ca788d02a284fbaf58dc2cd4072b355a2))
* Require Cloud Build BYOSA in secure-cd submodule instead of default CB SA ([771f462](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/771f462ca788d02a284fbaf58dc2cd4072b355a2))
* Use Connect Gateway as alternative to VPN for deploying to private GKE clusters from Cloud Build (addressing https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/issues/20) ([771f462](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/771f462ca788d02a284fbaf58dc2cd4072b355a2))
* Use Connect Gateway for standalone example ([#59](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/issues/59)) ([771f462](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/771f462ca788d02a284fbaf58dc2cd4072b355a2))


### Bug Fixes

* documentation and walkthrough cleanup and clarification ([771f462](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/771f462ca788d02a284fbaf58dc2cd4072b355a2))
* increase app build test threshold to 20 mins ([#61](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/issues/61)) ([ad57bd5](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/ad57bd5d87d588ab9341ddf7b8d7983dca4b70f0))
* set project via walkthrough link ([#62](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/issues/62)) ([0059004](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/0059004aa17a9badca13d33ec15be875eb010a39))

## [0.3.1](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/compare/v0.3.0...v0.3.1) (2023-02-14)


### Bug Fixes

* reduce zones used in standalone example clusters ([#45](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/issues/45)) ([1fa43a4](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/1fa43a46d2a3ed4fd86c30b65f75df7ddeb4cbab))
* set initial_node_count to 2 ([#43](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/issues/43)) ([34f3ead](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/34f3ead0b533e9a8c340f51b1dd7e2ad92808cbd))

## [0.3.0](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/compare/v0.2.0...v0.3.0) (2022-12-15)


### Features

* replace default Cloud Build SA with custom SA in build phase ([#35](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/issues/35)) ([b5ab9e0](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/b5ab9e024b901726df06a3539fa29e49e023f4e5))


### Bug Fixes

* pass through labels ([#38](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/issues/38)) ([b615569](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/b615569d4334f80b7836bf8b5aabae7be2d9a76d))
* update standalone single project documentation and walkthrough ([#36](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/issues/36)) ([06cb65a](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/06cb65aa994656b5decbb88671bc5cbbade51ab4))
* use registry modules in standalone_single_project example ([#33](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/issues/33)) ([1c032cc](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/1c032ccd6954e4d8e8c584efd296f95b5a06e799))

## [0.2.0](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/compare/v0.1.0...v0.2.0) (2022-09-28)


### Features

* Cloud Deploy support ([#25](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/issues/25)) ([49402b4](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/49402b46010b20e3afcaeec200cc2b64db409d01))

## 0.1.0 (2022-03-16)


### Features

* Refactor CI pipeline ([#5](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/issues/5)) ([4023ae8](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/commit/4023ae8aa9f36d8b881f8f655eed25dd547b19cf))

## [0.1.0](https://github.com/terraform-google-modules/terraform-google-secure-cicd/releases/tag/v0.1.0) - 20XX-YY-ZZ

### Features

- Initial release

[0.1.0]: https://github.com/terraform-google-modules/terraform-google-secure-cicd/releases/tag/v0.1.0
