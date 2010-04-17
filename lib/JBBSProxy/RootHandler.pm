package JBBSProxy::RootHandler;
use base qw(Tatsumaki::Handler);

sub get {
    my $self = shift;
    $self->render('index.html');
}

sub post {
    my $self = shift;
    my $url = $self->request->param('url');
    return $self->response->redirect("/$url");
}

1;
