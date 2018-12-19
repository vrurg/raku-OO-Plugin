use v6.d;
unit module OO::Plugin::Declarations;
use OO::Plugin::Registry;
use WhereList;

multi trait_mod:<is> ( Routine:D $routine, :%wrapper! ) is export {
    die "wrapper trait in its hash form requires 'class'" unless %wrapper<class>:exists;
    Plugin::Registry.instance.register-wrapper( $routine, |%wrapper<class method> );
}

multi trait_mod:<is> ( Routine:D $routine, :$wrapper! is copy where * ~~ List | Pair ) is export {
    note "WRAPPER: ", $wrapper.WHAT;
    note "WRAPPER data: ", $wrapper.perl;
    my $registry = Plugin::Registry.instance;
    for $wrapper.List -> $w {
        given $w {
            when Pair {
                $registry.register-wrapper( $routine, .key, .value )
            }
            when Str {
                $registry.register-wrapper( $routine, $_ );
            }
        }
    }
    # note "DYN: ", $*PLUG-TEST;
}

multi trait_mod:<is>( Method:D $method, :$pluggable! ) is export {
    note "PLUGGABLE: ", $method.name, " from ", $method.package.^name, "/", $method.package.^shortname;
    Plugin::Registry.instance.register-pluggable( $method );
}

multi trait_mod:<is>( Mu:U \type, :$pluggable! ) is export {
    note "PLUGGABLE CLASS: ", type.^name;
    Plugin::Registry.instance.register-pluggable( type );
}
