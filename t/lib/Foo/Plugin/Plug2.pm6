use v6;
use OO::Plugin;
unit module Foo::Plugin::Plug2;

plugin Plug2:ver<0.2.2> {
    our %meta =
        after => <Plug1 Foo::Plugin::Test>,
        name => 'Plug2',
        ;
}
