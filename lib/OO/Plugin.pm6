use v6;

module OO::Plugin:ver<0.0.0>:auth<cpan:VRURG> {
    our proto plugin-meta (|) {*}
    multi plugin-meta ( *%meta ) {
        use OO::Plugin::Registry;
        note "PLUGIN META *: ", %meta;
        Plugin::Registry.instance.plugin-meta( %meta, CALLER::<::?CLASS> )
    }
    multi plugin-meta ( %meta ) {
        use OO::Plugin::Registry;
        note "PLUGIN META  : ", %meta;
        Plugin::Registry.instance.plugin-meta( %meta, CALLER::<::?CLASS> )
    }
    multi plugin-meta ( |c ) {
        note "PLUGIN META  : ", c.perl;
    }
}

my package EXPORTHOW {
    package DECLARE {
        use OO::Plugin::Metamodel::PluginHOW;
        constant plugin = OO::Plugin::Metamodel::PluginHOW;
    }
}

sub EXPORT {
    use OO::Plugin::Class;
    use OO::Plugin::Registry;
    use OO::Plugin::Declarations;
    return %(
        OO::Plugin::Declarations::EXPORT::ALL::,
        'Plugin' => Plugin,
        '&plugin-meta' => &OO::Plugin::plugin-meta,
    );
}
