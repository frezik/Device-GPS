package Device::GPS;

use v5.14;
use warnings;
use Moose;
use namespace::autoclean;
use Device::GPS::Connection;

# ABSTRACT: Read GPS (NMEA) data over a wire

use constant {
    'CALLBACK_POSITION'     => '$GPGGA',
    'CALLBACK_ACTIVE_SATS'  => '$GPGSA',
    'CALLBACK_SATS_IN_VIEW' => '$GPGSV',
    'CALLBACK_REC_MIN'      => '$GPRMC',
    'CALLBACK_GEO_LOC'      => '$GPGLL',
    'CALLBACK_VELOCITY'     => '$GPVTG',
};

has 'connection' => (
    is       => 'ro',
    isa      => 'Device::GPS::Connection',
    required => 1,
);

has '_callbacks' => (
    is  => 'ro',
    isa => 'HashRef[ArrayRef[CodeRef]]',
    default => sub {{
        CALLBACK_POSITION     => [],
        CALLBACK_ACTIVE_SATS  => [],
        CALLBACK_SATS_IN_VIEW => [],
        CALLBACK_REC_MIN      => [],
        CALLBACK_GEO_LOC      => [],
        CALLBACK_VELOCITY     => [],
    }},
);


sub add_callback
{
    my ($self, $type, $callback) = @_;
    push @{ $self->_callbacks->{$type} }, $callback;
    return 1;
}

sub parse_next
{
    my ($self) = @_;
    my $sentence = $self->connection->read_nmea_sentence;
    my ($type, @data) = split /,/, $sentence;
    my $checksum = pop @data;
    # TODO verify checksum
    @data = $self->_convert_data_by_type( $type, @data );

    foreach my $callback (@{ $self->_callbacks->{$type} }) {
        $callback->(@data);
    }

    return 1;
}

sub _convert_data_by_type
{
    my ($self, $type, @data) = @_;
    $type =~ s/\A\$//;
    my $method = '_convert_data_for_' . $type;
    @data = $self->$method( @data ) if $self->can( $method );
    return @data;
}

sub _convert_data_for_GPGGA
{
    my ($self, @data) = @_;

    my $convert = sub {
        my ($datapoint) = @_;
        $datapoint /= 100;
        return int($datapoint) + ($datapoint - int($datapoint))
            * 1.66666667;
    };

    $data[1] = $convert->( $data[1] );
    $data[3] = $convert->( $data[3] );

    return @data;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

  Device::GPS - Read GPS (NMEA) data over a wire

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 SEE ALSO

L<GPS::NMEA>

=head1 LICENSE

Copyright (c) 2015  Timm Murray
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright 
      notice, this list of conditions and the following disclaimer in the 
      documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.

=cut
