<?php

$cmd = 'composer.sh ';

$cmd.= $_SERVER['DOCUMENT_ROOT'] . '/';
$cmd = eregi_replace('server/.*$', '', $cmd) ;

$dataArray = array(
  'title' => 'Composer Install',
  'content' => '',
);

$dataArray['content'].= '<h1>Build on ' . $_SERVER['HTTP_HOST'] . '</h1>';

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
