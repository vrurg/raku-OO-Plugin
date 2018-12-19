use v6.d;
use OO::Plugin::Class;

package OO::Plugin::Registry::_types { }

class Plugin::Registry is export {
    has %!registry;

    my $instance;

    method new ( |params ) { self.instance( |params ) }

    submethod instance ( |params ) {
        return $instance //= self.bless( |params );
    }

    method register-plugin ( Mu:U \type ) {
        OO::Plugin::Registry::_types::{ type.^name } = type;
    }

    method plugin-names {
        OO::Plugin::Registry::_types::.keys
    }

    method plugin-types {
        OO::Plugin::Registry::_types::.values;
    }

    proto method plugin-meta (|) {*}
    multi method plugin-meta ( %meta, Mu:U $class ) {
        die "Can't register meta for {$class.^name} which is not a Plugin" unless $class ~~ Plugin;

        %!registry<meta>{ $class.^name }{ .keys } = .values with %meta;
    }
    multi method plugin-meta ( Str:D $plugin ) { %!registry<meta>{ $plugin } }
    multi method plugin-meta ( Plugin:U $plugin ) { %!registry<meta>{ $plugin.^name } }

    proto method register-pluggable (|) {*}
    multi method register-pluggable ( Method:D $method ) {
        note "REGISTERING METHOD ", $method.name, " from ", $method.package.^name;
        %!registry<pluggables><methods>{ $method.package.^name }{ $method.name } = $method;
        self.register-pluggable( $method.package ); # Implicitly register method's class as pluggable
    }
    multi method register-pluggable ( Mu:U \type ) {
        note "REGISTERING CLASS ", type.^name;
        %!registry<pluggables><classes>{ type.^name } = type;
    }

    proto method register-wrapper (|) {*}
    multi method register-wrapper ( Routine:D $routine, Str:D $class, Str:D $method = '*' ) {
        %!registry<wrappers><methods>{ $class }{ $method } = $routine;
    }
    multi method register-wrapper ( Routine:D $routine, Mu:U \type, Str:D $method = '*' ) {
        self.register-pluggable( type );  # Implicitly register the class as pluggable.
        samewith( $routine, type.^name, $method );
    }

    method pluggable-classes ( --> List ) {
        %!registry<pluggables><classes>.keys
    }

    method type ( Str:D $class-name --> Mu:U ) {
        %!registry<pluggables><classes>{ $class-name }
    }
}
