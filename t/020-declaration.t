use v6.d;
use lib './t';

use OO::Plugin;

class Foo is pluggable {
    method foo is pluggable {
        note "method foo";
    }

    proto method bar (|) is pluggable {*}
    multi method bar ( Str:D $s ) { note "String $s" }
    multi method bar ( Int:D $i ) { note "Int $i" }
}

class Bar is Foo {
    method bar (|c) {
        note "Bar::bar";
        callwith( |c );
    }
}

Bar.new.bar("aaa");
Bar.new.bar(12);
