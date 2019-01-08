use v6;
BEGIN {
    # Test plugin distro must be pre-installed before anything else or it won't be found by plugin manager.
    use lib 'build-tools/lib';
    use OOPTest;
    use Test;
    install-distro( './t/p6-Foo-Plugin-Test' ) or flunk "failed to install plugin distro";
}
use lib <t/lib build-tools/lib inst#.test-repo>;
use Test;
use OOPTest;
use OO::Plugin::Manager;
use OO::Plugin;
use Data::Dump;

plan 1;

# require ::("Foo::Plugin::Test");
# my \tt = ::("Foo::Plugin::Test");
# note ">>>>", tt::.keys;
# note "----", ::("Foo::Plugin")::Test.keys;
# note "++++", Foo::Plugin::Test.keys;

my $mgr = OO::Plugin::Manager.new( base => 'Foo' );
$mgr.load-plugins;

# diag Dump $mgr.meta( 'Foo::Plugin::Test' ), :!color, :skip-methods;
# diag Dump $mgr.info( 'Foo::Plugin::Test' ), :!color, :skip-methods;
# diag $mgr.info('Plug2')<version> // "*unversioned*";

$mgr.initialize;

my $registry = Plugin::Registry.instance;

ok <Sample TestPlug1 TestPlugin Plug2>.Set == $registry.plugin-types.map( { $mgr.short-name( $_.^name ) } ).Set, "plugin modules are loaded";

done-testing;

# vim: ft=perl6
