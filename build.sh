app_name="test_appimage"
app_comment="App Image Update Test"
terminal="true"
categories="Development;"
pip_app_name="test_appimage"
icon_name="test_appimage"
icon_url="https://raw.githubusercontent.com/mario33881/betterSIS/64bf89345c4e5465d60828b4c8d54ffe9e2cb9bb/_static/images/logo.svg"
architecture="x86_64"
python_version="python3.8"
python_full_version="${python_version}.11"
python_short_version="cp38"
svg="0" # 0: true (uses inkscape for svg -> png), 1: false

# download appimage
wget https://github.com/niess/python-appimage/releases/download/${python_version}/${python_full_version}-${python_short_version}-${python_short_version}-manylinux1_${architecture}.AppImage

# give permission to execute and extract the appimage
chmod +x python*-manylinux1_${architecture}.AppImage
./python*-manylinux1_${architecture}.AppImage --appimage-extract

# install using pip
./squashfs-root/AppRun -m pip install https://github.com/mario33881/test_appimage/archive/refs/heads/main.zip --no-cache-dir

# Change AppRun so that it launches bettersis
sed -i -e "s|/opt/${python_version}/bin/${python_version}|/usr/bin/${pip_app_name}|g" ./squashfs-root/AppRun

# Edit the desktop file
mv squashfs-root/usr/share/applications/python*.desktop squashfs-root/usr/share/applications/bettersis.desktop
sed -i -e "s|^Name=.*|Name=${app_name}|g" squashfs-root/usr/share/applications/*.desktop
sed -i -e "s|^Exec=.*|Exec=${pip_app_name}|g" squashfs-root/usr/share/applications/*.desktop
sed -i -e "s|^Icon=.*|Icon=${icon_name}|g" squashfs-root/usr/share/applications/*.desktop
sed -i -e "s|^Comment=.*|Comment=${app_comment}|g" squashfs-root/usr/share/applications/*.desktop
sed -i -e "s|^Terminal=.*|Terminal=${terminal}|g" squashfs-root/usr/share/applications/*.desktop
sed -i -e "s|^Categories=.*|Categories=${categories}|g" squashfs-root/usr/share/applications/*.desktop
rm squashfs-root/*.desktop
cp squashfs-root/usr/share/applications/*.desktop squashfs-root/

# Add icon
mkdir -p squashfs-root/usr/share/icons/hicolor/128x128/apps/

if [ "$svg" = "0" ] ; then
    sudo apt-get install inkscape -y
    wget $icon_url -O $icon_name.svg
    inkscape --export-type="png" -w 128 -h 128 $icon_name.svg -o squashfs-root/usr/share/icons/hicolor/128x128/apps/$icon_name.png
else
    sudo apt-get install imagemagick -y
    wget $icon_url -O $icon_name.png
    convert -resize 128x128 $icon_name.png squashfs-root/usr/share/icons/hicolor/128x128/apps/$icon_name.png
fi

cp squashfs-root/usr/share/icons/hicolor/128x128/apps/$icon_name.png squashfs-root/

# Add AppImageUpdate inside the AppImage itself
wget https://github.com/AppImage/AppImageUpdate/releases/download/continuous/AppImageUpdate-x86_64.AppImage -O squashfs-root/appimageupdate.AppImage
chmod +x squashfs-root/appimageupdate.AppImage
./squashfs-root/appimageupdate.AppImage --appimage-extract
mv ./squashfs-root/squashfs-root ./squashfs-root/appimageupdate
rm -rf squashfs-root/appimageupdate.AppImage

# TODO: try to trim files from the image to reduce size of appimage


# Convert back into an AppImage
export VERSION=$(cat squashfs-root/opt/python*/lib/python*/site-packages/$pip_app_name-*.dist-info/METADATA | grep "^Version:.*" | cut -d " " -f 2)
wget -c https://github.com/$(wget -q https://github.com/probonopd/go-appimage/releases -O - | grep "appimagetool-.*-$architecture.AppImage" | head -n 1 | cut -d '"' -f 2)
chmod +x appimagetool-*.AppImage

export ARCH=$architecture
appimagetool ./squashfs-root/ -u "gh-releases-zsync|mario33881|test_appimage|latest|test_appimage-*x86_64.AppImage.zsync"
