use v6.d;
use lib './t';
use Test;
use OO::Plugin;
use OO::Plugin::Manager;

plan 42;

class Foo is pluggable {
    method foo is pluggable {
        flunk "method foo is unexpectedly executed";
        return pi;
    }

    proto method bar (|) is pluggable {*}
    multi method bar ( Str:D $s ) { "++" ~ $s }
    multi method bar ( Int:D $i ) { -$i }
}

plugin Bar {
    method bar ( $record ) is plug-before( 'Foo' => 'bar' ) {
        pass 'before &Foo::bar';
        $record.private = { :mine<private string> };
        $record.shared<Bar> = "Do me a favor, please!";
    }

    method a-bar ( $record ) is plug-around( :Foo<bar> ) {
        pass 'around &Foo::bar';
        is $record.private<mine>, 'private string', "private value is passed between method handlers";
        my $param = $record.params.list[0];
        plug-last "KA-BOOM!" if $param ~~ Int and $param !~~ 42; # Not The Right Answer
    }

    method foo ( $record ) is plug-around( :Foo<foo> ) {
        pass 'around &Foo::foo';
        $record.set-rc( 42 ); # This will prevent the original method from being called
    }
}

plugin Baz before Bar {
    method a-bar ( $record ) is plug-after( :Foo<bar> ) is plug-before( :Foo<bar> ){
        pass "stage {$record.stage} of \&Foo::bar";
        # note "? DO SOME {$record.stage} work for Foo::bar";
        nok $record.private.defined, "private is not set in this plugin";
        given $record.stage {
            when 'before' {
                is-deeply $record.shared, {}, "shared data comes from Bar plugin, but it's not called yet";
            }
            when 'after' {
                is $record.shared<Bar>, "Do me a favor, please!", "shared data comes from Bar plugin";
            }
        }
    }

    my PlugRecord $rr;

    # The declaration:
    #
    # proto method fubar ( $ ) is plug-around(:Foo<foo>) {*}
    #
    # means passing only of PlugRecord instance. Anything else will cause the handler to receive all method arguments
    # following the $record. This would simplify dispatching.
    proto method fubar ( $, | ) is plug-around(:Foo<foo>) {*}
    multi method fubar ( $record ) {
        pass "multi-dispatch around handler of foo: no parameters";
    }
    multi method fubar ( $record, Str $s ) {
        pass "multi-dispatch around handler of foo: string parameter";
        if $record.private<passed> {
            pass "second-pass after redo";
        }
        else {
            $record.private<passed> = True;
            pass "initiating plug-redo";
            plug-redo;
        }
    }

    method a-foo ( $record ) is plug-after( :Foo<foo> ) {
        if $record.private<passed> {
            pass "after Foo::foo handler modifies return value after REDO";
            $record.set-rc( "The answer is " ~ $record.rc );
        }
    }
}

my $mgr = OO::Plugin::Manager.new( :!debug );
$mgr.load-plugins;
$mgr.initialize;

my $c = $mgr.class(Foo);
isnt $c.^name, "Foo", "class is overriden";
my $inst = $c.new;
is $inst.bar( "oki-doki" ), '++oki-doki', "bar string return value: untouched original";
is $inst.bar( 42 ), -42, "bar return for param 42: untouched by plugin";
is $inst.bar( 41 ), "KA-BOOM!", "bar return for params 41: KA-BOOM! from plugin";
is $inst.foo, 42, "42 returned from handler";
is $inst.foo( "OK" ), "The answer is 42", "returned value modified by 'after' handler";

done-testing;
