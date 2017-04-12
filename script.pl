#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA;

__PACKAGE__->main;
exit;

sub main {
    my $self = shift;
    my $directory;
    my $url;

     if (@ARGV <= 1) {
        print STDERR "ERROR: Must be ran as the following:\n";
        print "./script.pl DIRECTORY URL\n";
        print "Example: ./script.pl ~/Code/ http://pastebin.com\n";
        exit;
    } else {
        $directory = $ARGV[0] || die 'ERROR: please enter a directory as argument.';
        $url       = $ARGV[1] || die 'ERROR: please enter a URL as argument.';
    }

    my @files = $self->read_directory($directory, $url);
    die @files;
}

sub read_directory {
    my ($self, $directory, $url) = @_;
    my @files;

    opendir (DIR, $directory) or die $!;

    while (my $filename = readdir(DIR)) {
        my $file = "$directory/$filename";
        $file =~ s/\/\//\//g; # strip double slash '//'

        if (-f $file) {
            open(FILE, $file) or die "ERROR: $file could not be opened."; 
            binmode(FILE); # Neccessary for proper sha256

            # compute sha256sum
            my $digest = Digest::SHA->new(256);
            $digest->addfile(*FILE);
            my $sha = $digest->hexdigest();

            push @files, {
                id   => $sha,
                path => $file, 
                size => -s $file,
            };
        }
    }

    closedir(DIR);

    return @files; 
}