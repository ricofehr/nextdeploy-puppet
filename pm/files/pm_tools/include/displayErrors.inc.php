<?php

/*
$dataArray = array (
	'code' => 500,
	'log' => true,
	'description' => 'Votre requête n\'a pu aboutir car une erreur interne au serveur est survenue !',
);
*/

if (! empty($dataArray['log'])) {
	require_once(dirname(__FILE__) . '/functions.inc.php');
	myLog($dataArray['code']);
}

// format français
if (setlocale(LC_TIME, 'fr_FR.utf8') === FALSE) {
    die('unable to setlocale()!');
}

$htmlDate = strftime('le %A %d %B %Y, à %H heures %M minutes et %S secondes', time());
$htmlRequesturi = 'http://' . htmlentities($_SERVER['SERVER_NAME'] . $_SERVER['REQUEST_URI'], ENT_QUOTES);
$htmlRemoteAddr = htmlentities($_SERVER['REMOTE_ADDR'], ENT_QUOTES);
if (gethostbyaddr($_SERVER['REMOTE_ADDR']) != $_SERVER['REMOTE_ADDR']) {
    $htmlRemoteAddr.= ' (' . htmlentities(gethostbyaddr($_SERVER['REMOTE_ADDR'])) . ')';
}
$htmlAgent = htmlentities($_SERVER['HTTP_USER_AGENT'], ENT_QUOTES);

$htmlReferer = '-';
if (! empty($_SERVER['HTTP_REFERER'])) {
	// TODO: better cause petable and syntaxe
	$htmlReferer = '<a href="' . $_SERVER['HTTP_REFERER'] . '" title="Revenir à la page de provenance">'
		. htmlentities($_SERVER['HTTP_REFERER'], ENT_QUOTES)
		. '</a>';
}

$htmlPost = '';
foreach ($_POST as $k => $v) {
	$htmlPost .= '<li>' . htmlentities($k, ENT_QUOTES) . ' = ' . htmlentities($v, ENT_QUOTES) . '</li>';
}
if (! empty($htmlPost)) {
	$htmlPost = '<ul>' . $htmlPost . '</ul>';
} else {
	$htmlPost = '-';
}


?>
<!DOCTYPE html
     PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="fr-FR" lang="fr-FR">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<title>Erreur <?php print ($dataArray['code']); ?></title>
</head>
<body>
	<h1>Erreur <?php print ($dataArray['code']); ?></h1>
	<h2><?php print ($dataArray['description']); ?></h2>

	<p>
		Request : <?php print($htmlRequesturi); ?><br />
		POST parameters : <?php print($htmlPost); ?><br />
		Referer : <?php print($htmlReferer); ?><br />
		Remote address : <?php print($htmlRemoteAddr); ?><br />
		User Agent : <?php print($htmlAgent); ?><br />
		Date : <?php print($htmlDate); ?><br />
	</p>

</body>
</html>
