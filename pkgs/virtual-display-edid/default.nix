{ lib, runCommand, fetchurl, python3 }:

let
  src = fetchurl {
    url = "https://raw.githubusercontent.com/akatrevorjay/edid-generator/master/1920x1080.bin";
    hash = "sha256-vMG3e1FFSVChV2zuIw2Yur7K1OjMOliEmeIK3DpsR/Q=";
  };
in
runCommand "virtual-display-edid-1920x1080" {
  nativeBuildInputs = [ python3 ];
  inherit src;
} ''
  mkdir -p $out/lib/firmware/edid
  python3 -c "
import os, shutil
shutil.copy(os.environ['src'], '/tmp/edid-raw.bin')
data = bytearray(open('/tmp/edid-raw.bin', 'rb').read())
data = data[:128]
data[20] = 0x80
data[24] = 0x06
data[127] = (256 - sum(data[:127]) % 256) % 256
outpath = os.environ['out'] + '/lib/firmware/edid/1920x1080.bin'
with open(outpath, 'wb') as f:
    f.write(data)
print('EDID: %d bytes, sum=%d' % (len(data), sum(data)))
"
''
