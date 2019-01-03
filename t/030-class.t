use v6.d;
use OO::Plugin;
use lib './t';
use Test;
use OO::Plugin::Manager;

module Tester {
class Foo is pluggable {
    method foo is pluggable {
        note "method foo";
        return pi;
    }

    proto method bar (|) is pluggable {*}
    multi method bar ( Str:D $s ) { note "! String $s"; "++" ~ $s }
    multi method bar ( Int:D $i ) { note "! Int $i"; -$i }
}

class A2 is pluggable {

}

plugin Fubar demand PluginA, PluginB {
    plugin-meta demand => 'PluginC', name => 'Fubarus';
    plug-class Bar for Tester::Foo, A1, A2 is for( <Foo Another>, Foo ) {
        method bar (|) {
            note $?PACKAGE.^name, "::", &?ROUTINE.name;
            callsame;
        }
    }
}

plugin Чудернацький after Fubar, P1, P2 {
    plug-class Працівник for Tester::Foo {
        method bar (|) {
            note "Працює ", $?PACKAGE.^name, "::", &?ROUTINE.name;
            callsame;
        }
    }
}
}

my $mgr = OO::Plugin::Manager.new( base => 'Foo' );
$mgr.load-plugins;
$mgr.initialize;

my \c := $mgr.class(Tester::Foo);
note "CREATED CLASS: ", c.^name, ": ", c.^mro;

my $inst = c.new;

note ">>>>>>> CALL bar";
$inst.bar(42);
note "<<<<<<< bar ok";

note "plug-class Bar is from ", Tester::Fubar::Bar.^candidates[0].^plugin;
note "plug-class Працівник is from ", Tester::Чудернацький::Працівник.^candidates[0].^plugin;

done-testing;
