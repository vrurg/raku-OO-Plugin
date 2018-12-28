use v6.d;
unit class OO::Plugin::Manager:auth<CPAN:VRURG>:ver<0.0.0>:api<0>;
use File::Find;
use JSON::Fast;
use Data::Dump;
use OO::Plugin::Metamodel::PluginHOW;
use OO::Plugin::Registry;
use OO::Plugin::Class;
use OO::Plugin::Exception;

my class X::OO::Plugin::NotFound is Exception {
    has $.plugin;

    method message {
        "No plugin '$!plugin' found"
    }
}

enum PlugPriority is export <plugLast plugNormal plugFirst>;

# --- ATTRIBUTES

has Bool $.debug is rw = True;

has Str $.base is required;
has @.namespaces = <Plugin Plugins>;
#| Callback to validate plugin module before trying to load it.
has &.validator is rw where * ~~ :( Str $ --> Bool );

#| In strict mode non-pluggable classes/methods cannot be overriden.
has Bool $.strict = False;

# List of hashes of:
#  'Module::Name' => "Error String"
has @.load-errors;

# :moduleName("text reason")
# Reason could later be extended if necessary to be a structure
has %!disabled;

# Plugin modules metadata. Hash of hashes of attributes:
# 'A::Plugin::Sample' => { # First level keys must always be plugin's FQN
# Type object corresponding to the class
#       type => TypeObject,
# Plugin meta-data fetched from it's %meta
#       meta => { meta-key => "meta-value", ... },
# Plugin version
#       version => v0.0.1,
# },
has %!mod-info;

# Order of plugins
has @!order;

# Three keys with list of plugins: first, normal, last
# Each will later get corresponding priority: plugFirst, plugNormal, plugLast
has %!user-priority;

# Map of plugins into other plugins requiring them.
has %!required-by;

# Plugin objects – instantiated plugin classes.
has %!objects;

# Plugin registry instance
has $!registry;

# Caches
has %!cached;

submethod TWEAK {
    $!registry = Plugin::Registry.instance;
}

method normalize-name ( Str:D $plugin --> Str ) {
    return $plugin with %!mod-info{ $plugin };
    return $_ with $!registry.fqn-plugin-name( $plugin );
    fail X::OO::Plugin::NotFound.new( :$plugin );
}

method meta ( Str:D $plugin --> Hash ) {
    my $fqn = self.normalize-name( $plugin );
    # $fqn would contain Failure if the name cannot be normalized.
    return $fqn unless $fqn;

    %!mod-info{ $fqn }<meta>.clone
}

method info ( Str:D $plugin --> Hash ) {
    my $fqn = self.normalize-name( $plugin );
    # $fqn would contain Failure if the name cannot be normalized.
    return $fqn unless $fqn;

    %!mod-info{ $fqn }.clone
}

proto method set-priority (|) {*}

multi method set-priority ( @plugins, PlugPriority:D $priority = plugNormal ) {
    %!mod-info{ self.normalize-name( $_ ) }<priority> = $priority for @plugins;
}

multi method set-priority ( Str:D $plugin, PlugPriority:D $priority = plugNormal ) {
    samewith( @$plugin, $priority )
}

multi method set-priority ( *@plugins, PlugPriority:D :$priority = plugNormal ) {
    samewith( @plugins, $priority )
}

method load-plugins ( --> True ) {
    my @mods = self!find-modules;
    MOD:
    for @mods -> $mod {
        with &!validator {
            next MOD unless &!validator( $mod );
        }
        # note "++++++++ TRYING $mod";
        require ::($mod);

        CATCH {
            default {
                # note "Module load failed:\n", ~$_, $_.backtrace.full, "----------------------" if $!debug;
                @!load-errors.push: $mod => ~$_ ~ ( $!debug ?? $_.backtrace !! "");
            }
        }
    }

    for $!registry.plugin-types -> \type {
        my $fqn = type.^name;
        # Keys from plugin module's %meta override keys from the registry module

        %!mod-info{ $fqn }<meta> = $!registry.plugin-meta( type );

        with type::<%meta> {

            sub fix-meta ( %meta --> Hash(Seq) ) {
                gather for %meta.keys -> $key {
                    given $key {
                        when 'after' | 'before' | 'requires' {
                            take $key => %meta{ $key }.Array;
                        }
                        default {
                            take $key => %meta{ $key };
                        }
                    }
                }
            }

            %!mod-info{ $fqn }<meta>{ .keys } = .values with fix-meta( $_ );
        }

        %!mod-info{ $fqn }<type> = type;
        %!mod-info{ $fqn }<version> = %!mod-info{ $fqn }<meta><version> // $_ with type.^ver;
    }

    self!rebuild-caches;
}

