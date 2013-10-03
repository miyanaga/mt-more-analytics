package MT::MoreAnalytics::Tags::Util;

use strict;
use MT::Util;
use MT::MoreAnalytics::Util;

sub hdlr_GADays {
    my ( $ctx, $args ) = @_;

    my $from = $args->{from}
        or return $ctx->error( '[_1] requires [_2] attribute.', 'mt:GADays', 'from' );
    my $to = $args->{to}
        or return $ctx->error( '[_1] requires [_2] attribute.', 'mt:GADays', 'to' );
}

1;