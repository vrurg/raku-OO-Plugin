use v6;
unit class Manager:auth<CPAN:VRURG>:ver<0.0.0>:api<0>;
use Pluggable;
use File::Find;
use JSON::Fast;

constant $PLUGIN-JSON = "PLUGIN.json";

has Str $.base is required;
has @.namespaces = <Plugin Plugins>;
#| Callback to validate plugin module before trying to load it.
has &.validator where * ~~ :( Str $ --> Bool );

# :moduleName("text reason")
# Reason could later be extended if necessary to be a structure
has %!disabled;

# Plugin modules metadata. Hash of hashes of attributes:
# 'A::Plugin::Sample' => {
#       meta-file => "/path/to/resources/PLUGIN.json",
#       other-info => ...,
# },
has %!mod-info;

# Meta-data fetched from both PLUGIN.json and module's %meta
# This attribute may not contain any generated data – only what comes from PLUGIN.json or plugin module's %meta
has %!mod-meta;

method !find-modules {
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
                                    %!mod-info{ $mod-name } = {
                                        prefix => $r.prefix;
                                    }
                                }
                            }
                            when / resources $ / {
                                # When loading resources measures must be taken to avoid overriding other modules
                                # metadata by allowing to have module names in PLUGIN.json other than the full path to
                                # the file suggests.
                                # For example, for ./lib/Some/Mod/resources/PLUGIN.json don't allow defining meta for
                                # Another::Mod::*
                                my $mod-prefix = $*SPEC.splitdir( $_ )[ $dircount..*-2 ].join('::') ~ "::";
                                with $*SPEC.catfile( $_, $PLUGIN-JSON ).IO {
                                    if .f {
                                        my %meta = from-json( .open.slurp );
                                        # Filter out non-conforming keys
                                        %!mod-meta{ $_ } = %meta{ $_ } for grep { / ^ $mod-prefix / }, %meta.keys;
                                    }
                                }
                            }
                        }
                    }
                }
                when CompUnit::Repository::Installation {
                    next unless .installed;
                    my @bases = @.namespaces.map: { $!base ~ '::' ~ $_ };
                    for .installed -> $distro {
                        my %meta;

                        # Pre-load meta
                        if $distro.meta<resources>.list.grep: $PLUGIN-JSON { # .content doesn't check for file existance
                            %meta = from-json $distro.content( "resources/$PLUGIN-JSON" ).slurp;
                        }

                        for $distro.meta<provides>.keys.grep( rx/ ^ @bases / ) -> $module {
                            %!mod-info{ $module } = {
                                    distro => $distro,
                            };
                            # Only fetch meta for installed modules, skip all other
                            %!mod-meta{ $module } = $_ with %meta{ $module };
                        }
                    }
                }
            }
        }
    }
}

method load-plugins {
    self!find-modules;
    MOD:
    for %!mod-info.keys -> $mod {
        note "Loading $mod";
        with &!validator {
            next MOD unless &!validator( $mod );
        }
        require ::($mod);
        note "LOADED ", $mod;

        # Keys from plugin module's %meta override keys from JSON data
        with ::("$mod\::\%meta") {
            %!mod-meta{ $mod }{ .keys } = .values;
        }

        # If class is not defined then use module name.
        # NOTE: Mind the comment for %!mod-meta: we don't modify it!
        %!mod-info{ $mod }<class> = %!mod-meta{ $mod }<class>;
        %!mod-info{ $mod }<class> //= $mod if ::($mod).HOW ~~ Metamodel::ClassHOW;

        with %!mod-info{ $mod }<class> {
            note "CLASS NAME IS ", $_;
            my $type;
            for ("", "$mod\::", "$mod\::EXPORT::DEFAULT::") -> $pfx {
                last unless ( $type = ::("$pfx$_") ) ~~ Failure;
            }
            %!mod-info{ $mod }<type> = $type;
            note "CLASS: ", $type.WHAT;
        } else {
            note "DISABLING $mod: no class defined";
            self.disable($mod, "Plugin class is not defined for this module");
        }

        CATCH {
            default {
                self.disable( $mod, ~$_ ~ $_.backtrace );
                note "DISABLING $mod: ", %!disabled{$mod};
            }
        }
    }
}

method disable (Str:D $name, Str:D $reason) {
    %!disabled{ $name } = $reason;
}

method disabled ( Str:D $name ) {
    ? %!disabled{ $name }
}

method init {
    for %!mod-info.keys -> $mod {
        next if self.disabled( $mod );
        my $plug = %!mod-info{$mod}<type>.new;
        note "CREATED ", $plug.WHAT if $plug;
    }
}
