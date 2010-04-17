package JBBSProxy::AboutHandler;
use base qw(Tatsumaki::Handler);

sub get {
    my $self = shift;
    $self->render('about.html');
}

1;
