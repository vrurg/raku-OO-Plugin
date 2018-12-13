use v6;
use lib <t/lib build-tools/lib>;
use Test;
use OOPTest;
use OO::Plugin::Manager;
use Pluggable;
use _T010::Plugin::Plug1;

ok install-distro( './t/p6-Foo-Plugin-Test' ), "test plugin installed";
END wipe-repo;

my $mgr = Manager.new( base => '_T010' );
$mgr.load-plugins;

$mgr = Manager.new( base => 'Foo' );
$mgr.load-plugins;

$mgr.init;

# vim: ft=perl6
