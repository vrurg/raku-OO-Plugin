use v6;
use lib <t/lib build-tools/lib inst#.test-repo>;
use Test;
use OOPTest;
use OO::Plugin::Manager;
use Pluggable;
use Data::Dump;

ok install-distro( './t/p6-Foo-Plugin-Test' ), "test plugin installed";
#END wipe-repo;

require ::("Foo::Plugin::Test");
my \tt = ::("Foo::Plugin::Test");
note ">>>>", tt::.keys;
note "----", ::("Foo::Plugin")::Test.keys;
# note "++++", Foo::Plugin::Test.keys;

my $mgr = Manager.new( base => 'Foo' );
$mgr.load-plugins;

# diag Dump $mgr.meta( 'Foo::Plugin::Test' ), :!color, :skip-methods;
# diag Dump $mgr.info( 'Foo::Plugin::Test' ), :!color, :skip-methods;
# diag $mgr.info('Plug2')<version> // "*unversioned*";

$mgr.init;

# vim: ft=perl6
