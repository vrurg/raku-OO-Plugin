use v6.d;
use lib './t';

use OO::Plugin;
use OO::Plugin::Manager;

class Foo is pluggable {
    method foo is pluggable {
        note "method foo";
        return pi;
    }

    proto method bar (|) is pluggable {*}
    multi method bar ( Str:D $s ) { note "! String $s"; "++" ~ $s }
    multi method bar ( Int:D $i ) { note "! Int $i"; -$i }
}

plugin Bar {
    method bar ( $record ) is plug-before( 'Foo' => 'bar' ) {
        note "? BEFORE Foo::bar";
        $record.private = { :mine<value> };
        $record.shared<Bar> = "Do me a favor, please!";
    }

    method a-bar ( $record ) is plug-around( :Foo<bar> ) {
        note "? AROUND Foo::bar";
        note $record.private;
        plug-last "KA-BOOM!";
    }

    method foo ( $record ) is plug-around( :Foo<foo> ) {
        note "? AROUND Foo::foo";
        $record.set-rc( 42 );
    }
}

plugin Baz {
    method a-bar ( $record ) is plug-after( :Foo<bar> ) is plug-before( :Foo<bar> ){
        note "? DO SOME {$record.stage} work for Foo::bar";
        note $record.private;
        note $record.shared;
    }
}

my $mgr = OO::Plugin::Manager.new( base => 'Foo' );
$mgr.load-plugins;
$mgr.initialize;

my $c = $mgr.class(Foo);
note $c.^name;
my $inst = $c.new;
note "bar returned: ", $inst.bar( "oki-doki" );
note "bar returned: ", $inst.bar( 42 );
note "foo returned: ", $inst.foo;
