use v6.d;
use OO::Plugin::Class;

package OO::Plugin::Registry::_types { }

module OO::Plugin::Registry {
    sub register-plugin ( Mu:U \type ) is export {
        OO::Plugin::Registry::_types::{ type.^name } = type;
    }

    sub plugin-names is export {
        OO::Plugin::Registry::_types::.keys
    }

    sub plugin-types is export {
        OO::Plugin::Registry::_types::.values;
    }

    my %metas;
    proto plugin-meta (|) {*}
    multi plugin-meta ( %meta, Mu:U $class = Nil ) is export {
        if $class === Nil {
            $class = CALLER::<::?CLASS>;
        }

        die "Can't register meta for {$class.^name} which is not a Plugin" unless $class ~~ Plugin;

        %metas{ $class.^name }{ .keys } = .values with %meta;
    }
    multi plugin-meta ( *%meta ) is export {
        samewith( %meta, CALLER::<::?CLASS> );
    }
    multi plugin-meta ( Str:D $plugin ) { %metas{ $plugin } }
    multi plugin-meta ( Plugin:U $plugin ) { %metas{ $plugin.^name } }
}
