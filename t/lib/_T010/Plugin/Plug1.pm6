use v6;
unit class _T010::Plugin::Plug1;

use OO::Plugin;

our %meta =
    after => 'SomePlugin',
    requires => 'AnotherPlugin',
    ;

class TestPlug1 is Plugin {
}
