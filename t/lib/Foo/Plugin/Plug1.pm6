use v6;
use OO::Plugin;

plugin TestPlug1:ver<0.0.1> {
    our %meta =
        after => 'SomePlugin',
        requires => 'AnotherPlugin',
        ;

    plugin-meta mykey => "my value", version => v1.2.3;
}
