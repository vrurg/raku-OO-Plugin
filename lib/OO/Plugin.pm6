use v6;

module OO::Plugin:ver<0.0.0>:auth<cpan:VRURG> {
    use OO::Plugin::Exception;

    our proto plugin-meta (|) is export {*}
    multi plugin-meta ( *%meta ) {
        use OO::Plugin::Registry;
        Plugin::Registry.instance.plugin-meta( %meta, CALLER::<::?CLASS> )
    }
    multi plugin-meta ( %meta ) {
        use OO::Plugin::Registry;
        Plugin::Registry.instance.plugin-meta( %meta, CALLER::<::?CLASS> )
    }

    sub plug-last ( $rc? ) is export {
        CX::Plugin::Last.new(
            plugin => $*CURRENT-PLUGIN,
            :$rc,
        ).throw
    }
}

sub EXPORT {
    use nqp;
    use NQPHLL:from<NQP>;
    use OO::Plugin::Class;
    use OO::Plugin::Registry;
    use OO::Plugin::Declarations;
    use OO::Plugin::Metamodel::PluginHOW;
    use OO::Plugin::Metamodel::PlugRoleHOW;

    my role PluginGrammar {
        token package_declarator:sym<plugin> {
            :my $*OUTERPACKAGE := self.package;
            :my $*PKGDECL := 'plugin';
            :my $*LINE_NO := HLL::Compiler.lineof(self.orig(), self.from(), :cache(1));
            :my $*CURRENT-PLUGIN-CLASS; # Must be set by corresponding HOW
            <sym><.kok> <package_def>
            <.set_braid_from(self)>
        }

        token package_declarator:sym<plug-class> {
            :my $*OUTERPACKAGE := self.package;
            :my $*PKGDECL := 'role';
            :my $*LINE_NO := HLL::Compiler.lineof(self.orig(), self.from(), :cache(1));
            :my $*IN-PLUG-CLASS = True;
            :my @*PLUG-CLASS-EXTENDING;
            <sym><.kok>
            {
                self.panic( "plug-class must only be declared within scope of a plugin" )
                    unless try $*CURRENT-PLUGIN-CLASS.HOW ~~ OO::Plugin::Metamodel::PluginHOW;
                $*LANG.set_how('role', OO::Plugin::Metamodel::PlugRoleHOW);
            }
            <package_def>
            <.set_braid_from(self)>
            {
                # XXX Possible problem if package_def fails - not sure if role's HOW would be restored.
                $*LANG.set_how('role', Metamodel::ParametricRoleHOW);
            }
        }

        rule trait_mod:sym<for> {
            [ <sym> { $*IN-PLUG-CLASS || self.panic( "modificator 'for' is only applicable to a plug-class" ) } ]
            $<for-list>=( <longname> | <.panic("Expecting a class name here")> )+ % ','
        }
    }

    my role PluginActions {

        sub mkey ( Mu $/, Str:D $key ) {
            nqp::atkey(nqp::findmethod($/, 'hash')($/), $key)
        }

        method package_declarator:sym<plugin>(Mu $/) {
            $/.make( mkey($/, 'package_def').ast );
        }

        method package_declarator:sym<plug-class>(Mu $/) {
            $/.make( mkey($/, 'package_def').ast );
        }

        method trait_mod:sym<for> (Mu $/) {
            my @for-list = mkey( $/, 'for-list' );
            for @for-list -> $type {
                with mkey( $type, 'longname' ) {
                    @*PLUG-CLASS-EXTENDING.push: .Str;
                }
            }
        }
    }

    unless $*LANG.^does( PluginGrammar ) {
        $*LANG.set_how( 'plugin', OO::Plugin::Metamodel::PluginHOW );
        $ = $*LANG.define_slang(
            'MAIN',
            $*LANG.HOW.mixin( $*LANG.WHAT, PluginGrammar ),
            $*LANG.actions.^mixin(PluginActions)
        );
    }


    return %(
        OO::Plugin::Declarations::EXPORT::ALL::,
        'Plugin' => Plugin,
        'PlugRecord' => PlugRecord,
        # '&plugin-meta' => &OO::Plugin::plugin-meta,
    );
}
