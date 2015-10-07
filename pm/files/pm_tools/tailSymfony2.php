<?php

// Minimal PHPTail
$refreshDelay = 60;
$linesNumber = 250;

$dataArray = array(
	'title' => 'Main logs HTTP view - Apache / PHP / MySQL',
	'content' => '',
);

$dir = str_replace('/web', '', $_SERVER['DOCUMENT_ROOT'].'/app/logs/') ;
$logFiles = array(
);

if (is_dir($dir)) {
    if ($dh = opendir($dir)) {
        while (($file = readdir($dh)) !== false) {
        	if(eregi('.*\.log$', $file))$logFiles[$dir.$file] = $file ;
	}
        closedir($dh);
    }
}

foreach ($logFiles as $k => $v) {

	$dataArray['content'].= '<h1>' . $v . ': ' . htmlentities(basename($k)) . '</h1>';

		$cmdOutput = array();
		exec('tail --lines=' . $linesNumber . ' ' . $k, $cmdOutput);
		
		$dataArray['content'].= '<pre>';
		for ($j = 0, $cnt2 = count($cmdOutput); $j < $cnt2; $j++) {
			$dataArray['content'].= htmlentities($cmdOutput[$j], ENT_QUOTES) . chr(10);
		}
		$dataArray['content'].= '</pre>';
/*
	}
*/
}



require_once('include/displaySimple.inc.php');
