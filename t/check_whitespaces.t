=encoding UTF-8

=head1 DESCRIPTION

Test checks if these space usage guidelines are executed in files.
Test checks every *.pm and *.t in 'lib' and 't' dirs.

 * New line is "\n", but not "\r\n"
 * In the end of lines there are no spaces before "\n"
 * In the end of file's last line there is "\n"
 * In the end of file there are no lines with only "\n" (but the file with
   just one line "\n" is valid)

There is a way this script can fix the files. You just need to specify
$DO_THE_CHANGE to be true.

=cut

use strict;
use warnings FATAL => 'all';
use 5.010;
use DDP colored => 1;

use File::Find;
use File::Slurp;
use lib::abs;

use Test::Differences;
use Test::More tests => 1;

my $DO_THE_CHANGE = 0;  # If true then the spaces will be fixed

my @files;
my @files_with_errors;

sub wanted {
    return unless -T $_;

    return if ($File::Find::name =~ m{/\.svn/} );
    return if ($File::Find::name =~ m{/\.git/} );

    if ($File::Find::name =~ /\.t$|\.pm$/) {
        push @files, $File::Find::name;
    }
};

find(
    \&wanted,
    lib::abs::path('../lib'),
    lib::abs::path('../t'),
);

foreach my $file (@files) {
    my $original_content = read_file($file);

    my @lines = split /\n/, $original_content;

    foreach (@lines) {
        s/\r$//;
        s/\s*$//;
    }

    # removing emplty lines on bottom of the file
    foreach (reverse @lines) {
        if ($_ =~ /^\s*$/) {
            pop @lines;
        } else {
            last;
        }
    }

    my $fixed_content = join("\n", @lines) . "\n";

    if ($original_content ne $fixed_content) {
        if ($DO_THE_CHANGE) {
            write_file($file, $fixed_content);
        }
        push @files_with_errors, $file;
    }
}

eq_or_diff(
    join ("\n", @files_with_errors),
    '',
    "Found no files with whitespace problems"
);
