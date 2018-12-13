use v6;
use Test;

sub install-distro ( Str:D $source, Str:D :$dest-dir = '.test-repo' --> Bool ) is export {
    $dest-dir.IO.mkdir;
    my %env = %*ENV;
    my @p6libs;
    @p6libs = .split(':') with %env<PERL6LIB>;
    %env<PERL6LIB> = (|@p6libs, './lib').join(':');
    my $proc = run "zef", "install", "--to=inst#$dest-dir", "--force", $source, :out, :err, :%env;
    unless $proc.exitcode == 0 {
        diag "'zef install' exit code:", $proc.exitcode;
        diag "Module install output:";
        diag "> Stdout:";
        diag $proc.out.slurp;
        diag "> Stderr:";
        diag $proc.err.slurp;
    }
    CATCH {
        default {
            diag "Temporary repository installation failed: " ~ $_ ~ $_.backtrace;
            return False;
        }
    }
    return $proc.exitcode == 0;
}

sub wipe-repo ( Str:D :$dest-dir = '.test-repo' --> Bool ) is export {
    my $proc = run "rm", "-rf", $dest-dir;
    return $proc.exitcode == 0;
}
