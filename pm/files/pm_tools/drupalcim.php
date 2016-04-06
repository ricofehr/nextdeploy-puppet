<?php

$cmd = './drupalcim.sh ';

$cmd.= $_SERVER['DOCUMENT_ROOT'] . '/';
$cmd = eregi_replace('server/.*$', '/', $cmd) ;


$dataArray = array(
	'title' => 'Drupal cim',
	'content' => '',
);

$cmdOutput = array();
$return_var = -1;

$return = exec($cmd, $cmdOutput, $return_var);

if ($return_var) {
	$dataArray['content'].= '<div class="error"><strong>'.$return_var.'  An error as occured! Please check script output bellow.</strong></div>';
}

for ($j = 0, $cnt2 = count($cmdOutput); $j < $cnt2; $j++) {
	$dataArray['content'].= '<pre>' . $cmdOutput[$j] . '</pre>';
}

require_once('include/displaySimple.inc.php');
