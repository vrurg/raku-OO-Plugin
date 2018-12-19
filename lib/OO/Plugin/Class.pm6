use v6.d;
unit module OO::Plugin::Class;

class Plugin:auth<CPAN:VRURG>:ver<0.0.0>:api<0> is export {
    has $.plugin-manager is required where { is-plug-mgr $_ };

    proto method on-event (|) {*}

    proto method on-callback (|) {*}
}

role Pluggable is export {
    has $.plugin-manager is required where { is-plug-mgr $_ };
}

sub is-plug-mgr ( $obj ) {
    require ::('OO::Plugin::Manager');
    $obj ~~ ::('OO::Plugin::Manager')
}
