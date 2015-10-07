<?php
ini_set('memory_limit', '128M') ;

// Minimal PHPTail
$refreshDelay = 60;
$linesNumber = 100;

$dataArray = array(
	'title' => 'Main logs HTTP view - Apache / PHP / MySQL',
	'content' => '',
);

$host = $_SERVER['HTTP_HOST'];
$host = ereg_replace('^admin\.', '', $host);
$host = ereg_replace('^m\.', '', $host);

$logFiles = array(
  "/var/log/apache2/".$host."_error.log" => 'Vhost Error Apache Log',
	"/var/log/apache2/".$host."_access.log" => 'Vhost Access Apache Log',
  '/var/log/apache2/error.log' => 'Global Error Apache Log',
	'/var/log/apache2/access.log' => 'Global Access Apache Log',
);


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
