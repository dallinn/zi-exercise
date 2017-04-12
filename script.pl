#!/usr/bin/env perl

use strict;
use warnings;

use Archive::Tar;
use Digest::SHA;
use JSON;
use LWP::UserAgent;

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
    $self->write_tar(@files);
    $self->send_tar($url);

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

sub write_tar {
    my ($self, @files) = @_;
    my $tar = Archive::Tar->new();

    my $json = to_json(\@files);
    $tar->add_data('manifest.json', $json);

    foreach (@files) {
        my ($ext) = $_->{path} =~ /(\.[^.]+)$/; # last '.xxx' in full path
        $tar->add_data("$_->{id}$ext", $_->{path});
    }

    $tar->write('archive.tar.gz', COMPRESS_GZIP);
}

sub send_tar {
    my ($self, $url) = @_;
    my $ua   = LWP::UserAgent->new;
    my $gz   = "./archive.tar.gz";

    my $req = $ua->post($url,
        Content_Type => 'multipart/form-data',
        Content      => [ arc_file  => [ $gz ] ],
    );

    if ($req->is_success) {
        my $message = $req->decoded_content;
        print "$url response: $message\n";
    } else {
        print STDERR "$url ERROR:", $req->code, ", ", $req->message, "\n";
    }
}
