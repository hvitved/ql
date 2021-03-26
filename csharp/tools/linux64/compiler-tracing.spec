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
