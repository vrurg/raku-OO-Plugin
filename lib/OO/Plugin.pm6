use v6;

my package EXPORTHOW {
    package DECLARE {
        use OO::Plugin::Metamodel::PluginHOW;
        constant plugin = OO::Plugin::Metamodel::PluginHOW;
    }
}

role OO::Pluggable is export {
}

sub EXPORT {
    use OO::Plugin::Class;
    use OO::Plugin::Registry;
    %(
        'Plugin' => 'Plugin',
        '&plugin-meta' => &plugin-meta,
    )
}
