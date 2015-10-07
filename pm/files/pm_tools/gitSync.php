<?php

$cmd = './gitSync.sh ';

$cmd.= $_SERVER['DOCUMENT_ROOT'] . '/';
$cmd = eregi_replace('server/.*$', '/', $cmd) ;

if (isset($_GET['t']))
{
	$cmd .= " ".$_GET['t'] ;
}

$dataArray = array(
	'title' => 'Git pull',
	'content' => '',
);

$dataArray['content'].= '<h1>Pull on ' . $_SERVER['HTTP_HOST'] . '</h1>';

$cmdOutput = array();
$return_var = -1;
$return = exec($cmd, $cmdOutput, $return_var);

if ($return_var) {
	$dataArray['content'].= '<div class="error"><strong>An error as occured! Please check script output bellow.</strong></div>';
}

for ($j = 0, $cnt2 = count($cmdOutput); $j < $cnt2; $j++) {
	$dataArray['content'].= '<pre>' . $cmdOutput[$j] . '</pre>';
	if(@eregi("^.*HEAD is now.*$", $cmdOutput[$j]) && !isset($msg2))$msg2 = $cmdOutput[$j] ;
}

$host = $_SERVER['HTTP_HOST'] ;
$cmd = "varnishadm -T 127.0.0.1:6082 ban req.http.host == ".$host ;
exec($cmd, $cmdOutput, $return_var);
require_once('include/displaySimple.inc.php');
