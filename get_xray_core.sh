get_xray_core() {
    identify_the_operating_system_and_architecture
    local xray_version="$1"
    local xray_filename="Xray-linux-${ARCH}.zip"
    local download_url="https://github.com/XTLS/Xray-core/releases/download/${xray_version}/${xray_filename}"
    local checksum_url="https://github.com/XTLS/Xray-core/releases/download/${xray_version}/${xray_filename}.sha256"curl -sL "$checksum_url" -o /tmp/xray_checksum.txt
curl -sL "$download_url" -o "/tmp/${xray_filename}"

if ! (cd /tmp && sha256sum -c /tmp/xray_checksum.txt 2>/dev/null); then
    rm -f /tmp/xray_checksum.txt "/tmp/${xray_filename}"
    exit 1
fi

unzip -o "/tmp/${xray_filename}" -d "$DATA_DIR/xray-core"
chmod +x "$DATA_DIR/xray-core/xray"
rm -f /tmp/xray_checksum.txt "/tmp/${xray_filename}"}

