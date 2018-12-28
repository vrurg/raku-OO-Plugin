use v6;
use OO::Plugin;
unit module Foo::Plugin::Plug2;

plugin Plug2:ver<0.2.2> {
    our %meta =
        after => <Plug1 Foo::Plugin::Test>,
        name => 'Plug2',
        ;

    method my-handler (|) is plug-after( 'Int' => 'repeat' ) {
        note "C'mon!";
    }

    method type-handler (|) is plug-after{ class => Int, method => 'repeat' } {
        note "C'mon!";
    }
}
