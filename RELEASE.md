## Release

Current process: for each release we also create a separate branch (`release-x.y.z`), tag (`x.y.z`) and Github release (`x.y.z`).

This document describes the steps needed to make a release:

For each supported library:
 - `trackasia_gl_platform_interface`
 - `trackasia_gl_web`
 - `trackasia-flutter-gl`

Perform the following actions (these changes should also be on `main`):
 - Update `CHANGELOG.md` with the commits associated since previous release.
 - Update library version in `pubspec.yaml`


**Only on the release branch:** Repeat this action for `trackasia-flutter-gl` and `trackasia_gl_web` for the dependency_overrides:

```
Comment out:
dependency_overrides:
  trackasia_gl_platform_interface:
    path: ../trackasia_gl_platform_interface
```

and for the trackasia git dependencies, change ref from `main` to `release-x.y.z`.

Finally, create a Github release and git tag from the release branch.

The only difference between the release branch and `main` directly after the release are the `dependency_overrides` (these are useful for development and should therefore only be removed in the release branches) and the git ref for the intra-package dependencies.
