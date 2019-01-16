use v6.d;
use OO::Plugin::Class;

package OO::Plugin::Registry::_plugins { }
package OO::Plugin::Registry::_classes { } # For pluggable classes

subset PlugPosition of Str:D where * ~~ any <before around after>;

class Plugin::Registry is export {
    use OO::Plugin::Exception;

    has %!registry;

    my $instance;

    method new ( |params ) { self.instance( |params ) }

    submethod instance ( |params ) {
        return $instance //= self.bless( |params );
    }

    method register-plugin ( Mu:U \type ) {
        OO::Plugin::Registry::_plugins::{ type.^name } = type;
        %!registry<name-map><plugins>:delete;
    }

    method plugin-names {
        OO::Plugin::Registry::_plugins::.keys
    }

    method plugin-types {
        OO::Plugin::Registry::_plugins::.values;
    }

    method plugin-type ( Str:D $plugin --> Plugin:U ) {
        fail X::OO::Plugin::NotFound.new( :$plugin ) unless OO::Plugin::Registry::_plugins::{$plugin}:exists;
        OO::Plugin::Registry::_plugins::{$plugin}
    }

    proto method plugin-meta (|) {*}
    multi method plugin-meta ( %meta, Mu:U \type ) {
        die "Can't register meta for {type.^name} which is not a Plugin" unless type ~~ Plugin;

        my $pname = type.^name;

        # The order of setting meta data for a plugin is:
        # 1. decalaration (plugin Foo after/before/demand)
        # 2. plugin-meta call from within plugin block.
        # 3. %meta hash in plugin block.
        # The priority of data lowers from top to bottom. Thus, keys defained on later stages must not override keys
        # from earlier ones.

        for %meta.keys -> $key {
            next if %!registry<meta>{$pname}{$key}:exists;
            given $key {
                when any <after before demand> {
                    %!registry<meta>{$pname}{$key} ∪= %meta{$key}.list;
                }
                default {
                    %!registry<meta>{$pname}{$key} = %meta{$key};
                }
            }
        }
    }
    multi method plugin-meta ( Str:D $plugin --> Hash:D ) {
        self!deep-clone( %!registry<meta>{ self.short2fqn( :$plugin ) } // {} )
    }
    multi method plugin-meta ( Str:D :$fqn! --> Hash:D ) {
        self!deep-clone( %!registry<meta>{ $fqn } // {} )
    }
    multi method plugin-meta ( Plugin:U $plugin ) { samewith( fqn => $plugin.^name ) }

    proto method register-pluggable (|) {*}
    multi method register-pluggable ( Method:D $method ) {
        # note "REGISTERING METHOD ", $method.name, " from ", $method.package.^name;
        %!registry<pluggables><methods>{ $method.package.^name }{ $method.name } = $method;
        self.register-pluggable( $method.package ); # Implicitly register method's class as pluggable
    }
    multi method register-pluggable ( Mu:U \type ) {
        my $name = type.^name;
        # Avoid name-map rebuild if class is being re-registered
        return if OO::Plugin::Registry::_classes::{ $name }:exists;
        OO::Plugin::Registry::_classes::{ $name } = type;
        %!registry<name-map><classes>:delete;
        %!registry<extended-classes>:delete;
    }

    proto method register-plug (|) {*}
    multi method register-plug ( Method:D $routine,
                                Str:D $class,
                                Str:D $method = '*',
                                PlugPosition :$position = 'around',
                                *%params ) {
        # We could constain routine signature in the parameter but better provide explanatory errors.
        my $signature = $routine.signature;
        die "Invalid signature of the method handler" unless $signature ~~ :(Any: $, *%, *@ );
        my $fparam = $signature.params[1];
        die "Unsupported type constraint '", $fparam.type.WHO, "' for the first parameter"
            unless $fparam.type === Any | MethodHandlerMsg;
        die 'First parameter sigil must be $, not ' ~ $fparam.sigil
            unless $fparam.sigil eq '$';

        my $fqn = $routine.package.^name;
        my \type = self.type( $class );

        my @methods = $method eq '*' ?? type.^methods.map( *.name ) !! [ $method ];
        for @methods -> $class-method {
            die "There is already a handler for $class method $class-method in plugin $fqn"
                if %!registry<plugs><methods>{ $class }{ $class-method }{ $fqn }{ $position }:exists;

            %!registry<plugs><methods>{ $class }{ $class-method }{ $fqn }{ $position } = $routine;
        }
    }
    multi method register-plug ( Method:D $routine,
                                Mu:U \type,
                                Str:D $method = '*',
                                PlugPosition :$position = 'around' ) {
        self.register-pluggable( type );  # Implicitly register the class as pluggable.
        self.register-plug( $routine, type.^name, $method, :$position );
    }

    # plug-class registration block
    multi method register-plug ( Mu:U \plug-class, :@extending where { all .map: * ~~ Str:D  } ) {
        my $plug-name = plug-class.^name;
        # note "$plug-name extends {@extending}";
        given %!registry<plug-classes>{ $*CURRENT-PLUGIN-CLASS.^name }{ $plug-name } {
            $_<type> = plug-class;
            $_<extends> ∪= @extending.map( { self.fqn-class-name: $_ } );
        }
        # note "!!! PLUG CLASSES: ", %!registry<plug-classes>;
        %!registry<extended-classes>:delete; # Must be rebuild later
    }
    multi method register-plug ( Mu:U \plug-class, Mu:U \extending ) {
        self.register-pluggable( extending );
        self.register-plug( plug-class, extending => extending.^name.list );
    }
    multi method register-plug ( Mu:U \plug-class, @extending ) {
        self.register-plug( plug-class, extending => @extending.map: { $_ ~~ Str ?? $_ !! $_.^name } );
    }

    # Record manager-generated classes
    method register-autogen-class ( Str:D $class ) {
        %!registry<inventory><autogen-classs> ∪= $class;
    }

    method pluggable-classes ( --> List ) {
        OO::Plugin::Registry::_classes::.keys
    }

    proto method is-pluggable (|) {*}
    multi method is-pluggable ( Mu:U \type --> Bool:D ) {
        OO::Plugin::Registry::_classes::{ type.^name }:exists
    }
    multi method is-pluggable ( Str:D $class --> Bool:D ) {
        OO::Plugin::Registry::_classes::{ $class }:exists
    }
    multi method is-pluggable ( Str:D $class, Str:D $method --> Bool:D ) {
        %!registry<pluggables><methods>{ $class }{ $method }:exists
    }

    method type ( Str:D $class-name --> Mu:U ) {
        OO::Plugin::Registry::_classes::{ $class-name }
    }

    proto method short2fqn (|) {*}
    multi method short2fqn ( Str:D $what where * ~~ 'classes' | 'plugins', Str:D $name --> Str:D ) {
        self!build-name-map;
        %!registry<name-map>{ $what }<short2fqn>{ $name } // $name
    }
    multi method short2fqn ( Str:D :$plugin --> Str:D ) {
        samewith( 'plugins', $plugin );
    }
    multi method short2fqn ( Str:D :$class --> Str:D ) {
        samewith( 'classes', $class );
    }
    # multi method short2fqn ( *%what where *.keys.elems == 1 --> Str:D ) {
    #     for %what.kv -> $what, $name {
    #         return samewith( $what, $name );
    #     }
    # }

    proto method fqn2short (|) {*}
    multi method fqn2short( Str:D $what, Str:D $name --> Str:D ) {
        self!build-name-map;
        %!registry<name-map>{ $what }<fqn2short>{ $name } // $name
    }
    # multi method fqn2short( *%what where *.keys.elems == 1 --> Str:D ) {
    #     for %what.kv -> $what, $name {
    #         samewith( $what, $name );
    #     }
    # }
    multi method fqn2short ( Str:D :$plugin --> Str:D ) {
        samewith( 'plugins', $plugin )
    }
    multi method fqn2short ( Str:D :$class --> Str:D ) {
        samewith( 'classes', $class )
    }

    method fqn-class-name ( Str:D $name ) {
        self.short2fqn( <classes>, $name )
    }

    method fqn-plugin-name ( Str:D $name ) {
        self.short2fqn( <plugins>, $name )
    }

    method has-autogen-class ( Str:D $class --> Bool ) {
        ? %!registry<inventory><autogen-class>{ $class }
    }

    method !deep-clone ( $element ) {
        return $element unless $element.defined;
        $element.deepmap: {
            $_ ~~ Mu:U ?? $_ !! $_.clone
        }
    }

    method !build-name-map {
        sub gen-maps ( @type-list ) {
            # note "   \$";
            my %map;
            %map<short2fqn> = @type-list.map( { .^shortname => .^name } ).Hash;
            %map<fqn2short> = %map<short2fqn>.invert.Hash;
            # note "NAME MAP:", %map;
            %map
        }

        %!registry<name-map><classes> //= gen-maps( OO::Plugin::Registry::_classes::.values );
        %!registry<name-map><plugins> //= gen-maps( self.plugin-types );
    }

    method !build-extended-classes {
        # note ">>> PLUG     CLASSES: ", %!registry<plug-classes>.perl;
        for %!registry<plug-classes>.kv -> $plugin, %plugs {
            for %plugs.kv -> $plug-name, $plug-data  {
                for $plug-data<extends>.keys {
                    # Class name comes from a user and this could end up being in short form.
                    # Plugin name comes in FQN form already because it is taken from a type.
                    # note "    >>> Mapping $_: ", self.fqn-class-name: $_;
                    %!registry<extended-classes>{ self.fqn-class-name: $_ }{ $plugin }.push: $plug-data<type>;
                }
            }
        }
        # note "!!! PLUG     CLASSES: ", %!registry<plug-classes>.perl;
        # note "!!! EXTENDED CLASSES: ", %!registry<extended-classes>.perl;
    }

    method registry ( --> Hash:D ) {
        self!deep-clone( %!registry )
    }

    method plugs ( --> Hash:D ) {
        self!deep-clone( %!registry<plugs> //= {} )
    }

    method methods ( --> Hash:D ) {
        self!deep-clone( %!registry<plugs><methods> //= {} )
    }

    method pluggables ( --> Hash:D ) {
        self!deep-clone( %!registry<pluggables> //= {} )
    }

    method extended-classes ( --> Hash:D ) {
        self!build-extended-classes unless %!registry<extended-classes>:exists;
        self!deep-clone( %!registry<extended-classes> // {} )
    }

    method plug-classes ( --> Hash:D ) {
        self!deep-clone( %!registry<plug-classes> //= {} )
    }

    method inventory ( --> Hash:D ) {
        self!deep-clone( %!registry<inventory> //= {} )
    }
}
