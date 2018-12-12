use v6;
use lib 't/lib';
use Test;
use OO::Plugin::Manager;
use Pluggable;
use _T010::Plugin::Plug1;

my $mgr = Manager.new( base => '_T010' );
$mgr.load-plugins;

$mgr = Manager.new( base => 'Foo' );
$mgr.load-plugins;

$mgr.init;

# vim: ft=perl6
