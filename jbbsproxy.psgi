use strict;
use warnings;
use File::Basename;
use Tatsumaki::Application;

use JBBSProxy::RootHandler;
use JBBSProxy::AboutHandler;
use JBBSProxy::SubjectHandler;
use JBBSProxy::ThreadHandler;

my $app = Tatsumaki::Application->new([
    '/' => 'JBBSProxy::RootHandler',
    '/about' => 'JBBSProxy::AboutHandler',
    '/http://jbbs.livedoor.jp/(\w+)/(\d+)/?' => 'JBBSProxy::SubjectHandler',
    '/http://jbbs.livedoor.jp/bbs/read\.cgi/(\w+)/(\d+)/(\d+)/?(l?[0-9-]+n?)?' => 'JBBSProxy::ThreadHandler',
]);

$app->template_path('template');
$app->static_path('static');

if (__FILE__ eq $0) {
    require Tatsumaki::Server;
    Tatsumaki::Server->new(port => 9999)->run($app);
} else {
    return $app;
}
