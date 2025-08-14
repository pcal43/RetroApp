root_dir := justfile_directory()
etc_dir := root_dir + "/etc"
build_dir := root_dir + "/build"
ui_dir := root_dir + "/ui"
cli_dir := root_dir + "/cli"
platypus_dir := root_dir + "/platypus"

build:
    mkdir -p {{build_dir}}
    platypus \
      --name RetroApp \
      --interface-type "None" \
      --interpreter "/bin/sh" \
      --app-icon "{{platypus_dir}}/icon.icns" \
      --bundle-identifier "net.pcal.RetroApp" \
      --droppable \
      --bundled-file "{{ui_dir}}|{{cli_dir}}" \
      --overwrite \
      --quit-after-execution \
      "{{platypus_dir}}/script" \
      "{{build_dir}}/RetroApp.app"
    open {{build_dir}}


clean:
    rm -rf {{build_dir}}

test-stella:
    mkdir -p {{build_dir}}
    rm -rf {{build_dir}}/Halo2600.app
    {{cli_dir}}/retroapp build -n Halo2600 -b stella -c -r {{etc_dir}}/Halo2600.a26 -o {{build_dir}}
    open {{build_dir}}/Halo2600.app

test-nestopia:
    mkdir -p {{build_dir}}
    rm -rf {{build_dir}}/dpadhero2.app
    {{cli_dir}}/retroapp build -n dpadhero2 -b nestopia -c -r {{etc_dir}}/dpadhero2.zip -o {{build_dir}}
    open {{build_dir}}/dpadhero2.app

