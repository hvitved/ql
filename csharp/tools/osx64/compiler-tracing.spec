**/mcs.exe:
**/csc.exe:
  invoke ${config_dir}/Semmle.Extraction.CSharp.Driver
  prepend --compiler
  prepend "${compiler}"
  prepend --cil
**/mono*:
**/dotnet:
  replace yes
  invoke ${config_dir}/dotnet-wrapper
  prepend ${compiler}
**/msbuild:
**/xbuild:
  replace yes
  invoke ${compiler}
  append /p:UseSharedCompilation=false
/usr/bin/codesign:
  replace yes
  invoke /usr/bin/env
  prepend /usr/bin/codesign
  trace no
/usr/bin/pkill:
  replace yes
  invoke /usr/bin/env
  prepend /usr/bin/pkill
  trace no
/usr/bin/pgrep:
  replace yes
  invoke /usr/bin/env
  prepend /usr/bin/pgrep
  trace no
