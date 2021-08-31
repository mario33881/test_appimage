# TEST_APPIMAGE

This is a test repository for AppImages.
> AppImage updates is the primary test subject.

This script simply checks if the latest Github Release
contains a newer version by checking the version.txt file of the release,
shows the current version number, shows the latest version number and shows if the latest release is a new release.

The zsync file should enable the appimage to be updateable using [AppImageUpdate](https://github.com/AppImage/AppImageUpdate).

From version 1.3.0 I've included AppImageUpdate inside the AppImage: if you call the AppImage with the ```--update``` flag AppImageUpdate downloads the latest app version.