proto method disable (|) {*}

multi method disable ( Str:D $plugin, Str:D $reason ) {
    %!disabled{ self.normalize-name: $plugin } = $reason;
}

multi method disable ( @plugins, Str:D $reason ) {
    %!disabled{ self.normalize-name: $_ } = $reason for @plugins;
}

multi method disable ( *@plugins, Str:D :$reason ) {
    samewith( @plugins, $reason )
}

method disabled ( Str:D $name ) {
    %!disabled{ self.normalize-name: $name }
}

# Returns a Seq of ordered plugin objects
method plugin-objects {
    @!order.map: { %!objects{ $_ } }
}

method initialize ( --> Nil ) {
    self!build-order;

    for @!order -> $plugin {
        next if self.disabled( $plugin );
        %!objects{ $plugin } = %!mod-info{ $plugin }<type>.new( plugin-manager => self );
    }

    .?initialize for self.plugin-objects;
}

method class ( Any:U \type --> Any:U ) {

    return %!cached<types>{ type.^name } if %!cached<types>{ type.^name }:exists;

    my Mu:U $plug-class;
    if !$.strict or $!registry.is-pluggable( type ) {
        # Force-register class as pluggable to allow for later short<->fqn name transofrmations
        $!registry.register-pluggable( type );
        $plug-class := self!build-class( type );
    }
    else {
        # Leave non-pluggable classes alone.
        $plug-class := type;
    }

    %!cached<types>{ type.^name } = $plug-class;
}

method create ( Any:U \type, |params ) {
    my \wrapped-class = self.class( type );
    wrapped-class.new( |params )
}

method !find-modules ( --> Array(Seq) ) {
    gather {
        for $*REPO.repo-chain -> $r {
            given $r {
                when CompUnit::Repository::FileSystem {
                    my @bases = @.namespaces.map: { $*SPEC.catdir( ( $!base ~ '::' ~ $_ ).split( '::' ) ) };
                    # Get number of elements in the base prefix – to drop them off later and form pure module path and
                    # name.
                    my $dircount = $*SPEC.splitdir( $r.prefix ).elems;
                    for find( dir => .prefix, type => 'dir', exclude => rx{ [ '/' || ^^ ] '.precomp'}, :keep-going ) -> $dir {
                        given $dir {
                            when / @bases $ / {
                                for .dir.grep: { .f } -> $path {
                                    my $mod-name =
                                        $*SPEC.splitdir( $path.extension( "", joiner => "" ) )[ $dircount..* ]
                                              .join( '::' );
                                    take $mod-name;
                                }
                            }
                        }
                    }
                }
                when CompUnit::Repository::Installation {
                    next unless .installed;
                    my @bases = @.namespaces.map: { $!base ~ '::' ~ $_ };
                    for .installed -> $distro {
                        for $distro.meta<provides>.keys.grep( rx/ ^ @bases / ) -> $module {
                            take $module;
                        }
                    }
                }
            }
        }
    }
}

method !pre-sort {
    my @mods = %!mod-info.keys;

    my $count = @mods.elems;

    # Define priority ranges.
    my $high = 0;
    my $required = $high + $count;
    my $normal = $required + $count;
    my $low = $normal + $count;

    my %levels = @mods.map( * => $normal++ ).Hash;

    # For all required modules shift priority by count – thus they will effectively get into $required range.
    %levels{ $_ } -= $count for %!required-by.keys;

}

method !build-order {
    # Will later do sorting, etc. For now just get in any order skipping all disabled
    @!order = %!mod-info.keys.grep( { !self.disabled: $_ } );
}

method !autogen-class-name ( Str:D $base ) {
    my $name;
    repeat {
        $name = $base ~ "_" ~ ( ('a'..'z', 'A'..'Z', '0'..'9').flat.pick(6).join );
    } while $!registry.has-autogen-class( $name ); # Be on the safe side, however small are the changes for generating same class name again
    $!registry.register-autogen-class( $name );
    $name
}

