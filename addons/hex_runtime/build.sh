#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p bin
case "${HEX_PLATFORM:-$(uname -s)}" in
 Linux) target=bin/libhex_runtime.linux.x86_64.so; flags=(-shared -fPIC -lm -ldl -lpthread) ;;
 Darwin) target=bin/libhex_runtime.macos.$(uname -m).dylib; flags=(-dynamiclib -fPIC -lm) ;;
 Windows*) target=bin/hex_runtime.windows.x86_64.dll; flags=(-shared -static -static-libgcc -lm -lpthread) ;;
 *) echo 'Set HEX_PLATFORM to Linux, Darwin or Windows and CC to the compiler.' >&2; exit 1 ;;
esac
"${CC:-cc}" -O2 -fvisibility=hidden -D_GNU_SOURCE '-DCONFIG_VERSION="2025-09-13"' -Ivendor hex_runtime.c vendor/quickjs.c vendor/dtoa.c vendor/libregexp.c vendor/libunicode.c vendor/cutils.c -o "$target" "${flags[@]}"
echo "$target"
