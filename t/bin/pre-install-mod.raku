#!/usr/bin/env raku
use lib $?FILE.IO.parent(2).add('lib');
use OOPTest;
use Test;

sub MAIN (Str:D $mod-path) {
    install-distro( $mod-path ) or die "failed to install plugin distro from $mod-path";
}
