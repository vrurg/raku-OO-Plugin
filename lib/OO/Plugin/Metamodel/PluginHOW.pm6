use v6.d;
unit class OO::Plugin::Metamodel::PluginHOW is Metamodel::ClassHOW;
use OO::Plugin::Class;
use OO::Plugin::Registry;

method compose ( Mu \type, :$compiler_services ) {
    self.add_parent( type, Plugin );
    callsame;
    Plugin::Registry.instance.register-plugin( type );
}
