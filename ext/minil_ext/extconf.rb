require 'mkmf'

$CFLAGS << ' -Wall '
$CFLAGS << ' -Wextra '
$CFLAGS << ' -O3 '
$CFLAGS << ' -std=c99 '
$CFLAGS << ' -ggdb '

create_makefile('minil_ext')