# Parameters: wrapped-type, original type
method !build-class-chain ( Mu:U \wtype, Mu:U \type --> Mu:U ) {

    # Build list of plug-classes for this type
    my $type-name = type.^name;
    my %type-ext = $!registry.extended-classes{ $type-name } // {};

    my $last-class := type;

    if %type-ext {
        for @!order -> $fqn {
            # note "??? TYPE EXT for $type-name of $fqn: ", %type-ext;
            with %type-ext{ $fqn } {
                for $_.list -> \plug-class {
                    # note " Plugin $fqn extends $type-name with ", plug-class.^name, " // ", plug-class.HOW;
                    my $name = self!autogen-class-name( plug-class.^name );
                    # note "AUTOGEN CLASS: ", $name;
                    my \pclass = Metamodel::ClassHOW.new_type( :$name );
                    pclass.^add_parent( $last-class );
                    pclass.^add_role( plug-class );

                    pclass.^compose;

                    $last-class := pclass;
                }
            }
        }
    }

    # The wrapper's class my-plugin will
    my &plugin-method = my submethod {
        my $caller;
        my $skip = True;
        for Backtrace.new.list {
            next unless .code.^can('package');
            $skip &&= .package !=== $?CLASS;
            next if $skip;
            ( $caller = $_ ) && last if .package !=== $?CLASS;
        }
        # TODO Return plugin object when wrapper class gets .plugin-manager attribute
        my \plugin = $caller.package.^plugin;
    };
    &plugin-method.set_name('plugin');
    wtype.HOW.add_parent( wtype, $last-class );
}

# build-class is supposed to be called for unprocessed classes only.
method !build-class ( Mu:U \type --> Mu:U ) {

    my $type-name = type.^name;
    my %methods = $!registry.methods{ $type-name } // {};
    my $wrapper-name = self!autogen-class-name( $type-name );
    my \wtype = Metamodel::ClassHOW.new_type( name => $wrapper-name );

    self!build-class-chain( wtype, type );

    for %methods.keys -> $mname {
        # note "GENERATING METHOD ", $mname;
        my %routines; # Ordered list of routines to be called for the methods. Keys are stages: before, around, after
        for @!order -> $fqn {
            with %methods{ $mname }{ $fqn } {
                for .keys -> $stage {
                    %routines{ $stage }.push: %(
                        routine => $_{ $stage },
                        plugin-fqn => $fqn,
                        plugin-obj => %!objects{ $fqn },
                    );
                }
            }
        }

        my &orig-method = type.^find_method( $mname );
        # note "Orig method signature: ", &orig-method.signature;
        # note "Orig method mutli: ", &orig-method.candidates;

        # --- WRAPPING METHOD GENERATION BEGINS
        my &plug-method = my method ( |params ) {
            my &callee = nextcallee;
            # note "Wrapper for method $mname on ", self.WHICH;
            my ( %shared, %by-plugin );

            my PlugRecord $record .= new(
                :object(self),
                :params(params),
                :%shared,
                :method($mname),
            );

            for <before around after> -> $stage {

                $record.stage = $stage;

                if %routines{ $stage } {
                    for %routines{ $stage }.List -> $r {
                        # This is where we actually call plugs.
                        my $*CURRENT-PLUGIN = $r<plugin-obj>;

                        $record.private = %by-plugin{ $r<plugin-fqn> };

                        $r<plugin-obj>.&( $r<routine> )( $record );

                        %by-plugin{ $r<plugin-fqn> } = $record.private; # Remember what's been set by the plugin (if was)
                        $record.private = Nil; # Just be on the safe side...

                        if $record.has-rc and $stage ~~ 'before' {
                            warn "Plugin `$r<plugin-fqn>` set return value for method $mname at 'before' stage";
                            $record.reset-rc;
                        }
                    }

                    CATCH {
                        when CX::Plugin::Last {
                            # note "*** 'LAST' CONTROL RAISED BY ", $_.plugin.^name;
                            $record.set-rc( $_.rc ) unless $stage ~~ 'before';
                        }
                        default { $_.rethrow }
                    }
                }

                given $stage {
                    when 'around' {
                        # Only call the original method if no rc is set.
                        if !$record.has-rc {
                            # note "Refer to the original";
                            # note "PARAMS: ", params;
                            $record.set-rc( self.&callee( |$record.params ) );
                        }
                    }
                }
            }

            $record.rc
        };
        # --- WRAPPING METHOD GENERATION ENDS

        &plug-method.set_name( $mname );

        wtype.^add_method(
            $mname,
            &plug-method
        );
    }

    wtype.^compose
}

method !rebuild-caches {
    self!rebuild-requirements;
}

# Rebuild %!required-by
method !rebuild-requirements {
    %!required-by = ();
    for %!mod-info.keys -> $fqn {
        with %!mod-info{$fqn}<meta><requires> {
            # note "$fqn requires: ", %!mod-info{$fqn}<meta><requires>;
            %!required-by.append: .Array.map( { self.normalize-name($_) => $fqn } );
            CATCH {
                when X::OO::Plugin::NotFound {
                    self.disable( $fqn, "Required plugin " ~ .plugin ~ " not found" );
                }
                default { .rethrow }
            }
        }
    }
}
