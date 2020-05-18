#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );
use Cwd qw(getcwd);

use Archive::Tar;
use POSIX qw(strftime);
use MaxMind::DB::Writer::Tree;
use File::Path;
use File::Copy;
use Net::Works::Network;



sub create_asn_mmdb {
    my %types = (
        autonomous_system_number        => 'uint32',
        autonomous_system_organization  => 'utf8_string',
    );

    my $tree = MaxMind::DB::Writer::Tree->new(
        ip_version            => 4,
        record_size           => 28,
        database_type         => 'GeoIP2-ASN',
        languages             => ['en'],
        description           => { en => 'GeoLite2 ASN database' },
        map_key_type_callback => sub { $types{ $_[0] } },
    );

    my %ip_address = (
        '8.8.4.0/24' => {
            autonomous_system_number        => 15169,
            autonomous_system_organization  => 'GOOGLE',
        },
    );

    for my $address ( keys %ip_address) {
        my $network = Net::Works::Network->new_from_string( string => $address );
        $tree->insert_network( $network, $ip_address{ $address });
    }

    my $datestring = strftime "%Y%m%d", localtime;
    my $directory = "GeoLite2-ASN_$datestring";

    unless(mkdir $directory) {
        die "Unable to create $directory\n";
    }

    my $asn_filename = "$directory/GeoLite2-ASN.mmdb";

    # Write the database to disk.
    open my $fh, '>:raw', $asn_filename;
    $tree->write_tree( $fh );
    close $fh;

    # Write the new mmdb files to tarred archives
    my $tar = Archive::Tar->new();
    {
        use autodie;   
        $tar->add_files("$directory/GeoLite2-ASN.mmdb");

    }

    $tar->write('GeoLite2-ASN.tar.gz', COMPRESS_GZIP);

    # Clean up
    rmtree $directory;
    move("GeoLite2-ASN.tar.gz", "../resources/");
}

sub create_city_mmdb {
}

create_asn_mmdb();
create_city_mmdb();

