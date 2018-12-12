use v6;
use OO::Plugin;
unit module _T010::Plugin::Plug2;

our %meta =
    after => 'Plug1',
    ;

class Plug2 is Plugin is export {
}
