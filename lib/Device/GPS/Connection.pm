package Device::GPS::Connection;

use v5.14;
use warnings;
use Moose::Role;

requires 'read_nmea_sentence';

1;
__END__

