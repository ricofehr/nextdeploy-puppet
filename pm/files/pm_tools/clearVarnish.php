<?php
$host = $_SERVER['HTTP_HOST'] ;
$cmd = "varnishadm -T 127.0.0.1:6082 ban req.http.host == ".$host ;;
$dataArray = array(
	'title' => 'Clear Varnish Cache - ' . $host,
	'content' => '',
);

$dataArray['content'].= '<h1>' . $host . '</h1>';

$cmdOutput = array();
$return_var = -1;
chdir($_SERVER['DOCUMENT_ROOT']) ;
if(is_file("sites/default/settings.php"))exec("drush cc all", $cmdOutput, $return_var);
$return = exec($cmd, $cmdOutput, $return_var);

if ($return_var) {
	$dataArray['content'].= '<div class="error"><strong>An error as occured! Please check script output bellow.</strong></div>';
}
else $dataArray['content'].= '<pre>clear cache done !</pre>' ;

require_once('include/displaySimple.inc.php');
