use v6.d;
unit class OO::Plugin::Metamodel::PluginHOW is Metamodel::ClassHOW;
use OO::Plugin::Class;
use OO::Plugin::Registry;

method new_type ( :$name, |params ) {
    # In hope that compilation doesn't take advantage of multi-threading...
    $*CURRENT-PLUGIN-CLASS = callsame
}

method compose ( Mu \type, :$compiler_services ) {
    self.add_parent( type, Plugin );
    my \rc = callsame;
    Plugin::Registry.instance.register-plugin( type );
    rc
}
