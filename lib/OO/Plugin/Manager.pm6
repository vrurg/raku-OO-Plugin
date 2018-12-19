use v6.d;
unit class OO::Plugin::Manager:auth<CPAN:VRURG>:ver<0.0.0>:api<0>;
use File::Find;
use JSON::Fast;
use Data::Dump;
use OO::Plugin::Metamodel::PluginHOW;
use OO::Plugin::Registry;

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

# Three keys with list of plugins: first, normal, last
# Each will later get corresponding priority: plugFirst, plugNormal, plugLast
has %!user-order;

# Maps short names to module and vice versa.
has %!name-map;

# Map of plugins into other plugins requiring them.
has %!required-by;

# Plugin objects – instantiated plugin classes.
has @!objects;

# Plugin registry instance
has $!registry;

submethod TWEAK {
    $!registry = Plugin::Registry.instance;
}

method name2fqn ( Str:D $name ) { %!name-map<name2fqn>{ $name } }
method fqn2name ( Str:D $fqn  ) { %!name-map<fqn2name>{ $fqn }  }

method normalize-name ( Str:D $plugin --> Str ) {
    return $plugin with %!mod-info{ $plugin };
    return $_ with self.name2fqn( $plugin );
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
        require ::($mod);

        CATCH {
            default {
                note "Module load failed: ", ~$_, $_.backtrace.full if $!debug;
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

method initialize ( --> Nil ) {
    for %!mod-info.keys -> $mod {
        next if self.disabled( $mod );
        @!objects.push: %!mod-info{ $mod }<type>.new( plugin-manager => self );
    }

    note .WHAT for @!objects;
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

method !rebuild-caches {
    self!rebuild-name-map;
    self!rebuild-requirements;
}

method !rebuild-name-map {
    # Map short name into FQN
    %!name-map<short2fqn> = $!registry.plugin-types.map( { .^shortname => .^name } ).Hash;
    %!name-map<fqn2short> = %!name-map<short2fqn>.invert.Hash;
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

# Rebuild %!required-by
method !rebuild-requirements {
    %!required-by = ();
    for %!mod-info.keys -> $fqn {
        with %!mod-info{$fqn}<meta><requires> {
            note "$fqn requires: ", %!mod-info{$fqn}<meta><requires>;
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
