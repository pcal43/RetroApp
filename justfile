root_dir := justfile_directory()
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