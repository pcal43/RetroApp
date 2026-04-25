root_dir := justfile_directory()
etc_dir := root_dir + "/etc"
build_dir := root_dir + "/build"
ui_dir := root_dir + "/ui"
cli_dir := root_dir + "/cli"
platypus_dir := root_dir + "/platypus"

clean:
    rm -rf {{build_dir}}

build version="":
    #!/usr/bin/env sh
    VERSION="{{version}}"
    if [ -z "$VERSION" ]; then
        VERSION=$(cat {{root_dir}}/version)
    fi
    mkdir -p {{build_dir}}
    rm -f "{{build_dir}}/RetroAppMaker.app"
    platypus \
      --name RetroAppMaker \
      --app-version "$VERSION" \
      --interface-type "Text Window" \
      --interpreter "/bin/zsh" \
      --app-icon "{{root_dir}}/AppIcon.icns" \
      --bundle-identifier "net.pcal.RetroAppMaker" \
      --droppable \
      --suffixes 'png|bin'\
      --bundled-file "{{ui_dir}}|{{cli_dir}}|{{root_dir}}/version" \
      --overwrite \
      "{{platypus_dir}}/script" \
      "{{build_dir}}/RetroAppMaker.app"
    cp version "{{build_dir}}/RetroAppMaker.app/Contents/Resources/cli/"
    cp version "{{build_dir}}/RetroAppMaker.app/Contents/Resources/ui/"
    open {{build_dir}}

dmg dmg_path="" version="":
        #!/usr/bin/env sh
        VERSION="{{version}}"
        if [ -z "$VERSION" ]; then
            VERSION=$(cat {{root_dir}}/version)
        fi
        just build $VERSION

        mkdir -p {{build_dir}}/tmp_dmg
        cp -R {{build_dir}}/RetroAppMaker.app {{build_dir}}/tmp_dmg/
        ln -s /Applications {{build_dir}}/tmp_dmg/


        DMG_PATH="{{dmg_path}}"
        if [ -z "$DMG_PATH" ]; then
            DMG_PATH="{{build_dir}}/RetroAppMaker-$VERSION.dmg"
        fi

        echo "Using version: $VERSION"

        hdiutil create -volname "RetroAppMaker" \
                       -srcfolder {{build_dir}}/tmp_dmg \
                       -ov -format UDZO \
                       "${DMG_PATH}"
        rm -rf {{build_dir}}/tmp_dmg
        echo "DMG created at ${DMG_PATH}"

release: clean
    #!/usr/bin/env sh
    set -e

    #CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    #if [[ "$CURRENT_BRANCH" != "main" ]]; then
    #    echo "Error: Releases must be performed on the main branch" >&2
    #    echo "Current branch: $CURRENT_BRANCH" >&2
    #    exit 1
    #fi
    if [[ -n $(git status --porcelain) ]]; then
        echo "Error: Git working directory is not clean" >&2
        echo "Please commit or stash changes before releasing" >&2
        exit 1
    fi

    VERSION=$(cat {{root_dir}}/version)
    if [[ ! $VERSION == *+prerelease ]]; then
        echo "Error: Version must end with +prerelease" >&2
        exit 1
    fi

    RELEASE_VERSION=${VERSION%+prerelease}
    DMG_PATH="{{build_dir}}/RetroAppMaker-$RELEASE_VERSION.dmg"
    echo "Creating release version: $RELEASE_VERSION"
    just dmg "$DMG_PATH" "$RELEASE_VERSION" || { echo "DMG build failed"; exit 1; }

    echo "$RELEASE_VERSION" > {{root_dir}}/version

    git add {{root_dir}}/version
    git commit -m "*** Release $RELEASE_VERSION ***"

    MAJOR=$(echo $RELEASE_VERSION | cut -d. -f1)
    MINOR=$(echo $RELEASE_VERSION | cut -d. -f2)
    PATCH=$(echo $RELEASE_VERSION | cut -d. -f3)
    NEXT_PATCH=$((PATCH + 1))
    NEXT_VERSION="$MAJOR.$MINOR.$NEXT_PATCH+prerelease"

    echo "$NEXT_VERSION" > {{root_dir}}/version
    git add {{root_dir}}/version
    git commit -m "Prepare for next version $MAJOR.$MINOR.$NEXT_PATCH"

    set -x
    gh release create --generate-notes --title "$RELEASE_VERSION" --notes "release $RELEASE_VERSION" "$RELEASE_VERSION" "$DMG_PATH"
    set +x

    git push

    echo "Released version $RELEASE_VERSION and prepared for $MAJOR.$MINOR.$NEXT_PATCH"

test-stella:
    mkdir -p {{build_dir}}
    rm -rf {{build_dir}}/Halo2600.app
    {{cli_dir}}/retroapp build -n Halo2600 -b stella -c "{{etc_dir}}/" -r "{{etc_dir}}/Halo2600.a26" -o "{{build_dir}}"
    open {{build_dir}}/
    open {{build_dir}}/Halo2600.app

test-nestopia:
    mkdir -p {{build_dir}}
    rm -rf {{build_dir}}/dpadhero2.app
    {{cli_dir}}/retroapp build -n dpadhero2 -b nestopia -c -r {{etc_dir}}/dpadhero2.zip -o {{build_dir}}
    open {{build_dir}}/
    open {{build_dir}}/dpadhero2.app

