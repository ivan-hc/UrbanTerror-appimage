#!/bin/sh

APP=urbanterror

ARCH="x86_64"

# DEPENDENCIES

dependencies="unzip"
for d in $dependencies; do
	if ! command -v "$d" 1>/dev/null; then
		echo "ERROR: missing command \"d\", install the above and retry" && exit 1
	fi
done

_appimagetool() {
	if ! command -v appimagetool 1>/dev/null; then
		[ ! -f ./appimagetool ] && curl -#Lo appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-"$ARCH".AppImage && chmod a+x ./appimagetool
		./appimagetool "$@"
	else
		appimagetool "$@"
	fi
}

DOWNLOAD_PAGE=$(curl -Ls https://www.urbanterror.info/downloads/)
DOWNLOAD_URL=$(echo "$DOWNLOAD_PAGE" | tr '">< ' '\n' | grep -i "^http.*full.*zip$" | head -1)
VERSION=$(echo "$DOWNLOAD_PAGE" | tr '><' '\n' | grep -i "version [0-9]" | head -1 | tr ' ' '\n' | grep "^[0-9]")
if ! test -f ./*.zip; then curl -#Lo "$APP".zip "$DOWNLOAD_URL"; fi
mkdir -p "$APP".AppDir || exit 1

# Extract the package
unzip -qq ./*zip 1>/dev/null && rm -f ./*zip && mv ./UrbanTerror*/* "$APP".AppDir/ || exit 1

_appimage_basics() {
	# Icon
	curl -#Lo "$APP".png https://aur.archlinux.org/cgit/aur.git/plain/urbanterror.png?h=urbanterror 2>/dev/null && mv "$APP".png "$APP".AppDir/
	
	# Launcher
	cat <<-HEREDOC >> ./"$APP".AppDir/"$APP".desktop
	[Desktop Entry]
	Name=Urban Terror
	Type=Application
	Categories=Game;
	Terminal=false
	Exec=$APP
	Icon=$APP
	HEREDOC

	# AppRun
	printf '#!/bin/sh\nHERE="$(dirname "$(readlink -f "${0}")")"\nexec "${HERE}"/Quake3-UrT.x86_64 "$@"' > ./"$APP".AppDir/AppRun && chmod a+x ./"$APP".AppDir/AppRun
}

_appimage_basics

#############################################################################
#	CREATE THE APPIMAGE
#############################################################################

APPNAME=$(cat ./"$APP".AppDir/*.desktop | grep 'Name=' | head -1 | cut -c 6- | sed 's/ /-/g')
REPO="UrbanTerror-appimage"
TAG="continuous"
VERSION="$VERSION"
UPINFO="gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|$REPO|$TAG|*x86_64.AppImage.zsync"

ARCH=x86_64 _appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 20 \
	-u "$UPINFO" \
	./"$APP".AppDir "$APPNAME"_"$VERSION"-x86_64.AppImage

if ! test -f ./*.AppImage; then
	echo "No AppImage available."; exit 1
fi
