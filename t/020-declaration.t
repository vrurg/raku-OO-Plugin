use v6.d;
use lib './t';

module Some::Plugin::Probe {
    use OO::Plugin;

    class Foo {}

    plugin MyPlugin is Foo {
        has $.data;

        our %meta =
            after => <Plug1>,
            ;
    }
}
