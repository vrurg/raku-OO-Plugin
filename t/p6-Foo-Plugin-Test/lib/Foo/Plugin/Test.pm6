use v6.d;
unit module Foo::Plugin::Test;
use OO::Plugin;

plugin TestPlugin {
    our %meta =
        after => <SomePlugin>,
        ;
}

plugin Sample {
    our %meta;
}
