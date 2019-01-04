use v6;
use lib <t/lib build-tools/lib inst#.test-repo>;
use Test;
use OOPTest;
use OO::Plugin::Manager;
use OO::Plugin;
use Data::Dump;

plan 2;

ok install-distro( './t/p6-Foo-Plugin-Test' ), "test plugin installed";

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
